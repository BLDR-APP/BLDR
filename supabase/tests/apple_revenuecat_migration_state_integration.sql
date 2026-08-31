-- Local integration test for 20260830000023. Run only against an ephemeral
-- Supabase database after migrations; the transaction always rolls back.

BEGIN;

CREATE OR REPLACE FUNCTION pg_temp.assert_true(
  p_condition BOOLEAN,
  p_message TEXT
) RETURNS VOID LANGUAGE plpgsql AS $assert$
BEGIN
  IF NOT COALESCE(p_condition, false) THEN
    RAISE EXCEPTION 'assertion failed: %', p_message;
  END IF;
END
$assert$;

DO $test$
DECLARE
  v_user_a UUID := '10000000-0000-4000-8000-000000000001';
  v_user_b UUID := '10000000-0000-4000-8000-000000000002';
  v_user_c UUID := '10000000-0000-4000-8000-000000000003';
  v_claim JSONB;
  v_claim_id UUID;
  v_second_claim JSONB;
  v_before_subscriptions BIGINT;
  v_after_subscriptions BIGINT;
  v_result BOOLEAN;
BEGIN
  SELECT count(*) INTO v_before_subscriptions
  FROM public.user_subscriptions;

  INSERT INTO auth.users (id, instance_id, aud, role)
  VALUES
    (v_user_a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_user_b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_user_c, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

  INSERT INTO public.apple_revenuecat_migrations (user_id, status)
  VALUES
    (v_user_a, 'eligible'),
    (v_user_b, 'eligible'),
    (v_user_c, 'eligible');

  SELECT public.claim_apple_revenuecat_migration(v_user_a)
  INTO v_claim;
  PERFORM pg_temp.assert_true(
    (v_claim->>'claimed')::BOOLEAN,
    'eligible claim succeeds'
  );
  v_claim_id := (v_claim->>'claim_id')::UUID;

  SELECT public.claim_apple_revenuecat_migration(v_user_a)
  INTO v_second_claim;
  PERFORM pg_temp.assert_true(
    NOT (v_second_claim->>'claimed')::BOOLEAN,
    'second concurrent claim loses'
  );
  PERFORM pg_temp.assert_true(
    (SELECT attempt_count = 1
     FROM public.apple_revenuecat_migrations WHERE user_id = v_user_a),
    'attempt count increments once'
  );

  SELECT public.complete_apple_revenuecat_migration(
    v_user_a,
    gen_random_uuid(),
    v_user_a,
    'bldr_club',
    true,
    'active_entitlement',
    CURRENT_TIMESTAMP
  ) INTO v_result;
  PERFORM pg_temp.assert_true(NOT v_result, 'wrong claim cannot complete');

  SELECT public.complete_apple_revenuecat_migration(
    v_user_a,
    v_claim_id,
    v_user_b,
    'bldr_club',
    true,
    'active_entitlement',
    CURRENT_TIMESTAMP
  ) INTO v_result;
  PERFORM pg_temp.assert_true(
    NOT v_result,
    'non-canonical RevenueCat identity cannot complete'
  );

  SELECT public.complete_apple_revenuecat_migration(
    v_user_a,
    v_claim_id,
    v_user_a,
    'bldr_club',
    true,
    'active_entitlement',
    CURRENT_TIMESTAMP
  ) INTO v_result;
  PERFORM pg_temp.assert_true(v_result, 'valid proof completes');
  PERFORM pg_temp.assert_true(
    (SELECT status = 'completed'
     FROM public.apple_revenuecat_migrations WHERE user_id = v_user_a),
    'completed state persisted'
  );

  SELECT public.claim_apple_revenuecat_migration(v_user_a)
  INTO v_second_claim;
  PERFORM pg_temp.assert_true(
    NOT (v_second_claim->>'claimed')::BOOLEAN,
    'completed cannot return to eligible'
  );
  SELECT public.fail_apple_revenuecat_migration(
    v_user_a,
    v_claim_id,
    'LATE_FAILURE'
  ) INTO v_result;
  PERFORM pg_temp.assert_true(
    NOT v_result,
    'completed does not accept a late failure transition'
  );

  SELECT public.claim_apple_revenuecat_migration(v_user_b)
  INTO v_claim;
  v_claim_id := (v_claim->>'claim_id')::UUID;
  SELECT public.fail_apple_revenuecat_migration(
    v_user_b,
    v_claim_id,
    'RC_UNAVAILABLE'
  ) INTO v_result;
  PERFORM pg_temp.assert_true(v_result, 'valid in-progress failure succeeds');

  SELECT public.claim_apple_revenuecat_migration(v_user_b, false)
  INTO v_second_claim;
  PERFORM pg_temp.assert_true(
    NOT (v_second_claim->>'claimed')::BOOLEAN,
    'failed retry requires explicit authorization'
  );
  SELECT public.claim_apple_revenuecat_migration(v_user_b, true)
  INTO v_second_claim;
  PERFORM pg_temp.assert_true(
    (v_second_claim->>'claimed')::BOOLEAN,
    'explicitly authorized failed retry succeeds'
  );
  PERFORM pg_temp.assert_true(
    (SELECT attempt_count = 2
     FROM public.apple_revenuecat_migrations WHERE user_id = v_user_b),
    'retry increments attempt count'
  );

  -- Expired claims cannot finish or fail, but can be reclaimed atomically.
  SELECT public.claim_apple_revenuecat_migration(v_user_c)
  INTO v_claim;
  v_claim_id := (v_claim->>'claim_id')::UUID;
  UPDATE public.apple_revenuecat_migrations
  SET claim_expires_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
  WHERE user_id = v_user_c;

  SELECT public.fail_apple_revenuecat_migration(
    v_user_c,
    v_claim_id,
    'EXPIRED_FAILURE'
  ) INTO v_result;
  PERFORM pg_temp.assert_true(NOT v_result, 'expired claim cannot fail');

  SELECT public.complete_apple_revenuecat_migration(
    v_user_c,
    v_claim_id,
    v_user_c,
    'bldr_club',
    true,
    'active_entitlement',
    CURRENT_TIMESTAMP
  ) INTO v_result;
  PERFORM pg_temp.assert_true(NOT v_result, 'expired claim cannot complete');

  SELECT public.claim_apple_revenuecat_migration(v_user_c)
  INTO v_second_claim;
  PERFORM pg_temp.assert_true(
    (v_second_claim->>'claimed')::BOOLEAN,
    'expired claim can be reclaimed'
  );
  PERFORM pg_temp.assert_true(
    (SELECT attempt_count = 2
     FROM public.apple_revenuecat_migrations WHERE user_id = v_user_c),
    'expired reclaim increments attempt count'
  );

  -- Structural state invariants reject impossible direct writes, even for a
  -- trusted database role.
  BEGIN
    UPDATE public.apple_revenuecat_migrations
    SET claim_id = pg_catalog.gen_random_uuid(),
        claim_expires_at = CURRENT_TIMESTAMP + INTERVAL '1 minute'
    WHERE user_id = v_user_a;
    RAISE EXCEPTION 'non-in_progress retained a claim';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  BEGIN
    UPDATE public.apple_revenuecat_migrations
    SET status = 'in_progress',
        completed_at = NULL,
        revenuecat_app_user_id = NULL,
        revenuecat_entitlement_verified_at = NULL
    WHERE user_id = v_user_a;
    RAISE EXCEPTION 'in_progress existed without a claim';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  BEGIN
    UPDATE public.apple_revenuecat_migrations
    SET completed_at = NULL
    WHERE user_id = v_user_a;
    RAISE EXCEPTION 'completed existed without completed_at';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  BEGIN
    UPDATE public.apple_revenuecat_migrations
    SET completed_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_b;
    RAISE EXCEPTION 'non-completed retained completed_at';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  BEGIN
    UPDATE public.apple_revenuecat_migrations
    SET revenuecat_app_user_id = NULL
    WHERE user_id = v_user_a;
    RAISE EXCEPTION 'completed existed without canonical RevenueCat identity';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  BEGIN
    UPDATE public.apple_revenuecat_migrations
    SET revenuecat_entitlement_verified_at = NULL
    WHERE user_id = v_user_a;
    RAISE EXCEPTION 'completed existed without entitlement verification time';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  SELECT count(*) INTO v_after_subscriptions
  FROM public.user_subscriptions;
  PERFORM pg_temp.assert_true(
    v_before_subscriptions = v_after_subscriptions,
    'user_subscriptions remains unchanged'
  );
END
$test$;

-- ACL/RLS assertions do not mutate data and prove clients cannot write or
-- execute state-transition functions directly.
SELECT pg_temp.assert_true(
  (SELECT relrowsecurity FROM pg_class
   WHERE oid = 'public.apple_revenuecat_migrations'::regclass),
  'RLS enabled'
);
SELECT pg_temp.assert_true(
  NOT has_table_privilege('anon', 'public.apple_revenuecat_migrations', 'SELECT'),
  'anon has no SELECT'
);
SELECT pg_temp.assert_true(
  NOT has_table_privilege('authenticated', 'public.apple_revenuecat_migrations', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.apple_revenuecat_migrations', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.apple_revenuecat_migrations', 'DELETE'),
  'authenticated has no DML'
);
SELECT pg_temp.assert_true(
  NOT has_function_privilege(
    'authenticated',
    'public.complete_apple_revenuecat_migration(uuid,uuid,uuid,text,boolean,text,timestamptz)',
    'EXECUTE'
  ),
  'authenticated cannot mark completed'
);

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000001',
  true
);
SELECT pg_temp.assert_true(
  (SELECT count(*) = 1 FROM public.apple_revenuecat_migrations),
  'authenticated sees only own row'
);
RESET ROLE;

ROLLBACK;
