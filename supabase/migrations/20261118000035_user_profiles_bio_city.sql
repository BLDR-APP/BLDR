-- Comunidade v2, lote 1 (S12): bio e cidade do perfil social.
-- PROPOSTA: revisar antes de aplicar.
--
-- Nenhuma migration do repositório cria estas colunas; IF NOT EXISTS cobre o
-- caso de já existirem só em produção. Conferir antes:
--   select column_name, data_type from information_schema.columns
--   where table_schema = 'public' and table_name = 'user_profiles'
--     and column_name in ('bio', 'city');

alter table public.user_profiles
  add column if not exists bio text,
  add column if not exists city text;

alter table public.user_profiles
  drop constraint if exists user_profiles_bio_length,
  drop constraint if exists user_profiles_city_length;

-- NOT VALID: não reprova linhas antigas caso as colunas já existam com dados.
alter table public.user_profiles
  add constraint user_profiles_bio_length
    check (bio is null or char_length(bio) <= 160) not valid,
  add constraint user_profiles_city_length
    check (city is null or char_length(city) <= 80) not valid;
