// lib/features/club/presentation/bldr_club/create_arena_screen.dart
import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'dart:math';

class CreateArenaScreen extends StatefulWidget {
  const CreateArenaScreen({super.key});

  @override
  State<CreateArenaScreen> createState() => _CreateArenaScreenState();
}

class _CreateArenaScreenState extends State<CreateArenaScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingQuota = true;

  // Quota state (client-side best-effort; server-side RPC pending migration 00028)
  bool _isClub = false;
  int _createdThisMonth = 0;
  static const _freeCreateLimit = 2;

  // Configurações Padrão
  String _selectedMode = 'hustle';
  int _durationDays = 7;
  String _selectedValidation = 'photo';

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      final clubResult = await getIt<ResolveClubAccess>().call();
      final isClub = clubResult.valueOrNull ?? false;

      int created = 0;
      if (!isClub) {
        // Use the server-side preflight RPC for an accurate count from the
        // arenas table (same source the create RPC enforces against).
        final repo = getIt<ArenaRepository>();
        final squadsResult = await repo.mySquads();
        final squads = squadsResult.valueOrNull ?? [];
        final now = DateTime.now().toUtc();
        // Use UTC month start for preflight display (server uses SP timezone
        // for enforcement, so this count is approximate — only the RPC is
        // authoritative on whether the action is allowed).
        final monthStart = DateTime.utc(now.year, now.month, 1);
        created = squads.where((s) {
          final raw = s['created_at'] as String?;
          if (raw == null) return false;
          final dt = DateTime.tryParse(raw)?.toUtc();
          if (dt == null) return false;
          return !dt.isBefore(monthStart);
        }).length;
      }

      if (mounted) {
        setState(() {
          _isClub = isClub;
          _createdThisMonth = created;
          _isCheckingQuota = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingQuota = false);
    }
  }

  bool get _limitReached => !_isClub && _createdThisMonth >= _freeCreateLimit;

  // --- FUNÇÃO PARA GERAR CÓDIGO CURTO ---
  String _generateSquadCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    String part1 = String.fromCharCodes(Iterable.generate(3, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    String part2 = String.fromCharCodes(Iterable.generate(3, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return "$part1-$part2";
  }

  Future<void> _createArena() async {
    if (_limitReached) {
      await ClubPaywallSheet.show(context);
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dê um nome para o seu Squad!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final shareCode = _generateSquadCode();

      // Use the atomic server-side RPC which enforces quota and inserts
      // the arena + creator participant in a single transaction.
      final rpcResult = await getIt<ArenaRepository>().createSquadWithQuota(
        name: title,
        description: _descController.text.trim(),
        gameMode: _selectedMode,
        durationDays: _durationDays,
        validationType: _selectedValidation,
        shareCode: shareCode,
      );

      final rpcFailure = rpcResult.failureOrNull;
      if (rpcFailure != null) throw Exception(rpcFailure.message);

      final response = rpcResult.valueOrNull!;

      if (response['allowed'] == false) {
        // Server-side quota enforcement denied the action.
        final reason = response['reason'] as String? ?? '';
        if (reason == 'monthly_create_limit') {
          // Update local quota state so the UI reflects the new count.
          if (mounted) {
            setState(() {
              _createdThisMonth = (response['used'] as num?)?.toInt() ?? _createdThisMonth;
            });
          }
          await ClubPaywallSheet.show(context);
        } else {
          throw Exception('Não foi possível criar o Squad: $reason');
        }
        return;
      }

      final arenaJson = response['arena'] as Map?;
      final arenaId = arenaJson?['id']?.toString();

      if (mounted && arenaId != null) {
        // Update local quota display from server response.
        final used = (response['used'] as num?)?.toInt();
        if (used != null) setState(() => _createdThisMonth = used);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ArenaDetailsScreen(arenaId: arenaId),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Squad criado! Convoque a tropa. 🔥')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Descrição do Modo de Jogo
  String _getModeDescription() {
    switch (_selectedMode) {
      case 'survivor': return "⚠️ Hardcore: Quem ficar 2 dias sem treinar é eliminado automaticamente.";
      case 'alpha': return "🐺 O Líder da Matilha: Ganha quem somar mais XP total (todos os treinos contam).";
      case 'roadrunner': return "🏃 Cardio Puro: Vence quem acumular a maior distância em corridas.";
      case 'hustle': return "🔥 Consistência: Não importa o treino, importa ir. Ganha quem treinar mais dias.";
      default: return "";
    }
  }

  // Descrição do Protocolo de Validação
  String _getValidationDescription() {
    switch (_selectedValidation) {
      case 'photo': return "📸 PROVA VISUAL: Foto obrigatória. Sujeito a votação dos membros.";
      case 'manual': return "🤝 SISTEMA DE HONRA: Check-in manual. Foto opcional apenas para registro.";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      appBar: AppBar(
        backgroundColor: BldrColors.bgBase,
        title: const Text(
          "NOVO SQUAD",
          style: TextStyle(
            color: BldrColors.goldBright,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        leading: const BackButton(color: BldrColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Configure a Arena",
              style: BldrText.screenTitle.copyWith(color: BldrColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text("Escolha as regras de combate.", style: BldrText.body),

            // Free quota indicator (hidden for Club users and while loading)
            if (!_isCheckingQuota && !_isClub) ...[
              const SizedBox(height: 12),
              _QuotaIndicator(
                used: _createdThisMonth,
                limit: _freeCreateLimit,
                limitReached: _limitReached,
              ),
            ],

            const SizedBox(height: 32),

            // NOME
            const _Label("NOME DO SQUAD"),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: BldrColors.textPrimary),
              decoration: _inputDeco("Ex: Desafio de Carnaval"),
            ),

            const SizedBox(height: 24),

            // DESCRIÇÃO
            const _Label("PRÊMIO / PUNIÇÃO (OPCIONAL)"),
            TextField(
              controller: _descController,
              style: const TextStyle(color: BldrColors.textPrimary),
              decoration: _inputDeco("Ex: O último paga o açaí."),
            ),

            const SizedBox(height: 24),

            // MODO DE JOGO (GRID 2x2)
            const _Label("MODO DE JOGO"),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _ModeCard(
                      title: 'SURVIVOR',
                      subtitle: '(ÚLTIMO DE PÉ)',
                      icon: Icons.dangerous,
                      isSelected: _selectedMode == 'survivor',
                      onTap: () => setState(() {
                        _selectedMode = 'survivor';
                        if (_selectedValidation == 'manual') _selectedValidation = 'photo';
                      }),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ModeCard(
                      title: 'ALFA (XP)',
                      subtitle: '(XP ACUMULADO)',
                      icon: Icons.emoji_events,
                      isSelected: _selectedMode == 'alpha',
                      onTap: () => setState(() {
                        _selectedMode = 'alpha';
                        if (_selectedValidation == 'manual') _selectedValidation = 'photo';
                      }),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _ModeCard(
                      title: 'ROADRUNNER',
                      subtitle: '(MAIS KMs)',
                      icon: Icons.directions_run,
                      isSelected: _selectedMode == 'roadrunner',
                      onTap: () => setState(() {
                        _selectedMode = 'roadrunner';
                        _selectedValidation = 'manual';
                      }),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ModeCard(
                      title: 'HUSTLE',
                      subtitle: '(DIAS DE TREINO)',
                      icon: Icons.bolt,
                      isSelected: _selectedMode == 'hustle',
                      onTap: () => setState(() {
                        _selectedMode = 'hustle';
                        _selectedValidation = 'manual';
                      }),
                    )),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Descrição Dinâmica do MODO
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BldrColors.goldTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BldrColors.goldBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: BldrColors.goldBright, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getModeDescription(),
                      style: const TextStyle(
                        color: BldrColors.goldBright,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- PROTOCOLO DE VALIDAÇÃO ---
            const _Label("PROTOCOLO DE VALIDAÇÃO"),
            if (_selectedMode == 'roadrunner' || _selectedMode == 'hustle')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BldrColors.goldTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BldrColors.goldBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: BldrColors.goldBright, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Este modo usa apenas CHECK-IN de honra. O ranking é objetivo (km / dias) — sem votação de fotos.",
                        style: TextStyle(
                          color: BldrColors.goldBright,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(
                  "Como os agentes provam que treinaram?",
                  style: TextStyle(color: BldrColors.textSecondary, fontSize: 12),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ValidationCard(
                      title: 'VISUAL',
                      subtitle: 'FOTO OBRIGATÓRIA',
                      icon: Icons.camera_alt_outlined,
                      isSelected: _selectedValidation == 'photo',
                      onTap: () => setState(() => _selectedValidation = 'photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ValidationCard(
                      title: 'HONRA',
                      subtitle: 'CHECK-IN MANUAL',
                      icon: Icons.handshake_outlined,
                      isSelected: _selectedValidation == 'manual',
                      onTap: () => setState(() => _selectedValidation = 'manual'),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _getValidationDescription(),
                  style: const TextStyle(
                    color: BldrColors.goldBright,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // --- DURAÇÃO ---
            const _Label("DURAÇÃO"),
            Row(
              children: [7, 15, 30].map((days) => _DurationChip(
                days: days,
                isSelected: _durationDays == days,
                onTap: () => setState(() => _durationDays = days),
              )).toList(),
            ),

            const SizedBox(height: 40),

            // BOTÃO CRIAR
            if (_limitReached) ...[
              // Limit reached: explain and offer upgrade
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BldrColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BldrColors.goldBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Você já criou $_freeCreateLimit Squads este mês.",
                      style: TextStyle(
                        color: BldrColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "A cota gratuita é de 2 criações por mês. Assine o BLDR Club para criar sem limites.",
                      style: TextStyle(color: BldrColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => ClubPaywallSheet.show(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BldrColors.goldSolid,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "ASSINAR BLDR CLUB",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createArena,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BldrColors.goldSolid,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                        )
                      : const Text(
                          "CRIAR SQUAD",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: BldrColors.textMuted),
      filled: true,
      fillColor: BldrColors.surfaceInset,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BldrColors.goldBright),
      ),
    );
  }
}

// ── Quota indicator ───────────────────────────────────────────────────────────
class _QuotaIndicator extends StatelessWidget {
  final int used;
  final int limit;
  final bool limitReached;

  const _QuotaIndicator({
    required this.used,
    required this.limit,
    required this.limitReached,
  });

  @override
  Widget build(BuildContext context) {
    final color = limitReached ? Colors.redAccent : BldrColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: limitReached
            ? Colors.redAccent.withOpacity(0.08)
            : BldrColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: limitReached
              ? Colors.redAccent.withOpacity(0.3)
              : BldrColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            limitReached ? Icons.lock_outline : Icons.info_outline,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              limitReached
                  ? "Você já criou $limit Squads este mês. Assine o Club para criar sem limites."
                  : "$used de $limit Squads criados este mês",
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Labels & Cards ────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: BldrColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),
  );
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? BldrColors.goldTint : BldrColors.surface,
          border: Border.all(
            color: isSelected ? BldrColors.goldBright : BldrColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? BldrColors.goldBright : BldrColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? BldrColors.textPrimary : BldrColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? BldrColors.goldBright.withOpacity(0.7)
                    : BldrColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ValidationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BldrColors.goldTint : BldrColors.surface,
          border: Border.all(
            color: isSelected ? BldrColors.goldBright : BldrColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? BldrColors.goldBright : BldrColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? BldrColors.textPrimary : BldrColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  style: const TextStyle(color: BldrColors.textMuted, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.days,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? BldrColors.goldSolid : BldrColors.surface,
            border: isSelected
                ? null
                : Border.all(color: BldrColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "$days DIAS",
              style: TextStyle(
                color: isSelected ? Colors.black : BldrColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
