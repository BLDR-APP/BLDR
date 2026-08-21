// supabase/functions/strava-auth/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Endpoint de token do Strava
const STRAVA_TOKEN_URL = 'https://www.strava.com/oauth/token'

serve(async (req) => {
  // 1. Pega o 'code' da URL (ex: .../strava-auth?code=...)
  const url = new URL(req.url)
  const code = url.searchParams.get('code')

  if (!code) {
    return new Response(JSON.stringify({ error: 'Nenhum código fornecido' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // 2. Pega as chaves de segurança dos Segredos do Supabase
  const CLIENT_ID = Deno.env.get('STRAVA_CLIENT_ID')
  const CLIENT_SECRET = Deno.env.get('STRAVA_CLIENT_SECRET')

  // 3. Monta o payload para a requisição POST
  const payload = {
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    code: code,
    grant_type: 'authorization_code',
  }

  try {
    // 4. Faz a requisição POST para trocar o código por tokens
    const response = await fetch(STRAVA_TOKEN_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })

    if (!response.ok) {
      throw new Error(`Falha na troca de tokens: ${await response.text()}`)
    }

    const tokenData = await response.json()
    const { access_token, refresh_token, athlete } = tokenData

    // 5. (MUITO IMPORTANTE) Salvar os tokens no seu DB Supabase
    // Você precisa de um 'service_role' key para fazer isso com segurança
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' // Salve esta chave nos segredos também!
    )

    // Supondo que você tenha o ID do usuário (ex: do Supabase Auth)
    // Este é um exemplo; a autenticação do usuário na Edge Function é um passo extra.
    // Por enquanto, vamos focar em salvar os tokens:
    const { error }_ = await supabaseClient
      .from('sua_tabela_de_tokens') // Crie esta tabela
      .insert({
          user_id: 'ID_DO_USUARIO_LOGADO', // Você precisa descobrir como obter isso
          athlete_id: athlete.id,
          access_token: access_token,
          refresh_token: refresh_token,
          provider: 'strava'
       })

    if (error) {
       throw new Error(`Erro ao salvar no DB: ${error.message}`)
    }


    // 6. Redireciona o usuário de volta para o app Flutter
    // Use um deep link (ex: 'bldr://' ou 'seuschema://')
    const redirectUrl = 'bldr://auth-success'
    return new Response(null, {
      status: 302, // 302 é um redirecionamento
      headers: {
        'Location': redirectUrl,
      },
    })

  } catch (error) {
    console.error('Erro no fluxo de auth Strava:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})