-- Apple legacy -> RevenueCat: server-side one-shot migration state.
--
-- Infrastructure only. This migration does not seed users, call RevenueCat,
-- touch user_subscriptions, or connect the Flutter client to syncPurchases.

BEGIN;

CREATE TABLE public.apple_revenuecat_migrations (
  user_id UUID PRIMARY KEY
    REFERENCES auth.users(id) ON DELETE CASCADE,
  legacy_subscription_id UUID UNIQUE
    REFERENCES public.user_subscriptions(id) ON DELETE RESTRICT,
  status TEXT NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  last_error_code TEXT,
  claim_id UUID,
  claim_expires_at TIMESTAMPTZ,
  revenuecat_app_user_id UUID,
  revenuecat_entitlement_verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT apple_rc_migrations_status_allowed CHECK (
    status IN (
      'eligible',
      'in_progress',
      'completed',
      'failed',
      'review_required',
      'not_eligible'
    )
  ),
  CONSTRAINT apple_rc_migrations_attempt_count_nonnegative
    CHECK (attempt_count >= 0),
  CONSTRAINT apple_rc_migrations_claim_matches_status CHECK (
    (
      status = 'in_progress'
      AND claim_id IS NOT NULL
      AND claim_expires_at IS NOT NULL
    )
    OR (
      status <> 'in_progress'
      AND claim_id IS NULL
      AND claim_expires_at IS NULL
    )
  ),
  CONSTRAINT apple_rc_migrations_completed_state_complete CHECK (
    (
      status = 'completed'
      AND completed_at IS NOT NULL
      AND revenuecat_app_user_id = user_id
      AND revenuecat_entitlement_verified_at IS NOT NULL
    )
    OR (
      status <> 'completed'
      AND completed_at IS NULL
      AND revenuecat_app_user_id IS NULL
      AND revenuecat_entitlement_verified_at IS NULL
    )
  ),
  CONSTRAINT apple_rc_migrations_error_code_sanitized CHECK (
    last_error_code IS NULL
    OR last_error_code ~ '^[A-Z0-9_:-]{1,64}$'
  )
);

CREATE INDEX IF NOT EXISTS idx_apple_rc_migrations_status
  ON public.apple_revenuecat_migrations (status);

CREATE INDEX IF NOT EXISTS idx_apple_rc_migrations_claim_expiry
  ON public.apple_revenuecat_migrations (claim_expires_at)
  WHERE status = 'in_progress';

ALTER TABLE public.apple_revenuecat_migrations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_select_own_apple_rc_migration"
  ON public.apple_revenuecat_migrations;

CREATE POLICY "users_select_own_apple_rc_migration"
  ON public.apple_revenuecat_migrations
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

REVOKE ALL PRIVILEGES ON TABLE public.apple_revenuecat_migrations
  FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.apple_revenuecat_migrations TO authenticated;
GRANT ALL PRIVILEGES ON TABLE public.apple_revenuecat_migrations TO service_role;

-- Claims an eligible migration, an explicitly authorized failed retry, or an
-- expired in_progress lease. The conditional UPDATE is the concurrency guard:
-- only one caller can change the row and receive a claim_id.
CREATE OR REPLACE FUNCTION public.claim_apple_revenuecat_migration(
  p_user_id UUID,
  p_allow_failed_retry BOOLEAN DEFAULT false,
  p_lease_seconds INTEGER DEFAULT 900
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $function$
DECLARE
  v_row public.apple_revenuecat_migrations%ROWTYPE;
  v_claim_id UUID := pg_catalog.gen_random_uuid();
  v_now TIMESTAMPTZ := CURRENT_TIMESTAMP;
BEGIN
  IF p_user_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM auth.users WHERE id = p_user_id
  ) THEN
    RAISE EXCEPTION 'canonical user does not exist' USING ERRCODE = '23503';
  END IF;
  IF p_lease_seconds < 60 OR p_lease_seconds > 3600 THEN
    RAISE EXCEPTION 'lease must be between 60 and 3600 seconds'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.apple_revenuecat_migrations
  SET
    status = 'in_progress',
    attempt_count = attempt_count + 1,
    last_attempt_at = v_now,
    last_error_code = NULL,
    claim_id = v_claim_id,
    claim_expires_at = v_now + make_interval(secs => p_lease_seconds),
    updated_at = v_now
  WHERE user_id = p_user_id
    AND (
      status = 'eligible'
      OR (status = 'failed' AND COALESCE(p_allow_failed_retry, false))
      OR (
        status = 'in_progress'
        AND claim_expires_at IS NOT NULL
        AND claim_expires_at <= v_now
      )
    )
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('claimed', false, 'reason', 'not_claimable');
  END IF;

  RETURN jsonb_build_object(
    'claimed', true,
    'user_id', v_row.user_id,
    'claim_id', v_row.claim_id,
    'claim_expires_at', v_row.claim_expires_at,
    'attempt_count', v_row.attempt_count
  );
END
$function$;

-- Completion is backend-only. Before calling, the trusted backend must perform
-- an authoritative RevenueCat CustomerInfo check (or equivalent server-side
-- verification) proving the canonical UUID and active bldr_club entitlement.
-- This RPC does not contact RevenueCat; it only validates and persists the
-- backend assertion for the current live claim.
CREATE OR REPLACE FUNCTION public.complete_apple_revenuecat_migration(
  p_user_id UUID,
  p_claim_id UUID,
  p_revenuecat_app_user_id UUID,
  p_entitlement_id TEXT,
  p_entitlement_active BOOLEAN,
  p_verified_at TIMESTAMPTZ
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $function$
DECLARE
  v_updated_user_id UUID;
BEGIN
  IF p_user_id IS NULL
     OR p_claim_id IS NULL
     OR p_revenuecat_app_user_id IS DISTINCT FROM p_user_id
     OR p_entitlement_id IS DISTINCT FROM 'bldr_club'
     OR NOT COALESCE(p_entitlement_active, false)
     OR p_verified_at IS NULL
     OR p_verified_at > CURRENT_TIMESTAMP + INTERVAL '5 minutes' THEN
    RETURN false;
  END IF;

  UPDATE public.apple_revenuecat_migrations
  SET
    status = 'completed',
    completed_at = CURRENT_TIMESTAMP,
    revenuecat_app_user_id = p_revenuecat_app_user_id,
    revenuecat_entitlement_verified_at = p_verified_at,
    last_error_code = NULL,
    claim_id = NULL,
    claim_expires_at = NULL,
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id = p_user_id
    AND status = 'in_progress'
    AND claim_id = p_claim_id
    AND claim_expires_at > CURRENT_TIMESTAMP
    AND p_verified_at >= last_attempt_at
  RETURNING user_id INTO v_updated_user_id;

  RETURN v_updated_user_id IS NOT NULL;
END
$function$;

CREATE OR REPLACE FUNCTION public.fail_apple_revenuecat_migration(
  p_user_id UUID,
  p_claim_id UUID,
  p_error_code TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $function$
DECLARE
  v_error_code TEXT := upper(btrim(COALESCE(p_error_code, '')));
  v_updated_user_id UUID;
BEGIN
  IF p_user_id IS NULL
     OR p_claim_id IS NULL
     OR v_error_code !~ '^[A-Z0-9_:-]{1,64}$' THEN
    RETURN false;
  END IF;

  UPDATE public.apple_revenuecat_migrations
  SET
    status = 'failed',
    last_error_code = v_error_code,
    claim_id = NULL,
    claim_expires_at = NULL,
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id = p_user_id
    AND status = 'in_progress'
    AND claim_id = p_claim_id
    AND claim_expires_at > CURRENT_TIMESTAMP
  RETURNING user_id INTO v_updated_user_id;

  RETURN v_updated_user_id IS NOT NULL;
END
$function$;

REVOKE ALL ON FUNCTION public.claim_apple_revenuecat_migration(
  UUID, BOOLEAN, INTEGER
) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.complete_apple_revenuecat_migration(
  UUID, UUID, UUID, TEXT, BOOLEAN, TIMESTAMPTZ
) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fail_apple_revenuecat_migration(
  UUID, UUID, TEXT
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.claim_apple_revenuecat_migration(
  UUID, BOOLEAN, INTEGER
) TO service_role;
GRANT EXECUTE ON FUNCTION public.complete_apple_revenuecat_migration(
  UUID, UUID, UUID, TEXT, BOOLEAN, TIMESTAMPTZ
) TO service_role;
GRANT EXECUTE ON FUNCTION public.fail_apple_revenuecat_migration(
  UUID, UUID, TEXT
) TO service_role;

COMMIT;
