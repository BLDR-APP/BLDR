import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { verifyRevenueCatReconciliation } from "./revenuecat_verifier.ts";

const userId = "194ff474-bf0e-455a-ba3c-e35706d2d9e3";
const entitlementId = "entl123";

function list(items: unknown[]) {
  return new Response(
    JSON.stringify({ object: "list", items, next_page: null }),
    {
      status: 200,
      headers: { "content-type": "application/json" },
    },
  );
}

function config(fetcher: typeof fetch) {
  return {
    secretApiKey: "secret",
    projectId: "proj123",
    customerId: userId,
    entitlementResourceId: entitlementId,
    fetcher,
    now: () => new Date("2026-08-31T00:00:00Z"),
  };
}

function appleSubscription() {
  return {
    object: "subscription",
    id: "sub123",
    customer_id: userId,
    store: "app_store",
  };
}

Deno.test("prova histórica + entitlement ativo conclui active", async () => {
  const result = await verifyRevenueCatReconciliation(config(async (input) => {
    const path = new URL(input.toString()).pathname;
    if (path.endsWith("/subscriptions")) return list([appleSubscription()]);
    if (path.endsWith("/subscriptions/sub123/entitlements")) {
      return list([{ object: "entitlement", id: entitlementId }]);
    }
    return list([{
      object: "customer.active_entitlement",
      entitlement_id: entitlementId,
      expires_at: null,
    }]);
  }));
  assertEquals(result.state, "ACTIVE_ENTITLEMENT");
});

Deno.test("prova histórica + sem entitlement ativo conclui inactive", async () => {
  const result = await verifyRevenueCatReconciliation(config(async (input) => {
    const path = new URL(input.toString()).pathname;
    if (path.endsWith("/subscriptions")) return list([appleSubscription()]);
    if (path.endsWith("/subscriptions/sub123/entitlements")) {
      return list([{ object: "entitlement", id: entitlementId }]);
    }
    return list([]);
  }));
  assertEquals(result.state, "INACTIVE_ENTITLEMENT");
});

Deno.test("sem assinatura Apple retorna no evidence", async () => {
  const result = await verifyRevenueCatReconciliation(
    config(async () => list([])),
  );
  assertEquals(result.state, "NO_PURCHASE_EVIDENCE");
});

Deno.test("subscription Stripe isolada não conclui migração Apple", async () => {
  let entitlementLookupCalled = false;
  const result = await verifyRevenueCatReconciliation(config(async (input) => {
    const path = new URL(input.toString()).pathname;
    if (path.endsWith("/subscriptions")) {
      return list([{
        object: "subscription",
        id: "subStripe",
        customer_id: userId,
        store: "stripe",
      }]);
    }
    entitlementLookupCalled = true;
    return list([{ object: "entitlement", id: entitlementId }]);
  }));
  assertEquals(result.state, "NO_PURCHASE_EVIDENCE");
  assertEquals(entitlementLookupCalled, false);
});

Deno.test("customer 404 retorna no evidence sem criar customer", async () => {
  let method = "";
  const result = await verifyRevenueCatReconciliation(
    config(async (_input, init) => {
      method = init?.method ?? "";
      return new Response("not found", { status: 404 });
    }),
  );
  assertEquals(method, "GET");
  assertEquals(result.state, "NO_PURCHASE_EVIDENCE");
});

Deno.test("erro RevenueCat falha fechado", async () => {
  const result = await verifyRevenueCatReconciliation(
    config(async () => new Response("", { status: 503 })),
  );
  assertEquals(result.state, "UNAVAILABLE");
});

Deno.test("resposta malformada falha fechado", async () => {
  const result = await verifyRevenueCatReconciliation(
    config(async () => new Response("{}", { status: 200 })),
  );
  assertEquals(result.state, "INVALID_RESPONSE");
});

Deno.test("customer divergente no payload falha fechado", async () => {
  const result = await verifyRevenueCatReconciliation(config(async () =>
    list([{
      object: "subscription",
      id: "sub123",
      customer_id: "4a4ed139-5f98-46b8-8648-b7f6dc8d628c",
      store: "app_store",
    }])
  ));
  assertEquals(result.state, "INVALID_RESPONSE");
});

Deno.test("paginação mantém host e encontra evidência na página seguinte", async () => {
  let subscriptionPages = 0;
  const result = await verifyRevenueCatReconciliation(config(async (input) => {
    const url = new URL(input.toString());
    if (url.pathname.endsWith("/subscriptions")) {
      subscriptionPages++;
      if (!url.searchParams.has("starting_after")) {
        return new Response(
          JSON.stringify({
            object: "list",
            items: [],
            next_page:
              `/v2/projects/proj123/customers/${userId}/subscriptions?starting_after=sub0&limit=100`,
          }),
          { status: 200 },
        );
      }
      return list([appleSubscription()]);
    }
    if (url.pathname.endsWith("/subscriptions/sub123/entitlements")) {
      return list([{ object: "entitlement", id: entitlementId }]);
    }
    return list([]);
  }));
  assertEquals(subscriptionPages, 2);
  assertEquals(result.state, "INACTIVE_ENTITLEMENT");
});
