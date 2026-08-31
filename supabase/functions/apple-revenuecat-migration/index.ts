import { createClient } from "npm:@supabase/supabase-js";
import { CLUB_ENTITLEMENT_ID, createHandler, RequestFailure } from "./logic.ts";
import { verifyRevenueCatReconciliation } from "./revenuecat_verifier.ts";

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} not configured`);
  return value;
}

function productionHandler() {
  const supabaseUrl = requiredEnvironment("SUPABASE_URL");
  const anonKey = requiredEnvironment("SUPABASE_ANON_KEY");
  const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
  const revenueCatSecret = requiredEnvironment("REVENUECAT_SECRET_API_KEY");
  const revenueCatProjectId = requiredEnvironment("REVENUECAT_PROJECT_ID");
  const revenueCatClubEntitlementId = requiredEnvironment(
    "REVENUECAT_BLDR_CLUB_ENTITLEMENT_ID",
  );
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  return createHandler({
    authenticate: async (accessToken) => {
      const auth = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: `Bearer ${accessToken}` } },
        auth: { persistSession: false, autoRefreshToken: false },
      });
      const { data, error } = await auth.auth.getUser(accessToken);
      if (error || !data.user?.id) {
        throw new RequestFailure(401, "unauthorized");
      }
      return data.user.id;
    },
    getMigration: async (userId) => {
      const { data, error } = await admin.from("apple_revenuecat_migrations")
        .select(
          "user_id,status,claim_id,claim_expires_at,attempt_count,last_attempt_at,last_error_code",
        )
        .eq("user_id", userId).maybeSingle();
      if (error) throw error;
      return data;
    },
    claim: async (userId, allowNoEvidenceRetry = false) => {
      const { data, error } = await admin.rpc(
        "claim_apple_revenuecat_migration",
        {
          p_user_id: userId,
          p_allow_failed_retry: allowNoEvidenceRetry,
          p_lease_seconds: 900,
        },
      );
      if (error) throw error;
      return data;
    },
    verifyRevenueCat: async (userId) => {
      const verification = await verifyRevenueCatReconciliation({
        secretApiKey: revenueCatSecret,
        projectId: revenueCatProjectId,
        customerId: userId,
        entitlementResourceId: revenueCatClubEntitlementId,
      });
      if (
        verification.state === "UNAVAILABLE" ||
        verification.state === "INVALID_RESPONSE"
      ) {
        throw new Error(`RevenueCat verification ${verification.state}`);
      }
      return {
        customerId: verification.customerId,
        result: verification.state === "ACTIVE_ENTITLEMENT"
          ? "active_entitlement" as const
          : verification.state === "INACTIVE_ENTITLEMENT"
          ? "inactive_entitlement" as const
          : "no_purchase_evidence" as const,
        verifiedAt: verification.verifiedAt,
      };
    },
    complete: async (
      { userId, claimId, verifiedAt, entitlementActive, reconciliationResult },
    ) => {
      const { data, error } = await admin.rpc(
        "complete_apple_revenuecat_migration",
        {
          p_user_id: userId,
          p_claim_id: claimId,
          p_revenuecat_app_user_id: userId,
          p_entitlement_id: CLUB_ENTITLEMENT_ID,
          p_entitlement_active: entitlementActive,
          p_reconciliation_result: reconciliationResult,
          p_verified_at: verifiedAt,
        },
      );
      if (error) throw error;
      return data === true;
    },
    fail: async ({ userId, claimId, errorCode }) => {
      const { data, error } = await admin.rpc(
        "fail_apple_revenuecat_migration",
        {
          p_user_id: userId,
          p_claim_id: claimId,
          p_error_code: errorCode,
        },
      );
      if (error) throw error;
      return data === true;
    },
    now: () => Date.now(),
  });
}

if (import.meta.main) Deno.serve(productionHandler());
