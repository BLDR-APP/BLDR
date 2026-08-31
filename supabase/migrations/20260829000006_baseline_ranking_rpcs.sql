-- BASELINE: RPCs de ranking — definição real exportada do catálogo em 2026-08-29
--
-- ──────────────────────────────────────────────────────────────────────────────
-- DEPENDÊNCIA NÃO INVENTARIADA — BASELINE PARCIALMENTE UTILIZÁVEL
-- ──────────────────────────────────────────────────────────────────────────────
-- ranking_progression depende de public.personal_records.
-- Esta tabela NÃO foi inventariada e NÃO possui migration.
-- A função falhará com "relation does not exist" em ambientes onde a tabela
-- não foi criada. Gerar baseline de personal_records antes de aplicar em
-- ambiente limpo.
--
-- ──────────────────────────────────────────────────────────────────────────────
-- RETORNO REAL DAS RPCs (DIFERE DO QUE ESTAVA INFERIDO)
-- ──────────────────────────────────────────────────────────────────────────────
-- TABLE(user_id uuid, full_name text, username text, avatar_url text, total numeric)
-- Não há coluna "position" — calculada em memória no Flutter via índice.
-- Não há colunas "display_name" nem "value" — bug corrigido em RankingEntry.fromRow.
--
-- ──────────────────────────────────────────────────────────────────────────────
-- PROBLEMA DE PRIVACIDADE — ranking_visible NÃO filtrado
-- ──────────────────────────────────────────────────────────────────────────────
-- A migration 20260815000000_filter_ranking_by_visibility.sql adicionou
-- ranking_visible à tabela bldr_club.club_ranking e criou trigger de sincronização.
-- Porém as três RPCs abaixo fazem JOIN direto em user_profiles — não em
-- club_ranking — e NÃO filtram por ranking_visible nem por qualquer coluna
-- de privacidade. Usuários que optaram por não aparecer no ranking
-- continuam aparecendo nas RPCs exportadas. Isso é um problema de produto
-- que requer decisão e correção explícita — não corrigido neste baseline.
--
-- SECURITY DEFINER: as funções executam como postgres, bypassando RLS.
-- NÃO APLICAR sem supabase db diff prévio.

-- ── ranking_volume ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.ranking_volume(p_period text DEFAULT 'week'::text)
RETURNS TABLE(user_id uuid, full_name text, username text, avatar_url text, total numeric)
LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT
    up.id,
    up.full_name,
    up.username,
    up.avatar_url,
    COALESCE(SUM(uw.volume_kg), 0) +
    COALESCE((
      SELECT SUM(cuw.volume_kg)
      FROM public.club_user_workouts cuw
      WHERE cuw.user_id = up.id
        AND cuw.is_completed = true
        AND cuw.completed_at >= CASE p_period
          WHEN 'week'  THEN date_trunc('week', NOW() AT TIME ZONE 'America/Sao_Paulo')
          WHEN 'month' THEN date_trunc('month', NOW() AT TIME ZONE 'America/Sao_Paulo')
          ELSE '-infinity'::TIMESTAMPTZ
        END
    ), 0) AS total
  FROM public.user_profiles up
  LEFT JOIN public.user_workouts uw
    ON uw.user_id = up.id
    AND uw.is_completed = true
    AND uw.completed_at >= CASE p_period
      WHEN 'week'  THEN date_trunc('week', NOW() AT TIME ZONE 'America/Sao_Paulo')
      WHEN 'month' THEN date_trunc('month', NOW() AT TIME ZONE 'America/Sao_Paulo')
      ELSE '-infinity'::TIMESTAMPTZ
    END
  GROUP BY up.id, up.full_name, up.username, up.avatar_url
  HAVING COALESCE(SUM(uw.volume_kg), 0) > 0
      OR EXISTS (
        SELECT 1 FROM public.club_user_workouts cuw2
        WHERE cuw2.user_id = up.id AND cuw2.is_completed = true
      )
  ORDER BY total DESC
  LIMIT 50;
$function$;

GRANT EXECUTE ON FUNCTION public.ranking_volume(text)
  TO PUBLIC, anon, authenticated, service_role;

-- ── ranking_consistency ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.ranking_consistency(p_period text DEFAULT 'week'::text)
RETURNS TABLE(user_id uuid, full_name text, username text, avatar_url text, total numeric)
LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT
    up.id,
    up.full_name,
    up.username,
    up.avatar_url,
    COUNT(DISTINCT (completed_at AT TIME ZONE 'America/Sao_Paulo')::DATE)::NUMERIC AS total
  FROM public.user_profiles up
  JOIN (
    SELECT user_id, completed_at FROM public.user_workouts
    WHERE is_completed = true
      AND completed_at >= CASE p_period
        WHEN 'week'  THEN date_trunc('week', NOW() AT TIME ZONE 'America/Sao_Paulo')
        WHEN 'month' THEN date_trunc('month', NOW() AT TIME ZONE 'America/Sao_Paulo')
        ELSE '-infinity'::TIMESTAMPTZ
      END
    UNION ALL
    SELECT user_id, completed_at FROM public.club_user_workouts
    WHERE is_completed = true
      AND completed_at >= CASE p_period
        WHEN 'week'  THEN date_trunc('week', NOW() AT TIME ZONE 'America/Sao_Paulo')
        WHEN 'month' THEN date_trunc('month', NOW() AT TIME ZONE 'America/Sao_Paulo')
        ELSE '-infinity'::TIMESTAMPTZ
      END
  ) all_workouts ON all_workouts.user_id = up.id
  GROUP BY up.id, up.full_name, up.username, up.avatar_url
  ORDER BY total DESC
  LIMIT 50;
$function$;

GRANT EXECUTE ON FUNCTION public.ranking_consistency(text)
  TO PUBLIC, anon, authenticated, service_role;

-- ── ranking_progression ───────────────────────────────────────────────────────
-- Depende de public.personal_records — ver aviso no cabeçalho.
CREATE OR REPLACE FUNCTION public.ranking_progression(p_period text DEFAULT 'week'::text)
RETURNS TABLE(user_id uuid, full_name text, username text, avatar_url text, total numeric)
LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT
    up.id,
    up.full_name,
    up.username,
    up.avatar_url,
    COUNT(pr.id)::NUMERIC AS total
  FROM public.user_profiles up
  JOIN public.personal_records pr ON pr.user_id = up.id
  WHERE pr.recorded_at >= CASE p_period
    WHEN 'week'  THEN date_trunc('week', NOW() AT TIME ZONE 'America/Sao_Paulo')
    WHEN 'month' THEN date_trunc('month', NOW() AT TIME ZONE 'America/Sao_Paulo')
    ELSE '-infinity'::TIMESTAMPTZ
  END
  GROUP BY up.id, up.full_name, up.username, up.avatar_url
  ORDER BY total DESC
  LIMIT 50;
$function$;

GRANT EXECUTE ON FUNCTION public.ranking_progression(text)
  TO PUBLIC, anon, authenticated, service_role;
