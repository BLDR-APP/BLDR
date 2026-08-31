// @ts-ignore
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
// @ts-ignore
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { compactThreadSummary, contextDomains, routeIntent, responseSchemaPrompt, shouldRefreshThreadSummary, validateNutritionSnapshot, validateResponseV2, type HavokAction, type HavokIntent, type HavokResponseV2 } from './havok_v2.ts'

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' }
const model = 'claude-haiku-4-5-20251001'
const labels: Record<string, string> = { pt: 'português do Brasil', en: 'English', it: 'italiano' }

function json(text: string): unknown { return JSON.parse(text.replace(/```json/gi, '').replace(/```/g, '').trim()) }

async function optional<T>(work: () => PromiseLike<{ data: T | null; error: unknown }>): Promise<T | null> {
  try { const result = await work(); return result.error ? null : result.data } catch (_) { return null }
}

async function askClaude(prompt: string, locale: string): Promise<string> {
  const apiKey = Deno.env.get('ANTHROPIC_API_KEY')
  if (!apiKey) throw new Error('ANTHROPIC_API_KEY não configurada.')
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST', headers: { 'Content-Type': 'application/json', 'anthropic-version': '2023-06-01', 'x-api-key': apiKey },
    body: JSON.stringify({
      model, max_tokens: 1400,
      system: `Você é HAVOK, o coach de performance do BLDR. Responda em ${labels[locale] ?? labels.pt}. BLDR calcula; você interpreta apenas fatos no contexto. Não invente métricas, não diagnostique, não execute ações e não transforme atividades WHOOP em treinos BLDR. ${responseSchemaPrompt()}`,
      messages: [{ role: 'user', content: prompt }],
    }),
  })
  if (!response.ok) throw new Error(`Anthropic HTTP ${response.status}`)
  const data = await response.json()
  if (!data.content?.[0]?.text) throw new Error('Resposta vazia.')
  return data.content[0].text
}

function deviceContext(raw: unknown): Record<string, unknown> {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return {}
  const input = raw as Record<string, unknown>
  const health = input.appleHealth
  // HealthKit remains device-local. The caller may opt in to this bounded snapshot.
  const nutrition = input.nutrition
  const nutritionSnapshot = validateNutritionSnapshot(input.nutritionSnapshot ?? input.nutrition)
  return {
    ...(health && typeof health === 'object' && !Array.isArray(health) ? { appleHealth: health } : {}),
    // The diary is stored in Firestore and is not mirrored into Supabase. Only
    // the already-calculated current summary is accepted — never raw meals.
    ...(nutritionSnapshot ? { nutritionSummary: nutritionSnapshot } : {}),
  }
}

function workoutAnalytics(sessions: any[], sets: any[], plan: any[]) {
  const completedSets = sets.filter((set) => set.completed_at != null)
  const totalVolume = completedSets.reduce((total, set) => total +
    (Number(set.weight_kg) || 0) * (Number(set.reps) || 0), 0)
  const totalDurationSeconds = sessions.reduce((total, session) => total + (Number(session.total_duration_seconds) || 0), 0)
  const byExercise = new Map<string, { name: string; volume: number; bestE1rm: number; sets: number }>()
  for (const set of completedSets) {
    const exercise = set.exercises ?? {}
    const id = set.exercise_id ?? set.exercise_db_id
    if (!id) continue
    const current = byExercise.get(id) ?? { name: exercise.name ?? 'Exercício', volume: 0, bestE1rm: 0, sets: 0 }
    const reps = Number(set.reps) || 0; const weight = Number(set.weight_kg) || 0
    current.volume += weight * reps; current.sets += 1
    current.bestE1rm = Math.max(current.bestE1rm, weight * (1 + reps / 30))
    byExercise.set(id, current)
  }
  const muscleExposure: Record<string, number> = {}
  for (const set of completedSets) {
    const muscle = set.exercises?.primary_muscle_group
    if (typeof muscle === 'string' && muscle) muscleExposure[muscle] = (muscleExposure[muscle] ?? 0) + 1
  }
  return {
    frequencyLast28Days: sessions.length,
    recentSessionCount: sessions.length,
    completedSets: completedSets.length,
    volumeKg: Math.round(totalVolume * 100) / 100,
    totalDurationSeconds,
    averageDurationMinutes: sessions.length ? Math.round(totalDurationSeconds / sessions.length / 60) : null,
    exerciseProgress: [...byExercise.entries()].slice(0, 12).map(([exerciseId, value]) => ({ exerciseId, ...value, bestE1rm: Math.round(value.bestE1rm * 10) / 10 })),
    muscleExposure,
    currentWeeklyPlan: plan,
    source: 'user_workouts/workout_exercise_sets',
  }
}

async function contextFor(client: any, userId: string, intent: HavokIntent, local: Record<string, unknown>) {
  const domains = new Set(contextDomains(intent)); const context: Record<string, unknown> = { domains: [...domains] }
  if (domains.has('user') || domains.has('nutrition')) {
    const profile: any = await optional(() => client.from('user_profiles').select('onboarding_data, target_weight_kg').eq('id', userId).maybeSingle())
    const goals = profile?.onboarding_data && typeof profile.onboarding_data === 'object' ? profile.onboarding_data : {}
    if (profile) context.user = { goals, targetWeightKg: profile.target_weight_kg ?? null }
    if (domains.has('nutrition')) context.nutrition = { targets: { calories: goals.target_calories ?? null, protein: goals.target_protein ?? null, carbs: goals.target_carbs ?? null, fat: goals.target_fat ?? null }, summary: local.nutritionSummary ?? null }
  }
  if (domains.has('workout')) {
    const since = new Date(Date.now() - 28 * 86400000).toISOString()
    const sessions = await optional(() => client.from('user_workouts').select('id, name, started_at, completed_at, total_duration_seconds').eq('user_id', userId).not('completed_at', 'is', null).gte('completed_at', since).order('completed_at', { ascending: false }).limit(40)) as any[] | null
    const workoutIds = (sessions ?? []).map((session) => session.id).filter(Boolean)
    const [sets, plan] = await Promise.all([
      workoutIds.length ? optional(() => client.from('workout_exercise_sets').select('exercise_id, exercise_db_id, reps, weight_kg, completed_at, exercises(name, primary_muscle_group)').in('user_workout_id', workoutIds).limit(500)) : Promise.resolve([]),
      optional(() => client.from('weekly_plan_days').select('dia_semana, template_id, template_name, tipo, source').eq('user_id', userId).order('dia_semana')),
    ])
    context.workout = { recentSessions: sessions ?? [], source: 'user_workouts' }
    context.workoutAnalytics = workoutAnalytics(sessions ?? [], (sets as any[] | null) ?? [], (plan as any[] | null) ?? [])
  }
  if (domains.has('progress')) {
    const measurements = await optional(() => client.from('user_measurements').select('measurement_type, value, measured_at').eq('user_id', userId).order('measured_at', { ascending: false }).limit(16))
    context.progress = { measurements: measurements ?? [] }
  }
  if (domains.has('whoop')) {
    const daily = await optional(() => client.schema('bldr_club').from('whoop_daily_data').select('date, recovery_score, strain_score, sleep_score, hrv_rmssd, resting_heart_rate, sleep_duration_minutes, synced_at').eq('user_id', userId).order('date', { ascending: false }).limit(7)) as any[] | null
    context.whoop = { daily: daily ?? [], freshness: daily?.[0]?.synced_at ?? null }
  }
  if (domains.has('activities')) {
    const activities = await optional(() => client.from('wearable_activities').select('provider, activity_type, started_at, ended_at, strain, average_heart_rate, calories, status').eq('user_id', userId).eq('provider', 'whoop').neq('status', 'deleted').order('started_at', { ascending: false }).limit(10))
    context.whoopActivities = activities ?? []
  }
  if (domains.has('memory')) {
    const memories = await optional(() => client.schema('bldr_club').from('havok_memories').select('category, memory_key, value, updated_at').eq('user_id', userId).eq('active', true).order('updated_at', { ascending: false }).limit(30))
    context.memories = memories ?? []
  }
  if (Object.keys(local).length > 0) context.device = local
  return context
}

async function resolveWorkout(client: any, artifact: HavokResponseV2['artifact']): Promise<HavokResponseV2['artifact'] | null> {
  if (!artifact || artifact.type !== 'workout') return artifact
  const exercises = (artifact.data.exercicios ?? artifact.data.exercises) as unknown[]
  if (!Array.isArray(exercises) || exercises.length > 12) return null
  const canonical: Record<string, unknown>[] = []
  for (const raw of exercises) {
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null
    const entry = raw as Record<string, unknown>
    const exerciseId = typeof entry.exercise_id === 'string' ? entry.exercise_id : null
    const name = typeof entry.nome === 'string' ? entry.nome.trim() : typeof entry.name === 'string' ? entry.name.trim() : ''
    let found: any = null
    if (exerciseId) found = await optional(() => client.from('exercises').select('id, name, exercise_db_id').eq('id', exerciseId).maybeSingle())
    if (!found && name) found = await optional(() => client.from('exercises').select('id, name, exercise_db_id').ilike('name', name).limit(2).maybeSingle())
    // No free-text workout exercise may cross this persistence boundary.
    if (!found?.id) return null
    canonical.push({ ...entry, nome: found.name, exercise_id: found.id, exercise_db_id: found.exercise_db_id ?? null, resolution: 'RESOLVED' })
  }
  return { ...artifact, data: { ...artifact.data, canonical: true, exercicios: canonical } }
}

/** Resolves the only action that changes the workout artifact itself. The
 * model may suggest a name or ID, but the returned payload always contains
 * canonical exercise identities from BLDR's catalogue. */
async function resolveWorkoutActions(client: any, artifact: HavokResponseV2['artifact'], actions: HavokAction[]): Promise<HavokAction[] | null> {
  if (!artifact || artifact.type !== 'workout') return actions.filter((action) => !['START_WORKOUT', 'SAVE_WORKOUT', 'ADD_WORKOUT_TO_PLAN', 'REPLACE_EXERCISE'].includes(action.type))
  const exercises = (artifact.data.exercicios ?? artifact.data.exercises) as Array<Record<string, unknown>>
  const exerciseIds = new Set(exercises.map((exercise) => exercise.exercise_id).filter((id): id is string => typeof id === 'string'))
  const resolved: HavokAction[] = []
  for (const action of actions) {
    if (!['START_WORKOUT', 'SAVE_WORKOUT', 'ADD_WORKOUT_TO_PLAN', 'REPLACE_EXERCISE'].includes(action.type)) continue
    if (action.type !== 'REPLACE_EXERCISE') {
      resolved.push({ ...action, payload: {} })
      continue
    }
    const targetId = typeof action.payload.target_exercise_id === 'string' ? action.payload.target_exercise_id : ''
    const requestedId = typeof action.payload.replacement_exercise_id === 'string' ? action.payload.replacement_exercise_id : ''
    const requestedName = typeof action.payload.replacement_name === 'string' ? action.payload.replacement_name.trim() : ''
    if (!targetId || !exerciseIds.has(targetId) || (!requestedId && !requestedName)) return null
    const replacement: any = requestedId
      ? await optional(() => client.from('exercises').select('id, name, exercise_db_id').eq('id', requestedId).maybeSingle())
      : await optional(() => client.from('exercises').select('id, name, exercise_db_id').ilike('name', requestedName).limit(2).maybeSingle())
    if (!replacement?.id) return null
    resolved.push({
      ...action,
      payload: {
        target_exercise_id: targetId,
        replacement_exercise_id: replacement.id,
        replacement_exercise_db_id: replacement.exercise_db_id ?? null,
        replacement_name: replacement.name,
      },
    })
  }
  return resolved
}

async function saveMemoryCandidates(client: any, userId: string, candidates: HavokResponseV2['memoryCandidates']) {
  for (const memory of candidates) {
    if (memory.operation === 'forget') {
      await client.schema('bldr_club').from('havok_memories').update({ active: false, updated_at: new Date().toISOString() }).eq('user_id', userId).eq('category', memory.category).eq('memory_key', memory.key)
    } else {
      await client.schema('bldr_club').from('havok_memories').upsert({ user_id: userId, category: memory.category, memory_key: memory.key, value: memory.value, confidence: memory.confidence ?? .8, source: 'havok', active: true, updated_at: new Date().toISOString() }, { onConflict: 'user_id,category,memory_key' })
    }
  }
}

async function refreshThreadSummary(client: any, threadId: string, userId: string) {
  const { count, error: countError } = await client.schema('bldr_club').from('havok_messages')
    .select('id', { count: 'exact', head: true }).eq('thread_id', threadId)
  // Avoid summarizing every exchange. The first compacted summary happens at
  // 12 messages and then at six-message boundaries.
  if (countError || !count || !shouldRefreshThreadSummary(count)) return
  const { data: rows, error } = await client.schema('bldr_club').from('havok_messages')
    .select('role, content').eq('thread_id', threadId).order('created_at', { ascending: true }).limit(32)
  if (error || !rows?.length) return
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!serviceKey) return
  const admin = createClient(Deno.env.get('SUPABASE_URL') ?? '', serviceKey)
  await admin.schema('bldr_club').from('havok_thread_summaries').upsert({
    thread_id: threadId, user_id: userId, summary: compactThreadSummary(rows),
    source_message_count: count, updated_at: new Date().toISOString(),
  }, { onConflict: 'thread_id' })
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  // A short, sanitized stage marker makes an authenticated production trace
  // diagnosable without recording a JWT, user identity, prompt or model output.
  let stage = 'request'
  try {
    stage = 'auth'
    const authorization = req.headers.get('Authorization')
    if (!authorization) return new Response(JSON.stringify({ error: 'Usuário não autenticado.' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const client = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_ANON_KEY') ?? '', { global: { headers: { Authorization: authorization } } })
    const { data: { user } } = await client.auth.getUser()
    if (!user) return new Response(JSON.stringify({ error: 'Usuário não autenticado.' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    stage = 'request_body'
    const body = await req.json(); const threadId = typeof body.threadId === 'string' ? body.threadId : ''; const message = typeof body.userMessage === 'string' ? body.userMessage.trim() : ''
    if (!threadId || !message || message.length > 4000) throw new Error('Entrada inválida.')
    const { data: thread } = await client.schema('bldr_club').from('havok_threads').select('id').eq('id', threadId).eq('user_id', user.id).maybeSingle()
    if (!thread) return new Response(JSON.stringify({ error: 'Thread não encontrada.' }), { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    stage = 'context'
    const intent = routeIntent(message)
    const [history, summary, context] = await Promise.all([
      optional(() => client.schema('bldr_club').from('havok_messages').select('role, content').eq('thread_id', threadId).order('created_at', { ascending: false }).limit(20)),
      optional(() => client.schema('bldr_club').from('havok_thread_summaries').select('summary').eq('thread_id', threadId).eq('user_id', user.id).maybeSingle()),
      contextFor(client, user.id, intent, deviceContext(body.deviceContext ?? body.context)),
    ])
    const transcript = ((history as any[] | null) ?? []).reverse().map((item) => `${item.role === 'user' ? 'Usuário' : 'HAVOK'}: ${item.content}`).join('\n')
    const prompt = `Intent: ${intent}\nContexto factual:\n${JSON.stringify(context)}\nResumo: ${(summary as any)?.summary ?? '(sem resumo)'}\nHistórico:\n${transcript || '(início)'}\nPergunta: ${message}`
    stage = 'user_message_persistence'
    const { error: userError } = await client.schema('bldr_club').from('havok_messages').insert({ thread_id: threadId, role: 'user', content: message })
    if (userError) throw new Error('Não foi possível salvar a mensagem.')
    stage = 'anthropic_request'
    const rawResponse = await askClaude(prompt, typeof body.locale === 'string' ? body.locale : 'pt')
    stage = 'v2_response_validation'
    const response = validateResponseV2(json(rawResponse), intent)
    if (!response) return new Response(JSON.stringify({ error: 'Resposta HAVOK inválida.' }), { status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    stage = 'artifact_resolution'
    const artifact = await resolveWorkout(client, response.artifact)
    if (response.artifact?.type === 'workout' && !artifact) return new Response(JSON.stringify({ error: 'Não consegui resolver os exercícios. Peça nomes mais específicos.' }), { status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    stage = 'action_resolution'
    const actions = await resolveWorkoutActions(client, artifact, response.actions)
    if (!actions) return new Response(JSON.stringify({ error: 'Não consegui validar a substituição de exercício.' }), { status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    const safe = { ...response, artifact, actions }
    stage = 'memory_persistence'
    await saveMemoryCandidates(client, user.id, safe.memoryCandidates)
    stage = 'assistant_message_persistence'
    const { data: saved, error } = await client.schema('bldr_club').from('havok_messages').insert({ thread_id: threadId, role: 'assistant', content: safe.message, artifact_type: safe.artifact?.type ?? null, artifact_data: safe.artifact?.data ?? null, response_version: 2, response_data: safe }).select().single()
    if (error) throw new Error('Não foi possível salvar a resposta.')
    stage = 'thread_update'
    await client.schema('bldr_club').from('havok_threads').update({ last_message_at: new Date().toISOString() }).eq('id', threadId)
    stage = 'thread_summary'
    await refreshThreadSummary(client, threadId, user.id)
    stage = 'response'
    return new Response(JSON.stringify(saved), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    console.error('gerar-resposta-havok failed', { stage, message: (error as Error).message })
    return new Response(JSON.stringify({ error: 'HAVOK indisponível no momento.' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
