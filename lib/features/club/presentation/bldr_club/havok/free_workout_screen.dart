// lib/presentation/bldr_club/havok/free_workout_screen.dart

import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_hub.dart'; // Importa para usar as cores consistentes
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/workout_detail_screen.dart'; // Importa a tela de detalhes que já criamos
import 'package:bldr_fitness/l10n/app_localizations.dart';

class FreeWorkoutScreen extends StatefulWidget {
  const FreeWorkoutScreen({super.key});

  @override
  State<FreeWorkoutScreen> createState() => _FreeWorkoutScreenState();
}

class _FreeWorkoutScreenState extends State<FreeWorkoutScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _generateFreeWorkout() async {
    final userPrompt = _textController.text.trim();
    if (userPrompt.isEmpty) {
      // Opcional: Mostrar um snackbar se o campo estiver vazio
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await getIt<GenerateFreeWorkout>()(userPrompt);
      final data = result.valueOrNull;

      if (data != null && mounted) {
        // REUTILIZAMOS A TELA DE DETALHES!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(
              workoutData: data['workout_data'],
            ),
          ),
        );
      } else {
        throw 'A IA não conseguiu gerar o treino. Tente novamente.';
      }
    } catch (e) {
      // Opcional: Mostrar um snackbar de erro
      print('Erro ao gerar treino livre: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).free_workout_title, style: const TextStyle(color: goldColor)),
        backgroundColor: cardBackgroundColor,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).free_workout_describe,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Ex: "Um treino rápido de 20 minutos para peito e ombros em casa"',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).free_workout_hint,
                hintStyle: TextStyle(color: Colors.grey[600]),
                fillColor: cardBackgroundColor,
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: goldColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                disabledBackgroundColor: goldColor.withOpacity(0.5),
              ),
              onPressed: _isLoading ? null : _generateFreeWorkout,
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
              )
                  : Text(AppLocalizations.of(context).free_workout_btn, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}