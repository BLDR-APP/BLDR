import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Whoop migrou para v2 — v1 só tem activity-mapping
const WHOOP_API = 'https://api.prod.whoop.com/developer/v2'

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Não autorizado' }, 401)

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    if (authError || !user) return json({ error: 'Token inválido' }, 401)

    const body = await req.json().catch(() => ({}))
    const today = new Date()
    const yesterday = new Date(today)
    yesterday.setDate(yesterday.getDate() - 1)
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)
    const targetDate: string = body.date ?? today.toISOString().split('T')[0]

    // Carrega tokens e verifica expiração
    const { data: tokenRow, error: tokenErr } = await supabase
      .schema('bldr_club')
      .from('whoop_tokens')
      .select('access_token, expires_at')
      .eq('user_id', user.id)
      .single()

    if (tokenErr || !tokenRow) return json({ error: 'Whoop não conectado' }, 404)

    let accessToken: string = tokenRow.access_token
    const expiresAt = new Date(tokenRow.expires_at).getTime()
    const fiveMinutes = 5 * 60 * 1000

    if (Date.now() + fiveMinutes > expiresAt) {
      const refreshRes = await fetch(
        `${Deno.env.get('SUPABASE_URL')}/functions/v1/whoop-refresh`,
        { method: 'POST', headers: { Authorization: authHeader } },
      )
      if (refreshRes.ok) {
        const refreshed = await refreshRes.json()
        accessToken = refreshed.access_token
      }
    }

    const h = { Authorization: `Bearer ${accessToken}` }

    // v2: recovery mais recente (endpoint simples, sem paginação)
    const startISO = yesterday.toISOString()
    const endISO   = tomorrow.toISOString()
    const params   = `start=${encodeURIComponent(startISO)}&end=${encodeURIComponent(endISO)}&limit=1`

    const [recoveryRes, cycleRes, sleepRes] = await Promise.all([
      fetch(`${WHOOP_API}/recovery?${params}`, { headers: h }),
      fetch(`${WHOOP_API}/cycle?${params}`, { headers: h }),
      fetch(`${WHOOP_API}/activity/sleep?${params}`, { headers: h }),
    ])

    console.log('v2 recovery:', recoveryRes.status, 'cycle:', cycleRes.status, 'sleep:', sleepRes.status)

    const [recoveryData, cycleData, sleepData] = await Promise.all([
      recoveryRes.ok ? recoveryRes.json() : recoveryRes.text().then(t => { console.log('recovery err:', t); return null }),
      cycleRes.ok   ? cycleRes.json()   : cycleRes.text().then(t   => { console.log('cycle err:', t);    return null }),
      sleepRes.ok   ? sleepRes.json()   : sleepRes.text().then(t   => { console.log('sleep err:', t);    return null }),
    ])

    console.log('recovery records:', recoveryData?.records?.length, 'cycle:', cycleData?.records?.length, 'sleep:', sleepData?.records?.length)

    // v2 devolve { records: [...], next_token } para coleções
    const recovery = recoveryData?.records?.[0]
    const cycle    = cycleData?.records?.[0]
    // Ignora naps — pega primeiro sono principal
    const sleep    = sleepData?.records?.find((s: { nap: boolean }) => !s.nap) ?? sleepData?.records?.[0]

    const record = {
      user_id:        user.id,
      date:           targetDate,
      recovery_score: recovery?.score?.recovery_score       ?? null,
      hrv_rmssd:      recovery?.score?.hrv_rmssd_milli      ?? null,
      resting_hr:     recovery?.score?.resting_heart_rate   ?? null,
      strain_score:   cycle?.score?.strain                  ?? null,
      sleep_score:    sleep?.score?.sleep_performance_percentage ?? null,
      sleep_duration: sleep?.score?.total_in_bed_time_milli != null
        ? Math.round(sleep.score.total_in_bed_time_milli / 60000)
        : null,
      synced_at: new Date().toISOString(),
    }

    console.log('record:', JSON.stringify(record))

    const { data: saved, error: upsertErr } = await supabase
      .schema('bldr_club')
      .from('whoop_daily_data')
      .upsert(record, { onConflict: 'user_id,date' })
      .select()
      .single()

    if (upsertErr) {
      console.error('Erro ao salvar dados Whoop:', upsertErr)
      return json({ error: 'Erro ao salvar dados' }, 500)
    }

    return json(saved)
  } catch (e) {
    console.error('Erro inesperado whoop-sync:', e)
    return json({ error: String(e) }, 500)
  }
})

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
