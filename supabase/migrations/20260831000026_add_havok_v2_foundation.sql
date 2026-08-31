-- HAVOK V2 foundation. Additive only: existing HAVOK threads, messages and
-- artifacts remain readable as legacy V1 content.

CREATE TABLE IF NOT EXISTS bldr_club.havok_memories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category text NOT NULL CHECK (category IN (
    'preference', 'goal', 'constraint', 'routine', 'training_preference',
    'nutrition_preference', 'equipment', 'context'
  )),
  memory_key text NOT NULL CHECK (char_length(trim(memory_key)) BETWEEN 1 AND 120),
  value jsonb NOT NULL,
  source text NOT NULL DEFAULT 'havok' CHECK (source IN ('havok', 'user', 'imported')),
  confidence numeric(3,2) NOT NULL DEFAULT 0.80 CHECK (confidence >= 0 AND confidence <= 1),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  last_used_at timestamptz,
  UNIQUE (user_id, category, memory_key)
);

CREATE INDEX IF NOT EXISTS havok_memories_active_user_idx
  ON bldr_club.havok_memories (user_id, category, updated_at DESC)
  WHERE active = true;

CREATE TABLE IF NOT EXISTS bldr_club.havok_thread_summaries (
  thread_id uuid PRIMARY KEY REFERENCES bldr_club.havok_threads(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  summary text NOT NULL CHECK (char_length(trim(summary)) BETWEEN 1 AND 4000),
  source_message_count integer NOT NULL DEFAULT 0 CHECK (source_message_count >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS havok_thread_summaries_user_idx
  ON bldr_club.havok_thread_summaries (user_id, updated_at DESC);

-- V2 content is stored alongside the legacy artifact JSON. It is deliberately
-- nullable so all existing V1 messages remain valid.
ALTER TABLE bldr_club.havok_messages
  ADD COLUMN IF NOT EXISTS response_version integer,
  ADD COLUMN IF NOT EXISTS response_data jsonb;

ALTER TABLE bldr_club.havok_messages
  DROP CONSTRAINT IF EXISTS havok_messages_artifact_type_check;
ALTER TABLE bldr_club.havok_messages
  ADD CONSTRAINT havok_messages_artifact_type_check
  CHECK (artifact_type IS NULL OR artifact_type IN ('workout', 'recipe', 'nutrition_plan'));

ALTER TABLE bldr_club.havok_messages
  DROP CONSTRAINT IF EXISTS havok_messages_response_version_check;
ALTER TABLE bldr_club.havok_messages
  ADD CONSTRAINT havok_messages_response_version_check
  CHECK (response_version IS NULL OR response_version IN (1, 2));

ALTER TABLE bldr_club.havok_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bldr_club.havok_thread_summaries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS havok_memories_owner ON bldr_club.havok_memories;
CREATE POLICY havok_memories_owner ON bldr_club.havok_memories
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS havok_thread_summaries_owner ON bldr_club.havok_thread_summaries;
CREATE POLICY havok_thread_summaries_owner ON bldr_club.havok_thread_summaries
  FOR SELECT USING (user_id = auth.uid());

-- The Edge Function writes summaries with its server-side service role after
-- authenticating and ownership-checking the caller; clients never write them.
REVOKE INSERT, UPDATE, DELETE ON bldr_club.havok_thread_summaries FROM anon, authenticated;
