-- PROPOSTA REVISÁVEL — eventos in-app + push FCM da Comunidade.
-- NÃO APLICAR AUTOMATICAMENTE.
-- Reutiliza bldr_club.notifications e o webhook/Edge Function
-- bldr-club-notifier. Confirmar que o webhook está ativo antes da aplicação.

CREATE TABLE public.community_notification_events (
  event_key TEXT PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.community_notification_events ENABLE ROW LEVEL SECURITY;
-- Sem policies: somente funções SECURITY DEFINER escrevem nesta tabela.

CREATE OR REPLACE FUNCTION public.enqueue_community_notification(
  p_event_key TEXT, p_user_id UUID, p_title TEXT, p_message TEXT,
  p_action_type TEXT, p_action_data JSONB
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, bldr_club AS $$
BEGIN
  IF p_user_id IS NULL OR p_user_id = auth.uid() THEN RETURN; END IF;
  INSERT INTO public.community_notification_events(event_key)
  VALUES (p_event_key) ON CONFLICT DO NOTHING;
  IF NOT FOUND THEN RETURN; END IF;
  INSERT INTO bldr_club.notifications
    (user_id, title, message, type, action_type, action_data)
  VALUES
    (p_user_id, p_title, p_message, 'community', p_action_type, p_action_data);
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_community_follow()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, bldr_club AS $$
BEGIN
  PERFORM public.enqueue_community_notification(
    'follow:' || NEW.follower_id || ':' || NEW.followed_id,
    NEW.followed_id, 'Novo seguidor', 'Um atleta começou a seguir você.',
    'community_profile', jsonb_build_object('user_id', NEW.follower_id)
  );
  RETURN NEW;
END;
$$;
CREATE TRIGGER community_follow_notification
AFTER INSERT ON public.community_follows FOR EACH ROW
EXECUTE FUNCTION public.notify_community_follow();

CREATE OR REPLACE FUNCTION public.notify_community_reaction()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, bldr_club AS $$
DECLARE owner_id UUID;
BEGIN
  SELECT user_id INTO owner_id FROM public.community_feed WHERE id = NEW.feed_id;
  PERFORM public.enqueue_community_notification(
    'reaction:' || NEW.user_id || ':' || NEW.feed_id,
    owner_id, 'Nova reação', 'Seu post recebeu uma reação.',
    'community_post', jsonb_build_object('feed_id', NEW.feed_id)
  );
  RETURN NEW;
END;
$$;
CREATE TRIGGER community_reaction_notification
AFTER INSERT ON public.community_reactions FOR EACH ROW
EXECUTE FUNCTION public.notify_community_reaction();

CREATE OR REPLACE FUNCTION public.notify_community_comment()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, bldr_club AS $$
DECLARE target_id UUID;
BEGIN
  IF NEW.parent_id IS NULL THEN
    SELECT user_id INTO target_id FROM public.community_feed WHERE id = NEW.feed_id;
  ELSE
    SELECT user_id INTO target_id FROM public.community_comments WHERE id = NEW.parent_id;
  END IF;
  PERFORM public.enqueue_community_notification(
    'comment:' || NEW.id, target_id,
    CASE WHEN NEW.parent_id IS NULL THEN 'Novo comentário' ELSE 'Nova resposta' END,
    CASE WHEN NEW.parent_id IS NULL THEN 'Seu post recebeu um comentário.' ELSE 'Responderam ao seu comentário.' END,
    'community_post', jsonb_build_object('feed_id', NEW.feed_id, 'comment_id', NEW.id)
  );
  RETURN NEW;
END;
$$;
CREATE TRIGGER community_comment_notification
AFTER INSERT ON public.community_comments FOR EACH ROW
EXECUTE FUNCTION public.notify_community_comment();

-- Validar: webhook, FCM token, foreground/background, deep link, retries e
-- dois usuários authenticated. Não registrar tokens ou credenciais em logs.
