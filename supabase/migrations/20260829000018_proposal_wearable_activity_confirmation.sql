-- PROPOSTA REVISÁVEL — detecção e confirmação de atividades de wearables.
-- NÃO APLICAR AUTOMATICAMENTE.
--
-- A atividade externa só passa a contar para dashboard, semana, streak e XP
-- depois da confirmação do usuário. A conclusão efetiva continua usando a RPC
-- real public.complete_workout_with_analytics pelo aplicativo.

ALTER TABLE bldr_club.whoop_tokens
  ADD COLUMN IF NOT EXISTS last_workout_sync_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE TABLE IF NOT EXISTS public.wearable_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('whoop', 'apple_health', 'garmin')),
  external_activity_id TEXT NOT NULL,
  activity_type TEXT NOT NULL DEFAULT 'Atividade',
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL,
  duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
  strain NUMERIC,
  average_heart_rate INTEGER,
  max_heart_rate INTEGER,
  calories INTEGER,
  distance_km NUMERIC,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'confirmed', 'dismissed', 'deleted')),
  linked_workout_id UUID,
  linked_workout_source TEXT CHECK (linked_workout_source IN ('free', 'club')),
  provider_deleted_at TIMESTAMPTZ,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  confirmed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider, external_activity_id)
);

CREATE INDEX IF NOT EXISTS wearable_activities_user_status_started_idx
  ON public.wearable_activities(user_id, status, started_at DESC);

ALTER TABLE public.wearable_activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "wearable activities own select" ON public.wearable_activities;
CREATE POLICY "wearable activities own select"
  ON public.wearable_activities FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Escritas do usuário passam pelas RPCs abaixo. Ingestão é service-role.
GRANT SELECT ON public.wearable_activities TO authenticated;
GRANT ALL ON public.wearable_activities TO service_role;

CREATE TABLE IF NOT EXISTS public.wearable_webhook_events (
  trace_id TEXT PRIMARY KEY,
  provider TEXT NOT NULL DEFAULT 'whoop',
  event_type TEXT NOT NULL,
  external_activity_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'processing'
    CHECK (status IN ('processing', 'completed', 'error')),
  attempts INTEGER NOT NULL DEFAULT 1,
  error_message TEXT,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ
);

ALTER TABLE public.wearable_webhook_events ENABLE ROW LEVEL SECURITY;
GRANT ALL ON public.wearable_webhook_events TO service_role;

CREATE OR REPLACE FUNCTION public.prepare_wearable_workout(
  p_activity_id UUID,
  p_template_id UUID DEFAULT NULL,
  p_source TEXT DEFAULT 'free'
) RETURNS TABLE(workout_id UUID, workout_source TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_activity public.wearable_activities%ROWTYPE;
  v_workout_id UUID;
  v_name TEXT;
  v_source TEXT;
BEGIN
  SELECT * INTO v_activity
  FROM public.wearable_activities
  WHERE id = p_activity_id AND user_id = auth.uid()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Atividade não encontrada' USING ERRCODE = 'P0002';
  END IF;
  IF v_activity.status IN ('confirmed', 'dismissed', 'deleted') THEN
    RAISE EXCEPTION 'Atividade não está disponível para confirmação';
  END IF;

  IF v_activity.linked_workout_id IS NOT NULL THEN
    RETURN QUERY SELECT v_activity.linked_workout_id,
      COALESCE(v_activity.linked_workout_source, 'free');
    RETURN;
  END IF;

  v_source := CASE WHEN p_source = 'club' THEN 'club' ELSE 'free' END;

  IF v_source = 'club' THEN
    SELECT name INTO v_name
    FROM public.club_workout_templates
    WHERE id = p_template_id AND is_public = true;
    IF p_template_id IS NOT NULL AND v_name IS NULL THEN
      RAISE EXCEPTION 'Template do Club indisponível';
    END IF;
    v_name := COALESCE(NULLIF(v_name, ''), v_activity.activity_type, 'Atividade WHOOP');
    INSERT INTO public.club_user_workouts (
      user_id, workout_template_id, name, started_at,
      total_duration_seconds, notes, is_completed
    ) VALUES (
      auth.uid(), p_template_id, v_name, v_activity.started_at,
      v_activity.duration_seconds,
      'Importado de ' || upper(v_activity.provider), false
    ) RETURNING id INTO v_workout_id;
  ELSE
    SELECT name INTO v_name
    FROM public.workout_templates
    WHERE id = p_template_id
      AND (created_by = auth.uid() OR is_public = true);
    IF p_template_id IS NOT NULL AND v_name IS NULL THEN
      RAISE EXCEPTION 'Template pessoal indisponível';
    END IF;
    v_name := COALESCE(NULLIF(v_name, ''), v_activity.activity_type, 'Atividade WHOOP');
    INSERT INTO public.user_workouts (
      user_id, workout_template_id, name, started_at,
      total_duration_seconds, notes, is_completed
    ) VALUES (
      auth.uid(), p_template_id, v_name, v_activity.started_at,
      v_activity.duration_seconds,
      'Importado de ' || upper(v_activity.provider), false
    ) RETURNING id INTO v_workout_id;
  END IF;

  UPDATE public.wearable_activities
  SET status = 'processing', linked_workout_id = v_workout_id,
      linked_workout_source = v_source, updated_at = now()
  WHERE id = p_activity_id;

  RETURN QUERY SELECT v_workout_id, v_source;
END;
$$;

CREATE OR REPLACE FUNCTION public.confirm_wearable_activity(p_activity_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_activity public.wearable_activities%ROWTYPE;
  v_completed_at TIMESTAMPTZ;
BEGIN
  SELECT * INTO v_activity
  FROM public.wearable_activities
  WHERE id = p_activity_id AND user_id = auth.uid()
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Atividade não encontrada' USING ERRCODE = 'P0002';
  END IF;
  IF v_activity.linked_workout_id IS NULL THEN
    RAISE EXCEPTION 'Atividade ainda não possui treino associado';
  END IF;

  IF v_activity.linked_workout_source = 'club' THEN
    SELECT completed_at INTO v_completed_at FROM public.club_user_workouts
    WHERE id = v_activity.linked_workout_id AND user_id = auth.uid();
  ELSE
    SELECT completed_at INTO v_completed_at FROM public.user_workouts
    WHERE id = v_activity.linked_workout_id AND user_id = auth.uid();
  END IF;
  IF v_completed_at IS NULL THEN
    RAISE EXCEPTION 'O treino associado ainda não foi concluído';
  END IF;

  -- A sequência e os cards semanais devem refletir o dia real da atividade,
  -- não o momento posterior em que o usuário tocou na notificação.
  IF v_activity.linked_workout_source = 'club' THEN
    UPDATE public.club_user_workouts
    SET completed_at = v_activity.ended_at,
        total_duration_seconds = COALESCE(
          v_activity.duration_seconds, total_duration_seconds
        )
    WHERE id = v_activity.linked_workout_id AND user_id = auth.uid();
  ELSE
    UPDATE public.user_workouts
    SET completed_at = v_activity.ended_at,
        total_duration_seconds = COALESCE(
          v_activity.duration_seconds, total_duration_seconds
        )
    WHERE id = v_activity.linked_workout_id AND user_id = auth.uid();
  END IF;

  UPDATE public.wearable_activities
  SET status = 'confirmed', confirmed_at = now(), updated_at = now()
  WHERE id = p_activity_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.dismiss_wearable_activity(p_activity_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_activity public.wearable_activities%ROWTYPE;
BEGIN
  SELECT * INTO v_activity
  FROM public.wearable_activities
  WHERE id = p_activity_id AND user_id = auth.uid()
  FOR UPDATE;
  IF NOT FOUND OR v_activity.status IN ('confirmed', 'dismissed', 'deleted') THEN
    RETURN;
  END IF;

  -- Se a conclusão falhou depois do preparo, remove somente a sessão vazia
  -- criada por este fluxo. Treinos concluídos nunca são apagados aqui.
  IF v_activity.status = 'processing' AND v_activity.linked_workout_id IS NOT NULL THEN
    IF v_activity.linked_workout_source = 'club' THEN
      DELETE FROM public.club_user_workouts
      WHERE id = v_activity.linked_workout_id AND user_id = auth.uid()
        AND completed_at IS NULL;
    ELSE
      DELETE FROM public.user_workouts
      WHERE id = v_activity.linked_workout_id AND user_id = auth.uid()
        AND completed_at IS NULL;
    END IF;
  END IF;

  UPDATE public.wearable_activities
  SET status = 'dismissed', linked_workout_id = NULL,
      linked_workout_source = NULL, updated_at = now()
  WHERE id = p_activity_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.prepare_wearable_workout(UUID, UUID, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_wearable_activity(UUID)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.dismiss_wearable_activity(UUID)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.notify_wearable_activity_detected()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, bldr_club
AS $$
BEGIN
  INSERT INTO bldr_club.notifications (
    user_id, title, message, type, action_type, action_data
  ) VALUES (
    NEW.user_id,
    'Treino detectado pela WHOOP',
    'Encontramos uma atividade concluída. Confirme para atualizar seu treino, XP e sequência.',
    'wearable',
    'wearable_workout_detected',
    jsonb_build_object('activity_id', NEW.id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS wearable_activity_detected_notification
  ON public.wearable_activities;
CREATE TRIGGER wearable_activity_detected_notification
AFTER INSERT ON public.wearable_activities
FOR EACH ROW WHEN (NEW.status = 'pending')
EXECUTE FUNCTION public.notify_wearable_activity_detected();

-- Antes de aplicar, revisar especialmente:
-- 1. bldr_club.notifications/action_type/action_data já existem (migration 11).
-- 2. schemas reais de user_workouts e club_user_workouts coincidem com a Fase 2.
-- 3. O pipeline atual (complete_workout_with_analytics + transição de
--    is_completed) continua responsável por analytics, XP e eventos após
--    prepare_wearable_workout.
