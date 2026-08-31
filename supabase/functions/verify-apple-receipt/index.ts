import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  type AppleReceiptResponse,
  assertCanonicalUser,
  bearerToken,
  RequestFailure,
  validateAppleSubscription,
  verifyWithApple,
} from "./logic.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type Dependencies = {
  authenticate: (accessToken: string) => Promise<string>;
  verifyReceipt: (receiptData: string) => Promise<AppleReceiptResponse>;
  persist: (input: {
    userId: string;
    productId: string;
    billingPeriod: string;
    expirationDate: string;
  }) => Promise<void>;
  now: () => number;
};

export function createHandler(dependencies: Dependencies) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    if (req.method !== "POST") {
      return jsonResponse(405, {
        success: false,
        error: "Método não permitido.",
      });
    }

    try {
      const accessToken = bearerToken(req.headers.get("authorization"));
      const authenticatedUserId = await dependencies.authenticate(accessToken);

      let body: Record<string, unknown>;
      try {
        body = await req.json();
      } catch (_) {
        throw new RequestFailure(400, "Corpo da requisição inválido.");
      }

      const receiptData = body.receipt_data;
      if (typeof receiptData !== "string" || receiptData.length === 0) {
        throw new RequestFailure(400, "Recibo Apple obrigatório.");
      }
      const canonicalUserId = assertCanonicalUser(
        authenticatedUserId,
        body.user_id,
      );
      const appleResponse = await dependencies.verifyReceipt(receiptData);
      const subscription = validateAppleSubscription(
        appleResponse,
        body.product_id,
        dependencies.now(),
      );

      await dependencies.persist({
        userId: canonicalUserId,
        productId: subscription.productId,
        billingPeriod: subscription.billingPeriod,
        expirationDate: subscription.expirationDate,
      });

      return jsonResponse(200, {
        success: true,
        message: "Assinatura Apple validada.",
      });
    } catch (error) {
      if (error instanceof RequestFailure) {
        return jsonResponse(error.statusCode, {
          success: false,
          error: error.publicMessage,
        });
      }
      console.error("verify-apple-receipt falhou sem conceder acesso.");
      return jsonResponse(500, {
        success: false,
        error: "Não foi possível validar a assinatura Apple.",
      });
    }
  };
}

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} não configurado.`);
  return value;
}

const legacyPlanId = "d082af8c-216a-4499-a1f6-1fb84ac08a5f";

function productionHandler() {
  const supabaseUrl = requiredEnvironment("SUPABASE_URL");
  const supabaseAnonKey = requiredEnvironment("SUPABASE_ANON_KEY");
  const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
  const appleSharedSecret = requiredEnvironment("APPLE_SHARED_SECRET");

  return createHandler({
    authenticate: async (accessToken) => {
      const authClient = createClient(supabaseUrl, supabaseAnonKey, {
        global: { headers: { Authorization: `Bearer ${accessToken}` } },
        auth: { persistSession: false, autoRefreshToken: false },
      });
      const { data, error } = await authClient.auth.getUser(accessToken);
      if (error || !data.user?.id) {
        throw new RequestFailure(401, "Sessão inválida ou expirada.");
      }
      return data.user.id;
    },
    verifyReceipt: (receiptData) =>
      verifyWithApple(receiptData, appleSharedSecret, fetch),
    persist: async ({ userId, productId, billingPeriod, expirationDate }) => {
      const adminClient = createClient(supabaseUrl, serviceRoleKey, {
        auth: { persistSession: false, autoRefreshToken: false },
      });
      const { error } = await adminClient.from("user_subscriptions").upsert({
        user_id: userId,
        plan_id: legacyPlanId,
        apple_product_id: productId,
        status: "active",
        current_period_end: expirationDate,
        payment_provider: "apple_iap",
        billing_period: billingPeriod,
        updated_at: new Date().toISOString(),
      }, { onConflict: "user_id" });
      if (error) throw error;
    },
    now: () => Date.now(),
  });
}

if (import.meta.main) serve(productionHandler());
