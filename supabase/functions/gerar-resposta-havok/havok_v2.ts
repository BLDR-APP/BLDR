/** Pure HAVOK V2 contract helpers. Keep this file free of runtime secrets and
 * database access so response validation stays deterministic and testable. */

export const HAVOK_RESPONSE_VERSION = 2 as const

export const HAVOK_INTENTS = [
  'GENERAL',
  'WORKOUT_ANALYSIS',
  'WORKOUT_RECOMMENDATION',
  'WORKOUT_GENERATION',
  'NUTRITION_ANALYSIS',
  'NUTRITION_RECOMMENDATION',
  'RECIPE_GENERATION',
  'NUTRITION_PLAN_GENERATION',
  'PROGRESS_ANALYSIS',
  'RECOVERY_ANALYSIS',
  'PLAN_ADJUSTMENT',
] as const
export type HavokIntent = typeof HAVOK_INTENTS[number]

export const HAVOK_ACTIONS = [
  'START_WORKOUT', 'SAVE_WORKOUT', 'ADD_WORKOUT_TO_PLAN',
  'REPLACE_EXERCISE', 'EDIT_WORKOUT', 'OPEN_WORKOUT_ANALYTICS',
  'OPEN_EXERCISE_PROGRESS', 'SAVE_RECIPE', 'ADD_MEAL_TO_DIARY',
  'SAVE_NUTRITION_PLAN', 'OPEN_NUTRITION',
] as const
export type HavokActionType = typeof HAVOK_ACTIONS[number]

export type HavokInsight = {
  type: string
  title: string
  value: string
  delta?: string
  period?: string
  source: string
}

export type HavokAction = {
  type: HavokActionType
  label: string
  payload: Record<string, unknown>
}

export type MemoryCandidate = {
  operation: 'create' | 'update' | 'supersede' | 'forget'
  category: string
  key: string
  value?: unknown
  confidence?: number
}

export type HavokResponseV2 = {
  version: 2
  intent: HavokIntent
  message: string
  insights: HavokInsight[]
  artifact: { type: 'workout' | 'recipe' | 'nutrition_plan'; data: Record<string, unknown> } | null
  actions: HavokAction[]
  followUpSuggestions: string[]
  memoryCandidates: MemoryCandidate[]
}

/** The summary is deliberately refreshed infrequently: it complements the
 * recent message window instead of duplicating the whole conversation. */
export function shouldRefreshThreadSummary(messageCount: number): boolean {
  return messageCount >= 12 && messageCount % 6 === 0
}

export function compactThreadSummary(rows: Array<{ role?: unknown; content?: unknown }>): string {
  return rows.slice(-8).map((row) => {
    const role = row.role === 'user' ? 'Usuário' : 'HAVOK'
    return `${role}: ${String(row.content ?? '').replace(/\s+/g, ' ').trim().slice(0, 220)}`
  }).join('\n').slice(0, 1800)
}

export type NutritionContextSnapshot = {
  date: string
  caloriesConsumed: number
  protein: number
  carbs: number
  fat: number
  calorieGoal: number | null
  proteinGoal: number | null
  carbsGoal: number | null
  fatGoal: number | null
  water?: number
  mealsCount?: number
  generatedAt: string
}

export const volatileMemoryTerms = [
  'pr', '1rm', 'e1rm', 'peso', 'weight', 'recovery', 'strain', 'hrv',
  'resting', 'caloria', 'calorie', 'macro', 'volume', 'streak', 'frequência',
]

const memoryCategories = new Set([
  'preference', 'goal', 'constraint', 'routine', 'training_preference',
  'nutrition_preference', 'equipment', 'context',
])

export function routeIntent(message: string): HavokIntent {
  const text = message.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
  if (/(recuper|sono|dorm|hrv|strain|whoop|fadiga|cansad)/.test(text)) return 'RECOVERY_ANALYSIS'
  if (/(receita|cozin|ingrediente)/.test(text)) return 'RECIPE_GENERATION'
  if (/(dieta|plano alimentar|refeicao|caloria|proteina|macro|nutri)/.test(text)) {
    return /(monte|crie|plano)/.test(text) ? 'NUTRITION_PLAN_GENERATION' : 'NUTRITION_ANALYSIS'
  }
  if (/(evolucao|progresso|peso|medida)/.test(text)) return 'PROGRESS_ANALYSIS'
  if (/(treino|exercicio|supino|agachamento|volume|serie|repet)/.test(text)) {
    if (/(monte|crie|gere|gerar)/.test(text)) return 'WORKOUT_GENERATION'
    if (/(devo|recomenda|sugere|sugira)/.test(text)) return 'WORKOUT_RECOMMENDATION'
    return 'WORKOUT_ANALYSIS'
  }
  if (/(plano|semana|semana)/.test(text)) return 'PLAN_ADJUSTMENT'
  return 'GENERAL'
}

export function contextDomains(intent: HavokIntent): string[] {
  switch (intent) {
    case 'WORKOUT_ANALYSIS': return ['user', 'workout', 'memory']
    case 'WORKOUT_RECOMMENDATION':
    case 'WORKOUT_GENERATION': return ['user', 'workout', 'whoop', 'activities', 'memory']
    case 'NUTRITION_ANALYSIS':
    case 'NUTRITION_RECOMMENDATION':
    case 'RECIPE_GENERATION':
    case 'NUTRITION_PLAN_GENERATION': return ['user', 'nutrition', 'memory']
    case 'PROGRESS_ANALYSIS': return ['user', 'progress', 'workout', 'memory']
    case 'RECOVERY_ANALYSIS': return ['whoop', 'activities', 'workout', 'memory']
    case 'PLAN_ADJUSTMENT': return ['user', 'workout', 'whoop', 'activities', 'memory']
    default: return ['user', 'memory']
  }
}

function record(value: unknown): Record<string, unknown> | null {
  return value != null && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null
}

function cleanText(value: unknown, max: number): string | null {
  if (typeof value !== 'string') return null
  const text = value.trim()
  return text.length > 0 && text.length <= max ? text : null
}

function validateInsights(value: unknown): HavokInsight[] | null {
  if (!Array.isArray(value) || value.length > 4) return null
  const insights: HavokInsight[] = []
  for (const item of value) {
    const row = record(item)
    const type = cleanText(row?.type, 48)
    const title = cleanText(row?.title, 80)
    const insightValue = cleanText(row?.value, 80)
    const source = cleanText(row?.source, 80)
    if (!type || !title || !insightValue || !source) return null
    const delta = row?.delta == null ? undefined : cleanText(row.delta, 48)
    const period = row?.period == null ? undefined : cleanText(row.period, 48)
    if ((row?.delta != null && !delta) || (row?.period != null && !period)) return null
    insights.push({ type, title, value: insightValue, source, ...(delta ? { delta } : {}), ...(period ? { period } : {}) })
  }
  return insights
}

function validateActions(value: unknown): HavokAction[] | null {
  if (!Array.isArray(value) || value.length > 3) return null
  const actions: HavokAction[] = []
  for (const item of value) {
    const row = record(item)
    const type = cleanText(row?.type, 48)
    const label = cleanText(row?.label, 80)
    const payload = record(row?.payload)
    if (!type || !label || !payload || !HAVOK_ACTIONS.includes(type as HavokActionType)) return null
    // Routes, functions and arbitrary URLs must never be model-controlled.
    if (Object.keys(payload).some((key) => /route|function|url|callback|sql|rpc|user/i.test(key))) return null
    actions.push({ type: type as HavokActionType, label, payload })
  }
  return actions
}

function validateArtifact(value: unknown): HavokResponseV2['artifact'] | null | undefined {
  if (value == null) return null
  const row = record(value)
  const type = cleanText(row?.type, 32)
  const data = record(row?.data)
  if (!type || !data || !['workout', 'recipe', 'nutrition_plan'].includes(type)) return undefined
  if (type === 'workout') {
    const exercises = data.exercicios ?? data.exercises
    if (!Array.isArray(exercises) || exercises.length < 1 || exercises.length > 12) return undefined
    // The resolver will add canonical IDs. Never accept a workout artifact that
    // is already marked canonical without a valid identity for every exercise.
    if (data.canonical === true && exercises.some((exercise) => !cleanText(record(exercise)?.exercise_id, 128))) return undefined
  }
  return { type: type as 'workout' | 'recipe' | 'nutrition_plan', data }
}

export function validateMemoryCandidates(value: unknown): MemoryCandidate[] | null {
  if (value == null) return []
  if (!Array.isArray(value) || value.length > 4) return null
  const candidates: MemoryCandidate[] = []
  for (const item of value) {
    const row = record(item)
    const operation = cleanText(row?.operation, 16)
    const category = cleanText(row?.category, 48)
    const key = cleanText(row?.key, 120)
    const confidence = row?.confidence == null ? undefined : Number(row.confidence)
    if (!operation || !category || !key || !['create', 'update', 'supersede', 'forget'].includes(operation) || !memoryCategories.has(category)) return null
    if (volatileMemoryTerms.some((term) => key.toLowerCase().includes(term))) return null
    if (confidence != null && (!Number.isFinite(confidence) || confidence < 0 || confidence > 1)) return null
    if (operation !== 'forget' && row?.value == null) return null
    candidates.push({ operation: operation as MemoryCandidate['operation'], category, key, ...(operation === 'forget' ? {} : { value: row?.value }), ...(confidence == null ? {} : { confidence }) })
  }
  return candidates
}

/// Firestore diary data stays client-side. This validates only the bounded
/// deterministic summary produced by the existing BLDR nutrition use cases.
export function validateNutritionSnapshot(value: unknown): NutritionContextSnapshot | null {
  const row = record(value)
  const date = cleanText(row?.date, 32)
  const generatedAt = cleanText(row?.generatedAt, 48)
  const amount = (key: string, nullable = false): number | null => {
    const raw = row?.[key]
    if (raw == null && nullable) return null
    const parsed = Number(raw)
    return Number.isFinite(parsed) && parsed >= 0 && parsed <= 100000 ? parsed : null
  }
  const caloriesConsumed = amount('caloriesConsumed')
  const protein = amount('protein')
  const carbs = amount('carbs')
  const fat = amount('fat')
  if (!date || !generatedAt || caloriesConsumed == null || protein == null || carbs == null || fat == null) return null
  const calorieGoal = amount('calorieGoal', true)
  const proteinGoal = amount('proteinGoal', true)
  const carbsGoal = amount('carbsGoal', true)
  const fatGoal = amount('fatGoal', true)
  if ((row?.calorieGoal != null && calorieGoal == null) || (row?.proteinGoal != null && proteinGoal == null) || (row?.carbsGoal != null && carbsGoal == null) || (row?.fatGoal != null && fatGoal == null)) return null
  const water = row?.water == null ? undefined : amount('water')
  const mealsCount = row?.mealsCount == null ? undefined : amount('mealsCount')
  if ((row?.water != null && water == null) ||
      (row?.mealsCount != null &&
          (mealsCount == null || !Number.isInteger(mealsCount) || mealsCount > 20))) return null
  return { date, caloriesConsumed, protein, carbs, fat, calorieGoal, proteinGoal, carbsGoal, fatGoal, ...(water == null ? {} : { water }), ...(mealsCount == null ? {} : { mealsCount }), generatedAt }
}

export function validateResponseV2(raw: unknown, expectedIntent: HavokIntent): HavokResponseV2 | null {
  const row = record(raw)
  const version = row?.version
  const intent = cleanText(row?.intent, 48)
  const message = cleanText(row?.message, 5000)
  const insights = validateInsights(row?.insights ?? [])
  const artifact = validateArtifact(row?.artifact)
  const actions = validateActions(row?.actions ?? [])
  const followUpsRaw = row?.followUpSuggestions ?? []
  const memories = validateMemoryCandidates(row?.memoryCandidates)
  if (version !== HAVOK_RESPONSE_VERSION || !intent || !message || !HAVOK_INTENTS.includes(intent as HavokIntent) || intent !== expectedIntent || !insights || artifact === undefined || !actions || !Array.isArray(followUpsRaw) || followUpsRaw.length > 4 || !memories) return null
  const followUpSuggestions = followUpsRaw.map((item) => cleanText(item, 120))
  if (followUpSuggestions.some((item) => item == null)) return null
  return { version: HAVOK_RESPONSE_VERSION, intent: intent as HavokIntent, message, insights, artifact, actions, followUpSuggestions: followUpSuggestions as string[], memoryCandidates: memories }
}

export function responseSchemaPrompt(): string {
  return `Responda somente JSON válido neste schema: {"version":2,"intent":"${HAVOK_INTENTS.join('|')}","message":"texto","insights":[{"type":"string","title":"string","value":"string","delta":"opcional","period":"opcional","source":"fonte BLDR"}],"artifact":null|{"type":"workout|recipe|nutrition_plan","data":{}},"actions":[{"type":"${HAVOK_ACTIONS.join('|')}","label":"string","payload":{}}],"followUpSuggestions":["string"],"memoryCandidates":[{"operation":"create|update|supersede|forget","category":"preference|goal|constraint|routine|training_preference|nutrition_preference|equipment|context","key":"string","value":"opcional em forget","confidence":0.0}]}.
Nunca invente métricas. Insights devem citar apenas dados recebidos no contexto. Ações são propostas e não executam nada. Para workouts, use exercicios com nome, series, repeticoes, descanso_segundos; o backend resolverá identidades canônicas antes de persistir.`
}
