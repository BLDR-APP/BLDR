import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  ClaimResult,
  CoordinatorDependencies,
  createHandler,
  MigrationRow,
  RequestFailure,
  RevenueCatVerification,
} from "./logic.ts";

const USER = "194ff474-bf0e-455a-ba3c-e35706d2d9e3";
const OTHER = "4a4ed139-5f98-46b8-8648-b7f6dc8d628c";
const CLAIM = "6410f707-edf9-424e-bcc6-ce7702d6c20d";
const NOW = Date.parse("2026-08-31T12:00:00Z");

function request(body: Record<string, unknown>, token = "valid") {
  return new Request("http://localhost", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

function dependencies(overrides: Partial<CoordinatorDependencies> = {}) {
  let row: MigrationRow | null = {
    user_id: USER,
    status: "eligible",
    claim_id: null,
    claim_expires_at: null,
    attempt_count: 0,
    last_attempt_at: null,
    last_error_code: null,
  };
  let claimCalls = 0;
  const retryFlags: boolean[] = [];
  let completeCalls = 0;
  let failCalls = 0;
  const deps: CoordinatorDependencies = {
    authenticate: async (token) => {
      if (token !== "valid") throw new RequestFailure(401, "unauthorized");
      return USER;
    },
    getMigration: async (userId) => row?.user_id === userId ? row : null,
    claim: async (_userId, allowNoEvidenceRetry): Promise<ClaimResult> => {
      claimCalls++;
      retryFlags.push(allowNoEvidenceRetry);
      row = {
        user_id: USER,
        status: "in_progress",
        claim_id: CLAIM,
        claim_expires_at: "2026-08-31T12:15:00Z",
        attempt_count: 1,
        last_attempt_at: "2026-08-31T12:00:00Z",
        last_error_code: null,
      };
      return {
        claimed: true,
        claim_id: CLAIM,
        claim_expires_at: row.claim_expires_at!,
        attempt_count: 1,
      };
    },
    verifyRevenueCat: async (): Promise<RevenueCatVerification> => ({
      customerId: USER,
      result: "active_entitlement",
      verifiedAt: "2026-08-31T12:01:00Z",
    }),
    complete: async () => {
      completeCalls++;
      return true;
    },
    fail: async () => {
      failCalls++;
      return true;
    },
    now: () => NOW,
    ...overrides,
  };
  return {
    deps,
    setRow: (value: MigrationRow | null) => row = value,
    calls: () => ({ claimCalls, completeCalls, failCalls, retryFlags }),
  };
}

Deno.test("sem JWT e JWT inválido são rejeitados", async () => {
  const fixture = dependencies();
  const handler = createHandler(fixture.deps);
  const noJwt = await handler(
    new Request("http://localhost", {
      method: "POST",
      body: JSON.stringify({ operation: "claim" }),
    }),
  );
  const invalid = await handler(request({ operation: "claim" }, "invalid"));
  assertEquals(noJwt.status, 401);
  assertEquals(invalid.status, 401);
  assertEquals(fixture.calls().claimCalls, 0);
});

Deno.test("claim deriva usuário do JWT e ignora body.user_id", async () => {
  const fixture = dependencies();
  const response = await createHandler(fixture.deps)(request({
    operation: "claim",
    user_id: OTHER,
  }));
  assertEquals(response.status, 200);
  assertEquals((await response.json()).claimed, true);
  assertEquals(fixture.calls().claimCalls, 1);
});

Deno.test("review_required não é claimable", async () => {
  const fixture = dependencies();
  fixture.setRow({
    user_id: USER,
    status: "review_required",
    claim_id: null,
    claim_expires_at: null,
    attempt_count: 0,
    last_attempt_at: null,
    last_error_code: null,
  });
  const response = await createHandler(fixture.deps)(
    request({ operation: "claim" }),
  );
  assertFalse((await response.json()).claimed);
  assertEquals(fixture.calls().claimCalls, 0);
});

Deno.test("falha sem evidência antes do cooldown não é reclamada", async () => {
  const fixture = dependencies();
  fixture.setRow({
    user_id: USER,
    status: "failed",
    claim_id: null,
    claim_expires_at: null,
    attempt_count: 1,
    last_attempt_at: "2026-08-30T12:00:01Z",
    last_error_code: "RC_NO_PURCHASE_EVIDENCE",
  });
  const response = await createHandler(fixture.deps)(
    request({ operation: "claim" }),
  );
  assertFalse((await response.json()).claimed);
  assertEquals(fixture.calls().claimCalls, 0);
});

Deno.test("falha sem evidência após cooldown é reclamada uma vez", async () => {
  const fixture = dependencies();
  fixture.setRow({
    user_id: USER,
    status: "failed",
    claim_id: null,
    claim_expires_at: null,
    attempt_count: 1,
    last_attempt_at: "2026-08-24T12:00:00Z",
    last_error_code: "RC_NO_PURCHASE_EVIDENCE",
  });
  const handler = createHandler(fixture.deps);
  const first = await handler(request({ operation: "claim" }));
  const second = await handler(request({ operation: "claim" }));
  assertEquals((await first.json()).claimed, true);
  assertFalse((await second.json()).claimed);
  assertEquals(fixture.calls().claimCalls, 1);
  assertEquals(fixture.calls().retryFlags, [true]);
});

Deno.test("limite de tentativas, falha diferente e completed não podem retry", async () => {
  const rows: MigrationRow[] = [
    {
      user_id: USER,
      status: "failed",
      claim_id: null,
      claim_expires_at: null,
      attempt_count: 3,
      last_attempt_at: "2026-08-20T12:00:00Z",
      last_error_code: "RC_NO_PURCHASE_EVIDENCE",
    },
    {
      user_id: USER,
      status: "failed",
      claim_id: null,
      claim_expires_at: null,
      attempt_count: 1,
      last_attempt_at: "2026-08-20T12:00:00Z",
      last_error_code: "RC_SYNC_FAILED",
    },
    {
      user_id: USER,
      status: "completed",
      claim_id: null,
      claim_expires_at: null,
      attempt_count: 1,
      last_attempt_at: "2026-08-20T12:00:00Z",
      last_error_code: null,
    },
  ];
  for (const row of rows) {
    const fixture = dependencies();
    fixture.setRow(row);
    const response = await createHandler(fixture.deps)(
      request({ operation: "claim" }),
    );
    assertFalse((await response.json()).claimed);
    assertEquals(fixture.calls().claimCalls, 0);
  }
});

Deno.test("segundo claim durante lease não chama RPC novamente", async () => {
  const fixture = dependencies();
  const handler = createHandler(fixture.deps);
  await handler(request({ operation: "claim" }));
  const second = await handler(request({ operation: "claim" }));
  assertFalse((await second.json()).claimed);
  assertEquals(fixture.calls().claimCalls, 1);
});

Deno.test("sem evidência comercial falha claim e não completa", async () => {
  const fixture = dependencies({
    verifyRevenueCat: async () => ({
      customerId: USER,
      result: "no_purchase_evidence",
    }),
  });
  await createHandler(fixture.deps)(request({ operation: "claim" }));
  const response = await createHandler(fixture.deps)(request({
    operation: "verify_and_complete",
    claim_id: CLAIM,
    entitlement_active: true,
  }));
  assertEquals(response.status, 409);
  assertEquals(fixture.calls().completeCalls, 0);
  assertEquals(fixture.calls().failCalls, 1);
});

Deno.test("identidade RevenueCat incorreta não completa", async () => {
  const fixture = dependencies({
    verifyRevenueCat: async () => ({
      customerId: OTHER,
      result: "active_entitlement",
      verifiedAt: "2026-08-31T12:01:00Z",
    }),
  });
  await createHandler(fixture.deps)(request({ operation: "claim" }));
  const response = await createHandler(fixture.deps)(request({
    operation: "verify_and_complete",
    claim_id: CLAIM,
  }));
  assertEquals(response.status, 409);
  assertEquals(fixture.calls().completeCalls, 0);
  assertEquals(fixture.calls().failCalls, 1);
});

Deno.test("entitlement ativo e UUID canônico podem completar", async () => {
  const fixture = dependencies();
  await createHandler(fixture.deps)(request({ operation: "claim" }));
  const response = await createHandler(fixture.deps)(request({
    operation: "verify_and_complete",
    claim_id: CLAIM,
  }));
  assertEquals(response.status, 200);
  assertEquals((await response.json()).completed, true);
  assertEquals(fixture.calls().completeCalls, 1);
});

Deno.test("evidência histórica inativa completa sem conceder entitlement", async () => {
  let activeAssertion: boolean | null = null;
  const fixture = dependencies({
    verifyRevenueCat: async () => ({
      customerId: USER,
      result: "inactive_entitlement",
      verifiedAt: "2026-08-31T12:01:00Z",
    }),
    complete: async (input) => {
      activeAssertion = input.entitlementActive;
      return true;
    },
  });
  await createHandler(fixture.deps)(request({ operation: "claim" }));
  const response = await createHandler(fixture.deps)(request({
    operation: "verify_and_complete",
    claim_id: CLAIM,
  }));
  assertEquals(response.status, 200);
  assertEquals(
    (await response.json()).reconciliation_result,
    "inactive_entitlement",
  );
  assertEquals(activeAssertion, false);
});

Deno.test("claim expirada pode ser reclamada pelo backend", async () => {
  const fixture = dependencies();
  fixture.setRow({
    user_id: USER,
    status: "in_progress",
    claim_id: CLAIM,
    claim_expires_at: "2026-08-31T11:59:59Z",
    attempt_count: 1,
    last_attempt_at: "2026-08-31T11:40:00Z",
    last_error_code: null,
  });
  const response = await createHandler(fixture.deps)(
    request({ operation: "claim" }),
  );
  assertEquals(response.status, 200);
  assertEquals((await response.json()).claimed, true);
  assertEquals(fixture.calls().claimCalls, 1);
});

Deno.test("claim expirada não consulta RevenueCat nem completa", async () => {
  let verifyCalls = 0;
  const fixture = dependencies({
    verifyRevenueCat: async () => {
      verifyCalls++;
      throw new Error("should not run");
    },
  });
  fixture.setRow({
    user_id: USER,
    status: "in_progress",
    claim_id: CLAIM,
    claim_expires_at: "2026-08-31T11:59:59Z",
    attempt_count: 1,
    last_attempt_at: "2026-08-31T11:40:00Z",
    last_error_code: null,
  });
  const response = await createHandler(fixture.deps)(request({
    operation: "verify_and_complete",
    claim_id: CLAIM,
  }));
  assertEquals(response.status, 409);
  assertEquals(verifyCalls, 0);
  assertEquals(fixture.calls().completeCalls, 0);
});

Deno.test("falha informada pelo client aceita somente código fixo", async () => {
  const fixture = dependencies();
  await createHandler(fixture.deps)(request({ operation: "claim" }));
  const rejected = await createHandler(fixture.deps)(request({
    operation: "fail",
    claim_id: CLAIM,
    error_code: "ARBITRARY_CLIENT_ERROR",
  }));
  const accepted = await createHandler(fixture.deps)(request({
    operation: "fail",
    claim_id: CLAIM,
    error_code: "RC_SYNC_FAILED",
  }));
  assertEquals(rejected.status, 400);
  assertEquals(accepted.status, 200);
  assertEquals(fixture.calls().failCalls, 1);
});
