// supabase/functions/bldr-club-notifier/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import * as djwt from "https://deno.land/x/djwt@v3.0.2/mod.ts"

// === LÓGICA DE AUTH GOOGLE (Reutilizada da sua function de hidratação) ===
async function getAccessToken() {
  const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')
  const privateKeyPem = Deno.env.get('FCM_PRIVATE_KEY')

  if (!clientEmail || !privateKeyPem) throw new Error('Credenciais FCM ausentes.')

  const privateKey = privateKeyPem.replace(/\\n/g, '\n').trim()
  const pemContents = privateKey
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '')

  let binaryDer: ArrayBuffer
  try {
    binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0)).buffer
  } catch (err) {
    throw new Error('Erro Base64 Key.')
  }

  let key: CryptoKey = await crypto.subtle.importKey(
    'pkcs8', binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign']
  )

  const now = Math.floor(Date.now() / 1000)
  const jwt = await djwt.create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now,
    },
    key
  )

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const data = await response.json()
  return data.access_token as string
}

// === SERVIDOR HTTP (AQUI MUDA A LÓGICA DO BLDR CLUB) ===
serve(async (req) => {
  try {
    // 1. Recebe os dados do Webhook do Banco de Dados
    // O Supabase envia um JSON com: { type: 'INSERT', record: { ...dados_da_notificacao } }
    const payload = await req.json()
    const { record } = payload

    if (!record || !record.user_id) {
        return new Response('Payload inválido ou sem user_id', { status: 400 })
    }

    console.log(`🔔 Processando notificação BLDR CLUB para: ${record.user_id}`)

    // 2. Prepara acessos
    const projectId = Deno.env.get('FCM_PROJECT_ID')
    const accessToken = await getAccessToken()

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 3. Busca o Token APENAS desse usuário
    const { data: profile, error } = await supabaseAdmin
      .from('user_profiles')
      .select('fcm_token')
      .eq('id', record.user_id)
      .not('fcm_token', 'is', null)
      .single()

    if (error || !profile) {
      console.log(`Usuário ${record.user_id} não tem token ou não existe.`)
      return new Response('Usuário sem token', { status: 200 })
    }

    // 4. Monta a mensagem baseada no que foi salvo na tabela notifications
    const FCM_URL = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    const fcmPayload = {
        message: {
          token: profile.fcm_token,
          notification: {
            title: record.title,   // Vem da tabela notifications
            body: record.message,  // Vem da tabela notifications
          },
          // Configuração Android
          android: {
            priority: 'high',
            notification: {
                sound: 'default',
                channel_id: 'bldr_club_channel' // Importante para o Android
            },
          },
          // Configuração iOS
          apns: {
            headers: { 'apns-priority': '10' },
            payload: {
              aps: {
                alert: {
                  title: record.title,
                  body: record.message,
                },
                sound: 'default',
                badge: 1,
              },
            },
          },
          // Dados extras para o app saber o que fazer ao clicar
          data: {
             type: 'bldr_club_event',
             notification_type: record.type // success, error, info
          }
        },
      }

    // 5. Envia o Push
    const response = await fetch(FCM_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(fcmPayload),
      })

    const result = await response.json()
    console.log("Resultado FCM:", JSON.stringify(result))

    return new Response(JSON.stringify({ success: true }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200
    })

  } catch (err) {
    console.error('Erro function:', err)
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})