-- HAVOK_SPEC.md §4 — thread contínua de conversa do HAVOK.
-- Uma thread por dia por usuário (bldr_club.havok_threads); mensagens
-- dentro dela em bldr_club.havok_messages, com janela deslizante lida
-- pela edge function gerar-resposta-havok.

CREATE TABLE IF NOT EXISTS bldr_club.havok_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_message_at timestamptz NOT NULL DEFAULT now(),
  origin_screen text
);

CREATE INDEX IF NOT EXISTS havok_threads_user_id_created_at_idx
  ON bldr_club.havok_threads (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS bldr_club.havok_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL REFERENCES bldr_club.havok_threads(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('user', 'assistant')),
  content text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  artifact_type text CHECK (artifact_type IS NULL OR artifact_type IN ('workout', 'recipe')),
  artifact_id uuid
);

CREATE INDEX IF NOT EXISTS havok_messages_thread_id_created_at_idx
  ON bldr_club.havok_messages (thread_id, created_at ASC);

ALTER TABLE bldr_club.havok_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE bldr_club.havok_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS havok_threads_owner ON bldr_club.havok_threads;
CREATE POLICY havok_threads_owner ON bldr_club.havok_threads
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS havok_messages_owner ON bldr_club.havok_messages;
CREATE POLICY havok_messages_owner ON bldr_club.havok_messages
  FOR ALL
  USING (
    thread_id IN (
      SELECT id FROM bldr_club.havok_threads WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    thread_id IN (
      SELECT id FROM bldr_club.havok_threads WHERE user_id = auth.uid()
    )
  );
