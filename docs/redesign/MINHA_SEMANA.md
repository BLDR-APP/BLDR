# Minha semana — levantamento v2 (WeeklyPlanScreen)

> Só planejamento. Nada implementado. Figma: arquivo Treinos
> (`guqp4TpJiiCKjhSgzqxSjg`). Tela atual:
> `lib/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart`
> (2.307 linhas).

## 1. Frames — [V] visual / [F] funcionalidade inexistente

| Frame | Node | Classificação | Origem do dado hoje |
|---|---|---|---|
| Planner (arraste direto) | `282:68` | [V] cards, cabeçalho, resumo, estados Hoje/Planejado/Livre · [F] setas de semana, arrastar | `GetWeeklyPlan` (`weekly_plan_days`) + `PlanDayTypeResolver` + `GetWeeklyPlanConfig` (`onboarding_data.rest_days/split_preference/workout_frequency_days`); grupos via `HomeV2Format.muscleGroups` do template; "concluído" via `GetWeekCompletedWorkouts` |
| Ações do dia | `285:141` | [V] sheet · [F] as 3 ações valendo só para a semana | Hoje o toque abre o picker que grava direto no plano recorrente |
| Trocar treino | `285:231` | [V] lista + "CONFIRMAR TROCA" · [F] se for só nesta semana | Lista: templates do usuário (`GetWorkoutTemplates`), como no picker atual |
| Mover para outro dia | `285:320` | [F] | Não existe; destinos "ocupado/livre" saem do mesmo resolver |
| Editar plano | `278:1487` | [V] chips da divisão + 7 dias treino/descanso + "Salvar alterações" | Já existe: `_showEditPlanSheet` → `SaveWeeklyPlanConfig` (split + `rest_days` + 7 `tipo`) |
| Registrar extra | `278:1600` | [V] modalidades, slider de duração, notas | Já existe: `LogExtraActivity` → `extra_activities`; enum `ActivityType` tem as 9 modalidades do mockup |
| Salvo + Desfazer | `291:76` | [F] | Não existe auto-save nem desfazer |

Observação: no mockup, "Domingo" ocupa largura inteira só porque é o 7º card
(grade 2 colunas, ímpar). Regra proposta: o último card ocupa a linha toda,
seja treino ou descanso.

## 2. Modelo de dados — ajuste por semana

O plano recorrente (`weekly_plan_days`, 1 linha por `dia_semana`) **não muda**.
Ajustes de uma semana específica ficam numa tabela nova:

```sql
-- supabase/migrations/2026111700xxxx_weekly_plan_overrides.sql (proposta, não criada)
CREATE TABLE public.weekly_plan_overrides (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start    DATE NOT NULL CHECK (EXTRACT(ISODOW FROM week_start) = 1), -- segunda
  dia_semana    SMALLINT NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
  tipo          TEXT NOT NULL CHECK (tipo IN ('treino','descanso')),
  template_id   UUID REFERENCES public.workout_templates(id) ON DELETE SET NULL,
  template_name TEXT,
  source        TEXT DEFAULT 'user',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, week_start, dia_semana)
);
-- RLS: as 4 policies auth.uid() = user_id, igual a weekly_plan_days.
```

- Uma linha = "nesta semana, este dia é X". Mover/trocar gera 1–2 linhas;
  desfazer = restaurar as linhas anteriores (ou apagá-las).
- **Domain:** entidade `PlanDayOverride`; `WeeklyPlanRepository` ganha
  `getOverrides(weekStart)`, `upsertOverrides(weekStart, List)`,
  `deleteOverrides(weekStart, dias)`. Use cases `GetWeekPlan(weekStart)`
  (combina recorrente + ajustes), `ApplyWeekAdjustment`, `UndoWeekAdjustment`.
- **Data:** datasource Supabase novo; nenhuma coluna alterada nas tabelas
  existentes.
- **FREE vs BLDR CLUB:** a tabela não depende do plano. A regra de acesso atual
  (`ResolveClubAccess` / upsell PRO da tela) continua valendo para o que já é
  restrito; ajustes da semana podem ser livres (decisão D5).
- **Planos do HAVOK:** o HAVOK grava em `weekly_plan_days` com
  `source='havok'` (`workout_detail_screen.dart`). Override copia `source`
  para manter o selo HAVOK no card. A edge function `gerar-resposta-havok` lê
  `weekly_plan_days`; para ela enxergar a semana real precisa passar a ler os
  ajustes também (mudança em `supabase/functions`, fora do app — D6).
- **Sessões de treino:** não mudam. Sessão concluída/em andamento é ligada à
  data, não ao plano; o card só lê o estado para proteger o dia (seção 4).

## 3. Resolução do dia

Ordem proposta em `PlanDayTypeResolver` (e `TodayWorkoutResolver`):

1. **Ajuste da semana** (`weekly_plan_overrides` com `week_start` da data)
2. Linha do plano recorrente (`weekly_plan_days.tipo`)
3. `rest_days`
4. Frequência

Implementação: o resolver recebe `overrides` opcional (lista vazia = comportamento
atual, testes existentes continuam válidos). O hub (`current_week_card_widget`,
card "Treino de hoje") e a Home (`active_workout_card_widget`) passam a chamar
`GetWeekPlan(semanaAtual)` em vez de `GetWeeklyPlan()` — um ponto só, mesma regra
nas três telas.

## 4. Regras de interação

**Arrastar (long-press no card, ícone ⠿):**
- treino → descanso: move; origem vira descanso.
- treino → treino: troca os dois.
- solto fora de um card / em destino inválido: volta ao lugar, sem salvar.
- dia **concluído** ou **em andamento**: não arrasta e não aceita drop (card
  com estado "Concluído" e sem ⠿).
- dias passados da semana atual: não aceitam drop (D3).

**Mover para outro dia (sheet `285:320`):** mesmas regras; destino ocupado
mostra "os treinos trocarão de posição".

**Transformar em descanso:** override `tipo='descanso'` só no dia; o template
não é apagado.

**Descanso → "＋ Adicionar treino":** abre a lista de "Trocar treino"; gera
override `tipo='treino'`.

**Auto-save:** cada ação grava na hora (otimista: a UI muda antes da resposta).
Snackbar "Semana atualizada · <descrição>" + "DESFAZER" por ~5 s.
- Desfazer: reaplica o estado anterior guardado em memória.
- Erro ao salvar: restaura o estado anterior na tela e mostra aviso
  ("Não foi possível salvar. Sua semana voltou ao estado anterior.").

## 5. O que já existe

- **"HAVOK decide":** é só um valor de `split_preference`
  ("Deixe a HAVOK decidir"). Na tela, gera o rótulo "HAVOK decide" e cai nos
  rótulos genéricos; **não gera plano nenhum**. Gerar o plano pelo HAVOK hoje
  só acontece no chat (`havok_sheet` → `workout_detail_screen`, por dia).
  → O chip pode ficar como está (só salva a preferência); um comportamento
  "HAVOK monta a semana" é [F].
- **"+50 XP" do extra:** existe. `LogExtraActivity` insere em
  `extra_activities` com `xp_earned = 50` fixo no repository, e insere um
  evento em `bldr_club.xp_events` (falha silenciosa). **Não chama
  `add_xp_to_user`**, diferente de `supabase_club_datasource` que faz as duas
  coisas → o extra provavelmente aparece no feed mas não soma no XP total do
  usuário. Confirmar no banco antes de prometer "+50 XP" no botão (D7).
- Modalidades: `ActivityType` já tem as 9 do mockup. Duração e notas já são
  aceitas pelo use case.

## 6. Decisões para o usuário

- **D1 — Escopo das ações.** Proposta: mover, transformar em descanso e
  adicionar treino valem **só nesta semana**; ao **trocar treino**, perguntar
  "Só nesta semana / Todas as semanas" (a segunda grava em `weekly_plan_days`).
  "Editar plano" sempre muda o recorrente.
- **D2 — Navegação.** Proposta: semanas passadas somente leitura; atual + até
  4 futuras editáveis.
- **D3 — Dias passados da semana atual:** somente leitura? (proposta: sim).
- **D4 — Dias sem `template_id`** (linhas só com nome, ex. planos antigos):
  mostrar ao menos `template_name`, sem grupos; tocar abre "Trocar treino".
  Hoje a tela ignora essas linhas e mostra "Treino".
- **D5 — FREE:** ajustes da semana liberados para todos ou só CLUB?
- **D6 — HAVOK:** atualizar a edge function para ler os ajustes (fica fora do
  app)?
- **D7 — XP do extra:** corrigir para `add_xp_to_user` (mudança em data/) ou
  esconder "+50 XP" até lá, como foi feito com o XP do hub.
- **D8 — "HAVOK decide":** manter só como preferência ou esconder o chip até
  existir geração automática.
- **D9 — Sheet "Ações do dia" em dia concluído:** mostrar só "Ver treino"?

## 7. Decisões tomadas (2026-11-17)

- **Escopo:** arrastar, mover e transformar em descanso valem só para a
  semana. Trocar treino **e** adicionar treino em dia livre perguntam
  "Só nesta semana / Todas as semanas". "Editar plano" altera o recorrente.
- **Navegação:** semanas passadas somente leitura; atual + até 4 futuras
  editáveis.
- **Dias sem `template_id`:** mostrar o `template_name`.
- **Acesso:** ajustes por semana são **exclusivos do BLDR CLUB**.
  - FREE e CLUB: ver a semana atual, Editar plano (recorrente), trocar
    treino em todas as semanas (comportamento atual do seletor) e Registrar
    extra.
  - Só CLUB: arrastar, mover e transformar em descanso só nesta semana, a
    opção "Só nesta semana" e a navegação entre semanas.
  - No FREE, as ações exclusivas aparecem com cadeado e abrem o
    `ClubPaywallSheet` atual (via `ResolveClubAccess`).
- **"+50 XP" do extra:** escondido até a correção do sistema de XP
  (BACKLOG_FUNCIONAL B10, que vem antes da implementação desta tela).
- **"HAVOK decide":** chip exibido desabilitado, com "Em breve".
- **Dias já passados da semana atual (D3):** somente leitura, como as
  semanas passadas.
- **Função do HAVOK no servidor (D6):** sim — `gerar-resposta-havok` passa a
  ler `weekly_plan_overrides` da semana, para enxergar a semana real. Entra
  no plano de implementação abaixo.
- **Dia concluído (D9):** sem mover, trocar ou descanso; tocar mostra o
  treino feito (ou o resumo, se esse caminho já existir).

## 8. Plano de implementação (ordem)

1. BACKLOG_FUNCIONAL B10 (XP unificado) — pré-requisito.
2. Migration `weekly_plan_overrides` + RLS (criada, aplicada pelo usuário).
3. Domain: `PlanDayOverride`, métodos no `WeeklyPlanRepository`, use cases
   `GetWeekPlan`, `ApplyWeekAdjustment`, `UndoWeekAdjustment`; resolver com
   ajustes como 1ª prioridade; testes com repository fake.
4. Data: datasource Supabase dos ajustes.
5. Edge function `gerar-resposta-havok`: ler os ajustes da semana junto com
   `weekly_plan_days`.
6. Hub (card da semana, Treino de hoje) e Home passam a usar `GetWeekPlan`.
7. Tela v2 (frames 282:68 … 291:76) com gating CLUB (cadeado + paywall).
