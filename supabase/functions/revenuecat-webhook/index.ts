import { createClient } from "@supabase/supabase-js";
import {
  authenticateRevenueCatWebhook,
  mapRevenueCatEvent,
  millisToIso,
  orderedIdentityCandidates,
  rawAppUserId,
  RevenueCatEvent,
} from "./logic.ts";

const MAX_BODY_BYTES = 1_000_000;

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const expectedAuthorization = Deno.env.get("REVENUECAT_WEBHOOK_AUTH") ?? "";
  const signingSecret = Deno.env.get("REVENUECAT_WEBHOOK_SIGNING_SECRET") ?? "";
  const receivedAuthorization = request.headers.get("Authorization") ?? "";
  if (expectedAuthorization.length === 0 || signingSecret.length === 0) {
    console.error("revenuecat-webhook authentication configuration missing");
    return json({ error: "server_configuration_error" }, 500);
  }

  const declaredLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > MAX_BODY_BYTES) {
    return json({ error: "payload_too_large" }, 413);
  }

  const rawBody = new Uint8Array(await request.arrayBuffer());
  if (rawBody.byteLength > MAX_BODY_BYTES) {
    return json({ error: "payload_too_large" }, 413);
  }

  const authentication = await authenticateRevenueCatWebhook(
    receivedAuthorization,
    expectedAuthorization,
    request.headers.get("X-RevenueCat-Webhook-Signature") ?? "",
    signingSecret,
    rawBody,
  );
  if (!authentication.authenticated) {
    console.warn("revenuecat-webhook authentication rejected", {
      reason: authentication.reason,
    });
    return json({ error: "unauthorized" }, 401);
  }

  let payload: Record<string, unknown>;
  try {
    const bodyText = new TextDecoder("utf-8", { fatal: true }).decode(rawBody);
    payload = JSON.parse(bodyText) as Record<string, unknown>;
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const event = payload.event as RevenueCatEvent | undefined;
  if (!event || typeof event !== "object" || Array.isArray(event)) {
    return json({ error: "missing_event" }, 400);
  }
  if (
    typeof event.id !== "string" || event.id.length === 0 ||
    typeof event.type !== "string" || event.type.length === 0 ||
    typeof event.event_timestamp_ms !== "number" ||
    !Number.isFinite(event.event_timestamp_ms)
  ) {
    return json({ error: "invalid_event" }, 400);
  }

  const eventTimestamp = millisToIso(event.event_timestamp_ms);
  if (!eventTimestamp) return json({ error: "invalid_event_timestamp" }, 400);

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("revenuecat-webhook server configuration missing");
    return json({ error: "server_configuration_error" }, 500);
  }
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let canonicalUserId: string | null = null;
  for (const candidate of orderedIdentityCandidates(event)) {
    const { data, error } = await admin.auth.admin.getUserById(candidate);
    if (!error && data.user?.id === candidate) {
      canonicalUserId = candidate;
      break;
    }
  }

  const mapping = mapRevenueCatEvent(event);
  const { data, error } = await admin.rpc("process_revenuecat_event", {
    p_event_id: event.id,
    p_event_type: event.type,
    p_event_timestamp: eventTimestamp,
    p_raw_app_user_id: rawAppUserId(event),
    p_canonical_user_id: canonicalUserId,
    p_payload: payload,
    p_apply_mirror: canonicalUserId !== null && mapping.applyMirror,
    p_entitlement_id: mapping.entitlementId,
    p_product_id: mapping.productId,
    p_store: mapping.store,
    p_status: mapping.status,
    p_billing_period: mapping.billingPeriod,
    p_current_period_start: mapping.currentPeriodStart,
    p_current_period_end: mapping.currentPeriodEnd,
    p_will_renew: mapping.willRenew,
  });

  if (error) {
    console.error("revenuecat-webhook atomic processing failed", {
      code: error.code,
      eventType: event.type,
    });
    return json({ error: "processing_failed" }, 500);
  }

  const result = data as Record<string, unknown>;
  if (canonicalUserId === null) {
    console.warn("revenuecat-webhook identity unresolved", {
      eventType: event.type,
    });
  }
  return json({
    accepted: true,
    duplicate: result.duplicate === true,
    identity_resolved: canonicalUserId !== null,
    mirror_applied: result.mirror_applied === true,
    reason: result.reason,
  }, 200);
});

function json(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
