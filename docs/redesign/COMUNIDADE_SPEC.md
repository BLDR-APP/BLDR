# BLDR — Comunidade: Spec de Implementação

Referências visuais: `comunidade_v2_mockup.html` e `comunidade_criar_post_mockup.html`.
Design system: `lib/theme/bldr_tokens.dart` + `lib/design_system/bldr_components.dart`.
Imports sempre absolutos: `package:bldr_fitness/...`
Ao final de cada fase: `dart analyze lib && flutter test test/features`

---

## Estado atual

- `lib/features/club/presentation/comunidade/comunidade_screen.dart` — tela placeholder "Em breve"
- `lib/services/community_service.dart` — tem `fetchFeed`, `fetchAnnouncements`, `fetchEvents`; não tem nada para `community_feed`
- Banco: tabelas `community_feed`, `community_reactions`, `community_comments` já criadas
- Banco: `complete_workout_with_analytics` já insere em `community_feed` para `pr_beaten`
- `ArenaRepository` e `ArenaRepositoryImpl` existem para squad/check-in

---

## Fase 1 — Entidades e repositório do feed

**Arquivos a criar:**
- `lib/features/community/domain/entities/community_post.dart`
- `lib/features/community/domain/repositories/community_feed_repository.dart`
- `lib/features/community/data/repositories/community_feed_repository_impl.dart`

### community_post.dart

```dart
enum CommunityEventType {
  workoutCompleted,
  prBeaten,
  streakMilestone,
  levelUp,
  squadJoined,
  challengeCompleted,
  manual, // post manual do usuário
}

class CommunityPost {
  final String id;
  final String userId;
  final String? username;
  final String? userFullName;
  final String? userAvatarUrl;
  final CommunityEventType eventType;
  final Map<String, dynamic> payload;
  final String visibility; // 'public' | 'squad' | 'private'
  final DateTime createdAt;
  final List<CommunityReaction> reactions;
  final int commentCount;
  final String? myReactionEmoji; // emoji que o usuário atual reagiu, ou null

  const CommunityPost({
    required this.id,
    required this.userId,
    this.username,
    this.userFullName,
    this.userAvatarUrl,
    required this.eventType,
    required this.payload,
    required this.visibility,
    required this.createdAt,
    this.reactions = const [],
    this.commentCount = 0,
    this.myReactionEmoji,
  });

  // helpers de payload
  String get workoutName => payload['workout_name'] ?? 'Treino concluído';
  int? get durationSeconds => payload['duration_s'] as int?;
  double? get volumeKg => (payload['volume_kg'] as num?)?.toDouble();
  List<String> get muscleGroups =>
      (payload['muscle_groups'] as List?)?.cast<String>() ?? [];
  String? get exerciseName => payload['exercise_name'] as String?;
  double? get prWeightKg => (payload['weight_kg'] as num?)?.toDouble();
  int? get prReps => payload['reps'] as int?;
  double? get e1rm => (payload['e1rm'] as num?)?.toDouble();
  int? get streakDays => payload['days'] as int?;
  String? get caption => payload['caption'] as String?;
  String? get photoUrl => payload['photo_url'] as String?;
  String? get activityType => payload['activity_type'] as String?;

  String get displayName => username != null ? '@$username' : (userFullName ?? 'Atleta');
  String get authorName => userFullName ?? username ?? 'Atleta';

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final profile = json['user_profiles'] as Map<String, dynamic>?;
    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: profile?['username'] as String?,
      userFullName: profile?['full_name'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String?,
      eventType: _parseEventType(json['event_type'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      visibility: json['visibility'] as String? ?? 'public',
      createdAt: DateTime.parse(json['created_at'] as String),
      reactions: (json['reactions'] as List?)
              ?.map((r) => CommunityReaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      commentCount: json['comment_count'] as int? ?? 0,
      myReactionEmoji: json['my_reaction'] as String?,
    );
  }

  static CommunityEventType _parseEventType(String raw) {
    switch (raw) {
      case 'workout_completed': return CommunityEventType.workoutCompleted;
      case 'pr_beaten': return CommunityEventType.prBeaten;
      case 'streak_milestone': return CommunityEventType.streakMilestone;
      case 'level_up': return CommunityEventType.levelUp;
      case 'squad_joined': return CommunityEventType.squadJoined;
      case 'challenge_completed': return CommunityEventType.challengeCompleted;
      default: return CommunityEventType.manual;
    }
  }
}

class CommunityReaction {
  final String emoji;
  final int count;
  const CommunityReaction({required this.emoji, required this.count});

  factory CommunityReaction.fromJson(Map<String, dynamic> json) =>
      CommunityReaction(
        emoji: json['emoji'] as String,
        count: json['count'] as int,
      );
}
```

### community_feed_repository.dart

```dart
abstract class CommunityFeedRepository {
  /// Feed público — paginado por cursor (created_at)
  Future<List<CommunityPost>> fetchFeed({
    int limit = 20,
    DateTime? before,
  });

  /// Publicar post manual
  Future<void> createPost({
    required String eventType, // 'manual'
    required Map<String, dynamic> payload,
    // payload contém: caption?, photo_url?, workout_id?, activity_type?,
    // whoop_strain?, whoop_fc?, whoop_kcal?, duration_s?
    required String visibility,
  });

  /// Reagir ou retirar reação
  Future<void> toggleReaction({
    required String feedId,
    required String emoji,
  });

  /// Copiar treino de um post para workout_templates do usuário
  /// Retorna o id do novo template criado
  Future<String> copyWorkout({required String workoutId, required String source});

  /// Streak milestone — inserir post automático (chamado pelo Flutter após detectar milestone)
  Future<void> postStreakMilestone({required int days});
}
```

### community_feed_repository_impl.dart

Implementa `CommunityFeedRepository` usando `SupabaseClient`:

- `fetchFeed`: SELECT em `community_feed` com join em `user_profiles` (username, full_name, avatar_url). Agregar reações via subquery ou RPC. Filtrar `visibility = 'public'`. Ordenar por `created_at DESC`. Paginar com `.lt('created_at', before)` quando cursor presente.

- `createPost`: INSERT em `community_feed` com `user_id = auth.uid()`, `event_type`, `payload`, `visibility`.

- `toggleReaction`: verificar se já existe em `community_reactions` para (feed_id, user_id, emoji). Se sim, DELETE. Se não, INSERT. Usar `ON CONFLICT DO NOTHING`.

- `copyWorkout`: chamar RPC `copy_workout_to_template(p_workout_id, p_source)` — **esta RPC ainda não existe, criar no banco na Fase 2**.

- `postStreakMilestone`: INSERT em `community_feed` com `event_type = 'streak_milestone'`, `payload = {days: N}`.

Registrar em `injection.dart`:
```dart
getIt.registerLazySingleton<CommunityFeedRepository>(
  () => CommunityFeedRepositoryImpl(SupabaseService.instance.client),
);
```

**Ao final: dart analyze lib**

---

## Fase 2 — RPC copy_workout_to_template (banco)

Executar no SQL Editor do Supabase BLDR:

```sql
CREATE OR REPLACE FUNCTION public.copy_workout_to_template(
  p_workout_id UUID,
  p_source TEXT DEFAULT 'free'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_template_id UUID;
  v_workout_name TEXT;
BEGIN
  -- Buscar nome do treino
  IF p_source = 'club' THEN
    SELECT COALESCE(wt.name, 'Treino copiado')
    INTO v_workout_name
    FROM public.club_user_workouts cuw
    LEFT JOIN public.club_workout_templates wt ON wt.id = cuw.workout_template_id
    WHERE cuw.id = p_workout_id;
  ELSE
    SELECT COALESCE(wt.name, 'Treino copiado')
    INTO v_workout_name
    FROM public.user_workouts uw
    LEFT JOIN public.workout_templates wt ON wt.id = uw.workout_template_id
    WHERE uw.id = p_workout_id;
  END IF;

  -- Criar template novo para o usuário
  INSERT INTO public.workout_templates (user_id, name, is_public)
  VALUES (v_user_id, v_workout_name || ' (cópia)', false)
  RETURNING id INTO v_template_id;

  -- Copiar exercícios
  IF p_source = 'club' THEN
    INSERT INTO public.workout_template_exercises
      (workout_template_id, exercise_id, exercise_db_id, free_name, sets, reps, weight_kg, rest_seconds, sort_order)
    SELECT
      v_template_id,
      wes.exercise_id,
      NULL, -- club não tem exercise_db_id
      wes.free_name,
      COUNT(*),
      MAX(wes.reps),
      MAX(wes.weight_kg),
      90,
      ROW_NUMBER() OVER (ORDER BY MIN(wes.created_at))
    FROM public.club_workout_exercise_sets wes
    WHERE wes.user_workout_id = p_workout_id
    GROUP BY wes.exercise_id, wes.free_name;
  ELSE
    INSERT INTO public.workout_template_exercises
      (workout_template_id, exercise_id, exercise_db_id, free_name, sets, reps, weight_kg, rest_seconds, sort_order)
    SELECT
      v_template_id,
      wes.exercise_id,
      wes.exercise_db_id,
      wes.free_name,
      COUNT(*),
      MAX(wes.reps),
      MAX(wes.weight_kg),
      90,
      ROW_NUMBER() OVER (ORDER BY MIN(wes.created_at))
    FROM public.workout_exercise_sets wes
    WHERE wes.user_workout_id = p_workout_id
    GROUP BY wes.exercise_id, wes.exercise_db_id, wes.free_name;
  END IF;

  RETURN v_template_id;
END;
$$;
```

Verificar que as colunas da tabela `workout_template_exercises` batem com o schema real. Ajustar nomes se necessário antes de executar.

---

## Fase 3 — ComunidadeScreen: Feed

Substituir o placeholder em `lib/features/club/presentation/comunidade/comunidade_screen.dart`.

**Estrutura da tela:**

```
BldrBackground
└── Scaffold
    ├── CustomScrollView
    │   ├── SliverAppBar (pinned: false, floating: true)
    │   │   └── header: título "Comunidade" + ícones (troféu → ranking, sino → notificações)
    │   ├── SliverToBoxAdapter
    │   │   ├── _TabBar (Explorar | Seguindo | Squads)
    │   │   ├── _SearchBar (decorativo por ora — busca na Fase 6)
    │   │   └── _ActiveChallengeStrip (hardcoded vazio se sem desafio ativo)
    │   └── SliverList (posts do feed)
    │       └── _FeedCard (por tipo de post)
    └── FAB dourado (+) — só na tab Explorar
        └── abre CreatePostScreen (Fase 5)
```

**_TabBar:**
- Tabs: "Explorar", "Seguindo", "Squads"
- "Seguindo" e "Squads": ao tocar, mostrar SnackBar "Em breve" por ora
- Underline dourado no tab ativo, texto `BldrColors.goldBright`

**Carregamento do feed:**
```dart
late final CommunityFeedRepository _repo;
List<CommunityPost> _posts = [];
bool _loading = true;
DateTime? _cursor;
bool _hasMore = true;

Future<void> _loadFeed() async {
  final posts = await _repo.fetchFeed(limit: 20, before: _cursor);
  setState(() {
    _posts.addAll(posts);
    _cursor = posts.isEmpty ? _cursor : posts.last.createdAt;
    _hasMore = posts.length == 20;
    _loading = false;
  });
}
```

Scroll infinito: `NotificationListener<ScrollNotification>` — ao atingir 80% do scroll, chamar `_loadFeed()` se `_hasMore && !_loading`.

**_FeedCard — lógica por tipo:**

Todos os cards compartilham o mesmo header:
```
Avatar circular (36px) + nome + @handle + tempo relativo ("há 12 min")
```

Para `workoutCompleted`:
- Título: nome do treino (payload['workout_name'])
- Caption: payload['caption'] se não nulo
- Foto: payload['photo_url'] se não nulo — `ClipRRect(borderRadius: 12) + CachedNetworkImage`
- Stats row: chips de duração + volume + séries (só os que existirem no payload)
- Muscle tags: payload['muscle_groups']
- Card "Ver treino" com link → `_showWorkoutDetail` (sheet, Fase 4)
- Reactions row

Para `prBeaten`:
- Badge "🏆 NOVO PR" no header
- Card dourado com: nome do exercício + peso + reps + e1RM estimado

Para `streakMilestone`:
- Badge "🔥 STREAK" laranja (#FF6432) no header
- Número grande de dias

Para `manual`:
- Caption do usuário
- Foto se houver
- Card de treino se payload['workout_id'] existir
- Card de atividade se payload['activity_type'] existir

**Rivalry card:**
- Inserir fixo na posição 3 do feed (após o 2º post)
- Buscar usuário com streak similar via query simples:
  ```dart
  // Buscar no Supabase: user com streak próximo ao meu
  // SELECT id, full_name, username FROM user_profiles
  // WHERE id != auth.uid()
  // ORDER BY ABS(streak - meu_streak) ASC LIMIT 1
  ```
- Se não encontrar rival, não exibir o card

**Reactions row:**
- 4 emojis fixos: 🔥 💪 ⚡ 🏆
- Tocar: `_repo.toggleReaction(feedId: post.id, emoji: emoji)` + atualizar estado otimista
- Botão "Comentar": por ora abre SnackBar "Comentários disponíveis para membros Club" se Free, ou sheet vazio se Club

**Ao final: dart analyze lib && flutter test test/features**

---

## Fase 4 — Sheet de detalhe do treino + copiar

Criar `lib/features/community/presentation/workout_detail_sheet.dart`.

Aberto via `showModalBottomSheet` ao tocar em "Ver treino →" no feed.

```
WorkoutDetailSheet(
  workoutId: String,
  source: String, // 'free' | 'club'
  workoutName: String,
)
```

**Conteúdo do sheet:**

1. Handle + título do treino
2. Stats (duração, volume, séries) em chips
3. Músculos em tags
4. Lista de exercícios com séries e cargas — buscar via:
   ```dart
   // SELECT exercise_id, free_name, weight_kg, reps, completed_at
   // FROM workout_exercise_sets (ou club_workout_exercise_sets)
   // WHERE user_workout_id = workoutId
   // ORDER BY created_at
   ```
   Agrupar por exercício, mostrar sets com peso × reps
5. Botão "Copiar treino" (dourado, largura total):
   - Free: verificar contador mensal em SharedPreferences (`workout_copies_YYYY_MM`)
   - Se >= 3: mostrar SnackBar "Você atingiu o limite de 3 cópias este mês. Faça upgrade para Club"
   - Se < 3: chamar `_repo.copyWorkout(workoutId, source)` + incrementar contador + SnackBar "Treino copiado para Meus Treinos ✓"
   - Club: sem limite, copiar direto

**Ao final: dart analyze lib**

---

## Fase 5 — CreatePostScreen

Criar `lib/features/community/presentation/create_post_screen.dart`.

Tela completa (não sheet) — push via `Navigator.push`.

**Estrutura:**
```
Scaffold
├── AppBar: × fechar | "Criar post" | [Publicar] dourado (desabilitado se vazio)
├── Body (SingleChildScrollView)
│   ├── Composer area: avatar + @username + TextField multilinha
│   ├── IconBar: 🏋️ Treino | 🤸 Atividade | ⌚ Wearable | 📷 Foto | ··· Mais
│   └── ContentArea (muda por ícone ativo):
│       ├── Treino → _WorkoutSelector
│       ├── Atividade → _ActivitySelector
│       ├── Wearable → _WearableImporter
│       ├── Foto → ImagePicker (galeria)
│       └── Mais → sheet com Local/Data (decorativos por ora)
└── Footer fixo: [🌐 Todos ▾] visibilidade | [Publicar]
```

**State:**
```dart
String? _caption;
String? _photoPath; // caminho local
CommunityPost? _selectedWorkout; // treino selecionado (último 5)
String? _selectedActivity; // tipo de atividade
Map<String, dynamic>? _wearableData; // dados importados
String _visibility = 'public';
bool _includePrs = true; // toggle nos PRs do treino
int _activeIcon = 0; // 0=treino 1=atividade 2=wearable 3=foto 4=mais
```

**_WorkoutSelector:**
- Buscar últimos 5 treinos concluídos:
  ```dart
  // SELECT id, name, completed_at, volume_kg, muscle_groups, source
  // FROM user_workouts WHERE is_completed = true
  // ORDER BY completed_at DESC LIMIT 5
  ```
- Lista de cards clicáveis com nome + data + volume
- Ao selecionar: exibir preview rico acima da lista (nome, stats, músculos, toggle de PRs)
- "Trocar" no preview volta a mostrar a lista

**_ActivitySelector:**
- Grid 3 colunas com busca
- Atividades: Musculação, Corrida, Ciclismo, Calistenia, HIIT, Boxe, Jiu-Jitsu, Natação, Yoga, Basquete, Tênis, Surf, Futebol, Caminhada, Crossfit, Pilates, Funcional, Volêi, Padel, Corrida, Trilha, Escalada
- Ícones: emoji representativo de cada atividade
- Ao selecionar: exibir card compacto com nome + campos manuais (duração, distância se cardio, calorias)

**_WearableImporter:**
Verificar wearables conectados e dados recentes:

```dart
Future<Map<String, dynamic>?> _detectWearableData() async {
  // 1. Whoop: buscar whoop_daily_data mais recente (hoje)
  // Se strain > 0 → retornar {source: 'whoop', strain, fc_media, calorias, duracao_min}
  
  // 2. HealthKit (iOS): chamar HealthKitService para workout recente (últimas 3h)
  // Se encontrar → retornar {source: 'apple_health', duracao_min, calorias, fc_media}
  
  return null; // sem dados
}
```

Exibir:
- Se Whoop conectado + dados: card vermelho com strain/FC/kcal + botão "Importar"
- Se Apple Health autorizado: card com duração/kcal + botão "Importar"  
- Garmin: "Em breve"
- Ao importar: preencher campos do post com os dados

**Publicar:**
```dart
Future<void> _publish() async {
  final payload = <String, dynamic>{
    if (_caption?.isNotEmpty == true) 'caption': _caption,
    if (_photoPath != null) 'photo_url': await _uploadPhoto(),
    if (_selectedWorkout != null) ...{
      'workout_id': _selectedWorkout!.payload['workout_id'],
      'workout_name': _selectedWorkout!.workoutName,
      'source': _selectedWorkout!.payload['source'],
      'duration_s': _selectedWorkout!.durationSeconds,
      'volume_kg': _selectedWorkout!.volumeKg,
      'muscle_groups': _selectedWorkout!.muscleGroups,
      if (_includePrs) 'include_prs': true,
    },
    if (_selectedActivity != null) 'activity_type': _selectedActivity,
    if (_wearableData != null) ..._wearableData!,
  };

  await _repo.createPost(
    eventType: 'manual',
    payload: payload,
    visibility: _visibility,
  );

  Navigator.pop(context);
}
```

Upload de foto: `SupabaseClient.storage.from('community-posts').upload(...)` → retorna URL pública.

**Visibilidade sheet:**
- Botão "🌐 Todos ▾" no footer abre `showModalBottomSheet`
- Opções: Todos / Só meu squad / Só eu
- Radio buttons estilo iOS

**Conectar FAB → CreatePostScreen:**
Em `comunidade_screen.dart`:
```dart
FloatingActionButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CreatePostScreen()),
  ).then((_) => _loadFeed()), // recarrega feed ao voltar
  backgroundColor: BldrColors.goldSolid,
  child: const Icon(Icons.add, color: Colors.black),
)
```

**Ao final: dart analyze lib && flutter test test/features**

---

## Fase 6 — Integração com WorkoutSummaryScreen

Em `lib/features/workouts/presentation/workouts_screen/workout_summary_screen.dart`, adicionar botão "Compartilhar na comunidade" abaixo do botão "Compartilhar treino" existente:

```dart
OutlinedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CreatePostScreen(
        preselectedWorkoutId: widget.data.workoutId,
        preselectedSource: widget.data.source,
      ),
    ),
  ),
  icon: const Icon(Icons.people_outline),
  label: const Text('Compartilhar na comunidade'),
  style: OutlinedButton.styleFrom(
    foregroundColor: BldrColors.goldBright,
    side: const BorderSide(color: BldrColors.goldBorder),
    padding: const EdgeInsets.symmetric(vertical: 13),
  ),
)
```

`CreatePostScreen` precisa aceitar parâmetros opcionais `preselectedWorkoutId` e `preselectedSource` para pré-selecionar o treino recém-concluído.

**Ao final: dart analyze lib**

---

## Fase 7 — Squad: card de importação de wearable no check-in

O sheet de check-in existente (`CreateCheckinSheet` em `arena_details_screen.dart` ou arquivo próprio) deve receber um card condicional no topo.

Localizar o sheet e adicionar no `initState`:

```dart
Future<void> _detectWearable() async {
  // Mesma lógica do _WearableImporter da Fase 5
  // Busca dados Whoop/HealthKit das últimas 3h
  final data = await _fetchRecentWearableData();
  if (data != null && mounted) {
    setState(() => _wearableData = data);
  }
}
```

No build do sheet, antes dos campos manuais:
```dart
if (_wearableData != null)
  _WearableImportCard(
    data: _wearableData!,
    onImport: () => setState(() {
      // Preencher campos existentes do sheet com os dados
      _durationController.text = (_wearableData!['duration_min'] ?? 0).toString();
      _caloriesController.text = (_wearableData!['calorias'] ?? 0).toString();
      // etc.
      _wearableData = null; // esconder card após importar
    }),
    onDismiss: () => setState(() => _wearableData = null),
  ),
```

`_WearableImportCard` é um widget reutilizável — criar em `lib/features/community/presentation/widgets/wearable_import_card.dart`:
- Fundo com tint da cor do wearable (vermelho para Whoop, neutro para Apple Health)
- Fonte: nome do wearable + dados detectados
- Botões: [Importar] [Ignorar]

**Ao final: dart analyze lib && flutter test test/features**

---

## Fase 8 — Ranking

Criar `lib/features/community/presentation/ranking_screen.dart`.

Acessado pelo ícone de troféu no header da tela de Comunidade.

**Estrutura:**
```
BldrBackground
└── Scaffold
    ├── AppBar: ← voltar | "Ranking"
    └── Body
        ├── Seletor de período: Semana | Mês | Geral (segmented control)
        ├── Seletor de categoria: Volume total | Consistência | Progressão (chips horizontais)
        ├── Card "Sua posição" (dourado):
        │   ├── #posição + nome + volume/stat da categoria
        │   ├── Barra de progresso até próxima posição
        │   └── Variação vs período anterior (↑3)
        ├── Card de rival automático (se encontrado)
        └── Lista top 10:
            ├── Pódio visual (1º, 2º, 3º) com alturas diferentes
            └── Lista compacta 4–10 + "···" + posição do usuário
```

**Dados:**
- Query: `SELECT user_id, SUM(volume_kg) as total, COUNT(*) as workouts FROM user_workouts WHERE is_completed = true AND completed_at >= [início_período] GROUP BY user_id ORDER BY total DESC LIMIT 50`
- Para Free: exibir só top 10 + posição própria. Linhas 11–(posição-1) ficam ocultas com "···"
- Para Club: ranking completo
- Verificar subscription via `UserSubscription` já carregada no app

**Rival automático:**
- Do resultado da query, encontrar usuário com `ABS(total - meu_total)` menor, excluindo o próprio usuário
- Exibir card: "⚡ [Nome] está X ton à frente — Desafiar"
- "Desafiar" → SnackBar "Em breve" por ora (duelos são feature futura)

**Ao final: dart analyze lib && flutter test test/features**

---

## Checklist pós-implementação

Testar manualmente na seguinte ordem:

| Cenário | Esperado |
|---|---|
| Abrir Comunidade → feed carrega | Posts aparecem ou empty state |
| Scroll até o fim | Mais posts carregam (paginação) |
| Tocar em reação | Emoji ativa/desativa otimisticamente |
| Tocar em "Ver treino" | Sheet abre com exercícios |
| Tocar "Copiar treino" (Free, 1ª vez) | Copia + contador incrementa |
| Tocar "Copiar treino" (Free, 4ª vez) | Paywall snackbar |
| FAB → CreatePostScreen | Tela abre |
| Selecionar treino no composer | Preview rico aparece |
| Selecionar atividade | Grid de tipos aparece |
| Tocar Wearable com Whoop conectado | Card com dados detectados |
| Importar do Whoop | Campos preenchidos |
| Publicar post | Volta ao feed + post novo aparece |
| WorkoutSummaryScreen → "Compartilhar na comunidade" | CreatePostScreen abre com treino pré-selecionado |
| Squad → abrir sheet de check-in (Whoop conectado) | Card de importação aparece |
| Importar no check-in do squad | Campos preenchidos |
| Troféu → RankingScreen | Abre com dados |
| Free no ranking | Só top 10 + posição própria visível |

---

## Notas críticas para o Codex

1. **Não alterar** `ArenaRepository`, `ArenaRepositoryImpl` nem `CreateCheckinSheet` — só adicionar o card de wearable, nada mais
2. **Não alterar** `complete_workout_with_analytics` — já está correta
3. **Não alterar** lógica de subscription — usar o que já existe no app
4. A tabela `community_feed` usa RLS — o `CommunityFeedRepositoryImpl` usa o client autenticado do Supabase normalmente
5. Upload de foto para comunidade: usar bucket `community-posts` — criar o bucket no Supabase Dashboard antes de testar (Storage → New bucket → community-posts → Public)
6. Imports absolutos em todos os arquivos novos: `package:bldr_fitness/...`
7. Registrar `CommunityFeedRepository` no `injection.dart` antes de qualquer tela usar
