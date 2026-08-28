import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Lidar com requisições OPTIONS (CORS)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Pegar dados enviados pelo Flutter
    const { receipt_data, user_id, product_id } = await req.json()

    if (!receipt_data || !user_id) {
      throw new Error('Dados incompletos: receipt_data e user_id são obrigatórios.')
    }

    // 2. Pegar o Segredo que salvamos no Supabase
    const sharedSecret = Deno.env.get('APPLE_SHARED_SECRET')
    if (!sharedSecret) {
      throw new Error('APPLE_SHARED_SECRET não configurado no Supabase.')
    }

    // 3. Função para validar com a Apple (Lógica de Retry Prod -> Sandbox)
    const verifyReceipt = async (isSandbox = false) => {
      const url = isSandbox
        ? 'https://sandbox.itunes.apple.com/verifyReceipt'
        : 'https://buy.itunes.apple.com/verifyReceipt';

      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          'receipt-data': receipt_data,
          'password': sharedSecret,
          'exclude-old-transactions': true
        })
      })
      return await response.json()
    }

    // Tenta Produção primeiro
    let appleResponse = await verifyReceipt(false)

    // Se a Apple retornar Status 21007, significa que é um recibo de teste (Sandbox)
    // Então tentamos novamente na URL de Sandbox
    if (appleResponse.status === 21007) {
      console.log('Recibo de Sandbox detectado. Retentando no ambiente de teste...')
      appleResponse = await verifyReceipt(true)
    }

    // 4. Verificar se a validação passou
    // Status 0 significa sucesso.
    if (appleResponse.status !== 0) {
      console.error('Erro na validação Apple:', appleResponse)
      throw new Error(`Falha na validação da Apple. Status: ${appleResponse.status}`)
    }

    // 5. Validar se o Produto comprado bate com o esperado (Opcional, mas recomendado)
    // A Apple retorna um array 'latest_receipt_info'. Pegamos o mais recente.
    const latestTransaction = appleResponse.latest_receipt_info
      ? appleResponse.latest_receipt_info[0]
      : appleResponse.receipt;

    // Aqui você pode checar se latestTransaction.product_id == product_id se quiser ser estrito.

    // 6. Atualizar o Banco de Dados (Supabase)
    // Inicia o cliente Supabase (usando a Service Role Key para ter permissão de escrita total)
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Calculando data de expiração (converte de milissegundos da Apple para ISO string)
    const expirationDate = new Date(parseInt(latestTransaction.expires_date_ms)).toISOString()

    // Atualiza ou insere na tabela user_subscriptions
    const { error: dbError } = await supabaseClient
      .from('user_subscriptions')
      .upsert({
        user_id: user_id,
        plan_id: latestTransaction.product_id, // Usa o ID da Apple como Plan ID
        status: 'active',
        current_period_end: expirationDate,
        payment_provider: 'apple_iap', // Importante para saber a origem depois
        updated_at: new Date().toISOString()
      })

    if (dbError) {
      throw dbError
    }

    // 7. Retornar Sucesso para o Flutter
    return new Response(
      JSON.stringify({ success: true, message: 'Assinatura validada e ativada.' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 },
    )
  }
})