import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateCheckinSheet extends StatefulWidget {
  final String arenaId;
  final String validationType;
  final int? xpLimitPerDay;
  final String gameMode;

  const CreateCheckinSheet({
    super.key,
    required this.arenaId,
    required this.validationType,
    this.xpLimitPerDay,
    this.gameMode = 'alpha',
  });

  @override
  State<CreateCheckinSheet> createState() => _CreateCheckinSheetState();
}

class _CreateCheckinSheetState extends State<CreateCheckinSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _distanceController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  String _selectedActivity = 'gym';
  final Map<String, IconData> _activities = {
    'gym': Icons.fitness_center,
    'run': Icons.directions_run,
    'cycle': Icons.directions_bike,
    'swim': Icons.pool,
    'crossfit': Icons.local_fire_department,
    'cardio': Icons.monitor_heart,
    'sport': Icons.sports_soccer,
  };

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) setState(() => _imageFile = File(image.path));
    } catch (e) {
      print("Erro ao selecionar imagem: $e");
    }
  }

  Future<void> _submit() async {
    print("Iniciando envio...");

    // --- 1. TRAVA DE FOTO OBRIGATÓRIA ---
    if (widget.validationType == 'photo' && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Essa Arena exige foto para validar o treino!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // --- 2. VALIDAÇÃO DE TÍTULO ---
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dê um título ao treino!"))
      );
      return;
    }

    // --- 3. VALIDAÇÃO DE KM (ROADRUNNER) ---
    if (widget.gameMode == 'roadrunner') {
      final km = double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0;
      if (km <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Informe a distância percorrida em km!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {

      // Tratamento dos Números
      final int minutes = int.tryParse(_durationController.text) ?? 0;
      final int calories = int.tryParse(_caloriesController.text) ?? 0;
      final double km = double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0;

      // --- 3. CÁLCULO DE XP BASE ---
      int xpEarned = 10;
      xpEarned += minutes;
      if (_selectedActivity == 'run' || _selectedActivity == 'cycle') xpEarned += (km * 10).round();

      // --- 4. BÔNUS DE VARIEDADE + TRAVA DIÁRIA (apenas ALPHA) ---
      if (widget.gameMode == 'alpha') {
        final now = DateTime.now().toUtc();
        final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

        final todayPosts =
            (await getIt<ArenaRepository>().myTodayPosts(widget.arenaId))
                    .valueOrNull ??
                <Map<String, dynamic>>[];

        // Bônus de variedade: +15 XP se já treinou hoje com outra modalidade
        final todayTypes = (todayPosts as List)
            .map((r) => r['activity_type'] as String?)
            .whereType<String>()
            .toSet();
        if (todayTypes.isNotEmpty && !todayTypes.contains(_selectedActivity)) {
          xpEarned += 15;
        }

        // Trava do limite diário
        if (widget.xpLimitPerDay != null && widget.xpLimitPerDay! > 0) {
          int xpAlreadyEarnedToday = 0;
          for (var row in todayPosts) {
            xpAlreadyEarnedToday += (row['xp_earned'] ?? 0) as int;
          }
          final int remainingXp = widget.xpLimitPerDay! - xpAlreadyEarnedToday;
          if (remainingXp <= 0) {
            xpEarned = 0;
          } else if (xpEarned > remainingXp) {
            xpEarned = remainingXp;
          }
        }
      }

      // --- 5. SALVAR NO BANCO (upload da prova incluso) ---
      final saveResult = await getIt<ArenaRepository>().submitCheckin(
        arenaId: widget.arenaId,
        imagePath: _imageFile?.path,
        post: {
          'activity_title': _titleController.text,
          'caption': _descController.text,
          'activity_type': _selectedActivity,
          'duration_minutes': minutes,
          'calories': calories,
          'distance_km': km,
          'xp_earned': xpEarned,
        },
      );
      final saveFailure = saveResult.failureOrNull;
      if (saveFailure != null) throw Exception(saveFailure.message);

      print("Post salvo com sucesso!");

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("ERRO AO POSTAR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    final bool isPhotoMandatory = widget.validationType == 'photo';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("REGISTRAR ATIVIDADE",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                textAlign: TextAlign.center
            ),
            const SizedBox(height: 24),

            if (widget.gameMode != 'alpha') ...[
              _ModeBanner(gameMode: widget.gameMode),
              const SizedBox(height: 16),
            ],

            // Foto
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _imageFile != null ? gold : (isPhotoMandatory ? Colors.redAccent.withOpacity(0.3) : Colors.white24)),
                  image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
                ),
                child: _imageFile == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: isPhotoMandatory ? Colors.redAccent : gold, size: 40),
                    const SizedBox(height: 8),
                    Text(
                        isPhotoMandatory ? "FOTO OBRIGATÓRIA" : "FOTO (OPCIONAL)",
                        style: TextStyle(
                            color: isPhotoMandatory ? Colors.redAccent : Colors.white54,
                            fontWeight: isPhotoMandatory ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12
                        )
                    )
                  ],
                )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "TÍTULO (Ex: Costas e Bíceps)",
                labelStyle: TextStyle(color: gold),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold)),
              ),
            ),
            const SizedBox(height: 16),

            // Atividade (Chips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _activities.entries.map((e) {
                  final isSelected = _selectedActivity == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.key.toUpperCase()),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedActivity = e.key),
                      avatar: Icon(e.value, size: 16, color: isSelected ? Colors.black : Colors.white),
                      backgroundColor: Colors.black,
                      selectedColor: gold,
                      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Inputs Numéricos
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _NumberInput(
                      controller: _durationController,
                      label: "MINUTOS",
                      icon: Icons.timer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberInput(
                      controller: _caloriesController,
                      label: "KCAL",
                      icon: Icons.local_fire_department,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),

            if (_selectedActivity == 'run' || _selectedActivity == 'cycle' || widget.gameMode == 'roadrunner')
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _NumberInput(
                  controller: _distanceController,
                  label: widget.gameMode == 'roadrunner' ? "DISTÂNCIA (km) — OBRIGATÓRIO" : "DISTÂNCIA (km)",
                  icon: Icons.map,
                  color: Colors.cyanAccent,
                ),
              ),

            const SizedBox(height: 8),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("POSTAR NO FEED", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),

            Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)),
          ],
        ),
      ),
    );
  }
}

class _ModeBanner extends StatelessWidget {
  final String gameMode;
  const _ModeBanner({required this.gameMode});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> config = {
      'survivor':   {'color': Colors.redAccent,    'icon': Icons.favorite,       'text': 'Este check-in mantém suas vidas. Foto rejeitada = −1 vida.'},
      'roadrunner': {'color': Colors.cyanAccent,   'icon': Icons.directions_run, 'text': 'Informe seus km — é o que conta no ranking.'},
      'hustle':     {'color': Colors.orangeAccent, 'icon': Icons.bolt,           'text': 'Registrar hoje = +1 dia no ranking. Só conta 1 por dia.'},
    };
    final cfg = config[gameMode];
    if (cfg == null) return const SizedBox.shrink();
    final Color color = cfg['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(cfg['icon'] as IconData, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cfg['text'] as String,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para inputs numéricos
class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;

  const _NumberInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
        prefixIcon: Icon(icon, color: color, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      ),
    );
  }
}