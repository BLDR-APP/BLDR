function assert(
  condition: unknown,
  message = "assertion failed",
): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals(actual: unknown, expected: unknown): void {
  assert(Object.is(actual, expected), `expected ${expected}, got ${actual}`);
}

function assertMatch(value: string, pattern: RegExp): void {
  assert(pattern.test(value), `value did not match ${pattern}`);
}

const migration = await Deno.readTextFile(
  new URL(
    "../migrations/20260830000023_apple_revenuecat_migration_state.sql",
    import.meta.url,
  ),
);
const reconciliationMigration = await Deno.readTextFile(
  new URL(
    "../migrations/20260830000024_expand_apple_revenuecat_reconciliation.sql",
    import.meta.url,
  ),
);
const seed = await Deno.readTextFile(
  new URL(
    "../../docs/billing/apple_revenuecat_migration_seed.sql",
    import.meta.url,
  ),
);

Deno.test("migration state is isolated from commercial subscription state", () => {
  assert(!/UPDATE\s+public\.user_subscriptions/i.test(migration));
  assert(!/INSERT\s+INTO\s+public\.user_subscriptions/i.test(migration));
  assert(!/syncPurchases\s*\(|api\.revenuecat\.com/i.test(migration));
});

Deno.test("RLS permits only own-row reads to authenticated", () => {
  assertMatch(migration, /ENABLE ROW LEVEL SECURITY/i);
  assertMatch(migration, /FOR SELECT\s+TO authenticated/i);
  assertMatch(migration, /auth\.uid\(\) = user_id/i);
  assertMatch(
    migration,
    /REVOKE ALL PRIVILEGES[\s\S]*FROM PUBLIC, anon, authenticated/i,
  );
  assert(!/FOR (INSERT|UPDATE|DELETE)\s+TO authenticated/i.test(migration));
});

Deno.test("transition RPCs are service-role only", () => {
  const functions = [
    "claim_apple_revenuecat_migration",
    "complete_apple_revenuecat_migration",
    "fail_apple_revenuecat_migration",
  ];
  for (const name of functions) {
    assertMatch(
      migration,
      new RegExp(
        `REVOKE ALL ON FUNCTION public\\.${name}\\([\\s\\S]*?FROM PUBLIC, anon, authenticated`,
        "i",
      ),
    );
    assertMatch(
      migration,
      new RegExp(
        `GRANT EXECUTE ON FUNCTION public\\.${name}\\([\\s\\S]*?TO service_role`,
        "i",
      ),
    );
  }
});

Deno.test("claim is conditional, leased and increments attempts", () => {
  assertMatch(migration, /attempt_count = attempt_count \+ 1/i);
  assertMatch(migration, /status = 'eligible'/i);
  assertMatch(migration, /status = 'failed'.*p_allow_failed_retry/is);
  assertMatch(migration, /claim_expires_at <= v_now/i);
  assertMatch(migration, /RETURNING \* INTO v_row/i);
});

Deno.test("status, claim and completed proof invariants are bidirectional", () => {
  assertMatch(
    migration,
    /status = 'in_progress'[\s\S]*claim_id IS NOT NULL[\s\S]*claim_expires_at IS NOT NULL/i,
  );
  assertMatch(
    migration,
    /status <> 'in_progress'[\s\S]*claim_id IS NULL[\s\S]*claim_expires_at IS NULL/i,
  );
  assertMatch(
    migration,
    /status = 'completed'[\s\S]*completed_at IS NOT NULL[\s\S]*revenuecat_app_user_id = user_id[\s\S]*revenuecat_entitlement_verified_at IS NOT NULL/i,
  );
  assertMatch(
    migration,
    /status <> 'completed'[\s\S]*completed_at IS NULL[\s\S]*revenuecat_app_user_id IS NULL[\s\S]*revenuecat_entitlement_verified_at IS NULL/i,
  );
});

Deno.test("failure and completion require a live claim", () => {
  const liveClaimMatches = migration.match(
    /AND claim_expires_at > CURRENT_TIMESTAMP/g,
  ) ?? [];
  assertEquals(liveClaimMatches.length, 2);
});

Deno.test("UUID generation is explicitly resolved through pg_catalog", () => {
  assertMatch(migration, /pg_catalog\.gen_random_uuid\(\)/i);
  assert(!/(?<!pg_catalog\.)gen_random_uuid\(\)/i.test(migration));
});

Deno.test("completion requires canonical bldr_club proof", () => {
  assertMatch(
    migration,
    /p_revenuecat_app_user_id IS DISTINCT FROM p_user_id/i,
  );
  assertMatch(migration, /p_entitlement_id IS DISTINCT FROM 'bldr_club'/i);
  assertMatch(reconciliationMigration, /p_entitlement_active IS NULL/i);
  assertMatch(
    reconciliationMigration,
    /'active_entitlement'[\s\S]*'inactive_entitlement'/i,
  );
  assertMatch(migration, /status = 'in_progress'/i);
  assertMatch(migration, /claim_id = p_claim_id/i);
  assertMatch(migration, /This RPC does not contact RevenueCat/i);
});

Deno.test("completed supports proved active and inactive commercial states", () => {
  assertMatch(
    reconciliationMigration,
    /revenuecat_entitlement_active BOOLEAN/i,
  );
  assertMatch(reconciliationMigration, /reconciliation_result TEXT/i);
  assertMatch(
    reconciliationMigration,
    /status = 'completed'[\s\S]*revenuecat_entitlement_active IS NOT NULL/i,
  );
  assertMatch(
    reconciliationMigration,
    /status <> 'completed'[\s\S]*revenuecat_entitlement_active IS NULL[\s\S]*reconciliation_result IS NULL/i,
  );
  assertMatch(
    reconciliationMigration,
    /p_reconciliation_result IS DISTINCT FROM\s*\(\s*CASE\s+WHEN p_entitlement_active THEN 'active_entitlement'\s+ELSE 'inactive_entitlement'\s+END\s*\)/i,
  );
  assertMatch(reconciliationMigration, /END;\s*\$function\$;/i);
});

Deno.test("seed is guarded, non-identifying and non-executing", () => {
  assertMatch(seed, /CREATE TEMP TABLE apple_rc_expected_cohort/i);
  assertEquals((seed.match(/'eligible'/g) ?? []).length >= 2, true);
  assertEquals((seed.match(/'review_required'/g) ?? []).length >= 1, true);
  assertMatch(seed, /apple_rc_revalidated/i);
  assert((seed.match(/\bEXCEPT\b/g) ?? []).length >= 4);
  assertMatch(seed, /apple_rc_expected_existing/i);
  assertMatch(seed, /differs from pinned three-row baseline/i);
  assert(!/AND\s+us\.current_period_end/i.test(seed));
  assert(!/ON CONFLICT/i.test(seed));
  assertMatch(seed, /ROLLBACK;/i);
  assert(!/@/.test(seed));
  assert(!/COMMIT;/i.test(seed));
  assertEquals(
    (seed.match(/INSERT INTO public\.apple_revenuecat_migrations/gi) ?? [])
      .length,
    1,
  );
});

Deno.test("review_required is pinned but never claimable", () => {
  assertMatch(seed, /'review_required'/i);
  const claimFunction = migration.match(
    /CREATE OR REPLACE FUNCTION public\.claim_apple_revenuecat_migration[\s\S]*?\$function\$;/i,
  )?.[0] ?? "";
  assert(claimFunction.length > 0);
  assert(!/review_required/i.test(claimFunction));
});
