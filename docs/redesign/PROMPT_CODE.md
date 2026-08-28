# BLDR — Prompts para o Claude Code

Sequência de execução do redesign. Cada fase é um prompt separado, com validação
antes de seguir. Não juntar fases: o objetivo é conseguir revisar e reverter
pontualmente.

**Onde colocar os arquivos** (raiz do projeto Flutter):

```
bldr_fitness/
├── CLAUDE.md              ← acrescentar o ponteiro para docs/redesign/
├── ARCHITECTURE.md
├── ESTRUTURA.md
├── docs/
│   └── redesign/
│       ├── DESIGN_SYSTEM.md
│       ├── REDESIGN_SPEC.md
│       ├── BACKLOG_FUNCIONAL.md
│       ├── HAVOK_SPEC.md
│       ├── PROMPT_CODE.md
│       └── INVENTARIO.md     ← gerado na Fase 0
└── lib/
    ├── theme/bldr_tokens.dart
    └── design_system/bldr_components.dart
```

CLAUDE.md, ARCHITECTURE.md e ESTRUTURA.md permanecem na raiz — se referenciam por
caminho relativo e mover quebraria os links.

Arquivos `.md` não precisam ser declarados em `pubspec.yaml`: são documentação de
repositório, não asset do app.

---

## Fase 0 — Auditoria (não escreve código de UI)

```
Leia, nesta ordem: CLAUDE.md, ESTRUTURA.md, ARCHITECTURE.md,
docs/redesign/DESIGN_SYSTEM.md, docs/redesign/REDESIGN_SPEC.md e
docs/redesign/BACKLOG_FUNCIONAL.md.

Sua tarefa nesta fase é SOMENTE auditar. Não altere nenhum arquivo de UI.

Produza o arquivo docs/redesign/INVENTARIO.md com quatro seções:

## 1. Mapa de telas
Para cada tela citada no REDESIGN_SPEC.md, informe:
- caminho real do arquivo
- quantas linhas tem
- se é StatelessWidget/StatefulWidget/usa controller
- quais widgets internos ela compõe (e o caminho deles)
- se algum deles é compartilhado com outra tela (risco de efeito colateral)

Se alguma tela do SPEC não existir no código, marque como NÃO ENCONTRADA.
Se existir tela no código que não está no SPEC, liste em "telas fora do escopo".

## 2. Status dos itens [F]
Para CADA item do BACKLOG_FUNCIONAL.md, classifique:
- JÁ EXISTE — dado/lógica implementados; o redesign só precisa exibir
- PARCIAL — existe algo aproveitável; descreva o que falta
- NÃO EXISTE — precisa ser construído do zero

Cite o arquivo e a linha que embasam a classificação. Não chute: se não achou,
diga NÃO ENCONTRADO em vez de supor.

Dê atenção especial a:
- F1 (tipo de atividade por dia) — o app já detecta corrida/musculação/outro?
  Onde isso é gravado e sob qual nome de campo?
- B1 (duração média = 0m) e B2 (conquistas com contador furado) — localize a
  causa raiz nos use cases/repositories.

## 2b. HAVOK
Leia docs/redesign/HAVOK_SPEC.md e confirme no código o que o relatório de
estado atual afirma. Para cada item da seção 9 (bloqueadores) e 10 (dívidas
técnicas) do HAVOK_SPEC.md, diga se ainda é verdade hoje, citando arquivo e linha.

Verifique também:
- A cadeia de execução (§8.1) — o que exatamente falta para um treino gerado
  virar template executável? Quais classes/métodos já existem e podem ser
  reaproveitados de `features/workouts/`?
- Onde ficam hoje as cores goldColor/darkBackgroundColor/cardBackgroundColor de
  havok_hub.dart e quantos arquivos as importam de lá

## 3. Estado visual atual
- Onde vivem hoje as cores do app (AppTheme? constantes espalhadas? hex inline?)
- Qual família de fonte está configurada, e em qual arquivo
- Qual pacote de ícones está em uso
- Existe algum widget de card/botão/chip já reutilizado entre telas, ou cada
  tela monta o seu?

## 4. Riscos
Liste o que pode quebrar num redesign puramente visual, considerando as dívidas
já registradas no ARCHITECTURE.md — em especial legacy_ui_maps.dart (nutrição) e
ArenaRepository (club, maps crus consumidos direto pelas telas).
Aponte também testes de widget existentes que dependam de estrutura visual.

Não proponha soluções nesta fase. Só o retrato do que existe.
```

**Antes de seguir:** revisar o INVENTARIO.md. As respostas de F1, da fonte e do
pacote de ícones definem os próximos passos.

---

## Fase 0.5 — Limpeza (antes de qualquer redesign)

> Justificativa: o `INVENTARIO.md` §1.4 e §R6 encontraram **24 arquivos de UI sem
> nenhum importador (~7.500 linhas)**. Dois são armadilhas diretas:
> `active_workout_banner_widget.dart` (1339 l.) e `active_workout_banner_club.dart`
> (1392 l.) são a versão **mais completa** do banner de treino ativo — e não são
> renderizados. Sem deletar antes, há chance real de redesenhar o arquivo errado.

```
Leia docs/redesign/INVENTARIO.md, seções 1.4 e R6.

Tarefa: remover código morto. NÃO altere nenhum arquivo vivo.

1. Para cada um dos 24 arquivos listados como código morto no INVENTARIO.md,
   CONFIRME que continua sem importadores antes de deletar (grep pelo nome do
   arquivo e pelo nome da classe pública em lib/ e test/). Se algum tiver ganhado
   importador desde a auditoria, NÃO delete e me avise.

2. Atenção especial a estes dois, porque contêm lógica que o arquivo vivo não tem:
   - active_workout_banner_widget.dart:486 tem checkAchievements('workout')
   - active_workout_banner_club.dart

   ANTES de deletar, me diga em uma frase o que cada um faz que o equivalente
   vivo (_buildActiveWorkoutBanner em workouts_screen.dart:667) NÃO faz.
   Isso é insumo do bug B2 — não quero perder a informação junto com o arquivo.

3. Delete test/widget_test.dart (template do flutter create, nunca adaptado,
   fora do comando de validação do CLAUDE.md).

4. Não crie substitutos, não mova lógica, não refatore nada. Só remoção.

Ao final:
  dart analyze lib
  flutter test test/features

E rode o app: as telas principais devem abrir normalmente.
Commit isolado, com a lista do que foi removido na mensagem.
```

**Antes de seguir:** rodar o app e navegar pelas telas principais. Se algo sumiu,
o `git revert` deste commit é limpo — por isso ele é isolado.

---

## Fase 1 — Base do design system

```
Adicione ao projeto os dois arquivos fornecidos, nos caminhos exatos:

- lib/theme/bldr_tokens.dart
- lib/design_system/bldr_components.dart

Pasta design_system/ é própria e deliberada — NÃO colocar em lib/widgets/,
que contém custom_icon_widget.dart (2189 l.) e código morto, e é exportada por
app_export.dart para 77 arquivos.

As decisões de fonte, spacing e AppTheme já estão tomadas — ver
docs/redesign/DESIGN_SYSTEM.md §0. Não reabra nenhuma delas.

Ajuste necessário — fonte:
Os tokens declaram BldrText.family = 'Inter'. Como o app usa google_fonts sem
seção `fonts:` no pubspec, `fontFamily: 'Inter'` NÃO resolve sozinho.
Escolha um dos dois e me diga qual fez:
  (a) empacotar o Inter localmente (adicionar assets + seção fonts: no pubspec)
  (b) converter os TextStyle de BldrText para GoogleFonts.inter(...)
Prefiro (a): evita flash na primeira renderização e download em runtime.

Restrições:
- NÃO altere lib/theme/app_theme.dart. Os dois coexistem.
- NÃO altere nenhuma tela nesta fase.
- NÃO exporte os componentes novos via core/app_export.dart.
- Imports absolutos (package:bldr_fitness/...), conforme CLAUDE.md.

Ao final:
  dart analyze lib
  flutter test test/features

E me diga: os componentes compilam isoladamente? Crie um widget de teste
descartável que renderize um de cada (BldrGlassCard, BldrHeroCard,
BldrPrimaryButton, BldrChip, BldrSegmentedControl, BldrProgressBar, BldrListRow,
BldrEmptyState, BldrCarousel, BldrNavBar) para eu conferir visualmente antes de
aplicar em tela real. Pode ser uma rota temporária.
```

**Antes de seguir:** abrir a tela de teste dos componentes e comparar com os
mockups. Calibrar fonte, ícones e intensidade do blur **aqui** — esses três
ajustes moram nos componentes e propagam para as 16 telas seguintes. Corrigidos
depois, viram 16 retrabalhos.

---

## Fase 2 — Dashboard (tela piloto)

```
Redesenhe APENAS a tela de Dashboard (lib/shared/presentation/dashboard/),
seguindo os itens G1–G10 e D1–D9 do REDESIGN_SPEC.md.

REGRA CENTRAL: esta é uma mudança 100% de camada de apresentação.

Permitido:
- reorganizar a árvore de widgets
- trocar containers por BldrGlassCard / BldrHeroCard / BldrChip / etc.
- alterar cores, espaçamentos, raios, tipografia, ordem visual dos blocos

Proibido nesta fase:
- tocar em domain/ ou data/
- mudar assinatura de use case, controller ou repository
- mudar nome de rota ou fluxo de navegação
- remover chamada de dado existente
- alterar lógica de negócio

Sobre elementos sem dado (card de Parceiros, itens marcados [F]):
NÃO delete o widget. Deixe-o com renderização condicional — retorna
SizedBox.shrink() quando não há dado. Ele volta sozinho quando o backlog
funcional for implementado.

Sobre texto dinâmico: leia a seção "⚠️ Conteúdo dinâmico" do REDESIGN_SPEC.md.
Nenhum texto daquela tabela pode virar string fixa. Se a lógica que gera o texto
já existe, ela permanece — muda só onde e como o texto aparece.

Item D7 (gráfico de 7 dias) é [F]: se a auditoria marcou como NÃO EXISTE, deixe
o espaço com o componente pronto recebendo lista vazia, sem inventar dado falso.

Ao final:
  dart analyze lib
  flutter test test/features

E me diga: quais widgets do Dashboard são compartilhados com outras telas e
mudaram de aparência como efeito colateral?
```

**Antes de seguir:** rodar o app e comparar lado a lado com o mockup do Dashboard.
Calibrar fonte, ícones e intensidade do blur agora — o que for ajustado nos
componentes propaga para todas as telas seguintes.

---

## Fase 3 em diante — demais telas

Mesmo formato da Fase 2, uma tela (ou grupo) por vez, na ordem do fim do
REDESIGN_SPEC.md:

1. Treinos + Meu Plano  ⚠️ ver aviso sobre bifurcação abaixo
2. Perfil + Configurações (tela nova)
3. Nutrição + bottom sheet de adicionar alimento
4. BLDR Club (hub, treinos, plano, esportes, trackers, protocolo, comunidade, competição)
5. Progresso (4 abas)

Template:

```
Redesenhe [TELA], seguindo os itens [CÓDIGOS] do REDESIGN_SPEC.md.

Valem as mesmas restrições da Fase 2: mudança 100% de apresentação, sem tocar
em domain/data, sem alterar assinaturas, sem virar texto dinâmico em literal.
Elementos sem dado ficam ocultos por condicional, não removidos.

Reutilize os componentes de lib/widgets/bldr_components.dart. Se precisar de um
padrão visual que ainda não existe lá, ADICIONE ao arquivo de componentes em vez
de montar direto na tela — assim propaga e não diverge.

Ao final: dart analyze lib && flutter test test/features
```

### Avisos por tela

**Meu Plano — bifurcação obrigatória antes de redesenhar.**
`weekly_plan_screen.dart` (1353 l.) é **a mesma tela** para P1–P5 (Treinos) e
CP1–CP5 (Club → Meu Plano), importada por `workouts_screen.dart:22` e
`club_workout_screen.dart:21`. As duas listas de requisitos **não são idênticas**:
CP2–CP5 pedem ícone de atividade, XP por dia, extras e botão de registro; P1–P5
não. Antes de aplicar P* ou CP*, decida com o usuário: bifurcar em dois arquivos,
ou aceitar que as duas telas fiquem idênticas. Não decida sozinho.

**Telas sem controller e com regra de negócio no `State`.**
`club_workout_screen.dart` (3041 l.), `comunidade_screen.dart` (2834 l.) e
`profile_screen.dart` (1703 l.) misturam layout e lógica no mesmo `State` — não
existe `presentation/controllers/` em nenhuma feature. Ao aplicar itens [V]
nessas telas, você vai editar o arquivo que contém a inferência de tipo de
atividade, a contagem da semana e o clamp `_gymWorkoutsCount`. **Não toque nessa
lógica.** Se um item [V] parecer exigir mexer nela, pare e pergunte.

**Nutrição** — os widgets internos (MealTimelineWidget, DailyNutritionOverviewWidget,
modal) ainda renderizam maps via `legacy_ui_maps.dart`. Redesenhe o visual
mantendo o contrato de map intacto. Tipar esses widgets é outra tarefa, não
misturar com o redesign.

**BLDR Club → Competição** — as telas de arena/squad consomem `ArenaRepository`
com maps crus, sem use case. Mesma regra: muda o visual, mantém o consumo como
está.

**BLDR Club → todas** — a logo atual permanece em todas as telas onde já aparece.
`BldrNavBar` recebe a logo por parâmetro (`clubLogo`) justamente para isso.
Não substituir por texto, não remover o glow do asset, não alterar proporção.

**Progresso** — maior concentração de itens [F]. Consultar o INVENTARIO.md antes:
o que estiver NÃO EXISTE fica oculto, não vira dado falso.

**Todas as telas — não há rede de segurança automatizada.** O `INVENTARIO.md` §R8
mostra que **nenhum teste cobre UI**: os 5 arquivos em `test/features/` testam use
cases e mappers, exatamente a camada que um item [V] não deve tocar. `dart analyze`
+ `flutter test` passando **não significa** que a tela funciona. A validação real é
abrir a tela no app, com dado real e com conta vazia.

---

## Fase final — Backlog funcional

Só depois de todas as telas validadas visualmente. Aí sim entram `domain/` e
`data/`, seguindo as regras do CLAUDE.md: entidades tipadas, `Result<T>`,
registro no `injection.dart`, teste de unidade por feature.

Ordem sugerida (do BACKLOG_FUNCIONAL.md):
1. Prioridade 1 — os três bugs (B1, B2, B3). São correções, não features.
2. Prioridade 2 — itens que destravam o que o redesign já prevê.
3. Prioridade 3 — telas e seções novas.

---

## Checklist de revisão por tela

Antes de dar uma tela como pronta:

- [ ] Comparei lado a lado com o mockup correspondente
- [ ] Nenhuma cor fora do dourado/neutro (sem verde, azul, laranja, roxo, ciano, rosa)
- [ ] Nenhum texto da tabela de conteúdo dinâmico virou literal
- [ ] Elementos sem dado estão ocultos, não deletados
- [ ] Nenhum arquivo em `domain/` ou `data/` apareceu no diff
- [ ] `dart analyze lib` limpo
- [ ] `flutter test test/features` passando
- [ ] **Abri a tela no app** — analyze/test não cobrem UI (INVENTARIO §R8)
- [ ] Testei com dado real E com conta vazia (estados vazios)
- [ ] Se a tela lê `legacy_ui_maps.dart`: nenhuma chave de map foi renomeada
- [ ] Nenhuma cor de `AppTheme` (`successGreen`/`warningAmber`/`errorRed`) foi alterada
```
