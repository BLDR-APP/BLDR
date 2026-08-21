// lib/presentation/bldr_club/create_arena_screen.dart
import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'dart:math';

class CreateArenaScreen extends StatefulWidget {
  const CreateArenaScreen({super.key});

  @override
  State<CreateArenaScreen> createState() => _CreateArenaScreenState();
}

class _CreateArenaScreenState extends State<CreateArenaScreen> {
  static const gold = Color(0xFFD4AF37);

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLoading = false;

  // Configurações Padrão
  String _selectedMode = 'hustle';
  int _durationDays = 7;
  String _selectedValidation = 'photo';

  // --- FUNÇÃO PARA GERAR CÓDIGO CURTO ---
  String _generateSquadCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    String part1 = String.fromCharCodes(Iterable.generate(3, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    String part2 = String.fromCharCodes(Iterable.generate(3, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return "$part1-$part2";
  }

  Future<void> _createArena() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dê um nome para o seu Squad! 🛡️'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gera o código antes de salvar
      final shareCode = _generateSquadCode();

      // 1. Cria a Arena (o criador entra automaticamente)
      final createResult = await getIt<ArenaRepository>().createArena({
        'title': title,
        'description': _descController.text.trim(),
        'game_mode': _selectedMode,
        'validation_type': _selectedValidation,
        'share_code': shareCode,
        'start_date': DateTime.now().toIso8601String(),
        'end_date':
            DateTime.now().add(Duration(days: _durationDays)).toIso8601String(),
        'is_active': true,
      }, gameMode: _selectedMode);
      final createFailure = createResult.failureOrNull;
      if (createFailure != null) throw Exception(createFailure.message);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Squad criado! Convoque a tropa. 🔥')),
        );
      }
    } catch (e) {
      print('Erro ao criar arena: $e');
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
      case 'photo': return "📸 PROVA VISUAL: Foto obrigatória. Sujeito a julgamento do Tribunal.";
      case 'manual': return "🤝 SISTEMA DE HONRA: Check-in manual. Foto opcional apenas para registro.";
      default: return "";
    }
  }

  Color _getModeColor() => gold;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("NOVO SQUAD", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Configure a Arena", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Escolha as regras de combate.", style: TextStyle(color: Colors.white54)),

            const SizedBox(height: 32),

            // NOME
            const _Label("NOME DO SQUAD"),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco("Ex: Desafio de Carnaval"),
            ),

            const SizedBox(height: 24),

            // DESCRIÇÃO
            const _Label("PRÊMIO / PUNIÇÃO (OPCIONAL)"),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
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

            // Descrição Dinâmica do MODO (BLINDADO)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _getModeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getModeColor().withOpacity(0.3))
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _getModeColor(), size: 16),
                  const SizedBox(width: 8),
                  // <<< CORREÇÃO: Expanded permite que o texto quebre linha sem estourar
                  Expanded(
                    child: Text(
                      _getModeDescription(),
                      style: TextStyle(color: _getModeColor(), fontSize: 11, fontWeight: FontWeight.bold),
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
                  color: _getModeColor().withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getModeColor().withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: _getModeColor(), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Este modo usa apenas CHECK-IN de honra. O ranking é objetivo (km / dias) — sem necessidade de tribunal.",
                        style: TextStyle(color: _getModeColor(), fontSize: 11, fontWeight: FontWeight.bold),
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
                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
                  style: const TextStyle(color: gold, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // --- DURAÇÃO (BLINDADO) ---
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
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createArena,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("CRIAR SQUAD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[800]),
      filled: true,
      fillColor: const Color(0xFF121212),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gold)),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
  );
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  static const _gold = Color(0xFFD4AF37);

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
          color: isSelected ? _gold.withOpacity(0.08) : const Color(0xFF1A1A1A),
          border: Border.all(color: isSelected ? _gold : Colors.white12, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? _gold : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              subtitle.toUpperCase(),
              style: TextStyle(
                color: isSelected ? _gold.withOpacity(0.7) : Colors.grey[700],
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

// --- CLASSE VALIDATION CARD CORRIGIDA ---
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
    const gold = Color(0xFFD4AF37);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? gold.withOpacity(0.1) : const Color(0xFF1A1A1A),
          border: Border.all(color: isSelected ? gold : Colors.white10, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? gold : Colors.grey, size: 20),
            const SizedBox(height: 4),
            // <<< BLINDAGEM: Título com Flexible e FittedBox
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // <<< BLINDAGEM: Subtítulo com Flexible e FittedBox
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 9),
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

// --- CLASSE DURATION CHIP CORRIGIDA ---
class _DurationChip extends StatelessWidget {
  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({required this.days, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // <<< CORREÇÃO: Expanded aqui garante que os botões dividam a largura da tela
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Sem width fixo!
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF121212),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox( // Protege o texto
            fit: BoxFit.scaleDown,
            child: Text(
              "$days DIAS",
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}