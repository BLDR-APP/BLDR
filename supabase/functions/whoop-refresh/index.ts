import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const WHOOP_TOKEN_URL = 'https://api.prod.whoop.com/oauth/oauth2/token'

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

    const { data: row, error: readError } = await supabase
      .schema('bldr_club')
      .from('whoop_tokens')
      .select('refresh_token')
      .eq('user_id', user.id)
      .single()

    if (readError || !row) return json({ error: 'Whoop não conectado' }, 404)

    const clientId = (Deno.env.get('WHOOP_CLIENT_ID') ?? '').trim()
    const clientSecret = (Deno.env.get('WHOOP_CLIENT_SECRET') ?? '').trim()

    const tokenRes = await fetch(WHOOP_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: row.refresh_token,
        client_id: clientId,
        client_secret: clientSecret,
      }),
    })

    if (!tokenRes.ok) {
      const err = await tokenRes.text()
      return json({ error: `Falha ao renovar token: ${err}` }, 502)
    }

    const tokenData = await tokenRes.json()
    const accessToken: string = tokenData.access_token
    const refreshToken: string = tokenData.refresh_token
    const expiresIn: number = tokenData.expires_in ?? 3600
    const expiresAt = new Date(Date.now() + expiresIn * 1000).toISOString()

    await supabase
      .schema('bldr_club')
      .from('whoop_tokens')
      .update({
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', user.id)

    return json({ access_token: accessToken, expires_at: expiresAt })
  } catch (e) {
    console.error('Erro inesperado whoop-refresh:', e)
    return json({ error: String(e) }, 500)
  }
})

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
