# Treinos v2 — Levantamento e decisões (Figma `guqp4TpJiiCKjhSgzqxSjg`)

Regras do CLAUDE.md ("Rebranding v2 — Figma") valem aqui: mockup prevalece,
presentation-only (exceto os itens aprovados abaixo), tokens v2, textos do
mockup são simulação.

Legenda: **[V]** visual, dado já existe (origem citada) · **[F]** dado ou
funcionalidade inexistente.

## Escopo desta fase
- As 12 telas de musculação, hub, resumo e compartilhamento listadas abaixo.
- **Fase posterior** (começa por especificação funcional; nada implementado agora): HIIT, Indoor Cardio, Yoga, Pilates e Hyrox.
- Frames ocultos do arquivo ficam fora.
- **Leitura na implementação:** cada tela por partes — `get_metadata` do node para listar as seções e `get_design_context` em cada seção. Nenhuma tela implementada só pelo screenshot.

## Escala tipográfica (vale para todo o rebranding v2)
- Degraus fixos em `BldrTextV2`: **11 · 12 · 13 · 15 · 17 · 20 · 24 · 28 · 32** (`BldrTextV2.scale`). Mínimo 11.
- Cada tamanho do mockup vai para o degrau mais próximo; empate (14, 16, 22) sobe. Pesos, cores e espaçamento entre letras seguem o mockup.
- Exceções aprovadas (hierarquia valor × rótulo, etapa 2): nome do exercício no card e no picker = 13; valor nas caixas Séries/Reps/Desc. = 13; carga e reps nas linhas das séries = 12; rótulos em 11.
- Layout ajustado só o necessário: sem overflow, corte ou sobreposição em 320 e 440 px e com `textScaler` 1,3; nomes longos com reticências.
- Telas usam sempre os estilos da escala, nunca tamanhos soltos.

| Etapa 2 (mockup → degrau) | | Hub (mockup → degrau) | |
|---|---|---|---|
| 30 → 28 (voltar) | 24 → 24 (título) | 16 → 17 (abas) | 14 → 15 (nome do card, valores da semana) |
| 22 → 24 (sheet, nome) | 21 → 20 (seta) | 12 → 12 (card de hoje, dias) | 10 / 9 / 8 / 7 → 11 |
| 15 → 15 (×) | 14 → 15 (resumo) | 6,6 / 6 / 5,4 / 4,1 → 11 | |
| 12 → 12 (subtítulo) | 11 a 6 → 11 (exceto as exceções acima) | | |

## Regras de mídia

**Muscle Map.** O novo muscle map ainda não foi desenhado. Nas áreas dedicadas
a ele (card "Treino de hoje" do hub, mini mapas de "Meus treinos", "Músculos
trabalhados" no resumo, overlay e card de compartilhamento) fica o componente
atual (`BldrMuscleMap` + `MuscleNormalizer`), sem alterar desenho, cores nem
lógica. Do mockup segue-se só o container e os textos ao redor. Não é [F].

**GIFs dos exercícios.** O app não tem vídeos. Nos espaços de mídia do
exercício (miniaturas em 179:1015, 179:1590 e 179:1117, e a área "Execução" de
179:1319) ficam os GIFs atuais do ExerciseDB. Do mockup segue-se só o
container (tamanho, raio, borda, posição e legendas). Sem GIF, usa-se o
fallback atual do app. O botão de play do mockup não se aplica (proposta P4).

## Decisões aprovadas
1. Aba Esportes liga à `EsportesScreen` atual, com o paywall/regra de acesso de hoje.
2. Card da semana: "Planejados" vira Extras; a métrica XP fica **oculta** nesta fase (layout pronto para ela) — ver Verificações.
3. Biblioteca BLDR: sai o carrossel do hub; fica só o atalho em Explorar.
4. Duração: estimativa automática aprovada nesta fase, como função pura com teste (fórmula em P1).
5. Personalização por série: mantém a UI do mockup e corrige a persistência por série (impacto em P2).
6. Treino em andamento: elementos [F] ficam ocultos (sem "—"). Lista de séries, faixa flutuante de descanso e timeline podem sair, desde que nenhuma ação se perca (ver Verificações e P3).
7. Resumo: faixas ≥ 0,66 Alto, ≥ 0,33 Moderado; frase do .arb com os 2 músculos principais.
8. Compartilhar: os três estilos atuais viram Overlay e Card.
9. Criar treino: 6 chips do mockup; HIIT, Indoor Cardio, Yoga, Pilates e Hyrox desabilitados com "Em breve". Treinos existentes em Cardio/Mobilidade/Misto abrem e editam normalmente. Indicador de limite gratuito do picker mantido.
10. "Compartilhar na comunidade" sai do resumo e vira opção na tela de compartilhamento (proposta P5).
11. "Criar treino em passos" é [V]: reorganização da tela, sem rota nem dado novo.
12. "Ver semana" continua abrindo a `WeeklyPlanScreen` atual, sem mudança visual nesta fase.
13. GIFs atuais em todos os espaços de mídia; "vídeo do exercício" sai da lista de [F].

## Verificações feitas
- **XP da semana — fica oculto nesta fase.** Conferido no Supabase: as RLS permitem leitura de `bldr_club.xp_events` para autenticados, mas `add_xp_to_user` não grava em `xp_events` (só atualiza `club_ranking.xp_total`); nos últimos 30 dias há só 2 eventos ("Treino Livre Concluído"). Registrado no BACKLOG_FUNCIONAL.md.
- **Timeline de exercícios:** só exibe; não tem toque nem navegação para outro exercício. Nada se perde ao remover.
- **Lista de séries:** só exibe; não permite editar uma série concluída. Nada se perde ao remover.
- **Faixa flutuante de descanso:** tem duas ações — "+15 s" e "pular descanso". Precisam ir para o card de descanso (P3).

## Pendência conhecida — persistência por série (etapa 1)
- **Sintoma:** em "Personalizar séries", série 1 = 40 kg e série 2 = 45 kg; ao salvar e reabrir, as duas aparecem com 42,5 kg (média). A migration foi aplicada e a coluna `set_details` existe.
- **Quando:** investigar logo após a etapa 3 (editor). Nas etapas 2 e 3, a lógica de gravação/leitura das séries não muda além do necessário para o visual.
- **Pistas a checar:** se `set_details` chega ao insert/update do `WorkoutService`; se `_enrichExerciseDbRows` ou outro passo reconstrói as linhas do template sem a coluna; se a reabertura usa o caminho que lê `set_details`.

## Propostas (aguardam aprovação)

**P1 — Fórmula da duração estimada** (função pura, minutos arredondados para cima):
- Execução por série = reps × 3 s, mínimo 20 s; sem reps (por tempo) = `duration_seconds`; sem nenhum dos dois = 40 s.
- Descanso = `rest_seconds` de cada série, exceto após a última série do treino.
- Transição entre exercícios = 60 s (n_exercícios − 1).
- Exemplo: 3 exercícios, 12 séries de 10 reps, 60 s de descanso → 360 + 660 + 120 = 1140 s → "~19 min".

**P2 — Persistência por série (impacto em domain/data)**
- Hoje: `workout_template_exercises` guarda uma linha por exercício (`sets`, `reps`, `weight_kg`, `rest_seconds`); a tela salva a média da carga e um único reps/descanso, perdendo o que foi digitado por série.
- Banco: nova coluna `set_details jsonb` em `workout_template_exercises` (lista de `{weight_kg, reps, rest_seconds}`), com migration em `supabase/migrations`. Colunas atuais mantidas (com `sets` = tamanho da lista) para compatibilidade com leitores antigos e treinos já salvos.
- Domain: `TemplateExercise` ganha `setDetails` (lista de carga/reps/descanso), opcional. Nenhuma assinatura de use case muda.
- Data: `WorkoutModels` lê/grava `set_details`; `WorkoutService.createWorkoutTemplate`/`updateWorkoutTemplate` gravam a lista; `ensureInitialSets` e o início do treino passam a criar cada série com os valores da lista (fallback para os valores agregados quando a lista não existir).
- Presentation: `CreateWorkoutScreen` envia as séries em vez da média e carrega `setDetails` ao editar.
- Testes: model (ida e volta do JSON, fallback sem `set_details`) e criação de séries iniciais.
- Fora: templates do Club (`club_workout_template_exercises`) não mudam nesta fase.
- Exige aplicar a migration no Supabase antes do deploy do app.

**Sheet v2 reutilizável (etapa do treino em andamento — não implementado ainda)**
- Criar um componente único `BldrV2Sheet` no estilo dos nodes 179:1401 e 179:1496: borda dourada, cantos arredondados, alça, fundo escurecido com a tela visível atrás.
- Reutilizável por todos os sheets do app, inclusive os das modalidades futuras.
- Sheet de carga e reps: além de − / +, tocar no número permite digitar o valor, e segurar − / + repete o ajuste.

**P3 — Ações da faixa de descanso no card "Descanso" do mockup**
- "›" no fim do card = pular descanso (ação atual `_endRestEarly`).
- Texto "+15 s" dourado, pequeno, entre o rótulo "Descanso" e o timer = adicionar 15 s (ação atual `_addRestSeconds`).
- Fora do descanso, o card mostra o descanso padrão da série e não tem ações.

**P4 — Play do mockup sobre o GIF**
- Sem botão de play: o GIF roda em loop, como hoje.
- Tocar na área "Execução" abre o detalhe do exercício que já existe (instruções).
- Mantêm-se a legenda "Execução" e a faixa inferior; "Cadência" fica oculta ([F]) e "Alvo" mostra as reps da série.

**P5 — "Compartilhar na comunidade" na tela de compartilhamento**
- Link de texto dourado "Publicar na comunidade ›", abaixo do botão "Compartilhar" e acima da nota de rodapé, nas duas abas (Overlay e Card).
- Abre o mesmo fluxo de hoje (com os PRs pré-selecionados).

## Telas

### 1. Hub vazio — `249:18901`
**Tela atual:** `WorkoutsScreen` + `CurrentWeekCardWidget`.
- [V] Abas Treino / Esportes (`EsportesScreen`, regra de acesso atual).
- [V] Busca — `_searchOpen` no header.
- [V] Card "Treino de hoje": nome, "N exercícios · ~min", "Iniciar treino", toque para alterar — `_buildTodayHero`, `GetTemplateWithExercises`, `WeeklyPlanScreen`; muscle map atual.
- [V] "Minha semana" com estados por dia — `CurrentWeekCardWidget` (`_DayStatus`).
- [V] Treinos e Extras — `completedByDay`, `GetExtraActivities`.
- XP da semana: oculto nesta fase (layout pronto); depende de `add_xp_to_user` gravar em `xp_events` (backlog).
- [V] "Ver semana" → `WeeklyPlanScreen` sem mudança visual.
- [V] "Meus treinos" vazio, "Criar treino", "A partir de foto" — `_buildMyWorkoutsSection`, `_buildCreateCta`, `_onCreateFromPhoto`.
- [V] Explorar: BLDR Club, Biblioteca BLDR, Programas (cadeado) — `_buildExplorSection`, `ResolveClubAccess`.
- Sai: título "Treinos" (vira abas), métrica "Planejados", carrossel da Biblioteca BLDR.

### 2. Hub com treinos — `179:2`
**Tela atual:** `WorkoutsScreen`.
- [V] Tudo do hub vazio.
- [V] Lista vertical de "Meus treinos": mini muscle map (atual), nome, grupos, "N exercícios · ~min" — `_myWorkouts`, `MuscleNormalizer.mapDataForTemplate`; duração pela P1.
- Sai: carrossel horizontal (`_buildCompactWorkoutCard`).

### 3. Criar treino — passo 1 — `179:981`
**Tela atual:** `CreateWorkoutScreen` (hoje em uma tela só).
- [V] Fluxo em passos (nome/tipo → montar → picker) dentro da mesma tela.
- [V] Nome do treino; chip "Musculação" = categoria Força (`workout_type`).
- [V] Chips HIIT, Indoor Cardio, Yoga, Pilates, Hyrox desabilitados com "Em breve".
- [V] "Adicionar exercícios ›" abre o picker.
- Sai: seletor de duração fixa; chips Cardio/Mobilidade/Misto (treinos existentes nessas categorias continuam abrindo e editando).

### 4. Montar treino — `179:1015`
**Tela atual:** `CreateWorkoutScreen`.
- [V] Resumo: Exercícios, Séries, ~Minutos (P1), Desc. médio.
- [V] Card do exercício: GIF atual (container do mockup), nome, grupos, séries/reps/descanso, remover.
- [V] "Personalizar séries" com carga/reps por série, "+ adicionar série" — persistência pela P2.
- [V] "Criar", "Adicionar exercício".
- [F] Reps em faixa ("8–10").
- Sai: seletor de duração.

### 5. Adicionar exercícios (sheet) — `179:1117`
**Tela atual:** `_ExercisePickerSheet`.
- [V] Busca, chips de grupo, "N exercícios", contador de selecionados, seleção múltipla, "Adicionar N exercícios".
- [V] GIF atual na miniatura; tag de equipamento (ExerciseDB).
- [V] Indicador de limite gratuito mantido.
- Sai: segundo nível de filtro (músculo-alvo), se o mockup confirmar só um.

### 6. Editor de treino — `179:1590`
**Tela atual:** `CreateWorkoutScreen` em modo edição.
- [V] Nome editável, grupos do treino, resumo (Exercícios, Séries, ~Minutos pela P1, Desc. médio), "Salvar".
- [V] Cards numerados, "Padrão do exercício", séries com carga/reps (P2), "+ adicionar série", menu "•••", "Adicionar exercício N/M".
- [F] Reps em faixa.
- [F] "Segure para reordenar".
- Sai: seletor de duração.

### 7. Treino em andamento — `179:1319`
**Tela atual:** `ActiveWorkoutScreen`.
- [V] Status, nome, tempo, fechar.
- [V] FC (`HealthKitService`/Watch), Kcal (`_estimatedCalories`), "Série X de Y" e "Treino %" (`_buildOverallProgress`).
- [V] Exercício atual, músculos, "Série 2/4".
- [V] Área "Execução" com GIF atual (P4); dica = `instructions`.
- [V] Carga e reps, descanso (P3), "Concluir série", anterior/pausar/próximo.
- [F] ocultos: cadência, alvo em faixa, "Última vez", "PR possível", sugestão "+2,5 kg" e deltas dos steppers.
- Sai: lista de séries, faixa flutuante de descanso, timeline (sem perda de ação — ver Verificações).

### 8. Ajustar carga (sheet) — `179:1401`
- [V] Carga com − / + (estado `_weight`); steppers inline viram sheet.

### 9. Ajustar repetições (sheet) — `179:1496`
- [V] Reps com − / + (estado `_reps`).

### 10. Resumo — `211:5`
**Tela atual:** `WorkoutSummaryScreen` + `WorkoutSummaryData`.
- [V] "Concluído", nome, data/hora (`completedAtLabel`).
- [V] Duração, Volume, Séries, Exercícios.
- [V] "Novo PR" com "+X kg vs. melhor anterior" (`newPRs`); "XP ganho" (`xpEarned`).
- [V] Músculos trabalhados: muscle map atual, "Ênfase posterior/anterior" (`MuscleNormalizer.dominantView`), frase com os 2 músculos principais, níveis Alto/Moderado pelas faixas aprovadas.
- [V] "Compartilhar treino", "Concluir".
- Sai: "Compartilhar na comunidade" (vai para a tela de compartilhamento, P5); card "Performance" no formato atual.

### 11. Compartilhar — Overlay — `241:12891`
**Tela atual:** `WorkoutSharePreview` + templates + `WorkoutShareExporter`.
- [V] Abas Overlay / Card; overlay transparente com logo, duração, volume, séries, @usuário e muscle map atual.
- [V] "Compartilhar" para Stories (exporter, 1080 de largura).
- [V] "Publicar na comunidade ›" (P5).
- Sai: estilos Performance, Muscle Map e Minimal.

### 12. Compartilhar — Card — `241:12890`
- [V] Card editorial 9:16 (template novo, só visual): logo, @usuário, "Workout completed", data, muscle map atual, duração/volume/séries.
- [V] Exportação 1080 × 1920.

## Consolidado — [F] desta fase
Aprovados para implementar:
1. Estimativa automática de duração (P1).
2. Persistência de carga/reps/descanso por série (P2).

Ficam ocultos/fora nesta fase:
3. Reps em faixa ("8–10") — telas 4, 6 e 7.
4. Reordenar exercícios no editor — tela 6.
5. Cadência por exercício — tela 7.
6. "Última vez" por exercício — tela 7.
7. "PR possível" em tempo real — tela 7.
8. Sugestão de progressão de carga e deltas nos steppers — tela 7.

## Ordem de implementação
1. ✅ **Base:** função de duração (P1) + persistência por série (P2: migration, domain, data, testes).
2. ✅ **Criar treino:** passo 1, Montar treino e picker (179:981, 179:1015, 179:1117).
3. ✅ **Hub** vazio e com treinos (249:18901, 179:2), incluindo abas, card da semana (XP oculto) e lista de treinos.
4. ✅ **Editor** (179:1590).
5. ✅ **Treino em andamento** + sheets de carga e reps (179:1319, 179:1401, 179:1496).
6. ✅ **Resumo** (211:5).
7. **Compartilhar** Overlay e Card + comunidade (241:12891, 241:12890).
8. **Investigar a pendência da persistência por série.** Até lá, a lógica de gravação/leitura das séries só muda o necessário para o visual.

Cada etapa termina com `dart analyze lib`, `flutter test test/features` e comparação com os nodes da etapa.

## Hub revisado (305:1656 / 310:195) — implementado 2026-11-17

- Saíram "Explorar" (inclusive o atalho do BLDR Club) e as pílulas "Criar
  treino" / "A partir de foto".
- Botão da Workout Library (`BldrWorkoutLibraryFab`, 70 px): fundo da página
  (no mockup é transparente; ficaria ilegível sobre os cards), borda e ícone
  `#D4AF37`. Some enquanto o menu está aberto.
- Menu flutuante (`BldrWorkoutLibraryMenu`): 220 ms slide + fade; fecha ao
  tocar fora (sem ação), ao escolher um destino e pelo voltar do Android
  (`PopScope`). Largura 256/440 da tela (mockup 233) porque os textos subiram
  para o degrau 11. `book-clone` não existe no `flutter_tabler_icons` 1.43 →
  SVG do mockup em `assets/images/v2/icons/hub_book_clone.svg`.
- Programas com cadeado + paywall atual; Biblioteca livre.
- Dica de primeiro uso: `SharedPreferences` `hub_library_tip_seen_<uid>`.
- "Meus treinos": carrossel 2×2 (`BldrMyWorkoutsCarousel`), altura constante;
  card com mapa muscular em cima (30% da largura, 40–58 px) e nome/grupos
  embaixo na largura toda — ao lado do mapa ficava ilegível em 320 px.
  Três pontos: Editar / Excluir (Duplicar [F], oculto).
- pt: `=0` explícito no plural ("0 treinos"), pois a regra do pt trata 0 como
  "one".

## Etapa 4 — Editor (179:1590) — plano

- `CreateWorkoutScreen` em modo edição passa a usar `_buildEditorV2()`; a UI
  antiga de edição (cabeçalho, seletores Categoria/Duração, cards antigos,
  rodapé) é removida.
- Cabeçalho `BldrWorkoutHeader`: "EDITAR TREINO", nome, botão "SALVAR".
- Card de identidade: "NOME DO TREINO", nome editável (✎ = Tabler `pencil`
  foca o campo), grupos do treino. **Decisão do usuário:** a Categoria
  continua editável, como fileira de chips (`BldrTypeChip`) no card —
  diverge do mockup para não perder a ação.
- Resumo: Exercícios, Séries, ~Minutos (`WorkoutDurationEstimator`),
  Desc. médio (`BldrHudStats`, valor no degrau 17).
- Card do exercício: número "01" dourado, nome, "•••" (remover exercício),
  grupos, chips séries/reps/descanso (tocáveis, mesmos editores da
  criação), "PERSONALIZAR SÉRIES ›". Expandido: "PADRÃO DO EXERCÍCIO",
  "SÉRIES · PERSONALIZAÇÃO OPCIONAL", linhas carga/reps/"•••",
  "＋ ADICIONAR SÉRIE". Reps em faixa só como exibição.
- Sem miniatura/GIF: o mockup do editor não tem espaço de mídia.
- "Segure para reordenar" oculto. "Adicionar exercício N/M": não existe
  limite de exercícios por treino → mostra só N.
- Salvar em edição usa o estimador (antes: duração do seletor).
- **Feito.** Validado em 320/440 px e textScaler 1,3 (sem overflow). Chips
  e "Padrão do exercício" quebram linha em telas estreitas em vez de cortar.

## Etapa 5 — Treino em andamento + sheets (179:1319, 179:1401, 179:1496) — plano

- Cabeçalho: "● EM ANDAMENTO", nome, TEMPO, "×" = encerrar treino (diálogo
  atual `_stopWorkout`). O voltar do sistema continua pausando.
- HUD: FC (só com batimento recebido; sem "—"), KCAL (`_estimatedCalories`),
  SÉRIE "X de Y" no treino todo, TREINO % (destaque dourado).
- Exercício atual: rótulo, nome, músculos, selo "SÉRIE x/y".
- Execução (P4): GIF atual em loop no container do mockup, sem play; tocar
  abre o detalhe de técnica atual (que mantém o mapa muscular); faixa
  inferior só com "ALVO N reps" (cadência oculta).
- "SUA PRÓXIMA SÉRIE": carga × reps planejadas da série. Ocultos ([F]):
  "PR possível", "Última vez", delta.
- Carga e Reps: cards tocáveis que abrem o `BldrV2Sheet` (novo, reutilizável:
  borda dourada 2 px, raio 46, alça, fundo escurecido) com − / +; tocar no
  número permite digitar; segurar − / + repete. Valor no degrau 32 (mockup
  48). Deltas ocultos.
- Descanso (P3): fora do descanso mostra o descanso da série; descansando,
  contagem regressiva, "+15 s" e "›" (pular).
- "CONCLUIR SÉRIE" com borda dourada.
- Barra inferior: **decisão do usuário** — "Anterior" oculto; "Pausar" =
  pausar e sair (ação do voltar atual); "Próximo: <exercício> ›" = o "Pular"
  de hoje.
- Saem: lista de séries, faixa flutuante de descanso, timeline, chip de
  equipamento e o mapa muscular ao lado do GIF (continua no detalhe de
  técnica).
- **Feito.** Validado em 320/440 px e textScaler 1,3 (tela e sheet de
  carga). Os cards do HUD crescem em altura com fonte grande.

## Etapa 6 — Resumo (211:5) — plano

- Selo "✓ CONCLUÍDO", nome, `completedAtLabel`, frase "Boa sessão…".
- Resumo da sessão: Duração (mm:ss), Volume (milhar + "KG"), Séries,
  Exercícios — métricas sem dado somem (sem "—").
- Destaques: "NOVO PR" (primeiro PR de `newPRs`; "+X kg vs. melhor anterior"
  só com `previousWeightKg`) e "XP GANHO" (`xpEarned`); sem os dois, a seção
  some; com um só, ocupa a largura toda.
- Músculos trabalhados: container do mockup com o `BldrMuscleMap` atual na
  vista dominante; título "Ênfase posterior/anterior"
  (`MuscleNormalizer.dominantView`); frase do .arb com os 2 principais;
  até 3 linhas com ALTO (≥ 0,66) / MODERADO (≥ 0,33) — abaixo disso a linha
  não aparece.
- Ações: "COMPARTILHAR TREINO" (prévia atual) e "CONCLUIR" (volta ao
  início, como o "×" e o "Ir para o início" de hoje).
- Sai: "Compartilhar na comunidade" (vai para o compartilhar, P5) e o card
  "Performance".
- **Feito.** Validado em 320/440 px e textScaler 1,3. Em tela estreita
  (largura útil / escala < 330): métricas em 2×2, destaques empilhados e
  mapa muscular acima dos detalhes. Mais de um PR: mostra o primeiro.
  "Compartilhar na comunidade" volta na etapa 7 (tela de compartilhar).

## Etapa 7 — Compartilhar: Overlay e Card (241:12891, 241:12890) — plano

- `WorkoutSharePreview` v2: "‹", "COMPARTILHAR", subtítulo; abas OVERLAY /
  CARD (substituem Performance, Muscle Map e Minimal); prévia; título e
  texto do formato; "COMPARTILHAR" (exporter atual, 1080 de largura);
  nota "Formato otimizado para Instagram Stories"; "Publicar na comunidade ›"
  (P5) abrindo o `CreatePostScreen` com treino, origem e PRs, como o resumo
  fazia.
- Overlay: canvas 9:16 transparente com logo, mapa frente/costas atual,
  duração/volume/séries e @usuário. Na prévia, o canvas fica sobre um
  fundo escuro com "FUNDO TRANSPARENTE" e a nota de exportação (fora da
  área exportada).
- Card: 9:16 opaco `#050505` com o brilho dourado do fundo oficial, logo,
  @usuário, "WORKOUT COMPLETED", data, mapa frente/costas, métricas,
  divisor e logo no rodapé; exportação 1080 × 1920.
- O enum de domínio `WorkoutShareStyle` e os templates antigos não mudam
  (presentation-only); a tela passa a usar um enum de apresentação.
- Texto **dentro da imagem exportada** segue as proporções do mockup
  (escala pela largura do canvas), não a escala tipográfica da UI: é
  conteúdo de imagem. Textos da tela seguem a escala (mínimo 11).
- Logo: o mockup usa a fonte CODEX (não está no projeto); usa "BL/DR"
  empilhado em Montserrat Bold dourado.
- Sem @usuário (perfil indisponível), a linha some.
- **Feito.** Validado em 320/440 px e textScaler 1,3 nas duas abas.
  Os templates antigos (Performance, Muscle Map, Minimal) ficam no código
  sem uso na tela, junto com o enum de domínio, até uma limpeza aprovada.
