import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2022-11-15',
  httpClient: Stripe.createFetchHttpClient(),
});

serve(async (req) => {
  // Pega o token de autenticação do usuário que fez a chamada
  const authHeader = req.headers.get('Authorization')!;

  try {
    // Cria um cliente Supabase com os privilégios do usuário logado
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // Pega os dados do usuário a partir do token
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error('Usuário não encontrado.');

    console.log(`Iniciando exclusão para o usuário: ${user.id}`);

    // Cria um cliente com privilégios de administrador para realizar operações protegidas
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // 1. CANCELAR ASSINATURA NO STRIPE
    // Busca a assinatura ativa do usuário no nosso banco de dados
const { data: subscriptionData, error: subError } = await supabaseAdmin
      .from('user_subscriptions')
      .select('stripe_subscription_id, stripe_customer_id')
      .eq('user_id', user.id)
      .eq('status', 'active')
      .maybeSingle(); // <--- Mudei para maybeSingle() para não dar erro se não achar nada

    // O ERRO ESTAVA AQUI: Precisamos verificar se existe data E se existe o ID dentro dele
    if (subscriptionData && subscriptionData.stripe_subscription_id) {
      console.log(`Assinatura encontrada: ${subscriptionData.stripe_subscription_id}. Cancelando no Stripe...`);

      try {
        await stripe.subscriptions.cancel(subscriptionData.stripe_subscription_id);
        console.log(`Assinatura cancelada com sucesso no Stripe.`);
      } catch (stripeError) {
        // Se der erro no Stripe (ex: já cancelado), apenas logamos e continuamos
        console.log(`Aviso: Não foi possível cancelar no Stripe (pode já estar cancelado): ${stripeError.message}`);
      }

      // Deletar cliente (Opcional, mas seguro colocar try/catch também)
      if (subscriptionData.stripe_customer_id) {
         try {
             await stripe.customers.del(subscriptionData.stripe_customer_id);
         } catch (e) { console.log('Erro ao deletar customer (ignorando):', e.message); }
      }

    } else {
      console.log('Nenhuma assinatura ativa ou ID inválido. Pulando etapa do Stripe.');
    }

    // 3. DELETAR O USUÁRIO NO SUPABASE AUTH
    // Este é o passo final e mais importante. Ao deletar o usuário da autenticação,
    // as deleções em cascata (se configuradas) limparão as outras tabelas.
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id);

    if (deleteError) {
      throw new Error(`Erro ao deletar usuário no Supabase Auth: ${deleteError.message}`);
    }

    console.log(`Usuário ${user.id} deletado com sucesso do Supabase.`);

    return new Response(JSON.stringify({ message: 'Conta excluída com sucesso' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('Erro no processo de exclusão de conta:', error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});