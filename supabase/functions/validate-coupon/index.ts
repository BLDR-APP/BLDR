import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': '*'
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const requestData = await req.json();
    const { code } = requestData;

    if (!code) {
      return new Response(JSON.stringify({ error: 'Missing required parameter: code' }), { status: 400 });
    }

    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
    if (!stripeKey) {
      console.error('STRIPE_SECRET_KEY not set in environment variables!');
      throw new Error('Chave do Stripe não configurada no servidor.');
    }

    console.log(`[DEBUG] Stripe Key Prefix: ${stripeKey.substring(0, 8)}...`);

    const stripe = new Stripe(stripeKey, { apiVersion: '2023-10-16' });

    const couponCode = code.toUpperCase();
    console.log(`[DEBUG] Searching for coupon code: ${couponCode}`);

    // CORREÇÃO: busca pelo Promotion Code (código visível ao usuário)
    // e não pelo ID interno do coupon no Stripe
    const promos = await stripe.promotionCodes.list({
      code: couponCode,
      active: true,
      limit: 1,
      expand: ['data.coupon'],
    });

    if (!promos.data.length) {
      return new Response(JSON.stringify({ error: 'Cupom inválido' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    const promo = promos.data[0];
    const coupon = promo.coupon as Stripe.Coupon;

    if (!coupon.valid) {
      throw new Error('Cupom expirado ou inválido para uso.');
    }

    return new Response(JSON.stringify({
      isValid: true,
      coupon_id: promo.id,  // ID do promotion code (usado no create-subscription)
      discountType: coupon.percent_off ? 'percent' : 'amount',
      discountValue: coupon.percent_off || coupon.amount_off,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error: any) {
    const errorMessage = error.message || 'Internal server error';

    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
