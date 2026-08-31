-- Bounded backend-only retry policy for Apple reconciliation rows that did not
-- yet expose any RevenueCat purchase evidence. This does not claim or mutate
-- existing rows when applied; it only narrows a future RPC transition.
--
-- Policy:
--   * first automatic attempt remains the existing `eligible` claim;
--   * only RC_NO_PURCHASE_EVIDENCE can retry;
--   * retry waits at least seven days from the prior attempt;
--   * a row has at most three automatic attempts in total;
--   * review_required and completed remain non-claimable.

BEGIN;

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
      OR (
        status = 'failed'
        AND COALESCE(p_allow_failed_retry, false)
        AND last_error_code = 'RC_NO_PURCHASE_EVIDENCE'
        AND attempt_count < 3
        AND last_attempt_at <= v_now - INTERVAL '7 days'
      )
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

REVOKE ALL ON FUNCTION public.claim_apple_revenuecat_migration(
  UUID, BOOLEAN, INTEGER
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_apple_revenuecat_migration(
  UUID, BOOLEAN, INTEGER
) TO service_role;

COMMIT;
