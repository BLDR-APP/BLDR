// @ts-ignore
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
// @ts-ignore
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: 'Não autorizado' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return new Response(
      JSON.stringify({ error: 'Corpo inválido' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  const { tipo, mensagem, screenshot_url, user_email, user_name, app_version, platform } = body

  if (!tipo || !mensagem || typeof mensagem !== 'string') {
    return new Response(
      JSON.stringify({ error: 'Campos obrigatórios ausentes: tipo e mensagem' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  const validTypes = ['bug', 'sugestao', 'reclamacao', 'outro']
  if (!validTypes.includes(tipo as string)) {
    return new Response(
      JSON.stringify({ error: 'Tipo inválido' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  // Cliente do Supabase de GESTÃO — credenciais ficam APENAS aqui, como secrets
  const gestaoUrl = Deno.env.get('GESTAO_SUPABASE_URL')
  const gestaoKey = Deno.env.get('GESTAO_SUPABASE_SERVICE_KEY')

  if (!gestaoUrl || !gestaoKey) {
    console.error('Secrets GESTAO_SUPABASE_URL / GESTAO_SUPABASE_SERVICE_KEY não configurados')
    return new Response(
      JSON.stringify({ error: 'Configuração do servidor incompleta' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  const gestao = createClient(gestaoUrl, gestaoKey)

  const { data, error } = await gestao
    .from('feedback')
    .insert({
      tipo,
      mensagem: (mensagem as string).trim().substring(0, 2000),
      screenshot_url: screenshot_url ?? null,
      user_email: user_email ?? null,
      user_name: user_name ?? null,
      app_version: app_version ?? null,
      platform: platform ?? null,
    })
    .select('protocolo')
    .single()

  if (error) {
    console.error('Erro ao salvar feedback:', error)
    return new Response(
      JSON.stringify({ error: 'Falha ao salvar feedback' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  return new Response(
    JSON.stringify({ protocolo: (data as { protocolo: string }).protocolo }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  )
})
