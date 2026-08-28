# Relatório — HAVOK (estado atual)

_Gerado em 31/07/2026 a partir do código na branch `main`._

HAVOK é a marca da **IA do BLDR**. Hoje ele existe em duas camadas bem
distintas:

1. **Feature funcional** — um hub dentro do BLDR Club que gera treinos e
   receitas via Google Gemini (edge functions Supabase).
2. **Marca/persona** — o nome aparece espalhado em textos de onboarding,
   esportes, trackers e planos de performance, sem passar pela feature acima.

---

## 1. Mapa de arquivos

### 1.1 Camada de apresentação (Flutter)

Tudo em `lib/features/club/presentation/bldr_club/havok/`:

| Arquivo | Papel |
|---|---|
| [havok_hub.dart](lib/features/club/presentation/bldr_club/havok/havok_hub.dart) | Tela principal. Mascote 3D + módulo de treino + módulo de nutrição. Também define as cores globais `goldColor`, `darkBackgroundColor`, `cardBackgroundColor` que **todas** as outras telas HAVOK importam daqui. |
| [free_workout_screen.dart](lib/features/club/presentation/bldr_club/havok/free_workout_screen.dart) | Campo de texto livre → gera treino sob demanda. |
| [workout_library_screen.dart](lib/features/club/presentation/bldr_club/havok/workout_library_screen.dart) | Lista de treinos já gerados (modelo local `SavedWorkout`). |
| [workout_detail_screen.dart](lib/features/club/presentation/bldr_club/havok/workout_detail_screen.dart) | Exibe `nome` + lista de `exercicios` (série x reps). Somente leitura. |
| [recipe_results_screen.dart](lib/features/club/presentation/bldr_club/havok/recipe_results_screen.dart) | Resultado da receita + macros + FAB para salvar. |
| [recipe_library_screen.dart](lib/features/club/presentation/bldr_club/havok/recipe_library_screen.dart) | Lista de receitas salvas (modelo local `SavedRecipe`). |
| [widgets/panther_fab.dart](lib/features/club/presentation/bldr_club/havok/widgets/panther_fab.dart) | **Única porta de entrada** do hub: FAB da pantera no BLDR Club. |

### 1.2 Domínio / dados

| Arquivo | Conteúdo |
|---|---|
| [havok_repository.dart](lib/features/club/domain/repositories/havok_repository.dart) | Contrato com 6 métodos, todos em `Result<T>`. Payloads propositalmente `Map<String, dynamic>` (saída schemaless do modelo). |
| [havok_repository_impl.dart](lib/features/club/data/repositories/havok_repository_impl.dart) | Invoca as edge functions e lê as tabelas do schema `bldr_club`. Tem `_guard` que mapeia `PostgrestException` / `FunctionException` / `SocketException` / `TimeoutException` para `Failure` pt-BR. |
| [club_usecases.dart:442-487](lib/features/club/domain/usecases/club_usecases.dart:442) | Use cases `GenerateFreeWorkout`, `GenerateHavokWorkout`, `GenerateHavokRecipe`, `SaveHavokRecipe`, `GetHavokRecipes`, `GetHavokWorkouts` — todos wrappers finos sobre o repository. |
| [injection.dart:250-259](lib/core/di/injection.dart:250) | `HavokRepository` como lazy singleton (client Supabase + closure do user id); os 6 use cases como factories. |

### 1.3 Backend (Supabase Edge Functions, Deno)

| Função | O que faz |
|---|---|
| [gerar-treino-havok](supabase/functions/gerar-treino-havok/index.ts) | Lê `user_profiles.onboarding_data`, monta prompt personalizado (`generateHavokPrompt`), chama Gemini, **salva** em `bldr_club.havok_workouts` e devolve a linha salva. |
| [gerar-treino-livre](supabase/functions/gerar-treino-livre/index.ts) | Mesma coisa, mas o prompt vem do usuário (`userPrompt`), sem ler o perfil. Também salva em `havok_workouts`. |
| [gerar-receita-havok](supabase/functions/gerar-receita-havok/index.ts) | Lê `dietary_preferences` do onboarding, gera receita com macros. **Não salva** — só retorna o JSON. |
| [salvar-receita-havok](supabase/functions/salvar-receita-havok/index.ts) | Recebe `recipeData` e insere em `bldr_club.havok_recipes`. Trata conflito `23505` como "já está na sua biblioteca". |
| [gerar-plano-performance](supabase/functions/gerar-plano-performance/index.ts) | Usa a persona HAVOK no prompt (linha 43), mas **não pertence à feature** — é chamada por `UserService`, fora do `HavokRepository`. |

Todas registradas em `supabase/config.toml` com `verify_jwt = true`.

### 1.4 Assets

- `assets/models/HAVOKNEW.glb` — mascote 3D, renderizado com `model_viewer_plus` no hub.
- `assets/images/havoknew.png` — imagem do FAB.
- Também existem, sem referência no código Dart: `assets/models/Havok_Pantera.glb`, `havok_splash.png`, `havokperfil.jpg`. `assets/images/havok.png` foi deletado (aparece em `git status`) e nada mais o referencia.

---

## 2. Como está funcionando (fluxos)

### 2.1 Entrada

`BldrClubScreen` → `floatingActionButton: const PantherFab()`
([bldr_club_screen.dart:253](lib/features/club/presentation/bldr_club/bldr_club_screen.dart:253)) → `HavokHubScreen`.

Não há rota nomeada nem outro ponto de acesso ao hub.

### 2.2 Treino HAVOK (personalizado)

```
Botão "GERAR TREINO HAVOK"
  → GenerateHavokWorkout()            (Result<void>)
  → functions.invoke('gerar-treino-havok')
  → edge: getUser → user_profiles.onboarding_data
          → generateHavokPrompt(...)  (gênero, objetivo, experiência, frequência,
                                       duração, ambiente/equipamentos, foco, split)
          → Gemini 2.5 Flash
          → strip de ```json → JSON.parse
          → insert em bldr_club.havok_workouts
  → app navega para WorkoutLibraryScreen, que faz GetHavokWorkouts() do zero
```

O prompt pede explicitamente **um único dia de treino**, 5–8 exercícios, sem
aquecimento/descanso/notas, e JSON no formato
`{ "nome": ..., "exercicios": [{ "nome", "series", "repeticoes" }] }`.

Enquanto carrega, o hub mostra três mensagens encadeadas por timer
("Buscando informações do seu perfil…" → "Gerando…" → "Tudo pronto…").

### 2.3 Treino livre

`FreeWorkoutScreen` → `GenerateFreeWorkout(prompt)` → `gerar-treino-livre` →
salva igual ao anterior → `pushReplacement` para `WorkoutDetailScreen` usando
`data['workout_data']` da resposta.

### 2.4 Nutrição

```
TextField "Quais ingredientes tem aí?" (ou os 4 atalhos:
Pós-treino / Café da manhã / Almoço / Jantar)
  → GenerateHavokRecipe(query) → gerar-receita-havok (não persiste)
  → RecipeResultsScreen (descrição, macros, ingredientes, preparo)
  → FAB "salvar" → SaveHavokRecipe(recipeData) → salvar-receita-havok
  → RecipeLibraryScreen → GetHavokRecipes()
```

### 2.5 Persistência

Schema `bldr_club`, tabelas:

- `havok_workouts` — `user_id`, `workout_name`, `workout_data` (jsonb), `created_at`
- `havok_recipes` — `user_id`, `recipe_name`, `recipe_data` (jsonb), `created_at`

Leitura no app é filtrada por `user_id` e ordenada por `created_at desc`.
**Não há migração dessas tabelas no repositório** — foram criadas direto no
painel do Supabase.

### 2.6 A "marca" HAVOK fora da feature

- **Onboarding** ([onboarding_flow.dart](lib/shared/presentation/onboarding_flow/onboarding_flow.dart)): opção de split "Deixa a HAVOK decidir", textos explicativos, e a tela de conclusão com "Montando sua divisão de treino com o HAVOK…" — que é **apenas animação**, não dispara geração.
- **Esportes** ([esportes_screen.dart](lib/features/club/presentation/bldr_club/esportes_screen.dart)): `HavokInputWidget` / "DESAFIE O HAVOK" chama `UserService.generatePerformancePlan` → `gerar-plano-performance`. Passa por `UserService`, não pelo `HavokRepository`.
- **Trackers** ([match_tracker_screen.dart:836](lib/features/club/presentation/bldr_club/trackers/match_tracker_screen.dart:836)): faixa "Gerar ficha de treino com Havok" — o `onTap` só faz dois `Navigator.pop()` para voltar à tela de esportes. Não gera nada.
- **Arena** ([arena_details_screen.dart:162](lib/features/club/presentation/bldr_club/arena_details_screen.dart:162)): "DIRETRIZES DO HAVOK" são textos estáticos de regras.
- **Weekly plan / club workout**: `'HAVOK Decide'` como label de preferência de split.

---

## 3. Estado / pendências

### Bloqueadores de produto

1. **Paywall não existe.** [panther_fab.dart:17](lib/features/club/presentation/bldr_club/havok/widgets/panther_fab.dart:17) tem `final bool isPremiumUser = true;` hardcoded, com TODO para a tela de upsell. Hoje HAVOK é liberado para todo mundo.
2. **Treino gerado é beco sem saída.** `WorkoutDetailScreen` só lista exercícios — não vira template, não inicia sessão, não conecta com `club_active_workout_screen` nem com o plano semanal. O usuário gera e não consegue executar.
3. **Onboarding promete e não entrega.** A tela de conclusão diz que está montando a divisão com o HAVOK, mas nada é gerado ali; o primeiro treino só nasce se o usuário achar o FAB da pantera.
4. **Faixa do match tracker é falsa.** Promete gerar ficha e só navega para trás.

### Dívidas técnicas / desvios do CLAUDE.md

5. **Regra 1 violada**: `havok_hub.dart:42` usa `UserService.instance.getCurrentUserProfile()` direto na presentation.
6. **Regra 7 violada**: não há nenhum teste em `test/features/club/` cobrindo HAVOK (nem repository fake, nem use cases).
7. **Erros engolidos**: `free_workout_screen.dart:48` e `havok_hub.dart:223` só fazem `print`/`debugPrint`. Como o repository devolve `Result` (não lança), o `catch` nunca dispara — a falha vira tela parada sem feedback. O `Failure.message` em pt-BR já existe e não é usado.
8. **`GenerateHavokWorkout` retorna `Result<void>`** e descarta o treino que a edge function acabou de devolver; a biblioteca refaz o SELECT logo em seguida. Um round-trip desperdiçado.
9. **Parsing frágil**: `SavedWorkout.fromMap` / `SavedRecipe.fromMap` assumem `id`, `workout_name`, `workout_data` não-nulos — linha incompleta derruba a tela. Em `workout_detail_screen.dart:32`, `exercise['repeticoes']` é castado para `String`: se o modelo devolver `12` em vez de `"12"`, dá `TypeError`.
10. **JSON do modelo sem contrato forte**: as três funções de geração dependem de `.replace(/```json/g,'')` + `JSON.parse`. O Gemini suporta `responseMimeType: application/json` / response schema, que eliminaria essa classe de erro.
11. **Sem migração versionada** para `bldr_club.havok_workouts` / `havok_recipes` — schema só existe no ambiente remoto.
12. **`GOOGLE_AI_KEY` vai na query string** da URL do Gemini nas 3 funções (padrão da API, mas aparece em logs de rede/erro).
13. **Plano de performance fora da feature**: `gerar-plano-performance` deveria estar sob `HavokRepository`; hoje está em `UserService` (legado em extinção, regra 6).
14. **Sem rate limit / custo**: nada impede o usuário de apertar "GERAR TREINO HAVOK" indefinidamente; cada toque é uma chamada paga ao Gemini + um INSERT.
15. **Duplicação**: `gerar-treino-havok` e `gerar-treino-livre` são ~90% o mesmo arquivo (só muda a montagem do prompt).
16. **Cores hardcoded**: `goldColor` e companhia vivem dentro de `havok_hub.dart` e são importadas por telas e pelo FAB — acoplamento invertido; deveriam estar no theme.

### Funcionando bem

- Repository/use cases seguem o padrão `Result<Failure, T>` corretamente, com mapeamento de exceções do Supabase.
- DI registrado do jeito certo em `injection.dart`.
- Edge functions usam `ANON_KEY` + header `Authorization` do usuário, então RLS continua valendo (nenhuma usa service role).
- `verify_jwt = true` em todas as funções HAVOK.
- Prompts são detalhados e realmente aproveitam o `onboarding_data` (ambiente, equipamentos, foco muscular, split, objetivo).

---

## 4. Se for mexer, a ordem que faz sentido

1. Ligar o treino gerado ao executor de treino (item 2) — é o que trava o valor da feature.
2. Implementar o gate premium real no `PantherFab` (item 1).
3. Superfície de erro: usar `Failure.message` nas 4 telas (item 7).
4. Resolver a promessa do onboarding — gerar o primeiro treino de verdade ali (item 3).
5. Testes de unidade com `HavokRepository` fake (item 6, regra do projeto).
6. Endurecer o parsing: response schema no Gemini + `fromMap` defensivo (itens 9 e 10).
