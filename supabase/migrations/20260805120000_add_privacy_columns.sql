-- Adiciona colunas de privacidade e display_name em user_profiles.
-- Necessário para F13 (tela de Privacidade).

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS display_name        TEXT,
  ADD COLUMN IF NOT EXISTS photo_visibility    TEXT    NOT NULL DEFAULT 'public',
  ADD COLUMN IF NOT EXISTS feed_visible        BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS reactions_enabled   BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS ranking_visible     BOOLEAN NOT NULL DEFAULT true;
