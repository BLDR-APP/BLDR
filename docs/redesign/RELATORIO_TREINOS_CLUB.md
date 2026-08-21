# Relatório — Treinos do BLDR Club (UI + funcionalidade)

Diagnóstico apenas. Nenhum arquivo foi alterado para produzir este relatório.
Comparação feita contra o modo grátis (`workouts_screen.dart` /
`active_workout_screen.dart`), confirmado como arquivo distinto do Club
(`club_workout_screen.dart` / `club_active_workout_screen.dart`), sem
parâmetro de contexto compartilhado.

---

## 1. BUG — lista de exercícios não aparece no detalhe do treino (Club)

**Confirmado: é um bug de dado, não de renderização.** A lista chega vazia
até a UI porque a chave é perdida em **dois pontos independentes da cadeia**,
não um só.

### Camada 1 — `WorkoutModels.templateFromMap` lê a chave errada para o Club

[workout_models.dart:36-37](lib/features/workouts/data/models/workout_models.dart:36):
```dart
final rawExercises =
    (map['workout_template_exercises'] as List?)?.cast<Map>() ?? const [];
```
Este parser é **compartilhado** entre grátis e Club (não há versão
`club_*` dele). Ele sempre procura a chave `'workout_template_exercises'`
(sem prefixo).

Mas o service que alimenta o Club devolve outra chave —
[club_workouts_service.dart:95-98](lib/services/club_workouts_service.dart:95):
```dart
return {
  ...Map<String, dynamic>.from(template),
  'club_workout_template_exercises': enriched,
};
```
`enriched` (a lista de exercícios já montada com nome, grupo muscular etc.,
linhas 84-93 do mesmo arquivo) **existe e está correta** — o problema é
só o nome da chave. Resultado: `rawExercises` em `templateFromMap` é
**sempre `[]`** para templates do Club, então `WorkoutTemplate.exercises`
chega vazio na entidade de domínio, antes mesmo de qualquer código de tela
rodar.

### Camada 2 — a UI do Club lê uma terceira chave, que nunca existe

[club_workout_screen.dart:480-483](lib/features/club/presentation/bldr_club/club_workout_screen.dart:480):
```dart
final exercises =
    ((snap.data ?? {})['club_workout_template_exercises']
            as List?) ??
        [];
```
`snap.data` aqui é o resultado de `templateToLegacyMap(...)`
([legacy_ui_maps.dart:20](lib/features/workouts/presentation/mappers/legacy_ui_maps.dart:20)),
que **sempre** escreve a chave `'workout_template_exercises'` (sem
prefixo) — é o mesmo mapper usado pelo grátis, hardcoded. A UI do Club
procura `'club_workout_template_exercises'` nesse mapa, chave que
**nunca existe** nele. Mesmo que a Camada 1 fosse corrigida, esta linha
continuaria lendo vazio.

### Comparação com o grátis

O grátis usa a mesma chave em todo o caminho —
[workouts_screen.dart:198](lib/features/workouts/presentation/workouts_screen/workouts_screen.dart:198)
lê `'workout_template_exercises'`, que é exatamente o que
`WorkoutModels.templateFromMap` procura (a tabela do grátis se chama
`workout_template_exercises`, sem prefixo — por isso nunca deu problema lá).
**O grátis não tem esse bug porque, por coincidência, nome de tabela e
nome de chave hardcoded batem.** No Club, a tabela se chama
`club_workout_template_exercises` e a incompatibilidade fica exposta.

### Efeito colateral: o botão "Editar" também é afetado

[club_workout_screen.dart:536-541](lib/features/club/presentation/bldr_club/club_workout_screen.dart:536)
chama o mesmo `GetClubTemplateWithExercises` + `templateToLegacyMap` para
abrir `ClubCreateWorkoutScreen(editTemplate: full)`. Como `full.exercises`
já chega vazio da Camada 1, **a tela de edição também abre sem nenhum
exercício pré-carregado** — mesmo bug, segunda tela afetada.

**Correção de uma linha resolveria as duas camadas**, mas fica pendente de
autorização: ajustar `club_workouts_service.dart:97` para devolver a chave
`'workout_template_exercises'` (alinhando com o que o parser compartilhado
espera) resolveria a Camada 1 e, por consequência, a Camada 2 (a chave que
`templateToLegacyMap` grava já é a correta). Alternativa: ajustar
`templateFromMap` para aceitar as duas chaves — mais invasivo, toca o
parser compartilhado com o grátis.

---

## 2. BUG — contagem "Treinos" do card "Semana atual" travada em 1 (Club)

**Confirmado: NÃO é o mesmo bug do B4/`GetConsolidatedWorkoutHistory`.**
Este card já consulta as três fontes corretas — não há tabela esquecida.

### De onde vem o número

[club_workout_screen.dart:1846](lib/features/club/presentation/bldr_club/club_workout_screen.dart:1846):
```dart
final gymCount = completedByDay.length;
...
_gymWorkoutsCount = gymCount.clamp(0, effectiveFreq);
```
exibido em
[club_workout_screen.dart:2221](lib/features/club/presentation/bldr_club/club_workout_screen.dart:2221)
como o stat "Treinos".

### Por que trava em 1 — causa raiz real

`completedByDay` é um `Map<int diaDaSemana, ...>`
([club_workout_screen.dart:1742](lib/features/club/presentation/bldr_club/club_workout_screen.dart:1742)),
preenchido por três laços — treinos do Club (`:1745-1769`), treinos
pessoais (`:1772-1778`) e atividades avulsas (`:1784-1798`) — **todos
usando o dia da semana (0-6) como chave**, e todos usando
`putIfAbsent`/atribuição direta por chave. Ou seja: **o mapa deduplica por
dia, não por treino.**

`gymCount = completedByDay.length` conta **quantos dias distintos** tiveram
pelo menos um treino/atividade concluído — não quantos treinos foram
concluídos. Se o usuário completa 2, 3 ou mais treinos no mesmo dia
(cenário muito plausível em teste, repetindo o fluxo "Meus treinos" várias
vezes seguidas), o contador continua contando **1** para aquele dia, porque
é isso que a estrutura de dado mede. A rotulagem "Treinos" no
`BldrStatItem` promete uma contagem de treinos; o valor real entregue é
"dias com treino".

### Diferença do B4 / `GetConsolidatedWorkoutHistory`

O bug B4 (documentado em `ESTADO_POS_REDESIGN.md` §3) era sobre **esquecer
uma tabela inteira** (`club_user_workouts`) em alguns pontos do app. Aqui
as três fontes (`GetWeekCompletedWorkouts` — pessoal,
`GetClubWorkoutsBetween` — Club, `GetClubActivitiesBetween` — avulsas) já
são consultadas
([club_workout_screen.dart:1716-1732](lib/features/club/presentation/bldr_club/club_workout_screen.dart:1716)).
`GetConsolidatedWorkoutHistory` não é usado aqui e não precisaria ser — o
problema não é fonte de dado incompleta, é a **estrutura de agregação**
(dedupe por dia) usada para responder uma pergunta diferente ("quantos
treinos" em vez de "quantos dias treinados").

---

## 3. BUG — anel de descanso com sobreposição (Club)

**Confirmado: `_ClockPainter` foi reaproveitado num tamanho para o qual
não foi desenhado.**

[club_active_workout_screen.dart:1108-1118](lib/features/club/presentation/bldr_club/club_active_workout_screen.dart:1108):
a faixa flutuante de descanso usa um `SizedBox(width: 52, height: 52)` com
`CustomPaint(painter: _ClockPainter(...), child: Center(child: Text(label)))`
— texto do tempo centralizado sobre o `CustomPaint`.

`_ClockPainter`
([club_active_workout_screen.dart:1594](lib/features/club/presentation/bldr_club/club_active_workout_screen.dart:1594))
não é só um anel de progresso — ele desenha **12 marcadores de hora**
(estilo relógio analógico), lógica em
[club_active_workout_screen.dart:1644-1656](lib/features/club/presentation/bldr_club/club_active_workout_screen.dart:1644):
```dart
final outerR  = radius - strokeW / 2 - 2;
final innerR  = outerR - (isMajor ? 8.0 : 4.0);
```
Com `size = 52`: `radius = 52/2 - 8 = 18`, `strokeW = 6` →
`outerR = 18 - 3 - 2 = 13`, e para os marcadores maiores
`innerR = 13 - 8 = 5`. Ou seja, os traços de hora se estendem até **5px do
centro** de um círculo de 52px de diâmetro — exatamente onde o texto do
tempo (`fontSize: 15`) está centralizado. Os marcadores foram calculados
para o relógio grande original (`_buildRestClock`, pré-redesign, que usava
`36.w`/`36.h` ≈ 130-150px de diâmetro — nesse tamanho os traços ficavam
bem afastados do centro). Ao herdar a mesma classe para a faixa flutuante
pequena, os marcadores passaram a invadir visualmente a área do número.

**Confirmado por comparação:** o grátis usa `_MiniRingPainter`
([active_workout_screen.dart:1269](lib/features/workouts/presentation/workouts_screen/active_workout_screen.dart:1269)),
que desenha **só** trilho + arco de progresso, sem nenhum marcador de hora
— desenhado desde o início para o tamanho pequeno (52px) da faixa
flutuante. O Club não tem um equivalente "mini" — reaproveitou a classe do
relógio grande.

---

## 4. Status funcional geral (Club)

### Botões "Editar" / "Excluir" no detalhe do treino

**Existem e estão corretamente wireados**, mesmo padrão visual do grátis —
[club_workout_screen.dart:533-578](lib/features/club/presentation/bldr_club/club_workout_screen.dart:533).
"Editar" navega para `ClubCreateWorkoutScreen(editTemplate: full)`;
"Excluir" abre `_confirmDelete`, que chama `DeleteClubTemplate` e recarrega
a lista. **Porém, ambos herdam o bug da seção 1**: "Editar" abre sem
exercícios pré-carregados (mesma cadeia de dado quebrada).

Diferença notável do grátis: o grátis esconde os dois botões quando o
template não é do usuário (`isOwned`,
[workouts_screen.dart:178-179](lib/features/workouts/presentation/workouts_screen/workouts_screen.dart:178)
e `:254`). O Club **não tem essa checagem** — mas como este sheet só é
aberto a partir da aba "Criados por mim"
([club_workout_screen.dart](lib/features/club/presentation/bldr_club/club_workout_screen.dart), `_buildCreatedByMeTab`),
todo template ali já é do usuário, então na prática não é um bug — apenas
uma diferença estrutural que vale registrar caso o sheet passe a ser
reutilizado para templates públicos no futuro.

### Lista de séries — "Atual"/"A seguir" persiste valor real?

**Não, no Club.** O estado (`done`/`current`/`pending`) funciona
corretamente, mas o **valor exibido** (peso/reps) para uma série já
concluída não aparece.

Causa: `_confirmSet` do Club
([club_active_workout_screen.dart:274-296](lib/features/club/presentation/bldr_club/club_active_workout_screen.dart:274))
envia `weightKg`/`reps` para o backend via `CompleteClubSet`, mas no
espelhamento otimista local só grava `completed_at`/`is_completed`:
```dart
sets[setIdx] = {
  ...sets[setIdx],
  'completed_at': DateTime.now().toIso8601String(),
  'is_completed': true,
};
```
— nunca `weight_kg`/`reps`. Isso é a razão documentada no próprio código de
`_buildSeriesList`
([club_active_workout_screen.dart, comentário acima do método](lib/features/club/presentation/bldr_club/club_active_workout_screen.dart)),
escrito durante o redesign anterior: `valueLabel` fica `null` para séries
concluídas porque o dado não é gravado localmente.

**O grátis não tem essa lacuna** —
[active_workout_screen.dart:279-285](lib/features/workouts/presentation/workouts_screen/active_workout_screen.dart:279)
grava explicitamente `weight_kg`/`reps`/`completed_at` no `sets[setIdx]`
local logo após a chamada ao backend, com comentário próprio explicando o
motivo ("para que a lista de séries mostre o valor real confirmado"). É uma
lacuna de paridade, não uma quebra de tela — a lista renderiza, só omite o
valor.

---

## Resumo por gravidade

| # | Bug | Bloqueia uso? | Causa raiz | Escopo do fix |
|---|---|---|---|---|
| 1 | Exercícios não aparecem (detalhe + edição) | **Sim** | Chave de mapa incompatível em 2 pontos (`club_workouts_service.dart:97` vs `workout_models.dart:37` vs `club_workout_screen.dart:481`) | Provavelmente 1 linha em `club_workouts_service.dart`, mas cruza uma camada compartilhada com o grátis — merece confirmação antes de tocar |
| 2 | Contagem "Treinos" trava em 1 | Parcial (métrica errada, não crash) | Estrutura de agregação por dia usada como contagem de treinos (`club_workout_screen.dart:1846`) | Isolado nesta tela; não é o bug B4 |
| 3 | Ícone/marcadores sobre o número do timer | Cosmético, mas feio | `_ClockPainter` (relógio grande) reaproveitado num círculo de 52px | Trocar por um painter "mini" sem marcadores, como `_MiniRingPainter` do grátis |
| 4a | Editar/Excluir | Não — funcionam, mas Editar herda bug 1 | — | Resolvido junto do bug 1 |
| 4b | Valor de série concluída não aparece | Não — cosmético/informativo | `_confirmSet` do Club não espelha `weight_kg`/`reps` localmente | 3 linhas em `_confirmSet`, mesmo padrão do grátis |

Nenhuma correção foi aplicada. Aguardando autorização para agir sobre os
itens acima.
