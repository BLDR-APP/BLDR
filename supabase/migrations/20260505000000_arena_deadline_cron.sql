-- Migration: arena_deadline_cron
-- Encerra arenas vencidas e envia notificações de prazo para
-- assinantes BLDR CLUB com squads ativos.

-- ─────────────────────────────────────────────────────────────
-- 1. Função principal
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION bldr_club.process_arena_deadlines()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN

  -- 1a. Encerra arenas cujo prazo já passou
  UPDATE bldr_club.arenas
  SET is_active = false
  WHERE is_active = true
    AND end_date < NOW();

  -- 1b. Notificação de 3 dias — apenas assinantes BLDR CLUB ativos
  INSERT INTO bldr_club.notifications (user_id, title, message, type)
  SELECT
    ap.user_id,
    '⚡ Operação encerrando em 3 dias!',
    'Seu squad "' || a.title || '" termina em 3 dias. Não perca nenhum dia!',
    'info'
  FROM bldr_club.arenas a
  JOIN bldr_club.arena_participants ap
    ON ap.arena_id = a.id AND ap.status = 'active'
  JOIN public.user_subscriptions us
    ON us.user_id = ap.user_id AND us.status = 'active'
  JOIN public.subscription_plans sp
    ON sp.id = us.plan_id AND sp.plan_type = 'club'
  WHERE a.is_active = true
    AND DATE(a.end_date AT TIME ZONE 'UTC') = CURRENT_DATE + INTERVAL '3 days';

  -- 1c. Notificação de 1 dia — apenas assinantes BLDR CLUB ativos
  INSERT INTO bldr_club.notifications (user_id, title, message, type)
  SELECT
    ap.user_id,
    '🚨 Último dia de operação!',
    'Seu squad "' || a.title || '" encerra AMANHÃ. Faça seu check-in agora!',
    'info'
  FROM bldr_club.arenas a
  JOIN bldr_club.arena_participants ap
    ON ap.arena_id = a.id AND ap.status = 'active'
  JOIN public.user_subscriptions us
    ON us.user_id = ap.user_id AND us.status = 'active'
  JOIN public.subscription_plans sp
    ON sp.id = us.plan_id AND sp.plan_type = 'club'
  WHERE a.is_active = true
    AND DATE(a.end_date AT TIME ZONE 'UTC') = CURRENT_DATE + INTERVAL '1 day';

END;
$$;

-- ─────────────────────────────────────────────────────────────
-- 2. Agendamento via pg_cron: todo dia às 08:00 UTC (05:00 BRT)
--    Requer extensão pg_cron habilitada no Supabase Dashboard
--    (Database → Extensions → pg_cron)
-- ─────────────────────────────────────────────────────────────
SELECT cron.schedule(
  'bldr-arena-deadline-check',  -- nome do job (único)
  '0 8 * * *',                  -- todo dia às 08:00 UTC
  'SELECT bldr_club.process_arena_deadlines()'
);
