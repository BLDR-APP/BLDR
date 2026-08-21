# Guia da Nova Estrutura — Onde Encontrar as Coisas

> Guia prático do dia a dia. A explicação conceitual e o histórico da migração
> estão no [ARCHITECTURE.md](ARCHITECTURE.md).

## O mapa em 30 segundos

```
lib/
  main.dart                ← inicialização (Firebase, Supabase, Stripe, DI)
  core/                    ← infraestrutura compartilhada
    di/injection.dart      ← registro de TODAS as dependências (get_it)
    errors/                ← Failure e Result<T>
    constants/             ← constantes (ex.: onboarding)
  features/                ← o app, dividido por assunto
    <feature>/
      domain/              ← entidades + contratos + use cases (regras de negócio)
      data/                ← implementações que falam com Supabase/Firebase
      presentation/        ← TELAS e widgets da feature
  shared/presentation/     ← telas que usam várias features ao mesmo tempo
  routes/app_routes.dart   ← rotas nomeadas (não mudou)
  theme/                   ← AppTheme (não mudou)
  widgets/                 ← widgets globais reutilizáveis (não mudou)
  services/                ← LEGADO: hoje são "datasources" internos dos
                             repositories. Não chamar de telas novas.
  models/                  ← LEGADO: modelos antigos (ex.: subscription_plan)
```

## "Quero mexer na tela X" — tabela de localização

| Tela | Onde está agora |
|---|---|
| Login / Cadastro / OTP / Nova senha / Confirmação de e-mail | `lib/features/auth/presentation/` |
| Nutrição (diário, modal de comida, busca, água) | `lib/features/nutrition/presentation/nutrition_screen/` |
| Treinos (lista, criar, treino ativo, plano semanal, banner) | `lib/features/workouts/presentation/workouts_screen/` |
| Progresso (medidas, gráficos, relatório) | `lib/features/progress/presentation/progress_screen/` |
| Conquistas (toast, provider, galeria) | `lib/features/achievements/presentation/achievements/` |
| BLDR Club (tudo: treinos, comunidade, ranking, arenas, corrida, HAVOK…) | `lib/features/club/presentation/bldr_club/` |
| Checkout / pagamento | `lib/features/subscription/presentation/checkout_screen/` |
| Perfil / drawer | `lib/features/profile/presentation/profile_drawer/` |
| Portal profissional | `lib/features/professional_portal/presentation/screens/` |
| **Dashboard** | `lib/shared/presentation/dashboard/` |
| **Splash** | `lib/shared/presentation/splash_screen/` |
| **Onboarding** | `lib/shared/presentation/onboarding_flow/` |

Dashboard, splash e onboarding ficam em `shared/` porque consomem várias
features ao mesmo tempo — não pertencem a nenhuma delas.

## Anatomia de uma feature (exemplo: workouts)

```
lib/features/workouts/
  domain/
    entities/              ← WorkoutTemplate, WorkoutSession, WorkoutSet…
                             (classes puras, sem Supabase, sem Flutter)
    repositories/          ← INTERFACES: o que a feature sabe fazer
    usecases/              ← uma classe por operação (StartWorkout, CompleteSet…)
  data/
    datasources/           ← queries cruas ao Supabase
    models/                ← conversão map ↔ entidade (WorkoutModels)
    repositories/          ← implementação das interfaces do domain
  presentation/
    workouts_screen/       ← as telas
    mappers/legacy_ui_maps.dart ← conversores TEMPORÁRIOS entidade→map
                             para widgets antigos (não usar em código novo)
```

## Como uma tela busca dados (o padrão)

```dart
// 1. importe o DI e os use cases da feature
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';

// 2. chame o use case e trate o Result
final result = await getIt<GetWorkoutTemplates>()();
result.fold(
  onSuccess: (templates) => setState(() => _templates = templates),
  onFailure: (failure) => _showError(failure.message), // mensagem já em pt-BR
);
```

Regras de ouro:
- **Nunca** `Supabase.instance` ou `XService.instance` dentro de tela.
- Usuário logado: `getIt<GetCurrentUser>()()` (feature auth).
- Erro nunca é string crua: é `Failure` com `message` pronto para exibir.

## Onde estão as regras de negócio (exemplos)

| Regra | Arquivo |
|---|---|
| XP por refeição + bônus diário (4 refeições) | `features/nutrition/domain/usecases/nutrition_usecases.dart` (`LogMeal`) |
| Fim de duelo (fechar + notificar vencedor/perdedor) | `features/club/data/repositories/challenge_repository_impl.dart` (`checkActiveDuel`) |
| Cálculo de macros (regra de 3 por 100g) | `features/nutrition/domain/entities/macro_nutrients.dart` |
| Salvar corrida (registro + XP) | `features/club/` (`saveRun` no `ClubWorkoutRepository`) |
| Checagem de versão mínima | `features/app_version/domain/app_version_repository.dart` |

## Imports

Tudo dentro de `lib/` usa **imports absolutos**:
`import 'package:bldr_fitness/features/.../arquivo.dart';`
Não use mais imports relativos (`../../...`) — evita quebrar quando um arquivo muda de pasta.

## E a pasta `lib/services/`?

É **legado em extinção**. Os services que sobraram (workout, club_workouts,
progress, achievement, payment, user, auth…) são usados **somente por dentro
dos repositories** (estratégia "strangler"). Para o seu dia a dia:

- Precisa de um dado? Procure o **use case** na feature. Se não existir,
  adicione método no repository da feature — não chame o service da tela.
- `NotificationService` / `PushNotificationService` são infraestrutura de
  dispositivo e continuam como serviços (via `getIt`).

## Para criar uma feature nova

1. Crie `lib/features/<nome>/{domain,data,presentation}`.
2. Entidades e interface do repository no `domain/`.
3. Datasource + implementação no `data/`.
4. Registre tudo em `lib/core/di/injection.dart`.
5. Telas em `presentation/`, consumindo só use cases.
6. Testes em `test/features/<nome>/` com repository fake (exemplos prontos em
   `test/features/auth/` e `test/features/nutrition/`).

## Dívidas conhecidas (não estranhe ao encontrar)

- `mappers/legacy_ui_maps.dart` em algumas features: conversores temporários
  entidade→map para widgets ainda não tipados.
- `ArenaRepository` (Club) trafega maps crus e as telas o consomem direto,
  sem use cases — tipagem pendente.
- `bldr_club_screen.dart` mantém um canal realtime do Supabase (XP ao vivo).
- Portal profissional ainda não tem camada `domain/` (adiado a pedido).

Detalhes e status por fase: [ARCHITECTURE.md](ARCHITECTURE.md).
