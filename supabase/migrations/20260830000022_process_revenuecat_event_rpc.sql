-- PR3: atomic RevenueCat ledger claim + subscription mirror update.
-- Proposal only. Do not apply before review.

BEGIN;

CREATE OR REPLACE FUNCTION public.process_revenuecat_event(
  p_event_id TEXT,
  p_event_type TEXT,
  p_event_timestamp TIMESTAMPTZ,
  p_raw_app_user_id TEXT,
  p_canonical_user_id UUID,
  p_payload JSONB,
  p_apply_mirror BOOLEAN,
  p_entitlement_id TEXT,
  p_product_id TEXT,
  p_store TEXT,
  p_status TEXT,
  p_billing_period TEXT,
  p_current_period_start TIMESTAMPTZ,
  p_current_period_end TIMESTAMPTZ,
  p_will_renew BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $function$
DECLARE
  v_claimed_event_id TEXT;
  v_subscription public.user_subscriptions%ROWTYPE;
  v_subscription_id UUID;
  v_plan_id UUID;
  v_plan_ids UUID[];
  v_skip_reason TEXT;
BEGIN
  IF p_event_id IS NULL OR btrim(p_event_id) = '' THEN
    RAISE EXCEPTION 'event_id is required' USING ERRCODE = '22023';
  END IF;
  IF p_event_type IS NULL OR btrim(p_event_type) = '' THEN
    RAISE EXCEPTION 'event_type is required' USING ERRCODE = '22023';
  END IF;
  IF p_event_timestamp IS NULL THEN
    RAISE EXCEPTION 'event_timestamp is required' USING ERRCODE = '22023';
  END IF;
  IF p_payload IS NULL OR jsonb_typeof(p_payload) <> 'object' THEN
    RAISE EXCEPTION 'payload must be a JSON object' USING ERRCODE = '22023';
  END IF;
  IF p_entitlement_id IS NOT NULL AND p_entitlement_id <> 'bldr_club' THEN
    RAISE EXCEPTION 'unsupported entitlement' USING ERRCODE = '22023';
  END IF;
  IF p_status IS NOT NULL AND p_status NOT IN
    ('active', 'canceled', 'past_due', 'unpaid', 'trialing') THEN
    RAISE EXCEPTION 'unsupported subscription status' USING ERRCODE = '22023';
  END IF;
  IF p_billing_period IS NOT NULL AND p_billing_period NOT IN
    ('weekly', 'monthly', 'annual') THEN
    RAISE EXCEPTION 'unsupported billing period' USING ERRCODE = '22023';
  END IF;
  IF p_canonical_user_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM auth.users WHERE id = p_canonical_user_id
  ) THEN
    RAISE EXCEPTION 'canonical user does not exist' USING ERRCODE = '23503';
  END IF;

  INSERT INTO public.revenuecat_processed_events (
    event_id,
    event_type,
    event_timestamp,
    revenuecat_app_user_id,
    canonical_user_id,
    payload
  ) VALUES (
    p_event_id,
    p_event_type,
    p_event_timestamp,
    p_raw_app_user_id,
    p_canonical_user_id,
    p_payload
  )
  ON CONFLICT (event_id) DO NOTHING
  RETURNING event_id INTO v_claimed_event_id;

  IF v_claimed_event_id IS NULL THEN
    RETURN jsonb_build_object(
      'duplicate', true,
      'mirror_applied', false,
      'reason', 'event_already_processed'
    );
  END IF;

  IF p_canonical_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'duplicate', false,
      'mirror_applied', false,
      'reason', 'identity_unresolved'
    );
  END IF;

  IF NOT COALESCE(p_apply_mirror, false)
     OR p_entitlement_id IS DISTINCT FROM 'bldr_club' THEN
    RETURN jsonb_build_object(
      'duplicate', false,
      'mirror_applied', false,
      'reason', 'ledger_only_event'
    );
  END IF;

  SELECT us.*
  INTO v_subscription
  FROM public.user_subscriptions us
  WHERE us.user_id = p_canonical_user_id
  ORDER BY
    CASE WHEN us.revenuecat_app_user_id = p_canonical_user_id THEN 0 ELSE 1 END,
    CASE WHEN us.status IN ('active', 'trialing') THEN 0 ELSE 1 END,
    us.current_period_end DESC NULLS LAST,
    us.updated_at DESC
  LIMIT 1
  FOR UPDATE;

  IF FOUND THEN
    -- Commercial-period ordering is primary. The event timestamp is only a
    -- tie-breaker within the same commercial period (or when no dates exist).
    IF p_current_period_end IS NOT NULL
       AND v_subscription.current_period_end IS NOT NULL
       AND p_current_period_end < v_subscription.current_period_end THEN
      v_skip_reason := 'older_commercial_period';
    ELSIF (
      p_current_period_end IS NULL
      OR v_subscription.current_period_end IS NULL
      OR p_current_period_end = v_subscription.current_period_end
    ) AND v_subscription.revenuecat_last_event_at IS NOT NULL
      AND p_event_timestamp <= v_subscription.revenuecat_last_event_at THEN
      v_skip_reason := 'older_event_in_same_period';
    END IF;

    IF v_skip_reason IS NOT NULL THEN
      RETURN jsonb_build_object(
        'duplicate', false,
        'mirror_applied', false,
        'reason', v_skip_reason,
        'subscription_id', v_subscription.id
      );
    END IF;

    UPDATE public.user_subscriptions
    SET
      revenuecat_app_user_id = p_canonical_user_id,
      revenuecat_entitlement_id = 'bldr_club',
      revenuecat_product_id = COALESCE(p_product_id, revenuecat_product_id),
      revenuecat_store = COALESCE(p_store, revenuecat_store),
      revenuecat_last_event_id = p_event_id,
      revenuecat_last_event_at = p_event_timestamp,
      will_renew = COALESCE(p_will_renew, will_renew),
      status = COALESCE(p_status::public.subscription_status, status),
      billing_period = COALESCE(p_billing_period::public.billing_period, billing_period),
      current_period_start = COALESCE(p_current_period_start, current_period_start),
      current_period_end = COALESCE(p_current_period_end, current_period_end)
    WHERE id = v_subscription.id
    RETURNING id INTO v_subscription_id;
  ELSE
    -- A new mirror row is created only when the event contains a complete,
    -- commercially meaningful state and the canonical CLUB plan is unambiguous.
    IF p_status IS NULL OR p_billing_period IS NULL
       OR p_current_period_end IS NULL OR p_product_id IS NULL THEN
      RETURN jsonb_build_object(
        'duplicate', false,
        'mirror_applied', false,
        'reason', 'insufficient_state_for_new_subscription'
      );
    END IF;

    SELECT array_agg(sp.id ORDER BY sp.created_at) INTO v_plan_ids
    FROM public.subscription_plans sp
    WHERE sp.plan_type = 'club'
      AND sp.is_active = true;

    IF COALESCE(cardinality(v_plan_ids), 0) <> 1 THEN
      RETURN jsonb_build_object(
        'duplicate', false,
        'mirror_applied', false,
        'reason', 'active_club_plan_not_unique'
      );
    END IF;
    v_plan_id := v_plan_ids[1];

    INSERT INTO public.user_subscriptions (
      user_id,
      plan_id,
      status,
      billing_period,
      current_period_start,
      current_period_end,
      revenuecat_app_user_id,
      revenuecat_entitlement_id,
      revenuecat_product_id,
      revenuecat_store,
      revenuecat_last_event_id,
      revenuecat_last_event_at,
      will_renew
    ) VALUES (
      p_canonical_user_id,
      v_plan_id,
      p_status::public.subscription_status,
      p_billing_period::public.billing_period,
      p_current_period_start,
      p_current_period_end,
      p_canonical_user_id,
      'bldr_club',
      p_product_id,
      p_store,
      p_event_id,
      p_event_timestamp,
      p_will_renew
    )
    RETURNING id INTO v_subscription_id;
  END IF;

  UPDATE public.revenuecat_processed_events
  SET subscription_id = v_subscription_id
  WHERE event_id = p_event_id;

  RETURN jsonb_build_object(
    'duplicate', false,
    'mirror_applied', true,
    'reason', 'mirror_updated',
    'subscription_id', v_subscription_id
  );
END
$function$;

REVOKE ALL ON FUNCTION public.process_revenuecat_event(
  TEXT, TEXT, TIMESTAMPTZ, TEXT, UUID, JSONB, BOOLEAN, TEXT, TEXT, TEXT,
  TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.process_revenuecat_event(
  TEXT, TEXT, TIMESTAMPTZ, TEXT, UUID, JSONB, BOOLEAN, TEXT, TEXT, TEXT,
  TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN
) TO service_role;

COMMIT;
