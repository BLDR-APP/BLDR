# Nutrição v2 — Auditoria e plano

> Auditoria **somente leitura** (2026-11-19). Nenhum código foi alterado.
> Fontes: Figma Nutrition Hub `z6plKSVOCah3uDI1Abaxbe` (frames vigentes `102:*`
> e `119:*`, lidos por `get_metadata` + `get_design_context`) e o documento
> `BLDR_Nutrition_Hub_v1.0.md`, cujas decisões [APROVADO] valem. Os frames
> ocultos `2:2`, `2:8`, `7:278`, `16:2`, `23:2` e `83:*` foram ignorados.

## 1. Mapa do código atual

| Camada | Arquivo | Backend |
|---|---|---|
| Tela | `lib/features/nutrition/presentation/nutrition_screen/nutrition_screen.dart` | — |
| Resumo + IQD | `.../widgets/daily_nutrition_overview_widget.dart` | — |
| Timeline de refeições | `.../widgets/meal_timeline_widget.dart` | — |
| Água | `.../widgets/water_intake_widget.dart` | Supabase `user_water_intake` (via `features/progress`) |
| Adicionar alimento | `.../widgets/food_categories_modal.dart` → `.../widgets/Firebase/firebase_add_food_modal_widget.dart` (1119 linhas) | Firestore |
| Scanner | `.../widgets/barcode_scanner_page.dart` e uma 2ª cópia dentro do `firebase_add_food_modal_widget.dart` | `mobile_scanner` |
| Busca antiga | `.../widgets/nutrition_search_widget.dart` e `firebase_nutrition_search_widget.dart` (não estão em nenhuma tela; aparentemente órfãos) | `NutritionService` legado |
| IQD | `lib/services/iqd_calculator_service.dart` | — |
| Domínio | `domain/entities/{meal_entry,food_item,macro_nutrients,nutrition_goals,user_goals}.dart`, `domain/usecases/nutrition_usecases.dart` | — |
| Dados | `data/datasources/firestore_nutrition_datasource.dart` (`alimentos`, `user_favorites`, `user_meals`, `user_daily_bonuses`), `supabase_nutrition_goals_datasource.dart` (`user_profiles.onboarding_data`), `supabase_xp_datasource.dart` | Firestore + Supabase |
| Metas | `lib/features/profile/presentation/goals_screen.dart` | Supabase |

Use cases que já existem: `SearchFoods`, `GetCategoryFoods`, `GetFavoriteFoods`,
`SaveFavoriteFood`, `GetRecentFoods`, `GetNutritionGoals`, `GetUserGoals`,
`SaveUserGoals`, `GetMealsForDate`, `GetDailySummary`, `DeleteMealEntry`,
`UpdateMealQuantity` e `LogMeal`. Água: `GetDailyWaterIntake` e `LogWater`.

## 2. Matriz tela × situação

Legenda: **Existe** · **Parcial** (há função, falta visual ou regra) ·
**Ausente** (sem código) · **Backend** (exige coleção, API ou serviço novo).

| # | Tela / fluxo (Figma) | Situação | O que existe hoje | Lacuna |
|---|---|---|---|---|
| 1 | Hub — header, anel kcal, anéis de macro (102:312/309) | Parcial | Overview com kcal e macros; dados de `DailyNutritionSummary` | Visual v2 inteiro; pílula "HOJE ›" (navegar entre dias não existe) |
| 2 | Hub — card IQD com faixa e "↑ X pontos vs. semana" | Parcial | Score diário do `IqdCalculatorService` e blur para FREE | Rótulo "MUITO BOM" (as faixas atuais são Ótimo/Regular/Ruim); barra 60–100; **comparação semanal: Backend/Ausente** (não há histórico de IQD) |
| 3 | Hub — card Hidratação | Parcial | `WaterIntakeWidget` (meta, atalhos, remover o último) | Visual v2; meta lida via Supabase direto na tela (viola regra 1); `_incrementWater` do hub só soma +250 local (TODO) |
| 4 | Hub — pílulas por refeição (6 tipos) | Parcial | Timeline com 5 tipos (sem **Pós-treino** no domínio visual) | Pós-treino; ícones Tabler; formato de pílula |
| 5 | Refeição expandida 14:2 (+ vazia 102:297) | Parcial | `_showMealDetailModal` abre um sheet com lista e adicionar | Expandir inline no hub; cards de macro por refeição; menu "⋯" |
| 6 | FAB "+" (oculto com refeição expandida ou sheet aberto, 180–220 ms) | Ausente | — | Presentation-only |
| 7 | Add Food Sheet 102:316 (busca, 4 atalhos, 16 categorias, Recentes) | Parcial | `FoodCategoriesModal` (categorias) → modal com abas Recentes / Favoritos / Manual e busca por prefixo | Layout v2; atalhos; "VER TODOS" |
| 8 | Recentes e Favoritos unificado 102:317 | Existe (dados) / Parcial (UI) | `GetRecentFoods` (reconstruído de `user_meals`, sem duplicatas, 15 itens), `GetFavoriteFoods` | Favoritar/desfavoritar um alimento do catálogo: hoje só o cadastro manual vira favorito |
| 9 | Refeições salvas 102:318/319/320 | Backend | — | Entidade, coleção, criação (o Figma não mostra como criar), use cases |
| 10 | País / banco de alimentos 119:58/261 | Backend | Só a base `alimentos` (PT-BR, nomes em caixa alta) | Bases US/CA/IT; região do dispositivo; persistência da escolha |
| 11 | Porção 102:308 (±, Porção/Unidade, g/ml, "por 40 g", ADICIONAR EM) | Parcial | Diálogo com quantidade, g/un e peso por unidade (padrão 50 g) | **ml** (a base é só gramas); "Porção" padrão por alimento; chips de refeição dentro do sheet |
| 12 | Editar 102:301 | Parcial | Lápis do item → `_showEditOrDeleteModal` → `FirebaseAddFoodModalWidget(isEditing)` → `UpdateMealQuantity` | Visual v2; trocar a refeição de destino (o use case só muda a quantidade) |
| 13 | Remover 102:300 | Existe (função) | `DeleteMealEntry` + SnackBar | `BldrV2ConfirmDialog`; aviso de impacto no IQD; Undo (Toast) |
| 14 | Código de barras: scanner 102:306, encontrado 102:303, não encontrado 102:299 | Parcial / Backend | `mobile_scanner` lê o código. A busca `NutritionService.searchByBarcode` está num widget órfão, e o modal atual só lê o código | Não há base de códigos (sem Open Food Facts nem coluna `barcode` confirmada no Firestore); digitação manual; flash |
| 15 | Foto/IA 102:305/304/302/298 | Backend | `image_picker` está no pubspec, mas não há nada em Nutrição | Serviço de visão (Edge Function + LLM), limites, custo, regra CLUB |
| 16 | Cadastro manual 102:296/166/167 (2 passos) | Parcial | Aba "Manual" do modal (nome, kcal automático por macros, P/C/G; salva em `user_favorites`) | Marca, tipo sólido/líquido, por unidade, fibras/sódio/açúcar no formulário, 2 passos |
| 17 | Copiar refeição 102:313/314/315 | Ausente | — | Use case novo (lote de `LogMeal` com data e refeição de destino); sem backend novo |
| 18 | Adicionar água 102:311 | Parcial | Atalhos 150/250/350/500 e personalizado | Presets 200/300/500; visual v2 |
| 19 | Sucesso ao adicionar 102:307 | Parcial | SnackBar e popup de achievements | Ver conflito de posição no §5 |

## 3. Respostas

**1. Lápis em "Refeições de hoje" e "⋯" da refeição expandida.**
No app atual, o cabeçalho "Refeições de hoje" (`meal_timeline_widget.dart`) tem
título e contador, e não há lápis. Os dois botões do cabeçalho (câmera e busca)
fazem a mesma coisa: `onAddMeal(_suggestedMealType())`. A **câmera não abre
câmera**. O único lápis (`Icons.edit_rounded`) fica em cada item de alimento e
abre `_showEditOrDeleteModal`, com "Editar quantidade" e "Remover item". O menu
"⋯" não existe. No Figma, nem o lápis do cabeçalho nem o "⋯" têm frame de
destino. A única ação que pode vir do "⋯" é Copiar refeição (102:313).
→ Pergunta em aberto Q1.

**2. IQD.** A fórmula fica em `lib/services/iqd_calculator_service.dart` e é
chamada pelo `daily_nutrition_overview_widget.dart`:
- Começa em 60 pontos.
- Fibra: +40 proporcional até 25 g.
- Sódio: −20 proporcional entre 2000 e 3000 mg.
- Açúcar adicionado: −20 proporcional entre 50 e 100 g.
- O resultado fica entre 0 e 100. Faixas: ≥75 "Ótimo", ≥50 "Regular", abaixo disso "Ruim".

As dicas aparecem com sódio > 2000, fibra < 15 e açúcar > 50. É um cálculo
diário, sem persistência e sem média semanal. O IQD fica em `lib/services`
(legado) e não no domínio, apesar de ser regra de negócio.

**3. Metas.** kcal e macros vêm de `GetNutritionGoals`
(`supabase_nutrition_goals_datasource`, que lê `user_profiles.onboarding_data`),
com fallback `NutritionGoals.defaults`. São editadas em
`lib/features/profile/presentation/goals_screen.dart` (`SaveUserGoals`). A meta
de **água** não está em `NutritionGoals`: o `water_intake_widget` lê
`onboarding_data` direto pelo Supabase (padrão de 2500 ml) e nenhuma tela a
edita. O texto do Figma ("ajustada nas configurações de Nutrição") aponta para
uma tela que não existe.

**4. Recursos.**
- **Seletor de país/banco alimentar:** não existe.
- **Código de barras:** só a leitura, com `mobile_scanner`. Não há base de
  produtos ligada.
- **Foto/IA:** não existe (`image_picker` está no pubspec, sem uso em Nutrição).
- **Refeições salvas:** não existe.
- **Copiar refeição:** não existe.
- **Favoritos:** existe (`user_favorites`, só para alimentos manuais).
- **Recentes:** existe (derivados de `user_meals`).

**5. FREE x CLUB.** O acesso é resolvido por `ResolveClubAccess` em
`nutrition_screen.dart`. A única barreira real é o **card de IQD**: para FREE,
ele fica com blur e cadeado, e o toque leva a `AppRoutes.checkoutScreen`. O
`isClub` é repassado ao `FoodCategoriesModal` e ao `FirebaseAddFoodModalWidget`,
mas não é usado para bloquear nada. O documento do usuário não define a regra de
Foto/IA, scanner e refeições salvas. → Q4.

**6. Snapshot nutricional.** **Sim.** `MealEntry` (Firestore `user_meals`) grava
`foodName` e os **totais** de macros da quantidade consumida (kcal, P, C, G,
sódio, fibra, açúcar adicionado), além de `foodItemId`. Editar o catálogo não
altera o histórico. Limitação: não guarda os valores por 100 g, a unidade (g/ml/un)
nem o peso da unidade. `per100g` é reconstruído por engenharia reversa, e a edição
de uma entrada "por unidade" volta como gramas.

## 4. Violações de regra encontradas (dívida, fora do visual)

- `nutrition_screen.dart` usa `Supabase.instance.client.auth.currentUser` e
  `FirebaseAuthService` na apresentação (regras 1 e 8).
- `water_intake_widget.dart` lê `user_profiles` via Supabase direto (regra 1).
- Há duas classes `BarcodeScannerPage` duplicadas e widgets de busca órfãos que
  usam `NutritionService`.
- O IQD está em `lib/services` e não em `domain/`.

## 5. Conflitos e perguntas em aberto

| # | Pergunta |
|---|---|
| Q1 | O lápis de "Refeições de hoje" faz o quê? (Reordenar ou ocultar refeições? Editar tipos?) E o "⋯" tem só "Copiar refeição" ou também "Salvar como refeição" / "Limpar refeição"? |
| Q2 | **Conflito:** o sucesso de adição (102:307) é uma pílula **embaixo**; o Toast System [APROVADO] define topo, abaixo da safe area. Proposta: seguir o Toast System (topo) e tratar 102:307 como ilustrativo. |
| Q3 | **Conflito:** a barra de hidratação é azul no hub (102:312) e dourada no sheet (102:311). Qual vale? Proposta: azul nos dois (identidade de água). |
| Q4 | Regra FREE x CLUB para Foto/IA, scanner, refeições salvas, país e cópia. |
| Q5 | Foto/IA: qual provedor, limite diário, e onde roda (Edge Function obrigatória, sem chave no app)? |
| Q6 | Código de barras: usar Open Food Facts (gratuito, com cobertura BR variável) ou uma base própria? "Cadastrar alimento" a partir do não encontrado grava o código para todos ou só para o usuário? |
| Q7 | Países US/CA/IT: de onde vêm as bases? Importação para o Firestore `alimentos_<país>` ou uma API? |
| Q8 | Refeições salvas: como são criadas? O Figma só mostra listar, detalhar e adicionar. |
| Q9 | IQD: renomear as faixas para o padrão do Figma ("MUITO BOM"...) e manter a fórmula? A comparação semanal exige persistir o IQD diário (tabela nova). |
| Q10 | A meta de água entra em `NutritionGoals` e passa a ser editada em `goals_screen` (ou numa tela nova de "configurações de Nutrição")? |
| Q11 | Pílula "HOJE ›": navegar para dias anteriores está no escopo? (`GetMealsForDate` já aceita uma data.) |

## 6. Plano incremental

Pré-requisito: **Toast fase T1** (ver `TOAST_V2.md`), para que sucesso, erro e
Undo de Nutrição já nasçam no sistema novo.

| Fase | Área | Tipo | Conteúdo | Critério de aceite |
|---|---|---|---|---|
| N0 | Tokens e componentes | V | Tokens v2 de Nutrição em `bldr_tokens.dart`; componentes: anel de macro, card de métrica, pílula de refeição, linha de alimento, FAB | `dart analyze` limpo; nenhum `Color(0x…)` em widget |
| N1 | Hub | V | Header, anéis, IQD (só o score diário, sem a linha semanal), Hidratação, pílulas, refeição expandida inline, vazia, FAB com regra de ocultar | Igual a 102:312/309/297 em 440 px; sem overflow em 320 e em 320 com escala 1,3; FREE continua com blur no IQD |
| N2 | Add Food + Recentes/Favoritos + Porção + Editar/Remover | V | Reescrever os sheets com `BldrV2Sheet` e `BldrV2ConfirmDialog`; atalhos sem função aparecem conforme Q4 ou ficam ocultos | Adicionar, editar e remover continuam funcionando; Undo via Toast |
| N3 | Água | V+F pequeno | Sheet 102:311; corrigir o +250 local do hub para `LogWater`; mover a leitura da meta para um repository | Toque no "+" do hub persiste; nenhum `Supabase.instance` na tela |
| N4 | Cadastro manual 2 passos | F | Marca, sólido/líquido (ml), por unidade, micronutrientes | Alimento salvo com `per100` correto; aparece em Favoritos |
| N5 | Copiar refeição | F | Use case `CopyMeal(from, toDate, toMealType)` + teste com repository fake; sheets 102:313/314/315 | Cópia não substitui itens existentes; quantidades preservadas |
| N6 | Código de barras | F + Backend | Depois de Q6: datasource de produtos, encontrado e não encontrado, digitação manual, flash | Código real de produto BR encontrado; o não encontrado leva ao cadastro |
| N7 | Refeições salvas | F + Backend | Depois de Q8 | — |
| N8 | País | F + Backend | Depois de Q7 | Região do dispositivo (nunca GPS); escolha persiste; troca afeta só novas buscas |
| N9 | Foto/IA | F + Backend | Depois de Q5 e Q4 | Revisar antes de adicionar; tela de não identificado |
| N10 | IQD semanal | Backend | Depois de Q9 | — |

Cada fase termina com `dart analyze lib`, `TZ=UTC flutter test test/features`,
render em 320, 440 e 320 com escala 1,3, e comparação com o `get_screenshot` do node.

### O que testar no aparelho
- Adicionar alimento por categoria, por recentes e por favoritos; conferir anéis e IQD atualizados.
- Editar a quantidade (g e unidade), remover e desfazer pelo Toast.
- Expandir uma refeição: o FAB some e volta com animação; abrir um sheet: o FAB some.
- Água: o "+" do hub persiste após reabrir o app; atalhos e valor personalizado.
- Conta FREE vs. CLUB: blur do IQD e checkout.
- Scanner (N6): permissão de câmera negada/concedida, flash, código inexistente.
- Teclado aberto nos sheets de porção e cadastro sem overflow (iPhone SE).

## 7. N7 — Refeições salvas: proposta (não implementada)

A estrutura atual não tem onde guardar uma refeição salva: `user_meals` é o
diário (um documento por alimento consumido, com data) e `user_favorites`
guarda alimentos avulsos por 100 g. Nenhum campo agrupa vários alimentos sob
um nome reutilizável.

**Como se criaria (proposta):** no "⋯" da refeição expandida, ao lado de
"Copiar refeição", uma ação "Salvar como refeição" que pede um nome e grava
os alimentos atuais (nome, `food_item_id`, quantidade e macros totais, igual
ao snapshot do diário). A lista 102:318 lê essas refeições; 102:319/320
adicionam ao diário reaproveitando `CopyMeal`.

**Opções de dado (precisa de aprovação):**
- A) Coleção nova `user_saved_meals` `{user_id, name, items: [...], created_at}`.
- B) Reusar `user_favorites` com `type: 'meal'` e `items` — evita coleção nova,
  mas exige que o leitor de favoritos ignore `type == 'meal'`
  (mudança em `favorites()`).

## 8. Estado final (rodada de Nutrição v2)

### Implementado
| Área | Frames | Commit(s) |
|---|---|---|
| Hub (anéis, IQD semanal, hidratação, 6 refeições, refeição expandida, lápis de edição, FAB, seletor de data) | 102:312/309, 14:2, 102:297 | N1 `6868428` |
| Adicionar, Recentes/Favoritos, Porção, Editar, Remover | 102:316/317/308/301/300 | N2 `668a422` |
| Água (sheet, meta por repository) | 102:311 | N3 `6075bdf` |
| Cadastro manual 2 passos, ml e por unidade | 102:296/166/167 | N4 `ea14ea2`, `4b0188d` |
| Copiar refeição | 102:313/314/315 | N5 `57eeb69` |
| Refeições salvas (criar, usar, excluir) | 102:318/319/320 | N7 `6ba72c6`, `6373991` |
| País (Brasil, EUA, Canadá) | 119:58/261 | N8 `29c3413` |
| Busca sem diferenciar maiúsculas/acentos | — | `68e6ef5` |
| Toasts de Nutrição (adicionado, removido c/ Desfazer, erros, metas) | Toast 53:184 | T3 `1258976`, T4 `6483640` |

### Em breve (visível e desabilitado, sem fluxo)
- **Código de barras** e **Foto/IA** (atalhos do sheet de adicionar).
- **Itália** no seletor de país (coleção ainda não populada).

### Diferenças em relação aos mockups
- Textos de 7–10 px subiram para o mínimo de 11; colunas dos anéis de macro com 70 px (62 no Figma).
- Telas estreitas: cards de macro empilhados, macros dos alimentos em 2ª linha, chips em várias linhas, atalhos 2 × 2.
- Ícone do HAVOK saiu do cabeçalho (acesso pela NavBar).
- Carrossel de categorias usa as categorias reais de cada base (BR 16; EUA/Canadá 22 cada), não os nomes ilustrativos do Figma.
- Porção: g e ml selecionáveis em Porção e Unidade (padrão = base do alimento). Quando difere da base, o cálculo assume **1 ml ≈ 1 g** e mostra a nota; campo de peso da unidade aparece no modo Unidade.
- Linhas de alimento do catálogo mostram valores por 100 g/ml (a base não tem porção padrão).
- Refeições salvas: destino por chips (não dropdown); excluir sem frame (estilo de "Remover alimento"); sem edição de nome.
- Sucesso de adição por toast no topo (não a pílula inferior de 102:307).
- Modo de edição do lápis sem frame (mínimo: editar/remover por alimento).

### Dados (Firestore, sem coleção nova)
- `user_favorites`: alimentos (com `brand`, `unit`, `unit_weight`, `unit_description` opcionais) e refeições salvas (`type: 'meal'`). Único leitor: datasource de Nutrição, que filtra `type: 'meal'` (`foodsOnly`).
- `user_meals`: `unit: 'ml'` opcional para líquidos; ausente = g.
- Preferências no aparelho: país do banco e marca diária do toast de meta calórica.

### IQD e açúcar
O IQD é calculado na hora, somando os registros do dia, mas usa o **snapshot** de cada registro (`added_sugar` gravado no momento em que o alimento foi lançado). A nova leitura de açúcar (`added_sugars` no BR, `sugars_per_100g` nos EUA/Canadá) só vale para registros novos: **os dias passados não mudam** (registros antigos do catálogo BR têm açúcar 0 gravado).

### Dívidas conhecidas
- EUA/Canadá usam **açúcar total** como se fosse adicionado (aproximação aprovada; penaliza mais).
- ml em alimento de base g (e vice-versa) usa **1 ml ≈ 1 g** (aprovado): erro baixo em bebidas/iogurte, alto em óleo (~8%) e mel (~40%).
- Dois documentos do BR com chaves digitadas errado (`calories_per_1A00g`, `fat_per_1B00g`) — correção de dados no Firestore.
- Catálogo em memória por sessão: alimento novo na base só aparece na busca após reabrir o app.
- Textos fixos fora do `.arb` mantidos na T5 (lista em `TOAST_V2.md` §6).
- `NutritionService` legado ainda registrado no DI (sem uso em telas); `mobile_scanner` sem uso até a N6.
- Toasts de meta de hidratação e proteína seguem "uma vez por cruzamento" (só a calórica é diária persistida).
