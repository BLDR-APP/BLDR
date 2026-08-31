BEGIN;

ALTER TABLE public.apple_revenuecat_migrations
  ADD COLUMN revenuecat_entitlement_active BOOLEAN,
  ADD COLUMN reconciliation_result TEXT;

ALTER TABLE public.apple_revenuecat_migrations
  DROP CONSTRAINT apple_rc_migrations_completed_state_complete,
  ADD CONSTRAINT apple_rc_migrations_reconciliation_result_allowed CHECK (
    reconciliation_result IS NULL
    OR reconciliation_result IN ('active_entitlement', 'inactive_entitlement')
  ),
  ADD CONSTRAINT apple_rc_migrations_completed_state_complete CHECK (
    (
      status = 'completed'
      AND completed_at IS NOT NULL
      AND revenuecat_app_user_id = user_id
      AND revenuecat_entitlement_verified_at IS NOT NULL
      AND revenuecat_entitlement_active IS NOT NULL
      AND reconciliation_result = (
        CASE
          WHEN revenuecat_entitlement_active THEN 'active_entitlement'
          ELSE 'inactive_entitlement'
        END
      )
    ) OR (
      status <> 'completed'
      AND completed_at IS NULL
      AND revenuecat_app_user_id IS NULL
      AND revenuecat_entitlement_verified_at IS NULL
      AND revenuecat_entitlement_active IS NULL
      AND reconciliation_result IS NULL
    )
  );

DROP FUNCTION public.complete_apple_revenuecat_migration(
  UUID, UUID, UUID, TEXT, BOOLEAN, TIMESTAMPTZ
);

-- Backend-only assertion persistence. This RPC does not contact RevenueCat.
-- The trusted backend must first use read-only RevenueCat v2 resources to
-- prove canonical customer identity, historical Apple bldr_club evidence and
-- whether that entitlement is currently active.
CREATE FUNCTION public.complete_apple_revenuecat_migration(
  p_user_id UUID,
  p_claim_id UUID,
  p_revenuecat_app_user_id UUID,
  p_entitlement_id TEXT,
  p_entitlement_active BOOLEAN,
  p_reconciliation_result TEXT,
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
     OR p_entitlement_active IS NULL
     OR p_reconciliation_result IS DISTINCT FROM (
       CASE
         WHEN p_entitlement_active THEN 'active_entitlement'
         ELSE 'inactive_entitlement'
       END
     )
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
    revenuecat_entitlement_active = p_entitlement_active,
    reconciliation_result = p_reconciliation_result,
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
END;
$function$;

REVOKE ALL ON FUNCTION public.complete_apple_revenuecat_migration(
  UUID, UUID, UUID, TEXT, BOOLEAN, TEXT, TIMESTAMPTZ
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_apple_revenuecat_migration(
  UUID, UUID, UUID, TEXT, BOOLEAN, TEXT, TIMESTAMPTZ
) TO service_role;

COMMIT;
