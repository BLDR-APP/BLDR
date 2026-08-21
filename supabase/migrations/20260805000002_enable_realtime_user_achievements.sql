-- Garante que user_achievements está na publication do Realtime.
-- O erro 42710 ("already member") indica que já estava habilitado —
-- esta migration é no-op nesses casos.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'user_achievements'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_achievements;
  END IF;
END $$;
