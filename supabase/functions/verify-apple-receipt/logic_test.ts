import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createHandler } from "./index.ts";
import {
  APPLE_PRODUCTION_URL,
  APPLE_SANDBOX_URL,
  RequestFailure,
  verifyWithApple,
} from "./logic.ts";

const USER_A = "11111111-1111-4111-8111-111111111111";
const USER_B = "22222222-2222-4222-8222-222222222222";
const NOW = Date.UTC(2026, 7, 30);

function validAppleResponse(overrides: Record<string, unknown> = {}) {
  return {
    status: 0,
    receipt: { bundle_id: "com.bldr-fitness.app" },
    latest_receipt_info: [{
      product_id: "MENSAL",
      expires_date_ms: String(NOW + 2_592_000_000),
      transaction_id: "tx-2",
      original_transaction_id: "tx-1",
      ...overrides,
    }],
  };
}

function request(body: Record<string, unknown>, token = "valid-token") {
  return new Request("http://localhost/verify-apple-receipt", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

function harness(options: {
  authenticatedUser?: string;
  authFailure?: boolean;
  appleResponse?: ReturnType<typeof validAppleResponse> | { status: number };
} = {}) {
  const writes: Array<Record<string, unknown>> = [];
  const handler = createHandler({
    authenticate: async () => {
      if (options.authFailure) {
        throw new RequestFailure(401, "Sessão inválida ou expirada.");
      }
      return options.authenticatedUser ?? USER_A;
    },
    verifyReceipt: async () => options.appleResponse ?? validAppleResponse(),
    persist: async (input) => {
      writes.push(input);
    },
    now: () => NOW,
  });
  return { handler, writes };
}

const validBody = {
  user_id: USER_A,
  receipt_data: "receipt",
  product_id: "MENSAL",
};

Deno.test("JWT ausente é rejeitado sem escrita", async () => {
  const { handler, writes } = harness();
  const response = await handler(
    new Request("http://localhost", {
      method: "POST",
      body: JSON.stringify(validBody),
    }),
  );
  assertEquals(response.status, 401);
  assertEquals(writes.length, 0);
});

Deno.test("JWT inválido é rejeitado sem escrita", async () => {
  const { handler, writes } = harness({ authFailure: true });
  assertEquals((await handler(request(validBody, "invalid"))).status, 401);
  assertEquals(writes.length, 0);
});

Deno.test("body user_id diferente do JWT é rejeitado", async () => {
  const { handler, writes } = harness();
  assertEquals(
    (await handler(request({ ...validBody, user_id: USER_B }))).status,
    403,
  );
  assertEquals(writes.length, 0);
});

Deno.test("Apple 21002 é rejeitado e nunca fabrica acesso", async () => {
  const { handler, writes } = harness({ appleResponse: { status: 21002 } });
  assertEquals((await handler(request(validBody))).status, 422);
  assertEquals(writes.length, 0);
});

Deno.test("erro Apple genérico produz zero escrita", async () => {
  const { handler, writes } = harness({ appleResponse: { status: 21003 } });
  assertEquals((await handler(request(validBody))).status, 422);
  assertEquals(writes.length, 0);
});

Deno.test("resposta incompleta produz zero escrita", async () => {
  const { handler, writes } = harness({ appleResponse: { status: 0 } });
  assertEquals((await handler(request(validBody))).status, 422);
  assertEquals(writes.length, 0);
});

Deno.test("produto desconhecido produz zero escrita", async () => {
  const { handler, writes } = harness();
  assertEquals(
    (await handler(request({ ...validBody, product_id: "FAKE" }))).status,
    422,
  );
  assertEquals(writes.length, 0);
});

Deno.test("expiração ausente ou inválida produz zero escrita", async () => {
  for (const value of [undefined, "invalid", "0"]) {
    const { handler, writes } = harness({
      appleResponse: validAppleResponse({ expires_date_ms: value }),
    });
    assertEquals((await handler(request(validBody))).status, 422);
    assertEquals(writes.length, 0);
  }
});

Deno.test("receipt válido atualiza somente o usuário autenticado", async () => {
  const { handler, writes } = harness();
  assertEquals((await handler(request(validBody))).status, 200);
  assertEquals(writes.length, 1);
  assertEquals(writes[0].userId, USER_A);
  assertEquals(writes[0].productId, "MENSAL");
});

Deno.test("service-role não pode ser direcionada a outro usuário pelo body", async () => {
  const { handler, writes } = harness({ authenticatedUser: USER_B });
  assertEquals((await handler(request(validBody))).status, 403);
  assertEquals(writes.length, 0);
});

Deno.test("receipt cancelado ou expirado nunca concede acesso sintético", async () => {
  for (
    const override of [
      { cancellation_date_ms: String(NOW - 1000) },
      { expires_date_ms: String(NOW - 1000) },
    ]
  ) {
    const { handler, writes } = harness({
      appleResponse: validAppleResponse(override),
    });
    assertEquals((await handler(request(validBody))).status, 422);
    assertEquals(writes.length, 0);
  }
});

Deno.test("21007 mantém fallback Production para Sandbox", async () => {
  const urls: string[] = [];
  const responses = [{ status: 21007 }, validAppleResponse()];
  const fetcher = async (input: string | URL | Request) => {
    urls.push(String(input));
    return new Response(JSON.stringify(responses.shift()), { status: 200 });
  };
  const result = await verifyWithApple(
    "receipt",
    "secret",
    fetcher as typeof fetch,
  );
  assertEquals(result.status, 0);
  assertEquals(urls, [APPLE_PRODUCTION_URL, APPLE_SANDBOX_URL]);
});
