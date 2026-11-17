-- MINHA_SEMANA.md (seções 2, 8 e 9): ajustes do plano válidos só para UMA
-- semana, sem alterar o plano recorrente (`weekly_plan_days`).
--
-- Uma linha = "nesta semana, este dia é X". A leitura do plano da semana é
-- `weekly_plan_days` mesclado com estas linhas (o ajuste vence).
--
-- `week_start`: segunda-feira da semana, tipo DATE, calculada pelo app na
-- data LOCAL do usuário (fuso do aparelho), nunca em UTC.
--
-- Acesso CLUB: a regra fica no app (`ResolveClubAccess`). O banco tem
-- `bldr_club.is_club_member`, mas ele ignora usuários Apple legados ainda em
-- reconciliação (que o app trata como CLUB); usá-lo aqui recusaria gravações
-- que o app libera. Ver BACKLOG_FUNCIONAL.md (B16).
--
-- Tipos conferidos no banco (17/11): weekly_plan_days.template_id = uuid
-- (FK para workout_templates, mantida aqui); weekly_plan_days.club_template_id
-- = text sem FK, embora club_workout_templates.id seja uuid. Aqui
-- club_template_id segue o weekly_plan_days (text, sem FK) para a mesclagem
-- não precisar de conversão. Um template do Club apagado deixa o id órfão,
-- como já acontece no plano recorrente (o app mostra só o nome).
-- public.update_updated_at_column() existe.

create table if not exists public.weekly_plan_overrides (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  week_start       date not null,
  dia_semana       smallint not null check (dia_semana between 1 and 7),
  tipo             text not null check (tipo in ('treino', 'descanso')),
  template_id      uuid references public.workout_templates(id) on delete set null,
  -- text sem FK, igual a weekly_plan_days.club_template_id (opção A):
  -- a mesclagem com o plano recorrente não precisa de conversão.
  club_template_id text,
  template_name    text,
  source           text not null default 'user',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint weekly_plan_overrides_unique_day
    unique (user_id, week_start, dia_semana),
  constraint weekly_plan_overrides_week_start_is_monday
    check (extract(isodow from week_start) = 1)
);

comment on table public.weekly_plan_overrides is
  'Ajustes do plano para uma semana específica (week_start = segunda local). Vencem weekly_plan_days naquela semana.';

create index if not exists weekly_plan_overrides_user_week_idx
  on public.weekly_plan_overrides (user_id, week_start);

alter table public.weekly_plan_overrides enable row level security;

drop policy if exists "weekly_plan_overrides_select" on public.weekly_plan_overrides;
create policy "weekly_plan_overrides_select" on public.weekly_plan_overrides
  for select using (auth.uid() = user_id);

drop policy if exists "weekly_plan_overrides_insert" on public.weekly_plan_overrides;
create policy "weekly_plan_overrides_insert" on public.weekly_plan_overrides
  for insert with check (auth.uid() = user_id);

drop policy if exists "weekly_plan_overrides_update" on public.weekly_plan_overrides;
create policy "weekly_plan_overrides_update" on public.weekly_plan_overrides
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "weekly_plan_overrides_delete" on public.weekly_plan_overrides;
create policy "weekly_plan_overrides_delete" on public.weekly_plan_overrides
  for delete using (auth.uid() = user_id);

drop trigger if exists update_weekly_plan_overrides_updated_at
  on public.weekly_plan_overrides;
create trigger update_weekly_plan_overrides_updated_at
  before update on public.weekly_plan_overrides
  for each row execute function public.update_updated_at_column();
