-- PR2: additive RevenueCat mirror foundation.
--
-- This migration intentionally does not migrate subscription data, change
-- legacy billing flows, or modify the hardened RLS policies/grants on
-- user_subscriptions, payment_intents, or subscription_plans.

BEGIN;

-- Existing values remain unchanged. IF NOT EXISTS tolerates known migration
-- drift where Production may already contain the value.
ALTER TYPE public.billing_period ADD VALUE IF NOT EXISTS 'weekly';

ALTER TABLE public.user_subscriptions
  ADD COLUMN IF NOT EXISTS revenuecat_app_user_id UUID,
  ADD COLUMN IF NOT EXISTS revenuecat_entitlement_id TEXT,
  ADD COLUMN IF NOT EXISTS revenuecat_product_id TEXT,
  ADD COLUMN IF NOT EXISTS revenuecat_store TEXT,
  ADD COLUMN IF NOT EXISTS revenuecat_last_event_id TEXT,
  ADD COLUMN IF NOT EXISTS revenuecat_last_event_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS will_renew BOOLEAN;

-- BLDR configures RevenueCat only with the canonical Supabase auth UUID.
-- NOT VALID avoids scanning or rewriting the 99 legacy rows during rollout;
-- new/updated rows are still checked immediately. Validation can be performed
-- later, after the RevenueCat backfill/reconciliation has been reviewed.
DO $migration$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.user_subscriptions'::regclass
      AND conname = 'user_subscriptions_revenuecat_user_matches_user_id'
  ) THEN
    ALTER TABLE public.user_subscriptions
      ADD CONSTRAINT user_subscriptions_revenuecat_user_matches_user_id
      CHECK (
        revenuecat_app_user_id IS NULL
        OR revenuecat_app_user_id = user_id
      ) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.user_subscriptions'::regclass
      AND conname = 'user_subscriptions_revenuecat_entitlement_is_bldr_club'
  ) THEN
    ALTER TABLE public.user_subscriptions
      ADD CONSTRAINT user_subscriptions_revenuecat_entitlement_is_bldr_club
      CHECK (
        revenuecat_entitlement_id IS NULL
        OR revenuecat_entitlement_id = 'bldr_club'
      ) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.user_subscriptions'::regclass
      AND conname = 'user_subscriptions_revenuecat_event_pair_complete'
  ) THEN
    ALTER TABLE public.user_subscriptions
      ADD CONSTRAINT user_subscriptions_revenuecat_event_pair_complete
      CHECK (
        (revenuecat_last_event_id IS NULL AND revenuecat_last_event_at IS NULL)
        OR
        (revenuecat_last_event_id IS NOT NULL AND revenuecat_last_event_at IS NOT NULL)
      ) NOT VALID;
  END IF;
END
$migration$;

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_revenuecat_app_user_id
  ON public.user_subscriptions (revenuecat_app_user_id)
  WHERE revenuecat_app_user_id IS NOT NULL;

-- A single last_event_id on user_subscriptions cannot reject an older retry
-- after a newer event has been processed. This compact ledger provides robust
-- deduplication: RevenueCat retries reuse the same event.id.
CREATE TABLE IF NOT EXISTS public.revenuecat_processed_events (
  event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  event_timestamp TIMESTAMPTZ NOT NULL,
  revenuecat_app_user_id TEXT,
  canonical_user_id UUID,
  subscription_id UUID REFERENCES public.user_subscriptions(id) ON DELETE SET NULL,
  payload JSONB NOT NULL,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Raw RevenueCat identities are strings and can include historical, migrated,
-- aliased, or anonymous identifiers. This index supports audit/reprocessing
-- lookups without assuming UUID semantics.
CREATE INDEX IF NOT EXISTS idx_revenuecat_events_revenuecat_app_user_id
  ON public.revenuecat_processed_events (revenuecat_app_user_id)
  WHERE revenuecat_app_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_revenuecat_events_canonical_user_id
  ON public.revenuecat_processed_events (canonical_user_id)
  WHERE canonical_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_revenuecat_processed_events_event_timestamp
  ON public.revenuecat_processed_events (event_timestamp DESC);

-- Webhook bookkeeping is backend-only. No client policy is created.
ALTER TABLE public.revenuecat_processed_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE public.revenuecat_processed_events
  FROM anon, authenticated;
GRANT ALL PRIVILEGES ON TABLE public.revenuecat_processed_events
  TO service_role;

COMMIT;
