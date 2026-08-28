// @ts-ignore
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
// @ts-ignore
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const compareVersions = (a: string, b: string): number => {
  const pa = a.split('.').map(Number)
  const pb = b.split('.').map(Number)
  for (let i = 0; i < 3; i++) {
    if ((pa[i] ?? 0) > (pb[i] ?? 0)) return 1
    if ((pa[i] ?? 0) < (pb[i] ?? 0)) return -1
  }
  return 0
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ show: false }), { headers: corsHeaders })
  }

  const { appVersion } = await req.json().catch(() => ({ appVersion: '0.0.0' }))

  const bldrUrl = Deno.env.get('SUPABASE_URL')!
  const bldrKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const bldr = createClient(bldrUrl, bldrKey)

  const jwt = authHeader.replace('Bearer ', '')
  const { data: { user } } = await bldr.auth.getUser(jwt)
  if (!user) {
    return new Response(JSON.stringify({ show: false }), { headers: corsHeaders })
  }

  const gestaoUrl = Deno.env.get('GESTAO_SUPABASE_URL')!
  const gestaoKey = Deno.env.get('GESTAO_SUPABASE_SERVICE_KEY')!
  const gestao = createClient(gestaoUrl, gestaoKey)

  const { data: items } = await gestao
    .from('whats_new')
    .select('*')
    .eq('active', true)
    .order('created_at', { ascending: false })

  if (!items || items.length === 0) {
    return new Response(JSON.stringify({ show: false }), { headers: corsHeaders })
  }

  const { data: seen } = await bldr
    .from('whats_new_seen')
    .select('whats_new_id')
    .eq('user_id', user.id)

  const seenIds = new Set(seen?.map((s: { whats_new_id: string }) => s.whats_new_id) ?? [])

  for (const item of items) {
    if (seenIds.has(item.id)) continue

    const { trigger_mode, target_version } = item
    let shouldShow = false

    if (trigger_mode === 'flag') {
      shouldShow = true
    } else if (trigger_mode === 'version') {
      shouldShow = target_version
        ? compareVersions(appVersion ?? '0.0.0', target_version) >= 0
        : false
    } else if (trigger_mode === 'both') {
      const versionOk = target_version
        ? compareVersions(appVersion ?? '0.0.0', target_version) >= 0
        : false
      shouldShow = versionOk
    }

    if (shouldShow) {
      return new Response(
        JSON.stringify({ show: true, id: item.id, title: item.title, subtitle: item.subtitle, slides: item.slides }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
  }

  return new Response(JSON.stringify({ show: false }), { headers: corsHeaders })
})
