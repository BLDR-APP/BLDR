// lib/features/professional_portal/presentation/screens/workout_plan_editor_screen.dart

import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:bldr_fitness/features/professional_portal/presentation/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkoutPlanEditorScreen extends StatefulWidget {
  final int planId;
  final String planName;

  const WorkoutPlanEditorScreen({
    Key? key,
    required this.planId,
    required this.planName,
  }) : super(key: key);

  @override
  _WorkoutPlanEditorScreenState createState() => _WorkoutPlanEditorScreenState();
}

class _WorkoutPlanEditorScreenState extends State<WorkoutPlanEditorScreen> {
  final _repository = ProfessionalRepository();
  late Future<List<Map<String, dynamic>>> _exercisesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    setState(() {
      _exercisesFuture = _repository.getWorkoutPlanExercises(widget.planId);
    });
  }

  // Função que abre o formulário para adicionar um novo exercício
  void _showAddExerciseForm() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final restController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // Cor de fundo do menu
      isScrollControlled: true, // Permite o teclado subir sem cobrir o menu
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Novo Exercício',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nome do Exercício'),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: setsController,
                              decoration: const InputDecoration(labelText: 'Séries'),
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: repsController,
                              decoration: const InputDecoration(labelText: 'Repetições'),
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: restController,
                              decoration: const InputDecoration(labelText: 'Descanso (s)'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'Observações (opcional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                          if (formKey.currentState!.validate()) {
                            setModalState(() { _isLoading = true; });
                            try {
                              final currentExercises = await _exercisesFuture;
                              final newOrder = currentExercises.length + 1;

                              await _repository.addExerciseToPlan(
                                planId: widget.planId,
                                name: nameController.text.trim(),
                                sets: setsController.text.trim(),
                                reps: repsController.text.trim(),
                                rest: restController.text.trim(),
                                notes: notesController.text.trim(),
                                order: newOrder,
                              );

                              Navigator.of(context).pop(); // Fecha o menu
                              _loadExercises(); // Recarrega a lista
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                              );
                            } finally {
                              if (mounted) {
                                setModalState(() { _isLoading = false; });
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('Adicionar Exercício'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planName),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          // Usa o EmptyStateWidget (V2.0)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              title: "Nenhum Exercício Adicionado",
              message: "Clique no botão '+' para adicionar o primeiro exercício a este plano.",
              iconData: Icons.add_circle_outline,
              buttonText: "Adicionar Exercício",
              onButtonPressed: _showAddExerciseForm,
            );
          }

          final exercises = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final ex = exercises[index];
              return Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade800)
                ),
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ex['exercise_order']}. ${ex['exercise_name']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetricChip('Séries', ex['sets'] ?? '-'),
                          _buildMetricChip('Reps', ex['reps'] ?? '-'),
                          _buildMetricChip('Descanso', '${ex['rest_period'] ?? '-'}s'),
                        ],
                      ),
                      if (ex['notes'] != null && ex['notes']!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            'Obs: ${ex['notes']}',
                            style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExerciseForm,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // Widget auxiliar para os chips de métrica
  Widget _buildMetricChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}