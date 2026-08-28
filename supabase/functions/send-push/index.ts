import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
}

// ─── Types ────────────────────────────────────────────────────────────────────

interface Segment {
  is_club_member?: boolean
  min_streak?: number
  platform?: 'ios' | 'android' | 'all'
}

interface Target {
  mode: 'all' | 'segment' | 'user'
  user_id?: string
  segment?: Segment
}

interface PushPayload {
  title: string
  body: string
  type?: string
  action_data?: Record<string, unknown>
  target: Target
}

// ─── FCM OAuth2 JWT ───────────────────────────────────────────────────────────

async function getAccessToken(
  clientEmail: string,
  privateKey: string,
  projectId: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = { alg: 'RS256', typ: 'JWT' }
  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

  const sigInput = `${encode(header)}.${encode(payload)}`

  // Import private key for RS256 signing
  const keyData = privateKey.replace(/\\n/g, '\n')
  const pemBody = keyData
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')

  const binaryKey = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0))
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(sigInput),
  )
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')

  const jwt = `${sigInput}.${sigB64}`

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  })

  const tokenJson = await tokenRes.json()
  return tokenJson.access_token as string
}

// ─── Send single FCM message ──────────────────────────────────────────────────

async function sendToToken(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  accessToken: string,
  projectId: string,
): Promise<{ success: boolean; invalid: boolean }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          apns: { payload: { aps: { sound: 'default', badge: 1 } } },
          android: { notification: { sound: 'default', channel_id: 'bldr_push_channel' } },
        },
      }),
    },
  )

  if (res.ok) return { success: true, invalid: false }

  const err = await res.json()
  const errCode = err?.error?.details?.[0]?.errorCode ?? err?.error?.status
  const invalid = errCode === 'UNREGISTERED' || errCode === 'INVALID_ARGUMENT'
  return { success: false, invalid }
}

// ─── Main handler ─────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  // Auth: shared secret between Gestão and BLDR
  const webhookSecret = Deno.env.get('GESTAO_WEBHOOK_SECRET')
  const authHeader = req.headers.get('Authorization') ?? ''
  if (!webhookSecret || authHeader !== `Bearer ${webhookSecret}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...CORS, 'Content-Type': 'application/json' },
    })
  }

  const projectId = Deno.env.get('FIREBASE_PROJECT_ID')!
  const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')!
  const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')!
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  const supabase = createClient(supabaseUrl, supabaseKey)

  const payload = (await req.json()) as PushPayload
  const { title, body, type, action_data, target } = payload

  // ── Fetch target tokens ───────────────────────────────────────────────────

  let tokens: string[] = []

  if (target.mode === 'all') {
    const { data } = await supabase
      .from('user_profiles')
      .select('fcm_token')
      .not('fcm_token', 'is', null)
      .eq('notifications_enabled', true)
    tokens = (data ?? []).map((r: { fcm_token: string }) => r.fcm_token)
  } else if (target.mode === 'user' && target.user_id) {
    const { data } = await supabase
      .from('user_profiles')
      .select('fcm_token')
      .eq('id', target.user_id)
      .not('fcm_token', 'is', null)
      .single()
    if (data?.fcm_token) tokens = [data.fcm_token]
  } else if (target.mode === 'segment' && target.segment) {
    const seg = target.segment
    let query = supabase
      .from('user_profiles')
      .select('fcm_token')
      .not('fcm_token', 'is', null)
      .eq('notifications_enabled', true)

    if (seg.is_club_member !== undefined) {
      query = query.eq('is_club_member', seg.is_club_member)
    }
    if (seg.platform && seg.platform !== 'all') {
      query = query.eq('platform_type', seg.platform)
    }

    const { data } = await query
    tokens = (data ?? []).map((r: { fcm_token: string }) => r.fcm_token)

    // Streak filter: fetch user_workouts to compute streak in-memory
    // (avoids a complex DB function for the Gestão API)
    if (seg.min_streak && seg.min_streak > 0) {
      const { data: workouts } = await supabase
        .from('user_profiles')
        .select('id, fcm_token')
        .not('fcm_token', 'is', null)
        .in('fcm_token', tokens)

      const userIds = (workouts ?? []).map((u: { id: string }) => u.id)
      if (userIds.length > 0) {
        const { data: wkData } = await supabase
          .from('user_workouts')
          .select('user_id, completed_at')
          .in('user_id', userIds)
          .not('completed_at', 'is', null)
          .gte(
            'completed_at',
            new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(),
          )

        // Compute streak per user
        const streakMap: Record<string, number> = {}
        for (const w of wkData ?? []) {
          const uid = w.user_id as string
          const day = new Date(w.completed_at).toDateString()
          if (!streakMap[uid]) streakMap[uid] = 0
          streakMap[uid]++
          void day // just counting days for simplicity
        }

        const passIds = new Set(
          Object.entries(streakMap)
            .filter(([, s]) => s >= seg.min_streak!)
            .map(([id]) => id),
        )

        tokens = (workouts ?? [])
          .filter((u: { id: string; fcm_token: string }) => passIds.has(u.id))
          .map((u: { fcm_token: string }) => u.fcm_token)
      } else {
        tokens = []
      }
    }
  }

  tokens = tokens.filter(Boolean)

  if (tokens.length === 0) {
    await supabase.from('push_notifications_log').insert({
      title,
      body,
      type: type ?? null,
      target_mode: target.mode,
      target_segment: target.segment ?? null,
      sent_count: 0,
      failed_count: 0,
      notes: 'Nenhum token FCM encontrado para o alvo',
      created_at: new Date().toISOString(),
    })
    return new Response(
      JSON.stringify({
        sent: 0,
        failed: 0,
        invalid_tokens_removed: 0,
        warning: 'Nenhum dispositivo com token FCM encontrado para este alvo.',
      }),
      { headers: { ...CORS, 'Content-Type': 'application/json' } },
    )
  }

  // ── Get FCM access token ──────────────────────────────────────────────────

  const accessToken = await getAccessToken(clientEmail, privateKey, projectId)

  // ── Send in batches of 500 ────────────────────────────────────────────────

  const fcmData: Record<string, string> = {
    type: type ?? 'info',
    action_data: action_data ? JSON.stringify(action_data) : '{}',
  }

  let sent = 0
  let failed = 0
  const invalidTokens: string[] = []

  const BATCH = 500
  for (let i = 0; i < tokens.length; i += BATCH) {
    const batch = tokens.slice(i, i + BATCH)
    const results = await Promise.all(
      batch.map((token) =>
        sendToToken(token, title, body, fcmData, accessToken, projectId),
      ),
    )
    for (let j = 0; j < results.length; j++) {
      if (results[j].success) {
        sent++
      } else {
        failed++
        if (results[j].invalid) invalidTokens.push(batch[j])
      }
    }
  }

  // ── Remove invalid tokens ─────────────────────────────────────────────────

  if (invalidTokens.length > 0) {
    await supabase
      .from('user_profiles')
      .update({ fcm_token: null })
      .in('fcm_token', invalidTokens)
  }

  // ── Log push ──────────────────────────────────────────────────────────────

  await supabase.from('push_notifications_log').insert({
    title,
    body,
    type: type ?? null,
    target_mode: target.mode,
    target_segment: target.segment ?? null,
    sent_count: sent,
    failed_count: failed,
    notes: null,
    created_at: new Date().toISOString(),
  })

  return new Response(
    JSON.stringify({
      sent,
      failed,
      invalid_tokens_removed: invalidTokens.length,
      warning: null,
    }),
    { headers: { ...CORS, 'Content-Type': 'application/json' } },
  )
})
