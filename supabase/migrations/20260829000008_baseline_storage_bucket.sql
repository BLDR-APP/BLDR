-- BASELINE: bucket storage community-posts — exportado em 2026-08-29
--
-- Bucket confirmado: public = true, file_size_limit = null, allowed_mime_types = null.
-- Criado em 2026-08-29T01:13:25Z.
--
-- ──────────────────────────────────────────────────────────────────────────────
-- POLICIES DO BUCKET NÃO INVENTARIADAS
-- ──────────────────────────────────────────────────────────────────────────────
-- O inventário exportado (section 06_POLICY em storage.objects) contém apenas
-- policies dos buckets 'Images' e 'proofs'. Nenhuma policy explícita foi
-- exportada para 'community-posts'.
--
-- Com public = true, a Supabase Storage permite leitura pública sem policy.
-- Mas escrita (INSERT) requer policy ou service_role — o comportamento atual
-- para uploads do Flutter não foi verificado.
--
-- Antes de classificar este baseline como utilizável:
-- 1. Verificar policies existentes:
--    SELECT * FROM storage.policies WHERE bucket_id = 'community-posts';
-- 2. Se nenhuma policy de INSERT existir, confirmar se uploads funcionam
--    ou se estão bloqueados silenciosamente.
-- 3. Gerar baseline de policies após verificação.
--
-- ──────────────────────────────────────────────────────────────────────────────
-- AVISO DE APLICAÇÃO
-- ──────────────────────────────────────────────────────────────────────────────
-- INSERT em storage.buckets é protegido por trigger (protect_buckets_delete).
-- Para criar o bucket em novos ambientes, preferir Supabase CLI:
--   supabase storage create community-posts --public
--
-- ON CONFLICT DO NOTHING garante que a migration é segura onde o bucket existe.
-- Este arquivo documenta apenas o estado do bucket — NÃO inclui policies
-- recomendadas para não misturar estado real com SQL prescritivo.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'community-posts',
  'community-posts',
  true,
  null,
  null
)
ON CONFLICT (id) DO NOTHING;
