ALTER TABLE public.push_notifications_log
  ADD COLUMN IF NOT EXISTS notes TEXT;
