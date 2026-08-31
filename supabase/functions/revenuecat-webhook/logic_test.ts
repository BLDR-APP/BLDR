import { assert, assertEquals, assertFalse } from "@std/assert";
import {
  authenticateRevenueCatWebhook,
  billingPeriodFor,
  constantTimeEquals,
  createRevenueCatSignature,
  isUuid,
  mapRevenueCatEvent,
  orderedIdentityCandidates,
  RevenueCatEvent,
} from "./logic.ts";

const USER_A = "194ff474-bf0e-455a-ba3c-e35706d2d9e3";
const USER_B = "2d3d5915-92f6-450d-bd6a-0f59f3aad11c";
const NOW = Date.UTC(2026, 7, 30);
const FUTURE = NOW + 7 * 86_400_000;
const PAST = NOW - 7 * 86_400_000;
const AUTHORIZATION = "Bearer webhook-auth";
const SIGNING_SECRET = "test-signing-secret";
const NOW_SECONDS = Math.floor(NOW / 1000);
const encoder = new TextEncoder();

function event(type: string, overrides: RevenueCatEvent = {}): RevenueCatEvent {
  return {
    id: `event-${type}`,
    type,
    event_timestamp_ms: NOW,
    app_user_id: USER_A,
    entitlement_ids: ["bldr_club"],
    product_id: "CLUBWEEKLY",
    store: "APP_STORE",
    period_type: "NORMAL",
    purchased_at_ms: NOW,
    expiration_at_ms: FUTURE,
    ...overrides,
  };
}

Deno.test("autenticação usa comparação segura e rejeita valor diferente", async () => {
  assert(await constantTimeEquals("Bearer secret", "Bearer secret"));
  assertFalse(await constantTimeEquals("Bearer wrong", "Bearer secret"));
});

Deno.test("HMAC válida autentica o raw body", async () => {
  const rawBody = encoder.encode('{"event":{"id":"event-1"}}');
  const signature = await createRevenueCatSignature(
    rawBody,
    NOW_SECONDS,
    SIGNING_SECRET,
  );
  assertEquals(
    await authenticateRevenueCatWebhook(
      AUTHORIZATION,
      AUTHORIZATION,
      signature,
      SIGNING_SECRET,
      rawBody,
      NOW_SECONDS,
    ),
    { authenticated: true },
  );
});

Deno.test("HMAC inválida é rejeitada", async () => {
  const rawBody = encoder.encode('{"event":{"id":"event-1"}}');
  const invalidSignature = `t=${NOW_SECONDS},v1=${"0".repeat(64)}`;
  assertEquals(
    await authenticateRevenueCatWebhook(
      AUTHORIZATION,
      AUTHORIZATION,
      invalidSignature,
      SIGNING_SECRET,
      rawBody,
      NOW_SECONDS,
    ),
    { authenticated: false, reason: "invalid_signature" },
  );
});

Deno.test("timestamp expirado é rejeitado pela janela de replay", async () => {
  const rawBody = encoder.encode('{"event":{"id":"event-1"}}');
  const oldTimestamp = NOW_SECONDS - 301;
  const signature = await createRevenueCatSignature(
    rawBody,
    oldTimestamp,
    SIGNING_SECRET,
  );
  assertEquals(
    await authenticateRevenueCatWebhook(
      AUTHORIZATION,
      AUTHORIZATION,
      signature,
      SIGNING_SECRET,
      rawBody,
      NOW_SECONDS,
    ),
    { authenticated: false, reason: "expired_signature" },
  );
});

Deno.test("body alterado depois da assinatura é rejeitado", async () => {
  const original = encoder.encode('{"event":{"id":"event-1"}}');
  const altered = encoder.encode('{"event":{"id":"event-2"}}');
  const signature = await createRevenueCatSignature(
    original,
    NOW_SECONDS,
    SIGNING_SECRET,
  );
  assertEquals(
    await authenticateRevenueCatWebhook(
      AUTHORIZATION,
      AUTHORIZATION,
      signature,
      SIGNING_SECRET,
      altered,
      NOW_SECONDS,
    ),
    { authenticated: false, reason: "invalid_signature" },
  );
});

Deno.test("Authorization inválida rejeita mesmo com HMAC válida", async () => {
  const rawBody = encoder.encode('{"event":{"id":"event-1"}}');
  const signature = await createRevenueCatSignature(
    rawBody,
    NOW_SECONDS,
    SIGNING_SECRET,
  );
  assertEquals(
    await authenticateRevenueCatWebhook(
      "Bearer wrong",
      AUTHORIZATION,
      signature,
      SIGNING_SECRET,
      rawBody,
      NOW_SECONDS,
    ),
    { authenticated: false, reason: "invalid_authorization" },
  );
});

Deno.test("retry preserva event.id e aceita nova assinatura válida", async () => {
  const rawBody = encoder.encode(
    '{"event":{"id":"same-event-id","type":"RENEWAL"}}',
  );
  const first = await createRevenueCatSignature(
    rawBody,
    NOW_SECONDS,
    SIGNING_SECRET,
  );
  const retry = await createRevenueCatSignature(
    rawBody,
    NOW_SECONDS + 1,
    SIGNING_SECRET,
  );
  assert(first !== retry);
  assertEquals(
    await authenticateRevenueCatWebhook(
      AUTHORIZATION,
      AUTHORIZATION,
      first,
      SIGNING_SECRET,
      rawBody,
      NOW_SECONDS,
    ),
    { authenticated: true },
  );
  assertEquals(
    await authenticateRevenueCatWebhook(
      AUTHORIZATION,
      AUTHORIZATION,
      retry,
      SIGNING_SECRET,
      rawBody,
      NOW_SECONDS + 1,
    ),
    { authenticated: true },
  );
  assertEquals(
    JSON.parse(new TextDecoder().decode(rawBody)).event.id,
    "same-event-id",
  );
});

Deno.test("INITIAL_PURCHASE ativa e mapeia weekly", () => {
  const mapped = mapRevenueCatEvent(event("INITIAL_PURCHASE"), NOW);
  assertEquals(mapped.status, "active");
  assertEquals(mapped.billingPeriod, "weekly");
  assertEquals(mapped.willRenew, true);
  assert(mapped.applyMirror);
});

Deno.test("RENEWAL mensal renova acesso", () => {
  const mapped = mapRevenueCatEvent(
    event("RENEWAL", { product_id: "MENSAL" }),
    NOW,
  );
  assertEquals(mapped.status, "active");
  assertEquals(mapped.billingPeriod, "monthly");
  assertEquals(mapped.willRenew, true);
});

Deno.test("produto anual atual é mapeado para annual", () => {
  assertEquals(
    mapRevenueCatEvent(event("RENEWAL", { product_id: "ANUAL" }), NOW)
      .billingPeriod,
    "annual",
  );
});

Deno.test("CANCELLATION futura preserva acesso e desliga renovação", () => {
  const mapped = mapRevenueCatEvent(event("CANCELLATION"), NOW);
  assertEquals(mapped.status, "active");
  assertEquals(mapped.willRenew, false);
});

Deno.test("UNCANCELLATION restaura renovação", () => {
  const mapped = mapRevenueCatEvent(event("UNCANCELLATION"), NOW);
  assertEquals(mapped.status, "active");
  assertEquals(mapped.willRenew, true);
});

Deno.test("EXPIRATION encerra acesso", () => {
  const mapped = mapRevenueCatEvent(
    event("EXPIRATION", { expiration_at_ms: PAST }),
    NOW,
  );
  assertEquals(mapped.status, "canceled");
  assertEquals(mapped.willRenew, false);
});

Deno.test("BILLING_ISSUE respeita acesso ainda vigente", () => {
  assertEquals(
    mapRevenueCatEvent(event("BILLING_ISSUE"), NOW).status,
    "active",
  );
  assertEquals(
    mapRevenueCatEvent(event("BILLING_ISSUE", { expiration_at_ms: PAST }), NOW)
      .status,
    "past_due",
  );
});

Deno.test("PRODUCT_CHANGE aguarda evento comercial autoritativo", () => {
  const mapped = mapRevenueCatEvent(
    event("PRODUCT_CHANGE", { new_product_id: "ANUAL" }),
    NOW,
  );
  assertFalse(mapped.applyMirror);
  assertEquals(mapped.productId, "ANUAL");
});

Deno.test("produto desconhecido usa duração comercial confiável", () => {
  assertEquals(billingPeriodFor("other", NOW, FUTURE), "weekly");
});

Deno.test("app_user_id UUID válido tem prioridade", () => {
  assertEquals(
    orderedIdentityCandidates(event("RENEWAL", {
      app_user_id: USER_A,
      original_app_user_id: USER_B,
    })),
    [USER_A, USER_B],
  );
  assert(isUuid(USER_A));
});

Deno.test("alias UUID válido é candidato e ID externo não é", () => {
  assertEquals(
    orderedIdentityCandidates(event("RENEWAL", {
      app_user_id: "legacy-user",
      original_app_user_id: "$RCAnonymousID:abc",
      aliases: ["not-a-uuid", USER_B],
    })),
    [USER_B],
  );
});

Deno.test("identidade não resolvível não produz candidato", () => {
  assertEquals(
    orderedIdentityCandidates(event("RENEWAL", {
      app_user_id: "legacy-user",
      original_app_user_id: "$RCAnonymousID:abc",
      aliases: [],
    })),
    [],
  );
});

Deno.test("TRANSFER avalia destino antes da origem e é ledger-only", () => {
  const transfer = event("TRANSFER", {
    app_user_id: undefined,
    original_app_user_id: undefined,
    transferred_to: [USER_B],
    transferred_from: [USER_A],
  });
  assertEquals(orderedIdentityCandidates(transfer), [USER_B, USER_A]);
  assertFalse(mapRevenueCatEvent(transfer, NOW).applyMirror);
});

Deno.test("evento de entitlement alheio nunca atualiza mirror", () => {
  const mapped = mapRevenueCatEvent(
    event("RENEWAL", { entitlement_ids: ["other"] }),
    NOW,
  );
  assertFalse(mapped.applyMirror);
});

Deno.test("RENEWAL incompleto não concede acesso", () => {
  const mapped = mapRevenueCatEvent(
    event("RENEWAL", {
      expiration_at_ms: null,
    }),
    NOW,
  );
  assertFalse(mapped.applyMirror);
  assertEquals(mapped.status, null);
});

Deno.test("CANCELLATION sem expiração não revoga acesso por inferência", () => {
  const mapped = mapRevenueCatEvent(
    event("CANCELLATION", {
      expiration_at_ms: null,
    }),
    NOW,
  );
  assert(mapped.applyMirror);
  assertEquals(mapped.status, null);
  assertEquals(mapped.willRenew, false);
});

Deno.test("RPC usa PK + ON CONFLICT para retry duplicado", async () => {
  const migration = await Deno.readTextFile(
    new URL(
      "../../migrations/20260830000022_process_revenuecat_event_rpc.sql",
      import.meta.url,
    ),
  );
  assert(migration.includes("ON CONFLICT (event_id) DO NOTHING"));
  assert(migration.includes("'event_already_processed'"));
});

Deno.test("RPC bloqueia evento de período comercial mais antigo", async () => {
  const migration = await Deno.readTextFile(
    new URL(
      "../../migrations/20260830000022_process_revenuecat_event_rpc.sql",
      import.meta.url,
    ),
  );
  assert(
    migration.includes(
      "p_current_period_end < v_subscription.current_period_end",
    ),
  );
  assert(migration.includes("'older_commercial_period'"));
  assert(
    migration.includes(
      "p_event_timestamp <= v_subscription.revenuecat_last_event_at",
    ),
  );
});
