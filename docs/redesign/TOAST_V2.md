# Toast & Feedback v2 — Auditoria e plano

> Auditoria **somente leitura** (2026-11-19). Nenhum código foi alterado.
> Fontes: Figma `i7tNK50cQOCmGJkVQvjLoN`, canvas `53:184`, e o documento
> `BLDR_Toast_System_v1.0.md` ([APROVADO]: textos ilustrativos, política híbrida
> Compact/Expanded, topo central abaixo da safe area, um por vez com fila,
> Level Up fora do sistema).
>
> **T0 concluída:** todos os símbolos vigentes foram lidos por
> `get_design_context`. Medidas no §1.1; tokens em `BldrToastColorsV2`,
> `BldrToastTextV2` e `BldrToastV2` (`lib/theme/bldr_tokens.dart`).

## 1. Biblioteca do Figma (símbolos vigentes)

| Grupo | Símbolos |
|---|---|
| Bases | 54:4 Compact, 54:7 Expanded |
| Status | 55:8 Success, 55:13 Info, 55:18 Warning, 55:23 Error, 60:3 Warning expanded, 60:10 Error expanded |
| Ação | 58:23 Undo |
| Gamificação | 58:29 / 59:3 Achievement (compact/expanded), 65:3 / 67:3 Goal, 65:9 / 65:13 Challenge |
| Social | 62:3 / 62:9 Squads, 62:18 DM, 62:24 DM Quick Reply |
| Sistema | 64:3 Offline, 64:9 Workout/Session |
| HAVOK | 57:262 pílula, 57:261 card |

Ocultos/excluídos: 54:11, 55:28, 61:3 e 61:9 (Social legado).

### 1.1 Especificação (T0)

- **Superfície:** fundo `#000000`, borda de 1 px na cor da variante. Compact:
  altura 45, raio 27, largura do conteúdo (186–310). Expanded: largura 360,
  raio 26, altura conforme o conteúdo (92 base, 116 status/achievement, 132 com
  duas ações, 164 Goal com barra, 188 DM).
- **Bordas:** success `#32BA00`, info `#83B9E6`, warning `#EDC200`, error
  `#B20000`; as demais variantes usam o dourado `#D4AF37`.
- **Texto:** compact 13/600 `#F4F4F5`. Expanded: título 14/600 (vai para o degrau
  15), descrição 12/500 `#A2A3AB`, ação 11/600 na cor da variante com "→",
  ação secundária 11/600 `#A2A3AB`.
- **Ícones Tabler 24:** checks (success), info-circle, alert-triangle,
  alert-circle (error), arrow-back-up (undo), trophy, target-arrow (goal),
  swords (challenge), users (squads), message-circle (DM), wifi-off, stopwatch.
  Chevron 20 (down no compact expansível, up no expanded).
- **Undo (58:23):** ícone, mensagem e "Desfazer" em dourado à direita.
- **Goal expandido (67:3):** rótulo e valor do progresso (11), barra de 4 px com
  trilho `#1E1E1E` e gradiente dourado.
- **HAVOK (57:262/57:261):** fundo `#050505`, textos de 8,7 e 11,3 px (sobem para
  11 e 12 na escala). Fica fora desta rodada (T6).

## 2. Inventário atual

**SnackBars: 186 chamadas de `showSnackBar`**, distribuídas em arquivos por módulo:

| Módulo | Arquivos |
|---|---|
| features/club | 23 |
| features/workouts | 7 |
| features/professional_portal | 7 |
| features/auth | 6 |
| shared | 5 |
| features/profile | 5 |
| features/nutrition | 5 |
| features/community | 5 |
| features/progress | 4 |
| features/subscription | 1 |
| features/integrations | 1 |

Gerar a lista exata de arquivos (o "plano de varredura") com:
`grep -rln "showSnackBar\|SnackBar(" lib | sort`.

**Overlays, banners e toasts:**
- `MaterialBanner`, `OverlayEntry` manual e `Flushbar`: **nenhum uso**.
- `fluttertoast` está no pubspec, mas **sem uso** (candidato a remoção).
- `features/achievements/presentation/achievements/achievement_overlay.dart` +
  `widgets/achievement_toast.dart`: **já é um overlay global com fila**,
  acima do Navigator, usando `appNavigatorKey`. É a base natural do Toast System.
- `features/club/.../widgets/level_up_modal.dart`: modal, fica fora do sistema ([APROVADO]).
- `widgets/notification_permission_modal.dart` e `PopupService`: popup de
  permissão de notificação. Não é toast.
- HAVOK: `shared/presentation/dashboard/widgets/havok_insight_widget.dart` é um
  card inline na Home (dispensa diária via SharedPreferences), não um toast.
  `havok_sheet.dart` e `havok_action_controller.dart` ficam no Club.

**Infraestrutura:**
- `appNavigatorKey` global em `main.dart` (linhas 149 e 365).
  Não existe `scaffoldMessengerKey` global.
- **Conectividade:** `connectivity_plus ^7` está no pubspec e é reexportado em
  `core/app_export.dart`, mas **não há listener**. (`watch_connectivity` é do
  Apple Watch e não se aplica.)
- **DM:** **não existe**. O único chat é o do squad/arena
  (`squad_chat_screen.dart`, via `ArenaRepository.sendChatMessage`, sem stream
  realtime confirmado e sem quick reply).
- **Tokens/componentes:** não há tokens de toast em `bldr_tokens.dart`. Os
  tokens v2 de cor e superfície, `BldrTextV2` e Tabler Icons já existem e servem.

## 3. Matriz de eventos

Legenda: **Pronto** (o evento existe e já dispara feedback) · **Parcial** (o evento
existe, o feedback é um SnackBar comum ou falta dado) · **Inexistente** ·
**Backend**.

| Módulo | Evento | Variante | Situação | Origem hoje |
|---|---|---|---|---|
| Nutrição | meal.added | Success | Parcial | `nutrition_screen` (SnackBar) |
| Nutrição | meal.removed + Undo | Undo | Parcial | `DeleteMealEntry`; o Undo exige guardar o `MealEntry` e chamar `LogMeal` |
| Nutrição | save_failed | Error | Parcial | `Failure` de `Result` → SnackBar |
| Nutrição | hydration.goal_reached | Goal | Inexistente | Dá para derivar de `LogWater` + meta (sem backend) |
| Nutrição | protein.goal_reached | Goal | Inexistente | Derivável do resumo diário |
| Nutrição | targets.updated | Success | Parcial | `goals_screen` (SnackBar) |
| Conquistas | achievement.unlocked | Achievement | **Pronto** (visual antigo) | `AchievementOverlay` |
| Club | level_up | — | Fora do sistema | `level_up_modal` |
| Club/Arena | squad.message / squad.event | Squads | Parcial | Chat do squad sem realtime e sem push in-app |
| Social | dm.received / quick reply | DM | **Backend** | DM não existe |
| Desafios | challenge.progress / completed | Challenge | Parcial | Telas v2 de desafios (Fase 5), sem gatilho de evento |
| Treino | session.running / finished | Workout | Parcial | `active_workout_screen` |
| Sistema | offline / online | Connectivity | Inexistente | `connectivity_plus` instalado, sem listener |
| HAVOK | insight disponível | HAVOK | Parcial | Card inline na Home; falta a decisão de quando virar pílula |
| Geral | erros de `Failure` em telas | Error | Parcial | ~186 SnackBars |

## 4. Perguntas em aberto

| # | Pergunta |
|---|---|
| T-Q1 | Nutrição 102:307 mostra o sucesso **embaixo**; o sistema define o topo. Confirmar topo para tudo. |
| T-Q2 | O HAVOK em pílula/card substitui o `havok_insight_widget` inline da Home ou convive com ele? |
| T-Q3 | DM: está no roadmap? Sem DM, os símbolos 62:18/62:24 ficam reservados. |
| T-Q4 | Toasts com o app em background: só in-app (overlay) ou também push local? |
| T-Q5 | O `AchievementToast` atual migra para a variante Achievement (visual novo) na T1 ou depois? |
| T-Q6 | Remover `fluttertoast` do pubspec? |
| T-Q7 | Haptics por variante (success/error)? |

## 5. Plano incremental

| Fase | Conteúdo | Critério de aceite |
|---|---|---|
| **T0** | `get_design_context` de cada símbolo de 53:184; tokens v2 de toast em `bldr_tokens.dart` | Medidas e cores registradas; nenhum `Color(0x…)` em widget |
| **T1 Fundação** | `lib/core/toast/`: `ToastController` (fila, 1 por vez, prioridade, dedupe), host global evoluído do `AchievementOverlay` (sem segundo overlay), `BldrToast` Compact/Expanded, API `context.toast.success/info/warning/error/undo(...)`, swipe para dispensar, acessibilidade (`Semantics` liveRegion), textos nos `.arb`; testes de unidade da fila em `test/core/toast/` | Toast aparece acima de sheets e rotas, no topo abaixo da safe area; a fila respeita a ordem; o Undo executa o callback; render em 320, 440 e 320 com escala 1,3 |
| **T2 Conectividade** | Listener `connectivity_plus` em `core/` + repository; variante Offline persistente enquanto offline | Modo avião mostra Offline; ao voltar, some / mostra "Online" |
| **T3 Nutrição** | Eventos da matriz (junto com N2/N3 de `NUTRICAO_V2.md`) | Adicionar → Success; remover → Undo funcional; meta de água/proteína → Goal uma vez por dia |
| **T4 Gamificação** | Achievement/Goal/Challenge no visual novo; Level Up continua modal | Nenhuma regressão na fila de conquistas |
| **T5 Varredura** | Substituir os SnackBars por módulo, na ordem: nutrition → community → workouts → profile → progress → auth → club → professional_portal → resto. Um commit por módulo | `grep showSnackBar lib` diminui a cada commit; zero ao fim (ou exceções documentadas) |
| **T6 Social/HAVOK** | Squads (realtime), HAVOK pílula/card após T-Q2; DM após T-Q3 (Backend) | — |

### O que testar no aparelho
- Toast com sheet aberto, com teclado aberto e durante a navegação entre abas.
- Dois eventos seguidos: o segundo espera na fila.
- Notch / Dynamic Island: não fica sob a safe area; iPhone SE em 320 pt.
- Undo de remoção de alimento: o item volta com a mesma quantidade e o mesmo horário.
- Modo avião liga/desliga (T2).
- VoiceOver lê o toast.
- Dispensar com swipe para cima.
