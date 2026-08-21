-- Contagem de mensagens do usuário no HAVOK no dia atual (fuso America/Sao_Paulo).
-- Usada para aplicar o limite de 10 msg/dia no plano Free.
-- Usuários Club (subscription ativa) não são bloqueados — a verificação é feita no cliente.

create or replace view bldr_club.havok_daily_usage
  with (security_invoker = true)
as
select
  count(*) as message_count
from bldr_club.havok_messages m
join bldr_club.havok_threads t on t.id = m.thread_id
where
  t.user_id = auth.uid()
  and m.role = 'user'
  and m.created_at >= (now() at time zone 'America/Sao_Paulo')::date;
