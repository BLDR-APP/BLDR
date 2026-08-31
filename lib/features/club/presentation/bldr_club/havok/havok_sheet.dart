import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_action.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_thread.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_hub.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_memory_sheet.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_action_controller.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/workout_detail_screen.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:bldr_fitness/features/progress/domain/usecases/progress_usecases.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/whoop_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

/// Rótulos legíveis por `originScreen` — usados na saudação, nos divisores
/// de sessão (HAVOK_SPEC.md §4.4) e para escolher as sugestões contextuais.
const Map<String, String> kHavokOriginLabels = {
  'dashboard': 'Dashboard',
  'workouts': 'Treinos',
  'nutrition': 'Nutrição',
  'progress': 'Progresso',
  'weekly_plan': 'Meu Plano',
  'club_treinos': 'Club · Treinos',
  'club_esportes': 'Club · Esportes',
  'club_comunidade': 'Club · Comunidade',
};

/// Abre o hub de conversa do HAVOK como bottom sheet sobre a tela atual.
/// [originScreen] é uma das chaves de [kHavokOriginLabels].
Future<void> showHavokSheet(BuildContext context,
    {required String originScreen}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HavokSheet(originScreen: originScreen),
  );
}

class HavokSheet extends StatefulWidget {
  final String originScreen;

  const HavokSheet({super.key, required this.originScreen});

  @override
  State<HavokSheet> createState() => _HavokSheetState();
}

class _HavokSheetState extends State<HavokSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  HavokThread? _thread;
  List<HavokMessage> _messages = [];
  String? _greeting;
  List<String> _suggestions = const [];
  String? _error;

  static const int _dailyLimit = 10;
  int _dailyCount = 0;
  bool _isClub = false;

  bool get _atLimit => !_isClub && _dailyCount >= _dailyLimit;
  int get _remaining =>
      _isClub ? _dailyLimit : (_dailyLimit - _dailyCount).clamp(0, _dailyLimit);

  @override
  void initState() {
    super.initState();
    _suggestions = _suggestionsFor(widget.originScreen);
    _init();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _suggestionsFor(String originScreen) {
    switch (originScreen) {
      case 'nutrition':
        return const [
          'Quanto falta de proteína hoje?',
          'Sugere uma refeição dentro da minha meta'
        ];
      case 'progress':
        return const [
          'Como está minha evolução?',
          'Minha tendência de peso está boa?'
        ];
      case 'weekly_plan':
        return const [
          'Reorganiza minha semana',
          'Por que esse treino está hoje?'
        ];
      case 'workouts':
        return const [
          'Ajusta o volume do meu treino',
          'Qual grupo muscular estou negligenciando?'
        ];
      case 'club_treinos':
        return const [
          'Como está minha aderência no Club?',
          'Sugere um ajuste no meu treino de hoje'
        ];
      case 'club_esportes':
        return const [
          'Monta um treino pro meu esporte',
          'Como ajusto o protocolo ativo?'
        ];
      case 'club_comunidade':
        return const [
          'Como estou no ranking da semana?',
          'Bora bater uma meta em grupo?'
        ];
      case 'dashboard':
      default:
        return const [
          'Como está minha semana?',
          'O que eu ajusto no meu plano hoje?'
        ];
    }
  }

  Future<void> _init() async {
    try {
      final results = await Future.wait([
        getIt<ResolveClubAccess>()(),
        getIt<GetHavokDailyCount>()(),
        getIt<GetOrCreateTodayThread>()(widget.originScreen),
      ]);

      final hasClubAccess =
          (results[0] as dynamic).valueOrNull as bool? ?? false;
      final count = (results[1] as dynamic).valueOrNull as int? ?? 0;
      final thread = (results[2] as dynamic).valueOrNull;

      if (thread == null)
        throw Exception((results[2] as dynamic).failureOrNull?.message);

      final messagesResult = await getIt<GetThreadMessages>()(thread.id);
      final messages = messagesResult.valueOrNull ?? [];

      String? greeting;
      if (messages.isEmpty) {
        greeting = await _buildGreeting();
      }

      if (mounted) {
        setState(() {
          _isClub = hasClubAccess;
          _dailyCount = count;
          _thread = thread;
          _messages = messages;
          _greeting = greeting;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = AppLocalizations.of(context).havok_error_open;
          _loading = false;
        });
    }
  }

  /// Saudação da thread vazia (HAVOK_SPEC.md §3.1/§7.1): situação da semana +
  /// um padrão detectado + pergunta aberta. Gerada a partir de dado real já
  /// lido no app — nunca hardcoded.
  Future<String> _buildGreeting() async {
    final ctx = await _buildContext();
    final workoutsDone = ctx['workouts']?['completedThisWeek'] as int? ?? 0;
    final workoutsPlanned =
        ctx['planAdherence']?['plannedThisWeek'] as int? ?? 0;
    final proteinPct = ctx['nutrition']?['proteinPercentOfGoal'] as int?;

    final buffer = StringBuffer();
    if (workoutsPlanned > 0) {
      buffer.write(
          'Essa semana você fez $workoutsDone de $workoutsPlanned treinos planejados. ');
    } else if (workoutsDone > 0) {
      buffer.write(
          'Essa semana você já fez $workoutsDone treino${workoutsDone == 1 ? '' : 's'}. ');
    } else {
      buffer.write('Ainda não vi treino seu essa semana. ');
    }

    if (proteinPct != null && proteinPct < 80) {
      buffer.write('Sua proteína hoje está em $proteinPct% da meta. ');
    }

    buffer.write('Quer que eu olhe algo específico?');
    return buffer.toString();
  }

  /// Contexto real do usuário, montado com use cases já existentes
  /// (HAVOK_SPEC.md §2 — a camada 1 é SELECT, sem lógica nova). Passado
  /// direto para a edge function via body.context.
  Future<Map<String, dynamic>> _buildContext() async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final Map<String, dynamic> ctx = {};

    try {
      final weekResult =
          await getIt<GetWeekCompletedWorkouts>()(weekStart, weekEnd);
      final week = weekResult.valueOrNull;
      final completed = (week?.personal.length ?? 0) + (week?.club.length ?? 0);
      ctx['workouts'] = {'completedThisWeek': completed};

      final planResult = await getIt<GetWeeklyPlanConfig>()();
      final plan = planResult.valueOrNull;
      ctx['planAdherence'] = {
        'plannedThisWeek': plan?.frequencyDays ?? 0,
        'completedThisWeek': completed,
      };
    } catch (_) {}

    try {
      final userId = getIt<GetCurrentUser>()()?.id;
      final summaryResult = await getIt<GetDailySummary>()(now);
      final summary = summaryResult.valueOrNull;
      final goalsResult =
          userId == null ? null : await getIt<GetNutritionGoals>()(userId);
      final goals = goalsResult?.valueOrNull;
      if (summary != null && goals != null && goals.protein > 0) {
        ctx['nutrition'] = {
          'date': now.toIso8601String().split('T').first,
          'caloriesConsumed': summary.totals.calories,
          'protein': summary.totals.protein,
          'carbs': summary.totals.carbs,
          'fat': summary.totals.fat,
          'calorieGoal': goals.calories,
          'proteinGoal': goals.protein,
          'carbsGoal': goals.carbs,
          'fatGoal': goals.fat,
          'generatedAt': DateTime.now().toUtc().toIso8601String(),
        };
      }
    } catch (_) {}

    try {
      final weightResult =
          await getIt<GetMeasurements>()(measurementType: 'weight', limit: 1);
      final weights = weightResult.valueOrNull ?? [];
      if (weights.isNotEmpty) {
        ctx['weight'] = {'latestKg': weights.first.value};
      }
    } catch (_) {}

    // BACKLOG_FUNCIONAL.md B7 — fonte única de streak (GetCurrentStreak),
    // somando user_workouts + club_user_workouts.
    try {
      final streakResult = await getIt<GetCurrentStreak>()();
      final streak = streakResult.valueOrNull;
      if (streak != null) {
        ctx['streak'] = {'days': streak, 'at_risk': await _isStreakAtRisk()};
      }
    } catch (_) {}

    // Dados Whoop do dia — só quando conectado e com dado local.
    try {
      final whoopResult = await getIt<GetTodayWhoopData>()();
      final whoop = whoopResult.valueOrNull;
      if (whoop != null) {
        ctx['whoop'] = {
          'recovery': whoop.recoveryScore,
          'strain': whoop.strainScore,
          'sleep': whoop.sleepScore,
          'hrv': whoop.hrvRmssd,
        };
      }
    } catch (_) {}

    try {
      final locale = context.read<LocaleProvider>().locale.languageCode;
      ctx['locale'] = locale;
    } catch (_) {}

    try {
      final profileResult = await getIt<GetOnboardingContext>()();
      final profile = profileResult.valueOrNull;
      if (profile != null && profile.isNotEmpty) {
        ctx['perfil_usuario'] = {
          if (profile['main_goal'] != null) 'objetivo': profile['main_goal'],
          if (profile['experience_level'] != null)
            'nivel': profile['experience_level'],
          if (profile['workout_frequency_days'] != null)
            'dias_treino_semana': profile['workout_frequency_days'],
          if (profile['injuries'] is List &&
              (profile['injuries'] as List).isNotEmpty)
            'lesoes': profile['injuries'],
          if (profile['muscle_focus'] is List &&
              (profile['muscle_focus'] as List).isNotEmpty)
            'foco_muscular': profile['muscle_focus'],
          if (profile['workout_environment'] != null)
            'ambiente': profile['workout_environment'],
          if (profile['gender'] != null) 'sexo': profile['gender'],
          if (profile['age'] != null) 'idade': profile['age'],
        };
      }
    } catch (_) {}

    return ctx;
  }

  /// true se o treino mais recente (pessoal ou Club) não foi hoje.
  Future<bool> _isStreakAtRisk() async {
    final lastResult = await getIt<GetConsolidatedWorkoutHistory>()(
        completedOnly: true, limit: 1);
    final last = lastResult.valueOrNull?.firstOrNull;
    final lastDate = last?.completedAt?.toLocal();
    if (lastDate == null) return true;
    final today = DateTime.now();
    return !(lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day);
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    final thread = _thread;
    if (text.isEmpty || thread == null || _sending) return;

    if (_atLimit) {
      setState(() {
        _messages = [
          ..._messages,
          HavokMessage(
            id: 'local-limit-${DateTime.now().microsecondsSinceEpoch}',
            threadId: thread.id,
            role: 'user',
            content: text,
            createdAt: DateTime.now(),
          ),
          HavokMessage(
            id: 'limit-reply-${DateTime.now().microsecondsSinceEpoch}',
            threadId: thread.id,
            role: 'assistant',
            content:
                'Limite diário atingido ($_dailyLimit mensagens). Assine o BLDR Club para conversar sem limite.',
            createdAt: DateTime.now(),
          ),
        ];
        _greeting = null;
      });
      _inputController.clear();
      _scrollToEnd();
      return;
    }

    setState(() {
      _sending = true;
      _dailyCount = _dailyCount + 1;
      _messages = [
        ..._messages,
        HavokMessage(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          threadId: thread.id,
          role: 'user',
          content: text,
          createdAt: DateTime.now(),
        ),
      ];
      _greeting = null;
    });
    _inputController.clear();
    _scrollToEnd();

    try {
      final context = await _buildContext();
      final result = await getIt<SendHavokMessage>()(
        threadId: thread.id,
        userMessage: text,
        originScreen: widget.originScreen,
        context: context,
      );
      final reply = result.valueOrNull;
      if (reply == null) throw Exception(result.failureOrNull?.message);

      if (mounted) {
        final followUps = reply.responseData?['followUpSuggestions'];
        setState(() {
          _messages = [..._messages, reply];
          if (followUps is List) {
            _suggestions = followUps
                .whereType<String>()
                .where((item) => item.trim().isNotEmpty)
                .take(4)
                .toList();
          }
        });
        _scrollToEnd();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _dailyCount = (_dailyCount - 1).clamp(0, _dailyLimit));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O HAVOK não respondeu. Tente de novo.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _expand() {
    Navigator.of(context).pop();
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const HavokHubScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: BldrColors.bgBase,
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(),
                Expanded(child: _buildBody()),
                _buildInput(),
                _buildDisclaimer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/havoknew.png',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).havok_sheet_title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text(AppLocalizations.of(context).havok_sheet_subtitle,
                    style: TextStyle(
                        color: BldrColors.goldBright,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0)),
              ],
            ),
          ),
          // "Histórico" — nesta fase a thread é diária e já está toda
          // carregada na tela; o ícone rola até o início da conversa.
          IconButton(
            icon: const Icon(Icons.bookmark_border,
                color: BldrColors.textSecondary, size: 20),
            onPressed: () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut);
              }
            },
          ),
          IconButton(
            tooltip: 'Memória HAVOK',
            icon: const Icon(Icons.psychology_outlined,
                color: BldrColors.textSecondary, size: 20),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HavokMemorySheet()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_full,
                color: BldrColors.textSecondary, size: 18),
            onPressed: _expand,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: BldrColors.goldBright));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: BldrText.description));
    }

    final thread = _thread;
    final showOriginDivider = thread != null &&
        thread.originScreen != null &&
        thread.originScreen != widget.originScreen &&
        _messages.isNotEmpty;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (_greeting != null) _AssistantBubble(text: _greeting!, faded: false),
        for (final m in _messages) ...[
          m.isUser
              ? _UserBubble(text: m.content)
              : _AssistantBubble(text: m.content, faded: false),
          if (!m.isUser && m.responseData?['insights'] is List)
            _InsightCards(
                insights:
                    List<dynamic>.from(m.responseData!['insights'] as List)),
          // B6 — artifact_data sobrevive a reload da thread; o card abre o
          // treino gerado na tela com os botões reais (B5 resolvido).
          if (!m.isUser &&
              m.artifactType == 'workout' &&
              m.artifactData != null)
            _WorkoutArtifactCard(
              workoutData: m.artifactData!,
              responseData: m.responseData,
            ),
          if (!m.isUser &&
              (m.artifactType == 'recipe' ||
                  m.artifactType == 'nutrition_plan') &&
              m.artifactData != null)
            _DraftArtifactCard(
              type: m.artifactType!,
              data: m.artifactData!,
            ),
        ],
        if (showOriginDivider)
          _SessionDivider(
              label:
                  'Agora em ${kHavokOriginLabels[widget.originScreen] ?? widget.originScreen}'),
        if (_sending)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BldrColors.goldBright),
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (!_sending) _buildSuggestions(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions.map((s) {
        return BldrChip(
          label: s,
          onTap: () {
            _inputController.text = s;
            _send();
          },
        );
      }).toList(),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Entrada de foto — visual apenas, sem lógica (fora do escopo do L3).
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined,
                color: BldrColors.textMuted, size: 20),
            onPressed: null,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: BldrColors.surfaceInset,
                borderRadius: BldrRadius.all(BldrRadius.input),
                border: Border.all(color: BldrColors.border),
              ),
              child: TextField(
                controller: _inputController,
                enabled: !_atLimit,
                style: BldrText.body,
                cursorColor: BldrColors.goldBright,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: _atLimit
                      ? 'Limite diário atingido'
                      : AppLocalizations.of(context).havok_input_placeholder,
                  hintStyle:
                      BldrText.body.copyWith(color: BldrColors.textMuted),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BldrCircleButton(
            icon: Icons.arrow_upward,
            size: 40,
            onPressed: (_sending || _atLimit) ? null : _send,
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    final showUsage = !_loading && !_isClub;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          if (showUsage)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _atLimit
                    ? 'Limite diário atingido — assine o Club para continuar'
                    : '$_remaining/${_dailyLimit} mensagens restantes hoje',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _remaining <= 3
                      ? BldrColors.goldBright
                      : BldrColors.textMuted,
                  fontSize: 10,
                  fontWeight:
                      _remaining <= 3 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          Text(
            AppLocalizations.of(context).havok_disclaimer,
            textAlign: TextAlign.center,
            style: const TextStyle(color: BldrColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final String text;
  final bool faded;

  const _AssistantBubble({required this.text, required this.faded});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.asset('assets/images/havoknew.png',
                  width: 26, height: 26, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: BldrColors.surface,
                  border: Border.all(color: BldrColors.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(text, style: BldrText.body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: BldrColors.goldTintStrong,
              border: Border.all(color: BldrColors.goldBorder),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Text(text, style: BldrText.body),
          ),
        ),
      ),
    );
  }
}

class _SessionDivider extends StatelessWidget {
  final String label;

  const _SessionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider(color: BldrColors.borderSubtle)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style:
                    const TextStyle(color: BldrColors.textMuted, fontSize: 10)),
          ),
          const Expanded(child: Divider(color: BldrColors.borderSubtle)),
        ],
      ),
    );
  }
}

class _InsightCards extends StatelessWidget {
  final List<dynamic> insights;

  const _InsightCards({required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 34, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: insights.take(4).whereType<Map>().map((raw) {
          final item = Map<String, dynamic>.from(raw);
          return SizedBox(
            width: 150,
            child: BldrGlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title']?.toString() ?? 'Insight',
                      style: BldrText.description),
                  const SizedBox(height: 4),
                  Text(item['value']?.toString() ?? '--',
                      style: BldrText.cardTitle
                          .copyWith(color: BldrColors.goldBright)),
                  if (item['period'] != null)
                    Text(item['period'].toString(),
                        style: const TextStyle(
                            fontSize: 10, color: BldrColors.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Recipe and nutrition-plan artifacts are drafts. They are intentionally
/// visual-only here: a user action must be confirmed before any existing
/// nutrition use case is called.
class _DraftArtifactCard extends StatelessWidget {
  final String type;
  final Map<String, dynamic> data;

  const _DraftArtifactCard({required this.type, required this.data});

  @override
  Widget build(BuildContext context) {
    final recipe = type == 'recipe';
    final title = (data['nome'] ??
            data['name'] ??
            (recipe ? 'Receita sugerida' : 'Plano alimentar sugerido'))
        .toString();
    final ingredients = data['ingredientes'] ?? data['ingredients'];
    final meals = data['meals'];
    final subtitle = recipe
        ? '${ingredients is List ? ingredients.length : 0} ingredientes'
        : '${meals is List ? meals.length : 0} refeições planejadas';
    return Padding(
      padding: const EdgeInsets.only(left: 34, bottom: 8),
      child: BldrGlassCard(
        borderColor: BldrColors.goldBorder,
        child: Row(
          children: [
            Icon(recipe ? Icons.restaurant_menu : Icons.menu_book_outlined,
                color: BldrColors.goldBright),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BldrText.cardTitle),
                  Text('$subtitle · revise antes de salvar',
                      style: BldrText.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutArtifactCard extends StatelessWidget {
  final Map<String, dynamic> workoutData;
  final Map<String, dynamic>? responseData;

  const _WorkoutArtifactCard({
    required this.workoutData,
    this.responseData,
  });

  @override
  Widget build(BuildContext context) {
    final name = (workoutData['nome'] ?? workoutData['name'] as String?)
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? (workoutData['nome'] ?? workoutData['name']).toString()
        : 'Treino gerado';
    final exerciseCount =
        ((workoutData['exercicios'] ?? workoutData['exercises']) as List?)
                ?.length ??
            0;
    final canonical = workoutData['canonical'] == true &&
        ((workoutData['exercicios'] ?? workoutData['exercises']) as List?)
                ?.every(
                    (item) => item is Map && item['exercise_id'] is String) ==
            true;
    final actions = const HavokActionController()
        .supportedActions(responseData, hasCanonicalWorkout: canonical);

    return Padding(
      padding: const EdgeInsets.only(left: 34, bottom: 8),
      child: BldrGlassCard(
        borderColor: BldrColors.goldBorder,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => WorkoutDetailScreen(workoutData: workoutData)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(TablerIcons.barbell,
                    color: BldrColors.goldBright, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: BldrText.cardTitle),
                      Text(
                          AppLocalizations.of(context)
                              .havok_workout_exercises_tap(exerciseCount),
                          style: BldrText.meta),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: BldrColors.textMuted, size: 18),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions
                    .map((action) => BldrChip(
                          label: action.label,
                          onTap: () => _confirmAction(context, action),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction(
      BuildContext context, HavokActionProposal action) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BldrColors.surface,
        title: const Text('Confirmar ação', style: BldrText.sectionTitle),
        content: Text(
            '${action.label} será preparado para você confirmar no treino.',
            style: BldrText.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuar')),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    final actionWorkout =
        const HavokActionController().workoutForAction(workoutData, action);
    if (actionWorkout == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(workoutData: actionWorkout),
        ));
  }
}
