-- PROPOSTA REVISAVEL: armazenamento server-side da conexao Garmin.
-- NAO APLICAR antes da aprovacao no Garmin Connect Developer Program.

CREATE TABLE IF NOT EXISTS bldr_club.garmin_tokens (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  expires_at TIMESTAMPTZ,
  garmin_user_id TEXT,
  scopes TEXT[] NOT NULL DEFAULT '{}',
  connected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bldr_club.garmin_tokens ENABLE ROW LEVEL SECURITY;
-- Sem policies: tokens sao manipulados apenas por Edge Functions com
-- service_role. Nunca retornar access_token/refresh_token ao app.

REVOKE ALL ON bldr_club.garmin_tokens FROM anon, authenticated;
GRANT ALL ON bldr_club.garmin_tokens TO service_role;
