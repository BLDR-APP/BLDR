import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const WHOOP_TOKEN_URL = 'https://api.prod.whoop.com/oauth/oauth2/token'
const WHOOP_PROFILE_URL = 'https://api.prod.whoop.com/developer/v2/user/profile/basic'

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return json({ error: 'Não autorizado' }, 401)
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    if (authError || !user) {
      return json({ error: 'Token inválido' }, 401)
    }

    const body = await req.json()
    const code: string = body.code
    if (!code) {
      return json({ error: 'Parâmetro code ausente' }, 400)
    }

    const clientId = (Deno.env.get('WHOOP_CLIENT_ID') ?? '').trim()
    const clientSecret = (Deno.env.get('WHOOP_CLIENT_SECRET') ?? '').trim()
    const redirectUri = (Deno.env.get('WHOOP_REDIRECT_URI') ?? 'bldr://whoop/callback').trim()

    console.log('CLIENT_ID length:', clientId.length)
    console.log('CLIENT_SECRET length:', clientSecret.length)
    console.log('REDIRECT_URI:', redirectUri)

    const tokenRes = await fetch(WHOOP_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: redirectUri,
        client_id: clientId,
        client_secret: clientSecret,
      }),
    })

    if (!tokenRes.ok) {
      const err = await tokenRes.text()
      console.error('Falha ao trocar código Whoop:', err)
      return json({ error: `Falha na autenticação Whoop: ${err}` }, 502)
    }

    const tokenData = await tokenRes.json()
    const accessToken: string = tokenData.access_token
    const refreshToken: string = tokenData.refresh_token
    const expiresIn: number = tokenData.expires_in ?? 3600
    const expiresAt = new Date(Date.now() + expiresIn * 1000).toISOString()

    const profileRes = await fetch(WHOOP_PROFILE_URL, {
      headers: { Authorization: `Bearer ${accessToken}` },
    })

    let whoopUserId: string | null = null
    if (profileRes.ok) {
      const profile = await profileRes.json()
      whoopUserId = String(profile.user_id ?? profile.id ?? '')
    }

    const { error: upsertError } = await supabase
      .schema('bldr_club')
      .from('whoop_tokens')
      .upsert({
        user_id: user.id,
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_at: expiresAt,
        whoop_user_id: whoopUserId,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'user_id' })

    if (upsertError) {
      console.error('Erro ao salvar tokens Whoop:', upsertError)
      return json({ error: 'Erro ao salvar conexão' }, 500)
    }

    return json({ connected: true, whoop_user_id: whoopUserId })
  } catch (e) {
    console.error('Erro inesperado whoop-auth:', e)
    return json({ error: String(e) }, 500)
  }
})

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
