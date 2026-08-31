import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const WHOOP_WORKOUTS_URL =
  'https://api.prod.whoop.com/developer/v2/activity/workout'

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Não autorizado' }, 401)

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', ''),
    )
    if (authError || !user) return json({ error: 'Token inválido' }, 401)

    const { data: tokenRow, error: tokenError } = await supabase
      .schema('bldr_club')
      .from('whoop_tokens')
      .select('access_token, expires_at, last_workout_sync_at')
      .eq('user_id', user.id)
      .single()
    if (tokenError || !tokenRow) {
      return json({ error: 'Whoop não conectado' }, 404)
    }

    let accessToken = tokenRow.access_token as string
    if (Date.now() + 300000 > new Date(tokenRow.expires_at).getTime()) {
      const refreshResponse = await fetch(
        `${Deno.env.get('SUPABASE_URL')}/functions/v1/whoop-refresh`,
        { method: 'POST', headers: { Authorization: authHeader } },
      )
      if (!refreshResponse.ok) {
        return json({ error: 'Não foi possível renovar a conexão Whoop' }, 401)
      }
      accessToken = (await refreshResponse.json()).access_token
    }

    const url = new URL(WHOOP_WORKOUTS_URL)
    url.searchParams.set('limit', '10')
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    })
    if (!response.ok) {
      console.error('Whoop workouts status:', response.status)
      return json({ error: 'Não foi possível carregar atividades Whoop' }, 502)
    }

    const payload = await response.json()
    const records = payload.records ?? []
    const activities = records.map((workout: any) => ({
      provider: 'whoop',
      external_activity_id: workout.id,
      activity_type: workout.sport_name ?? 'Atividade',
      started_at: workout.start,
      ended_at: workout.end,
      duration_s: durationSeconds(workout.start, workout.end),
      strain: workout.score?.strain ?? null,
      average_heart_rate: workout.score?.average_heart_rate ?? null,
      max_heart_rate: workout.score?.max_heart_rate ?? null,
      calories: workout.score?.kilojoule == null
        ? null
        : Math.round(workout.score.kilojoule / 4.184),
      distance_km: workout.score?.distance_meter == null
        ? null
        : workout.score.distance_meter / 1000,
    }))

    // Reconciliação: se um webhook se perder, uma consulta autenticada posterior
    // persiste apenas atividades novas desde o último sync. ON CONFLICT evita
    // push/XP duplicados e não reabre atividades já confirmadas ou ignoradas.
    const lastSync = new Date(tokenRow.last_workout_sync_at).getTime()
    const newRows = records
      .filter((workout: any) =>
        workout.score_state === 'SCORED' &&
        new Date(workout.updated_at).getTime() > lastSync
      )
      .map((workout: any) => ({
        user_id: user.id,
        provider: 'whoop',
        external_activity_id: workout.id,
        activity_type: workout.sport_name ?? 'Atividade',
        started_at: workout.start,
        ended_at: workout.end,
        duration_seconds: durationSeconds(workout.start, workout.end),
        strain: workout.score?.strain ?? null,
        average_heart_rate: workout.score?.average_heart_rate ?? null,
        max_heart_rate: workout.score?.max_heart_rate ?? null,
        calories: workout.score?.kilojoule == null
          ? null
          : Math.round(workout.score.kilojoule / 4.184),
        distance_km: workout.score?.distance_meter == null
          ? null
          : workout.score.distance_meter / 1000,
        status: 'pending',
      }))
    if (newRows.length > 0) {
      const { error: reconcileError } = await supabase
        .from('wearable_activities')
        .upsert(newRows, {
          onConflict: 'provider,external_activity_id',
          ignoreDuplicates: true,
        })
      if (reconcileError) {
        console.error('Whoop reconciliation:', reconcileError.message)
      }
    }
    await supabase.schema('bldr_club').from('whoop_tokens').update({
      last_workout_sync_at: new Date().toISOString(),
    }).eq('user_id', user.id)

    return json({ activities })
  } catch (error) {
    console.error('whoop-workouts:', error)
    return json({ error: 'Erro inesperado ao consultar Whoop' }, 500)
  }
})

function durationSeconds(start: string, end: string): number | null {
  const duration = new Date(end).getTime() - new Date(start).getTime()
  return Number.isFinite(duration) && duration >= 0
    ? Math.round(duration / 1000)
    : null
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
