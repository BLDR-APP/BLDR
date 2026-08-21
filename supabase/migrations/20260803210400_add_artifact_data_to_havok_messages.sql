-- HAVOK_SPEC.md §3.1 / BACKLOG_FUNCIONAL.md B6 — persiste o artefato
-- (treino/receita) gerado dentro da conversa, para o card sobreviver a um
-- reload da thread. artifact_type/artifact_id já existiam (migration
-- 20260803153733); artifact_data guarda o JSON completo do artefato.

ALTER TABLE IF EXISTS bldr_club.havok_messages
  ADD COLUMN IF NOT EXISTS artifact_data JSONB;
