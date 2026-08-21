-- Tokens OAuth por usuário
CREATE TABLE IF NOT EXISTS bldr_club.whoop_tokens (
  user_id       UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  access_token  TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at    TIMESTAMPTZ NOT NULL,
  whoop_user_id TEXT,
  connected_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE bldr_club.whoop_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuário lê/escreve seus próprios tokens"
  ON bldr_club.whoop_tokens
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Dados diários sincronizados
CREATE TABLE IF NOT EXISTS bldr_club.whoop_daily_data (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date            DATE NOT NULL,
  recovery_score  INT,
  hrv_rmssd       NUMERIC,
  resting_hr      INT,
  strain_score    NUMERIC,
  sleep_score     INT,
  sleep_duration  INT,
  synced_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

ALTER TABLE bldr_club.whoop_daily_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuário lê/escreve seus próprios dados diários"
  ON bldr_club.whoop_daily_data
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_whoop_daily_data_user_date
  ON bldr_club.whoop_daily_data(user_id, date DESC);
