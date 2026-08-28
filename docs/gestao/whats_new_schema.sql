-- Rodar no SQL Editor do Supabase de GESTÃO (não no BLDR)
-- Fonte de verdade das novidades exibidas no app

CREATE TABLE IF NOT EXISTS public.whats_new (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title          TEXT NOT NULL DEFAULT 'O que há de novo no BLDR',
  subtitle       TEXT,
  slides         JSONB NOT NULL DEFAULT '[]',
  active         BOOLEAN NOT NULL DEFAULT false,
  trigger_mode   TEXT NOT NULL DEFAULT 'flag'
                 CHECK (trigger_mode IN ('version','flag','both')),
  target_version TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_whats_new_active
  ON public.whats_new(active, trigger_mode);

-- Registro de exemplo (v2.1 — Agosto 2026)
-- Cada slide: { featured, tag, title, description, icon }
-- icon: nome do SF Symbol (iOS) / ícone mapeado no Flutter
INSERT INTO public.whats_new (
  title, subtitle, slides, active, trigger_mode, target_version
) VALUES (
  'O que há de novo no BLDR',
  'Versão 2.1 · Agosto 2026',
  '[
    {
      "featured": true,
      "tag": "✨ Destaque",
      "title": "HAVOK agora fala no seu idioma",
      "description": "O HAVOK responde em Português, English ou Italiano — conforme o idioma escolhido nas Configurações.",
      "icon": "sparkles"
    },
    {
      "featured": false,
      "tag": "Live Activity",
      "title": "Corrida na Dynamic Island",
      "description": "Distância, pace e FC aparecem na Dynamic Island e na tela de bloqueio enquanto você corre.",
      "icon": "figure.run"
    },
    {
      "featured": false,
      "tag": "Apple Health",
      "title": "FC e calorias sincronizados",
      "description": "Conecte o Apple Health nas Configurações para sincronizar FC em tempo real e exportar calorias.",
      "icon": "heart.fill"
    },
    {
      "featured": false,
      "tag": "Notificações",
      "title": "Push notifications ativas",
      "description": "Conquistas, streak em risco e operações da semana agora chegam como notificação.",
      "icon": "bell.fill"
    },
    {
      "featured": false,
      "tag": "Feedback",
      "title": "Canal direto com o BLDR",
      "description": "Reporte bugs e envie sugestões direto pelo app. Configurações → Falar com o BLDR.",
      "icon": "bubble.left.fill"
    }
  ]',
  true,
  'flag',
  null
);
