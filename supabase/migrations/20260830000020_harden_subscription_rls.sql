-- Security hardening for client-facing billing tables.
--
-- This migration intentionally does not touch service_role privileges. Trusted
-- Edge Functions use service_role to maintain subscription state for Apple and
-- Stripe and must continue to bypass client RLS policies.

BEGIN;

-- Keep RLS enabled even in environments with minor schema drift.
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_intents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- user_subscriptions
-- authenticated may read only its own row. Client-side DML is forbidden.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "users_manage_own_user_subscriptions"
  ON public.user_subscriptions;

-- Replace the previous SELECT policy with one canonical policy so repeated
-- execution cannot create redundant permissive SELECT policies.
DROP POLICY IF EXISTS "Enable users to view their own data only"
  ON public.user_subscriptions;
DROP POLICY IF EXISTS "users_select_own_user_subscription"
  ON public.user_subscriptions;

CREATE POLICY "users_select_own_user_subscription"
  ON public.user_subscriptions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

REVOKE ALL PRIVILEGES ON TABLE public.user_subscriptions
  FROM anon, authenticated;
GRANT SELECT ON TABLE public.user_subscriptions TO authenticated;

-- ---------------------------------------------------------------------------
-- payment_intents
-- Retained as read-only for the owning authenticated user. No current client
-- or backend flow persists rows here, but service_role remains untouched.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "users_manage_own_payment_intents"
  ON public.payment_intents;
DROP POLICY IF EXISTS "users_select_own_payment_intents"
  ON public.payment_intents;

CREATE POLICY "users_select_own_payment_intents"
  ON public.payment_intents
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

REVOKE ALL PRIVILEGES ON TABLE public.payment_intents
  FROM anon, authenticated;
GRANT SELECT ON TABLE public.payment_intents TO authenticated;

-- ---------------------------------------------------------------------------
-- subscription_plans
-- Public clients may read active plans only. Plan management remains trusted.
-- Recreate the canonical policy to make its intended definition deterministic.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "public_can_read_subscription_plans"
  ON public.subscription_plans;

CREATE POLICY "public_can_read_subscription_plans"
  ON public.subscription_plans
  FOR SELECT
  TO public
  USING (is_active = true);

REVOKE ALL PRIVILEGES ON TABLE public.subscription_plans
  FROM anon, authenticated;
GRANT SELECT ON TABLE public.subscription_plans TO anon, authenticated;

COMMIT;
