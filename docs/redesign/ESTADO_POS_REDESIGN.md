# BLDR — Estado pós-redesign

Retrato do código nesta data, depois das sessões de redesign visual (Dashboard,
Treinos, Nutrição, Perfil, Configurações, Progresso, Meu Plano) e da correção do
bug B4 (metas nutricionais divergentes). Documento **descritivo**: nenhuma
correção é proposta aqui, nenhum arquivo de UI foi alterado para produzi-lo.

Método: leitura direta do código atual + 3 agentes de pesquisa em paralelo
cobrindo áreas não verificadas nesta sessão (telas do Club, busca de bugs de
divergência). Onde a fonte é o `INVENTARIO.md` (auditoria anterior, sem
reverificação porque a área não foi tocada), isso está indicado explicitamente.

---

## 1. Auditoria por tela — itens [V] do REDESIGN_SPEC.md

Legenda: **APLICADO** (código atual reflete a mudança) · **PARCIAL** ·
**NÃO APLICADO** (continua no estado antigo).

### Global (G1–G10)

Infra criada: `lib/theme/bldr_tokens.dart` e `lib/design_system/bldr_components.dart`
existem. Usados por: Dashboard, Treinos, Treino ativo, Nutrição (+ fluxo de
adicionar alimento), Perfil, Configurações, Progresso (4 abas), Meu Plano.
**Não usados** por nenhuma tela do BLDR Club (Hub, Treinos, Esportes, Round
Timer, Match Tracker, Protocolo, Comunidade, Competição) — confirmado por grep
sem nenhum resultado nesses 8 arquivos.

| Item | Status | Evidência |
|---|---|---|
| G1 Fundo `#050505` + glow dourado | APLICADO nas telas migradas · NÃO APLICADO no Club | `dashboard.dart:441` usa `BldrBackground`; `bldr_club_screen.dart:570-592` ainda usa `_GoldRadialBackground`/`_RadialBlob` privados com `Color(0xFFD4AF37)` |
| G2 Cards glass | APLICADO nas telas migradas · NÃO APLICADO no Club | `esportes_screen.dart:609` `color: const Color(0xFF1A1A1A)` sólido; `club_workout_screen.dart:2724` `color: _card` sólido |
| G3 Borda ou fundo, nunca os dois | mesmo padrão acima | `esportes_screen.dart:609-613` combina fundo sólido + borda |
| G4 Eliminar cores fora da paleta | NÃO APLICADO no Club | `competition_hub_screen.dart:18` `static const blue = Colors.cyanAccent`; `comunidade_screen.dart:1587` `Color(0xFF25D366)` (verde WhatsApp); `competition_hub_screen.dart:49-51` red/orange/cyan por modo |
| G5–G6 Tab bar glass / isolation | não avaliado (infra de navegação, fora do escopo de arquivo de tela) |
| G7 Peso máx. 600 | NÃO APLICADO no Club | `FontWeight.bold`/`w700`/`w900` onipresentes, ex. `club_workout_screen.dart:657`, `round_timer_screen.dart:332` |
| G8 Sentence case | PARCIAL | `competition_hub_screen.dart:71` `"CENTRAL DE OPERAÇÕES"`; `esportes_screen.dart:647` `"ACESSAR"` |
| G9 "Inicar Treino"→"Iniciar treino" | PARCIAL | `club_workout_screen.dart:656` ainda `'Iniciar Treino'` (Title Case; grafia já correta) |
| G10 Nome curto + subtítulo | NÃO APLICADO no Club | `club_workout_screen.dart` `_PersonalWorkoutTile` (~:2786) concatena tipo+minutos numa linha só |

### Dashboard (D1–D9)

Redesenhado (fonte: `dashboard.dart`, comentários inline citam os itens
diretamente).

| Item | Status | Evidência |
|---|---|---|
| D1 Header compacto | APLICADO | `dashboard.dart:463` `GreetingHeaderWidget` |
| D2 Faixa Nível/XP | APLICADO | `dashboard.dart:466` `LevelXpStripWidget` |
| D3 Chips roláveis | APLICADO | `dashboard.dart:471` `TodayMetricsWidget` |
| D4 Hero "Treino de hoje" | APLICADO | `dashboard.dart:476` `ActiveWorkoutCardWidget` |
| D5 Grid 2×2 | PARCIAL | grid existe (`dashboard.dart:481-534`), mas o 4º slot é `ConsistencyHeatmapWidget`, não o gráfico de 7 dias que D5/D7 pedem — ver D7 |
| D6 Macros em 3 linhas | APLICADO | dentro de `NutritionProgressWidget` variant `macros` |
| D7 Gráfico últimos 7 dias | [F] — NÃO EXISTE | slot ocupado por heatmap de consistência, não por gráfico de volume/duração |
| D8 Remover cards grandes de Consistência/Conquistas | APLICADO | comentário `dashboard.dart:535-537` confirma remoção, dado migrou para grid |
| D9 Card Parceiros oculto sem dado | APLICADO | comentário `dashboard.dart:541-543`, `PartnershipWidget` auto-oculta |

### Treinos (T1–T9) e Meu Plano (P1–P5 / CP1)

`workouts_screen.dart` e `active_workout_screen.dart` foram redesenhados em
tarefa anterior desta sessão (bottom sheet de detalhe do exercício, tela de
treino ativo, faixa flutuante de descanso) — não reverificado item a item nesta
rodada por já ter sido validado com `dart analyze`/testes na própria tarefa.

`weekly_plan_screen.dart` (Meu Plano — **mesmo arquivo** usado por Club → Meu
Plano):

| Item | Status | Evidência |
|---|---|---|
| P1 Remover "Perdido" → "Não feito" neutro | APLICADO | `:445` `'Treino não feito'`; `:1010` `BldrBadge(label: 'Não feito', gold: false)`; `:1028` `Opacity(0.6)` |
| P2 Barra segmentada só dourado | APLICADO | comentário `:871-872` confirma |
| P3 Timeline vertical | APLICADO | `:910` `BldrTimelineItem` |
| P4 Próximo treino em destaque | APLICADO | `:943-958`, `goldTintStrong` + botão "Ver treino" |
| P5 Descanso tracejado + ícone de sono | APLICADO | `:1031-1051` `BldrDashedContainer` + `Icons.bedtime_outlined` |
| CP1 Mesma estrutura de timeline | APLICADO | mesmo arquivo compartilhado |
| CP2–CP5 | [F] — não avaliado nesta parte |

### Nutrição (N1–N9) + Adicionar alimento (N10–N16) + Formulário manual (N17–N21)

Redesenhado em tarefas anteriores desta sessão (`nutrition_screen.dart`,
`daily_nutrition_overview_widget.dart`, `meal_timeline_widget.dart`,
`water_intake_widget.dart`, `food_categories_modal.dart`,
`firebase_add_food_modal_widget.dart`) — todos os itens [V] foram implementados
e validados na própria tarefa (`AskUserQuestion` + `dart analyze`/testes).
Confirmado nesta auditoria: N10 (`food_categories_modal.dart:88`,
`'Adicionar em: ...'`).

**Ganho adicional não creditado no SPEC:** F5 (`BACKLOG_FUNCIONAL.md`, resumo de
alimentos na linha da refeição, marcado [F]) **já foi resolvido** —
`_mealSummary()` em `meal_timeline_widget.dart:82-91` monta
`'Ovos, aveia · 430 kcal'` exatamente como pedido, substituindo o antigo
"Nenhum alimento" fixo quando há itens.

### BLDR Club — Hub, Treinos, Esportes, Round Timer, Match Tracker, Protocolo, Comunidade, Competição

**Nenhuma dessas 8 telas foi tocada pelo redesign.** Nenhuma importa
`bldr_tokens.dart`/`bldr_components.dart`. Onde a estrutura por acaso já bate
com o mockup (CT6 carrossel de Cardio/Yoga, CE4 estrutura de chips+campo+CTA,
CM3 toggle Iniciar/Pausar/Finalizar, CC3 card de posição com XP), é coincidência
pré-existente — continuam com paletas privadas (`Color(0xFFD4AF37)`, `_gold`,
`_card`) e peso de fonte acima de 600, violando G4/G7 mesmo nesses casos.

| Tela | Itens NÃO APLICADOS (destaque) | Itens APLICADOS/PARCIAL (coincidência estrutural) |
|---|---|---|
| Hub (C1–C5) | C2 (nível+ranking no mesmo card), C4 (squad sem corte) | C1 parcial (glow existe, duplicado, não é `BldrBackground`), C3 parcial (grid 2×2 existe, ícone centralizado não alinhado à esquerda) |
| Treinos (CT1–CT7) | CT2 (legenda), CT3 (stats em linha única), CT5 (botão outline), CT7 (badges com blur) | CT6 aplicado (carrosséis já existiam) |
| Esportes (CE1–CE5) | CE2 (carrossel de protocolos — hoje é lista vertical), CE3 (botão "ACESSAR" continua) | CE4 estrutural |
| Round Timer (CR1–CR5) | CR1 (anel de progresso), CR3 (sheet de ajuste), CR4 (badge solto) | CR2 parcial, CR5 parcial (falta modalidade por sessão) |
| Match Tracker (CM1–CM5) | CM1 (blocos com tint), CM2 (cronômetro no cabeçalho) | CM3 aplicado |
| Protocolo (CX1–CX4) | CX1 (subtítulo de tradução), CX2 (itálico cinza ainda presente, `:286`) | — |
| Comunidade (CC1–CC5) | CC1 (verde WhatsApp mantido, `:1574-1618`), CC2 (troféu em vez de coroa, bronze em vez de "dourado fosco") | CC3 aplicado |
| Competição (CQ1–CQ5) | CQ1 (`Colors.cyanAccent` mantido, `:18`), CQ4 (sem seção explicando os 4 modos), CQ5 (`create_arena_screen.dart:23` default ainda `'survivor'`, aviso vermelho `:109`) | CQ2 aplicado |

### Perfil (PF1–PF9) e Configurações (S1–S9, tela nova)

Redesenhados nesta sessão. Confirmado nesta auditoria:
- PF1 (e-mail removido) — `profile_screen.dart` não renderiza e-mail na tela; migrou para `EditProfileDialog` (acessado via Configurações).
- PF7 (Duelos oculto sem dado) — `_buildDuelsCard()` comentário explícito `:1256-1257`, card só chamado quando `_duelWins + _duelLosses > 0`.
- PF8 (engrenagem → Configurações) — `profile_screen.dart:31` referencia `AppRoutes.settingsScreen`.
- S9 (versão no rodapé) — `settings_screen.dart:56-57,771-772`, `PackageInfo.fromPlatform()`.
- S2 (vermelho só em Excluir conta) — não reverificado nesta rodada, validado na tarefa original.

Todos os demais itens [V] (PF2–PF6, PF9, S1, S3, S4) foram implementados e
validados na tarefa original com `dart analyze`/testes; não reabertos aqui.

### Progresso — 4 abas (PG/PC/PT/PN)

Redesenhado nesta sessão. Confirmado nesta auditoria:
- PG5 e PT3 permanecem **intencionalmente não corrigidos** (comentários explícitos citando B2/B1 do `BACKLOG_FUNCIONAL.md` em `achievements_gallery_widget.dart:11-13` e `workout_progress_widget.dart:284-285`) — conforme instrução original de não resolver esses bugs nesta fase.
- PC1–PC7: todos aplicados, incluindo os itens [F] (ver seção 2 — PC5 evoluiu de grid para carrossel real com data, `_buildPhotoGallery()`/`BldrCarousel`).
- PN1–PN2 aplicados; PN3, PN4, PN5, PN7 implementados nesta sessão (ver seção 2); PN6 (card de dicas removido) sem substituto ainda — ver seção 2, F16.

---

## 2. Reclassificação dos itens [F] — BACKLOG_FUNCIONAL.md e HAVOK_SPEC.md

Baseline: `INVENTARIO.md` (auditoria anterior ao redesign). Reverificado contra
o código atual apenas onde a sessão de redesign tocou a área (nutrição,
progresso, perfil/configurações); os demais itens transcrevem a classificação
do `INVENTARIO.md` sem releitura, por estarem fora do escopo tocado.

### Backlog Funcional (F1–F21)

| # | Item | Status | Evidência |
|---|---|---|---|
| F1 | Ícone de atividade por dia [CT1, CP2] | PARCIAL (assimétrico) | `INVENTARIO.md` §2/F1 — existe só em `club_workout_screen.dart`, por heurística de string. Área não tocada. |
| F2 | XP e métrica por dia na timeline [CP3] | NÃO EXISTE | `INVENTARIO.md` §2/F2. Área não tocada. |
| F3 | Atividades extras na timeline [CP4, CP5] | PARCIAL | `INVENTARIO.md` §2/F3. Área não tocada. |
| F4 | Gráfico últimos 7 dias no Dashboard [D7] | PARCIAL | `INVENTARIO.md` §2/F4 — heatmap conta sessões, não volume/duração. Confirma D7 acima. |
| **F5** | Resumo de alimentos na linha da refeição [N8] | **JÁ EXISTE (resolvido nesta sessão)** | `meal_timeline_widget.dart:82-91`, `_mealSummary()`. Ver seção 1. |
| F6 | Feed com descrição real [CC4] | NÃO EXISTE | `INVENTARIO.md` §2/F6. Área não tocada. |
| F7 | Reação com estado persistido [CC5] | PARCIAL | `INVENTARIO.md` §2/F7. Área não tocada. |
| F8 | Checklist de exercício no protocolo [CX3, CX4] | NÃO EXISTE | `INVENTARIO.md` §2/F8. Área não tocada. |
| F9 | Ranking interno do squad [CQ3] | PARCIAL | `INVENTARIO.md` §2/F9. Área não tocada. |
| F10 | Próxima conquista com critério [PF6] | PARCIAL | `INVENTARIO.md` §2/F10. Área não tocada. |
| **F11** | Configurações → Metas [S5] | **PARCIAL — edição continua NÃO EXISTINDO** | `settings_screen.dart:670-676` linha "Metas" desabilitada, badge "Em breve", comentário explícito de que não há tela de edição. `profile_screen.dart:886` tem `_showMeasurementsDialog()` mas **não é chamado de lugar nenhum** — código morto/inacessível. A correção do bug B4 criou `NutritionGoalsRepository`, mas só com `getGoals()` — **sem método de escrita**. Leitura correta ≠ F11 resolvido. |
| F12 | Configurações → Integrações [S6] | PARCIAL, agora com placeholder visível | `settings_screen.dart:711-717` linha desabilitada "Em breve". Nenhuma integração navegável. |
| F13 | Configurações → Privacidade [S7] | NÃO EXISTE, placeholder visível | `settings_screen.dart:719-725` "Em breve". |
| F14 | Central de ajuda e Termos [S8] | NÃO ENCONTRADO, placeholder visível | `settings_screen.dart:732-744` "Em breve". |
| **F15** | Progresso → Corpo [PC4–PC7] | **JÁ EXISTE (completo)** | PC4 `_buildProgressSummary()` + `LineChart`; PC7 `_buildRecentMeasurements()` em grupo com divisórias; **PC5 evoluiu de grid para carrossel real** (`BldrCarousel`, `photo_progress_widget.dart:490-502`); PC6 `_buildCompareFrame()` mantido. Sem gaps remanescentes. |
| **F16** | Progresso → Nutrição [PN3–PN7] | **PARCIAL, quase completo** | PN3 `_buildCalorieChart()`; **PN4 (média de macros) agora existe** — `_buildMacroAverages()`; **PN5 (evolução do IQD) agora existe** — `_buildIqdChart()`; PN7 `_buildRecentMeals()` mantido. **PN6**: card de dicas genéricas foi removido, mas o insight real que deveria substituí-lo **ainda não existe** (comentário explícito no código, `nutrition_analytics_widget.dart:208`) — único gap restante de F16. |
| F17 | IQD em tempo real no formulário manual [N22] | PARCIAL | `INVENTARIO.md` §2/F17 — `IqdCalculatorService.calculate()` já é trivial de plugar; falta o rodapé fixo e o wiring. Não reaberto nesta sessão. |
| F18 | Histórico de sets/partidas no Match Tracker [CM4, CM5] | PARCIAL | `INVENTARIO.md` §2/F18. Área não tocada. |
| F19 | BLDR Run — stats inline [CE1] | PARCIAL | `INVENTARIO.md` §2/F19. Área não tocada. |
| F20 | Esportes — resumo semanal [CE5] | PARCIAL | `INVENTARIO.md` §2/F20. Área não tocada. |
| F21 | Operação da semana no hub [C5] | NÃO EXISTE | `INVENTARIO.md` §2/F21. Área não tocada. |

**Nota fora da lista F1–F21:** o `INVENTARIO.md` registrava "Configurações
(S1–S9) NÃO ENCONTRADA" como tela. Isso mudou — `settings_screen.dart` agora
existe, com grupos "Conta", "Plano e assinatura", "Treino", "Aplicativo",
"Suporte" e "Sair/Excluir conta". A tela existe; S5–S8 continuam como linhas
desabilitadas "Em breve".

### HAVOK — Bloqueadores (§9) e dívidas (§10)

Não reverificado nesta sessão (área não tocada); transcrito do `INVENTARIO.md`
§2b, que já havia confirmado tudo verbatim contra o código em 01/08:

| # | Item | Ainda é verdade? | Evidência |
|---|---|---|---|
| 1 | Paywall real | SIM, verbatim | `panther_fab.dart:17` — `isPremiumUser = true` hardcoded, upsell comentado. |
| 2 | Rate limit por plano | SIM | Nenhuma checagem de cota nas 3 edge functions HAVOK. |
| 3 | Superfície de erro | SIM — 6 telas | `Failure.message` descartado via `print`/`catch (_)` em 6 arquivos. |
| 4 | Migrações versionadas | SIM | Tabelas HAVOK e `bldr_club.*` sem migration versionada. |
| 5 | Testes | SIM | Nenhum teste cobre HAVOK. |
| — | `havok_hub.dart:42` usa `UserService.instance` na presentation | SIM | Viola regra 1 do `CLAUDE.md`. |
| — | `GenerateHavokWorkout` descarta o treino gerado | SIM | `havok_repository_impl.dart:57-58`. |
| — | Parsing frágil (`repeticoes` como `String`) | SIM | `workout_detail_screen.dart:32`. |
| — | JSON sem contrato forte | SIM | Nenhuma das 3 functions Gemini usa `responseMimeType`/schema. |
| — | `gerar-plano-performance` em `UserService` | SIM | `user_service.dart:235`. |
| — | Cores do HAVOK fora de `BldrColors` | SIM | 6 arquivos importam `goldColor` etc. de `havok_hub.dart`. |

Cadeia de execução (§8.1 do HAVOK_SPEC): 3 dos 4 elos já reaproveitáveis de
`features/workouts/`; falta só o conversor `payload HAVOK → WorkoutTemplate`.
Não reverificado — fora do escopo tocado.

---

## 3. Bugs de divergência no padrão B4 — busca ativa

**Esta é a seção mais importante do relatório.** Busca por outros casos de
"mesmo dado, múltiplos caminhos de leitura independentes", mesmo onde hoje
ainda não gera um número visivelmente errado.

**Causa raiz comum a quase todos os achados abaixo:** o use case
`GetWorkoutHistory` (`workout_usecases.dart:138-149`) é tratado por vários
consumidores como "o histórico completo de treinos do usuário", mas sua
implementação (`WorkoutService.getUserWorkouts`, `workout_service.dart:438-461`)
só busca a tabela `user_workouts` — **nunca `club_user_workouts`**. Alguns
widgets sabem disso e fazem merge manual com `GetClubWorkoutHistory`; outros
não. Não existe hoje um único ponto de domínio ("histórico de treinos
consolidado, incluindo clube") — cada tela decide por conta própria se lembra
de fazer o merge. É estrutural o mesmo padrão do bug B4 (uma leitura "certa por
acidente" convivendo com leituras incompletas) e do bug B1 já documentado
(`progress_service.dart` esquecendo `club_user_workouts` num cálculo).

### 3.1 Streak (dias consecutivos) — 4 implementações, 3 incompletas

| Local | Fonte | Inclui `club_user_workouts`? |
|---|---|---|
| `profile_screen.dart:244-257` (Perfil) | soma `user_workouts` + `club_user_workouts` | Sim |
| `today_metrics_widget.dart:99-124` (Dashboard, chip "Streak") | `GetWorkoutHistory` → `WorkoutService.getUserWorkouts` | **Não** |
| `progress_overview_widget.dart:72-116` (Progresso → Visão Geral) | mesmo `GetWorkoutHistory` | **Não** |
| `progress_service.dart:443-524` (`getWorkoutStreak`) | mesma limitação; hoje sem chamadores ativos (código morto/latente) | **Não** |

**Já visível hoje:** sim, para qualquer usuário que treina via clube — o chip
"Streak" do Dashboard e o card "Resumo do progresso" em Progresso podem mostrar
um valor menor que o Perfil para o mesmo usuário no mesmo dia.

### 3.2 Heatmap de consistência — Dashboard incompleto vs. Progresso completo

`consistency_heatmap_widget.dart:39-58` (Dashboard) usa só `GetWorkoutHistory`.
`workout_progress_widget.dart:47-64` (Progresso) usa `GetWorkoutHistory` **+**
`GetClubWorkoutHistory` e mescla as duas listas antes de gerar o heatmap.
**Já visível hoje:** sim — os dois heatmaps (mesmo conceito: "dias com treino")
mostram padrões diferentes para usuários de clube. O próprio
`workout_progress_widget.dart` já sabe fazer o merge certo — a divergência não é
falta de conhecimento do padrão, é ausência de uma camada de domínio única.

### 3.3 Card "Semana atual" (Treinos) — marca dia como "perdido" indevidamente

`current_week_card_widget.dart:126-140` consulta
`Supabase.instance.client.from('user_workouts')` **diretamente** (sem use case,
sem `club_user_workouts`) para decidir o status (`done`/`lost`/`today`/`pending`)
de cada dia da semana. **Já visível hoje:** sim — um usuário que cumpriu o dia
com um treino de clube pode ver esse dia marcado como `_DayStatus.lost` mesmo
tendo treinado. É o mesmo padrão do B1, com efeito de UX mais grave: não é só um
número errado, é um rótulo ("perdido") que pode desmotivar sem motivo.

### 3.4 Total de treinos / conquistas / peso — terceira fonte em Progresso → Visão Geral

`UserService.getUserStatistics` (`user_service.dart:68-121`), consumido só por
`progress_overview_widget.dart:47-49`:
- `total_workouts` (`:71-75`) — só `user_workouts`, sem `club_user_workouts`. **Divergente hoje** de Perfil (`profile_screen.dart:234`, soma as duas) e Dashboard (`today_metrics_widget.dart:68-84`, soma as duas).
- `achievements` (`:86-90`) — query própria e paralela ao use case `GetUserAchievements` usado em outros lugares. Coincide numericamente hoje (mesma tabela, mesmo filtro), mas é duplicação frágil — risco silencioso, não erro visível ainda.
- `current_weight` (`:93-104`) — lê `user_measurements` direto, em paralelo ao que `progress_service.dart` já expõe para outros widgets de Progresso. Uso na tela não confirmado.

### 3.5 Nível do usuário — `current_level` do banco vs. recalculado a partir do XP

`bldr_club_screen.dart:139-149,232-238` **deliberadamente não confia** em
`current_level`: comentário explícito no código — *"Calcula o nível a partir do
XP total — fonte única de verdade para a UI. Evita depender de `current_level`
do banco, que pode chegar defasado quando o trigger do Supabase ainda não
rodou."* `level_xp_strip_widget.dart:18-22,71-83` (Dashboard) e
`profile_screen.dart:170-201` (Perfil) usam `current_level` bruto do banco,
**sem recalcular**. A curva de thresholds (`{1:0, 2:1000, 3:2500, 4:5000,
5:10000}`) está copiada em pelo menos 2 arquivos — o próprio
`level_xp_strip_widget.dart` documenta isso como "DUPLICAÇÃO CONHECIDA". Bug já
identificado pelo time e corrigido em 1 de 3 lugares; não confirmado se causa
divergência visível hoje (depende da velocidade do trigger em produção), mas o
cenário de risco já está documentado no próprio código-fonte.

### 3.6 Critério do popup de review — mesmo bug de fonte, vaza para lógica de produto

`dashboard.dart:98-141` (`_checkReviewCriteria`) usa `GetWorkoutHistory` (só
`user_workouts`) para decidir quando mostrar o popup de avaliação da loja
("3+ treinos", "streak de 5 dias", "7 dias distintos de uso"). Usuários
engajados via clube podem nunca atingir o critério e nunca ver o popup — efeito
colateral silencioso, sem número errado em tela, mas com impacto real de
produto.

**Resumo por gravidade:** 3.3 (rótulo "perdido" indevido, pior UX) > 3.1 e 3.2
(números visivelmente diferentes entre telas hoje) > 3.4 (total de treinos
divergente hoje; achievements/peso são duplicação silenciosa) > 3.5 (já
mitigado em 1 de 3 lugares, risco documentado pelo próprio time) > 3.6 (sem
número errado, mas afeta lógica de produto).

---

## 4. HAVOK_SPEC.md §9/§10 — o que mudou desde o INVENTARIO.md

Nada. Nenhuma área do HAVOK foi tocada por qualquer tarefa desta sessão. Os 5
bloqueadores de §9 e as 6 dívidas de §10 seguem idênticos ao que o
`INVENTARIO.md` §2b registrou (ver tabela na seção 2 acima). O único fato novo
é indireto: com `NutritionGoals`/`GetNutritionGoals` agora existindo como
padrão de referência (entidade + repositório + use case único para um dado que
antes vazava por 3 caminhos), esse é o modelo a seguir quando o HAVOK precisar
ler contexto do usuário (§2 do HAVOK_SPEC: "Contexto disponível" inclui
`onboarding_data`, histórico de treinos, diário nutricional — as mesmas fontes
que hoje têm caminhos duplicados documentados na seção 3 deste relatório).

---

## 5. Bugs novos notados durante a auditoria, ainda não documentados em lugar nenhum

- **Seção 3.1–3.4 inteira** (streak, heatmap, card "Semana atual", total de
  treinos em Progresso→Visão Geral) — nenhum desses está no `BACKLOG_FUNCIONAL.md`
  hoje. B1 documenta *só* a duração média zerada; o mesmo bug de fonte
  (esquecer `club_user_workouts`) se repete em pelo menos mais 4 lugares
  independentes que a auditoria original não havia mapeado.
- **`profile_screen.dart:886` (`_showMeasurementsDialog`) é código morto/inacessível** —
  existe uma tela de edição de peso/altura já implementada, mas nenhum botão ou
  rota chama esse método. É trabalho pronto e não aproveitado — relevante para
  quando F11 (Configurações → Metas) for endereçado.
- **Divergência de nível (`current_level` vs. XP recalculado, seção 3.5)** —
  já é conhecida pelo próprio time (comentário no código), mas não está
  registrada em nenhum documento do redesign (`BACKLOG_FUNCIONAL.md` nem
  `INVENTARIO.md` a mencionam). Vale registrar formalmente em algum lugar,
  dado que já foi corrigida pela metade.
- **G4 violado nas telas do Club de forma mais grave do que "cor fora da
  paleta"**: `competition_hub_screen.dart` usa cor (ciano/vermelho/laranja)
  como *codificação de significado* por modo de jogo — remover a cor sem
  repor a distinção por ícone/texto (regra de acessibilidade §11 do
  `DESIGN_SYSTEM.md`) vai exigir mais que uma troca de token quando essas
  telas entrarem no escopo do redesign.
- **CQ5 (aviso do modo Survivor) usa tom de alerta vermelho com ícone de
  alerta** (`create_arena_screen.dart:109`, `Colors.redAccent`) — o mesmo
  padrão que G8/N4/escrita do `DESIGN_SYSTEM.md` já eliminou em outras telas
  (tom neutro para estados não-positivos). Não é regressão, é uma tela que
  nunca foi tocada, mas fica destoante ao lado das telas já neutralizadas.
