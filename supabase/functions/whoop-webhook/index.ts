import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

declare const EdgeRuntime: { waitUntil(promise: Promise<unknown>): void }

const WHOOP_WORKOUT_URL =
  'https://api.prod.whoop.com/developer/v2/activity/workout'
const WHOOP_TOKEN_URL = 'https://api.prod.whoop.com/oauth/oauth2/token'
const MAX_SIGNATURE_AGE_MS = 5 * 60 * 1000

type WhoopEvent = {
  user_id: number
  id: string
  type: 'workout.updated' | 'workout.deleted' | string
  trace_id: string
}

serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'Método não permitido' }, 405)

  const rawBody = await req.text()
  const signature = (req.headers.get('X-WHOOP-Signature') ?? '').trim()
  const timestamp = (req.headers.get('X-WHOOP-Signature-Timestamp') ?? '').trim()
  const clientSecret = (Deno.env.get('WHOOP_CLIENT_SECRET') ?? '').trim()

  if (!await validSignature(rawBody, timestamp, signature, clientSecret)) {
    console.warn('whoop-webhook signature rejected', {
      hasSignature: signature.length > 0,
      hasTimestamp: timestamp.length > 0,
      hasClientSecret: clientSecret.length > 0,
      timestampIsNumeric: Number.isFinite(Number(timestamp)),
      signatureLength: signature.length,
    })
    return json({ error: 'Assinatura inválida' }, 401)
  }

  let event: WhoopEvent
  try {
    event = JSON.parse(rawBody) as WhoopEvent
  } catch {
    return json({ error: 'JSON inválido' }, 400)
  }
  if (!event.trace_id || !event.id || !event.type) {
    return json({ error: 'Evento incompleto' }, 400)
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  const { data: previous } = await admin
    .from('wearable_webhook_events')
    .select('status')
    .eq('trace_id', event.trace_id)
    .maybeSingle()
  if (previous?.status === 'completed' || previous?.status === 'processing') {
    return json({ accepted: true, duplicate: true }, 202)
  }

  if (previous?.status === 'error') {
    await admin.from('wearable_webhook_events').update({
      status: 'processing',
      error_message: null,
      attempts: 2,
    }).eq('trace_id', event.trace_id)
  } else {
    const { error } = await admin.from('wearable_webhook_events').insert({
      trace_id: event.trace_id,
      event_type: event.type,
      external_activity_id: event.id,
    })
    if (error) {
      if (error.code === '23505') {
        return json({ accepted: true, duplicate: true }, 202)
      }
      console.error('whoop-webhook claim:', error.message)
      return json({ error: 'Não foi possível registrar o evento' }, 500)
    }
  }

  EdgeRuntime.waitUntil(processEvent(admin, event).catch(async (error) => {
    console.error('whoop-webhook background:', String(error))
    await admin.from('wearable_webhook_events').update({
      status: 'error',
      error_message: String(error).slice(0, 500),
      processed_at: new Date().toISOString(),
    }).eq('trace_id', event.trace_id)
  }))

  return json({ accepted: true }, 202)
})

async function processEvent(admin: SupabaseClient, event: WhoopEvent) {
  if (event.type === 'workout.deleted') {
    const { data: existing } = await admin.from('wearable_activities')
      .select('status').eq('provider', 'whoop')
      .eq('external_activity_id', event.id).maybeSingle()
    if (existing) {
      await admin.from('wearable_activities').update({
        status: existing.status === 'confirmed' ? 'confirmed' : 'deleted',
        provider_deleted_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }).eq('provider', 'whoop').eq('external_activity_id', event.id)
      await removePendingNotification(admin, event.id)
    }
    return completeEvent(admin, event.trace_id)
  }

  if (event.type !== 'workout.updated') {
    return completeEvent(admin, event.trace_id)
  }

  const { data: tokenRow, error: tokenError } = await admin
    .schema('bldr_club').from('whoop_tokens')
    .select('user_id, access_token, refresh_token, expires_at')
    .eq('whoop_user_id', String(event.user_id))
    // Um mesmo wearable pode estar temporariamente ligado a mais de uma conta
    // em ambientes de teste. O vínculo renovado mais recentemente é o ativo.
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  if (tokenError || !tokenRow) throw new Error('Conexão WHOOP não encontrada')

  const accessToken = await validAccessToken(admin, tokenRow)
  const response = await fetch(`${WHOOP_WORKOUT_URL}/${event.id}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  // Entregas e retries podem chegar fora de ordem. Se um UPDATE antigo for
  // processado depois do DELETE, o recurso já não existe mais na API WHOOP.
  if (response.status === 404) {
    const { data: existing } = await admin.from('wearable_activities')
      .select('status').eq('provider', 'whoop')
      .eq('external_activity_id', event.id).maybeSingle()
    if (existing) {
      await admin.from('wearable_activities').update({
        status: existing.status === 'confirmed' ? 'confirmed' : 'deleted',
        provider_deleted_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }).eq('provider', 'whoop').eq('external_activity_id', event.id)
      await removePendingNotification(admin, event.id)
    }
    return completeEvent(admin, event.trace_id)
  }
  if (!response.ok) throw new Error(`WHOOP workout HTTP ${response.status}`)
  const workout = await response.json()

  // WHOOP pode emitir update antes de terminar o processamento dos scores.
  // Um novo workout.updated chegará quando o registro estiver SCORED.
  if (workout.score_state !== 'SCORED') {
    return completeEvent(admin, event.trace_id)
  }

  const normalized = normalizeWorkout(tokenRow.user_id, workout)
  const { data: existing } = await admin.from('wearable_activities')
    .select('id').eq('provider', 'whoop')
    .eq('external_activity_id', event.id).maybeSingle()
  if (existing) {
    const { status: _status, ...metrics } = normalized
    await admin.from('wearable_activities').update({
      ...metrics,
      updated_at: new Date().toISOString(),
    }).eq('id', existing.id)
  } else {
    const { error } = await admin.from('wearable_activities').insert(normalized)
    if (error) throw error
  }
  return completeEvent(admin, event.trace_id)
}

async function removePendingNotification(
  admin: SupabaseClient,
  externalActivityId: string,
) {
  const { data: activity } = await admin.from('wearable_activities')
    .select('id').eq('provider', 'whoop')
    .eq('external_activity_id', externalActivityId).maybeSingle()
  if (!activity) return

  const { error } = await admin.schema('bldr_club').from('notifications')
    .delete()
    .eq('action_type', 'wearable_workout_detected')
    .contains('action_data', { activity_id: activity.id })
  if (error) console.warn('whoop-webhook stale notification:', error.message)
}

async function validAccessToken(admin: SupabaseClient, row: any) {
  if (Date.now() + 300000 <= new Date(row.expires_at).getTime()) {
    return row.access_token as string
  }
  const response = await fetch(WHOOP_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: row.refresh_token,
      client_id: (Deno.env.get('WHOOP_CLIENT_ID') ?? '').trim(),
      client_secret: (Deno.env.get('WHOOP_CLIENT_SECRET') ?? '').trim(),
    }),
  })
  if (!response.ok) throw new Error(`WHOOP refresh HTTP ${response.status}`)
  const token = await response.json()
  const expiresAt = new Date(
    Date.now() + (token.expires_in ?? 3600) * 1000,
  ).toISOString()
  const { error } = await admin.schema('bldr_club').from('whoop_tokens').update({
    access_token: token.access_token,
    refresh_token: token.refresh_token ?? row.refresh_token,
    expires_at: expiresAt,
    updated_at: new Date().toISOString(),
  }).eq('user_id', row.user_id)
  if (error) throw error
  return token.access_token as string
}

function normalizeWorkout(userId: string, workout: any) {
  return {
    user_id: userId,
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
  }
}

async function completeEvent(admin: SupabaseClient, traceId: string) {
  const { error } = await admin.from('wearable_webhook_events').update({
    status: 'completed',
    error_message: null,
    processed_at: new Date().toISOString(),
  }).eq('trace_id', traceId)
  if (error) throw error
}

async function validSignature(
  body: string,
  timestamp: string,
  received: string,
  secret: string,
) {
  const timestampMs = Number(timestamp)
  if (!secret || !received || !Number.isFinite(timestampMs)) return false
  if (Math.abs(Date.now() - timestampMs) > MAX_SIGNATURE_AGE_MS) return false
  const key = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  )
  const signature = await crypto.subtle.sign(
    'HMAC', key, new TextEncoder().encode(timestamp + body),
  )
  const expected = btoa(String.fromCharCode(...new Uint8Array(signature)))
  return timingSafeEqual(expected, received)
}

function timingSafeEqual(left: string, right: string) {
  if (left.length !== right.length) return false
  let diff = 0
  for (let index = 0; index < left.length; index++) {
    diff |= left.charCodeAt(index) ^ right.charCodeAt(index)
  }
  return diff === 0
}

function durationSeconds(start: string, end: string) {
  const duration = new Date(end).getTime() - new Date(start).getTime()
  return Number.isFinite(duration) && duration >= 0
    ? Math.round(duration / 1000)
    : null
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
