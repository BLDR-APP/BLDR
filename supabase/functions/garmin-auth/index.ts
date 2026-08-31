import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const authorization = req.headers.get('Authorization')
    if (!authorization) return json({ error: 'Não autorizado' }, 401)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )
    const { data: { user }, error } = await supabase.auth.getUser(
      authorization.replace('Bearer ', ''),
    )
    if (error || !user) return json({ error: 'Token inválido' }, 401)

    const clientId = Deno.env.get('GARMIN_CLIENT_ID')
    const clientSecret = Deno.env.get('GARMIN_CLIENT_SECRET')
    const tokenUrl = Deno.env.get('GARMIN_TOKEN_URL')
    const redirectUri = Deno.env.get('GARMIN_REDIRECT_URI')
    if (!clientId || !clientSecret || !tokenUrl || !redirectUri) {
      return json({ error: 'Integração Garmin ainda não configurada' }, 503)
    }
    const { code } = await req.json()
    if (!code) return json({ error: 'Código OAuth ausente' }, 400)

    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'authorization_code', code,
        client_id: clientId, client_secret: clientSecret,
        redirect_uri: redirectUri,
      }),
    })
    if (!response.ok) return json({ error: 'Falha na autenticação Garmin' }, 502)
    const token = await response.json()
    const { error: saveError } = await supabase.schema('bldr_club')
      .from('garmin_tokens').upsert({
        user_id: user.id,
        access_token: token.access_token,
        refresh_token: token.refresh_token ?? null,
        expires_at: token.expires_in == null ? null
          : new Date(Date.now() + token.expires_in * 1000).toISOString(),
        scopes: String(token.scope ?? '').split(' ').filter(Boolean),
        updated_at: new Date().toISOString(),
      }, { onConflict: 'user_id' })
    if (saveError) return json({ error: 'Falha ao salvar conexão Garmin' }, 500)
    return json({ connected: true })
  } catch (error) {
    console.error('garmin-auth:', error)
    return json({ error: 'Erro inesperado na conexão Garmin' }, 500)
  }
})

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status, headers: { 'Content-Type': 'application/json' },
  })
}
