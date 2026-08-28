-- Adiciona pace_sec (segundos por km) em bldr_club.user_activities
-- Calculado no app no momento do insert; backfill para corridas existentes.

ALTER TABLE bldr_club.user_activities
  ADD COLUMN IF NOT EXISTS pace_sec INT;

-- Backfill para corridas que têm distância e duração mas ainda sem pace_sec
UPDATE bldr_club.user_activities
SET pace_sec = (duration_seconds / (distance_meters / 1000.0))::INT
WHERE pace_sec IS NULL
  AND distance_meters IS NOT NULL
  AND distance_meters > 0
  AND duration_seconds IS NOT NULL
  AND duration_seconds > 0;

-- Notifica PostgREST para recarregar o schema cache imediatamente
SELECT pg_notify('pgrst', 'reload schema');
