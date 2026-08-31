-- Migration: squad_free_club_limits (FULL REWRITE v2)
-- Rewrites the original 00028 to fix four architectural bugs:
--
-- BUG 1 — STALE CLUB AUTHORITY
--   The original used `user_subscriptions.status = 'active'` as the sole
--   Club signal. Apple legacy rows can have status = 'active' long after the
--   subscription expired. The RevenueCat mirror (migration 022) and Apple
--   reconciliation table (migrations 023/024) provide a stronger signal.
--
-- BUG 2 — MISSING COLUMN
--   arena_participants has no created_at column (documented in the baseline
--   migration 20260829000004). Counting that column fails silently. Replaced
--   by the immutable ledger below for join quota; arenas.created_at (which
--   does exist) is used for create quota.
--
-- BUG 3 — DELETE RESTORES QUOTA
--   arena_participants rows are deleted when a user leaves a Squad. Counting
--   them does not give a monotonic join quota. An immutable event ledger gives
--   a monotonic monthly count. Leaving a Squad does NOT free a slot.
--
-- BUG 4 — NON-ATOMIC QUOTA + ACTION
--   The previous check_and_record_squad_quota RPC accepted p_user_id from the
--   client and did not perform the actual arena INSERT or participant INSERT.
--   The insert happened separately on the client, creating a TOCTOU window:
--   the quota was checked in one call, the action taken in another. This
--   rewrite introduces two fully atomic RPCs that own both the quota check
--   and the write, with the user id always sourced from auth.uid().
--
-- ─────────────────────────────────────────────────────────────────────────────
-- CLUB AUTHORITY — canonical server-side source
-- ─────────────────────────────────────────────────────────────────────────────
--
-- CLUB AUTHORITY: requires positive proof from RevenueCat mirror only.
-- Apple legacy users in reconciliation (revenuecat_entitlement_id IS NULL) are
-- treated as Free for squad quota until RevenueCat confirms the entitlement.
-- This does NOT revoke their subscription — it only withholds unlimited squad quota
-- until there is a confirmed server-side signal.
--
-- The sole authoritative signal is:
--   public.user_subscriptions WHERE revenuecat_entitlement_id = 'bldr_club'
--   AND status IN ('active', 'trialing').
--   Written by process_revenuecat_event() (migration 022). This column is set
--   ONLY by the server-side webhook handler — a client cannot forge it.
--
-- Raw status = 'active' alone is NOT sufficient (see Bug 1 above).
-- There is NO Priority 2 / Apple legacy fallback in this function.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- CREATE QUOTA SOURCE — bldr_club.arenas (reliable, immutable)
-- ─────────────────────────────────────────────────────────────────────────────
--   arenas rows are created once and are never deleted when a user leaves
--   (only arena_participants is deleted on leave). creator_id and created_at
--   on arenas are set at insert time and do not change.
--   No ledger event is recorded for creates; the arenas table itself is the
--   authoritative source. The create RPC owns the INSERT atomically.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- JOIN QUOTA SOURCE — bldr_club.squad_quota_events (new, immutable ledger)
-- ─────────────────────────────────────────────────────────────────────────────
--   arena_participants has no created_at column and rows are deleted on leave.
--   The ledger records one 'join' event per join action, is never deleted, and
--   gives a monotonic monthly count. Leaving a Squad does NOT free a slot.
--   The join RPC inserts both the participant row and the ledger event inside
--   the same transaction. If the participant insert fails (e.g. UNIQUE
--   violation), both roll back — quota is never consumed without a successful
--   join.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- RACE SAFETY — advisory locks
-- ─────────────────────────────────────────────────────────────────────────────
--   Both RPCs use pg_advisory_xact_lock (blocking) to serialise concurrent
--   calls from the same user. Without a lock two simultaneous calls could both
--   read "4/5 used", both pass the check, and both proceed — resulting in
--   6 events. The advisory lock is released automatically at transaction end.
--   The lock key is a hash of the action type + user_id so create and join
--   locks for the same user are independent.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- QUOTA (Free tier):
--   Create : 2 Squads per calendar month (America/Sao_Paulo)
--   Join   : 5 Squads per calendar month (America/Sao_Paulo)
--
-- IMPORTANT: DO NOT apply to Production until the client-side quota UI
-- (create_arena_screen + join_squad_sheet) is deployed and tested.

-- ─────────────────────────────────────────────────────────────────────────────
-- 0. Drop the previous single-RPC design (replaced by two atomic RPCs below).
-- ─────────────────────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS bldr_club.check_and_record_squad_quota(uuid, uuid, text);
DROP FUNCTION IF EXISTS bldr_club.check_squad_limit(uuid, text);

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Immutable join event ledger
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bldr_club.squad_quota_events (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  arena_id    uuid        NOT NULL REFERENCES bldr_club.arenas(id) ON DELETE CASCADE,
  event_type  text        NOT NULL CHECK (event_type IN ('join')),
  occurred_at timestamptz NOT NULL DEFAULT now()
  -- NO UNIQUE(user_id, arena_id): re-joining the same Squad after leaving
  -- must consume a new quota event. The ledger is cumulative.
);

-- Index for monthly count queries (user + action + month window).
CREATE INDEX IF NOT EXISTS idx_squad_quota_events_user_type_month
  ON bldr_club.squad_quota_events (user_id, event_type, occurred_at DESC);

ALTER TABLE bldr_club.squad_quota_events ENABLE ROW LEVEL SECURITY;

-- Users may read their own events for quota display in the UI.
-- No direct INSERT/UPDATE/DELETE for any client role — only SECURITY DEFINER
-- RPCs below may write to this table.
DROP POLICY IF EXISTS "quota_events_read_own" ON bldr_club.squad_quota_events;
CREATE POLICY "quota_events_read_own"
  ON bldr_club.squad_quota_events
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Explicitly deny direct writes from client roles.
REVOKE INSERT, UPDATE, DELETE ON bldr_club.squad_quota_events FROM anon, authenticated;
GRANT SELECT ON bldr_club.squad_quota_events TO authenticated;
GRANT ALL    ON bldr_club.squad_quota_events TO service_role;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Club membership helper — SECURITY DEFINER, internal only
--    See header comment for rationale.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bldr_club.is_club_member(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, bldr_club, auth
AS $$
  -- CLUB AUTHORITY: positive proof from RevenueCat mirror only.
  -- revenuecat_entitlement_id is set ONLY by process_revenuecat_event() when
  -- a genuine RC webhook is processed — the client cannot set this column.
  -- Apple legacy users whose revenuecat_entitlement_id IS NULL are treated as
  -- Free for squad quota purposes until RC confirms the entitlement.
  SELECT EXISTS (
    SELECT 1
    FROM public.user_subscriptions us
    WHERE us.user_id = p_user_id
      AND us.revenuecat_entitlement_id = 'bldr_club'
      AND us.status IN ('active', 'trialing')
  );
$$;

-- is_club_member is intentionally NOT granted to authenticated — it is a
-- SECURITY DEFINER internal helper for the two RPCs below.
REVOKE ALL ON FUNCTION bldr_club.is_club_member(uuid) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION bldr_club.is_club_member(uuid) TO service_role;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Atomic CREATE RPC
--    Quota check + arena INSERT + creator participant INSERT in one transaction.
--    User id is always sourced from auth.uid() — never trusted from the client.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bldr_club.create_squad_with_quota(
  p_name            text,
  p_description     text,
  p_game_mode       text,
  p_duration_days   int,
  p_validation_type text,
  p_share_code      text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, bldr_club, auth
AS $$
DECLARE
  v_user_id     uuid;
  v_is_club     boolean;
  v_month_start timestamptz;
  v_used        int;
  v_limit       int := 2;
  v_arena       bldr_club.arenas%ROWTYPE;
BEGIN
  -- 1. Always use the server-side authenticated user — never trust a client param.
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  -- 2. Validate inputs fast.
  IF p_name IS NULL OR btrim(p_name) = '' THEN
    RAISE EXCEPTION 'Squad name is required' USING ERRCODE = '22023';
  END IF;
  IF p_duration_days IS NULL OR p_duration_days < 1 OR p_duration_days > 365 THEN
    RAISE EXCEPTION 'duration_days must be between 1 and 365' USING ERRCODE = '22023';
  END IF;

  -- 3. Determine Club membership using canonical authority.
  v_is_club := bldr_club.is_club_member(v_user_id);

  IF NOT v_is_club THEN
    -- 4. Acquire per-user advisory lock to serialise concurrent create calls.
    --    Two simultaneous calls from the same user will block here; the second
    --    will see the row created by the first and respect the updated count.
    --    Lock key is distinct from the join lock so creates and joins for the
    --    same user do not block each other.
    PERFORM pg_advisory_xact_lock(
      hashtext('squad_create_quota:' || v_user_id::text)
    );

    -- 5. Count arenas created by this user in the current calendar month
    --    (America/Sao_Paulo timezone for consistency with the Brazilian user base).
    v_month_start := date_trunc('month', now() AT TIME ZONE 'America/Sao_Paulo')
                     AT TIME ZONE 'America/Sao_Paulo';

    SELECT COUNT(*) INTO v_used
    FROM bldr_club.arenas
    WHERE creator_id = v_user_id
      AND created_at >= v_month_start;

    IF v_used >= v_limit THEN
      RETURN jsonb_build_object(
        'allowed', false,
        'used',    v_used,
        'limit',   v_limit,
        'reason',  'monthly_create_limit',
        'is_club', false
      );
    END IF;
  END IF;

  -- 6. Insert the arena. Dates are computed server-side to prevent clock skew.
  INSERT INTO bldr_club.arenas (
    title,
    description,
    game_mode,
    validation_type,
    share_code,
    creator_id,
    start_date,
    end_date,
    is_active
  ) VALUES (
    btrim(p_name),
    btrim(COALESCE(p_description, '')),
    p_game_mode,
    p_validation_type,
    p_share_code,
    v_user_id,
    now(),
    now() + (p_duration_days || ' days')::interval,
    true
  )
  RETURNING * INTO v_arena;

  -- 7. Insert the creator as a participant (same as createArena in the Dart repo).
  INSERT INTO bldr_club.arena_participants (
    arena_id,
    user_id,
    lives_count,
    current_score,
    status
  ) VALUES (
    v_arena.id,
    v_user_id,
    CASE WHEN p_game_mode = 'survivor' THEN 2 ELSE 0 END,
    0,
    'active'
  )
  ON CONFLICT (arena_id, user_id) DO NOTHING;

  -- 8. Return result.
  RETURN jsonb_build_object(
    'allowed',  true,
    'arena',    row_to_json(v_arena)::jsonb,
    'used',     CASE WHEN v_is_club THEN 0 ELSE v_used + 1 END,
    'limit',    CASE WHEN v_is_club THEN -1 ELSE v_limit END,
    'is_club',  v_is_club
  );
END;
$$;

GRANT EXECUTE ON FUNCTION bldr_club.create_squad_with_quota(
  text, text, text, int, text, text
) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Atomic JOIN RPC
--    Quota check + participant INSERT + ledger INSERT in one transaction.
--    If participant insert fails (e.g. UNIQUE violation), ledger rolls back
--    too — quota is never consumed without a successful join.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bldr_club.join_squad_with_quota(
  p_arena_id   uuid,
  p_share_code text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, bldr_club, auth
AS $$
DECLARE
  v_user_id     uuid;
  v_is_club     boolean;
  v_month_start timestamptz;
  v_used        int;
  v_limit       int := 5;
  v_arena       bldr_club.arenas%ROWTYPE;
  v_game_mode   text;
BEGIN
  -- 1. Always use the server-side authenticated user.
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  -- 2. Validate and fetch arena — share_code must match.
  SELECT * INTO v_arena
  FROM bldr_club.arenas
  WHERE id = p_arena_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason',  'arena_not_found'
    );
  END IF;

  IF v_arena.share_code IS DISTINCT FROM p_share_code THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason',  'invalid_share_code'
    );
  END IF;

  v_game_mode := v_arena.game_mode;

  -- 3. Check if already a participant.
  IF EXISTS (
    SELECT 1
    FROM bldr_club.arena_participants
    WHERE arena_id = p_arena_id
      AND user_id  = v_user_id
  ) THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason',  'already_member'
    );
  END IF;

  -- 4. Determine Club membership using canonical authority.
  v_is_club := bldr_club.is_club_member(v_user_id);

  IF NOT v_is_club THEN
    -- 5. Acquire per-user advisory lock to serialise concurrent join calls.
    --    Two simultaneous join calls from the same user will block; the second
    --    will see the ledger event inserted by the first.
    PERFORM pg_advisory_xact_lock(
      hashtext('squad_join_quota:' || v_user_id::text)
    );

    -- 6. Count join events in the current calendar month.
    v_month_start := date_trunc('month', now() AT TIME ZONE 'America/Sao_Paulo')
                     AT TIME ZONE 'America/Sao_Paulo';

    SELECT COUNT(*) INTO v_used
    FROM bldr_club.squad_quota_events
    WHERE user_id    = v_user_id
      AND event_type = 'join'
      AND occurred_at >= v_month_start;

    IF v_used >= v_limit THEN
      RETURN jsonb_build_object(
        'allowed', false,
        'used',    v_used,
        'limit',   v_limit,
        'reason',  'monthly_join_limit',
        'is_club', false
      );
    END IF;
  END IF;

  -- 7. Insert participant. Match exact columns joinArena() in Dart writes.
  INSERT INTO bldr_club.arena_participants (
    arena_id,
    user_id,
    lives_count,
    current_score,
    status,
    role
  ) VALUES (
    p_arena_id,
    v_user_id,
    CASE WHEN v_game_mode = 'survivor' THEN 2 ELSE 0 END,
    0,
    'active',
    'member'
  );
  -- If this INSERT fails (e.g. unexpected UNIQUE violation), the entire
  -- transaction rolls back — the ledger event below is not committed.

  -- 8. Record the join event in the immutable ledger (only for Free users;
  --    Club users bypass quota tracking entirely).
  IF NOT v_is_club THEN
    INSERT INTO bldr_club.squad_quota_events (user_id, arena_id, event_type)
    VALUES (v_user_id, p_arena_id, 'join');
  END IF;

  -- 9. Return result with arena title for UX.
  RETURN jsonb_build_object(
    'allowed',     true,
    'arena_title', v_arena.title,
    'used',        CASE WHEN v_is_club THEN 0 ELSE v_used + 1 END,
    'limit',       CASE WHEN v_is_club THEN -1 ELSE v_limit END,
    'is_club',     v_is_club
  );
END;
$$;

GRANT EXECUTE ON FUNCTION bldr_club.join_squad_with_quota(uuid, text)
  TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Read-only preflight helper — get_squad_quota
--    For displaying "X de Y usados" before the user submits.
--    No writes, no lock, NOT authoritative — the RPCs above are the authority.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bldr_club.get_squad_quota(
  p_user_id uuid,
  p_action  text   -- 'create' | 'join'
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, bldr_club, auth
AS $$
DECLARE
  v_is_club     boolean;
  v_month_start timestamptz;
  v_used        int;
  v_limit       int;
BEGIN
  IF p_action NOT IN ('create', 'join') THEN
    RAISE EXCEPTION 'Invalid action: %. Must be ''create'' or ''join''.', p_action
      USING ERRCODE = '22023';
  END IF;

  v_is_club := bldr_club.is_club_member(p_user_id);

  IF v_is_club THEN
    RETURN jsonb_build_object(
      'used',    0,
      'limit',   -1,
      'is_club', true
    );
  END IF;

  v_month_start := date_trunc('month', now() AT TIME ZONE 'America/Sao_Paulo')
                   AT TIME ZONE 'America/Sao_Paulo';

  IF p_action = 'create' THEN
    v_limit := 2;
    SELECT COUNT(*) INTO v_used
    FROM bldr_club.arenas
    WHERE creator_id = p_user_id
      AND created_at >= v_month_start;
  ELSE
    v_limit := 5;
    SELECT COUNT(*) INTO v_used
    FROM bldr_club.squad_quota_events
    WHERE user_id    = p_user_id
      AND event_type = 'join'
      AND occurred_at >= v_month_start;
  END IF;

  RETURN jsonb_build_object(
    'used',    v_used,
    'limit',   v_limit,
    'is_club', false
  );
END;
$$;

GRANT EXECUTE ON FUNCTION bldr_club.get_squad_quota(uuid, text)
  TO authenticated;
