// lib/features/professional_portal/presentation/screens/client_workout_list_screen.dart

import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar a data

// --- NOVOS IMPORTS (V2.0) ---
import 'package:bldr_fitness/features/professional_portal/presentation/widgets/empty_state_widget.dart';
import 'package:bldr_fitness/features/professional_portal/presentation/screens/workout_plan_editor_screen.dart';
// --- FIM DOS NOVOS IMPORTS ---


class ClientWorkoutListScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientWorkoutListScreen({
    Key? key,
    required this.clientId,
    required this.clientName,
  }) : super(key: key);

  @override
  _ClientWorkoutListScreenState createState() => _ClientWorkoutListScreenState();
}

class _ClientWorkoutListScreenState extends State<ClientWorkoutListScreen> {
  final _repository = ProfessionalRepository();
  late Future<List<Map<String, dynamic>>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlans();
  }

  void _loadWorkoutPlans() {
    setState(() {
      _plansFuture = _repository.getWorkoutPlans(widget.clientId);
    });
  }

  Future<void> _showCreatePlanDialog() async {
    // ... (função _showCreatePlanDialog permanece igual) ...
    final planNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final planName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo Plano de Treino'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: planNameController,
              decoration: const InputDecoration(hintText: "Ex: Treino A - Foco Peito"),
              validator: (value) => (value == null || value.isEmpty) ? 'Dê um nome ao plano' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(planNameController.text);
                }
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    if (planName != null && planName.isNotEmpty) {
      try {
        await _repository.createWorkoutPlan(
          planName: planName,
          clientId: widget.clientId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano criado com sucesso!'), backgroundColor: Colors.green),
        );
        _loadWorkoutPlans(); // Recarrega a lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // --- ALTERAÇÃO AQUI (V2.0) ---
  // A função agora navega para a tela de edição
  void _navigateToPlanDetails(int planId, String planName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPlanEditorScreen(
          planId: planId,
          planName: planName,
        ),
      ),
    ).then((_) {
      // Quando o personal voltar da tela de edição, recarregamos
      // caso ele tenha feito alguma alteração.
      _loadWorkoutPlans();
    });
  }
  // --- FIM DA ALTERAÇÃO ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treinos de ${widget.clientName}'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          // --- ALTERAÇÃO AQUI (V2.0) ---
          // Usa o novo EmptyStateWidget
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              title: "Nenhum Plano de Treino Criado",
              message: "Clique no botão '+' para começar a montar o primeiro treino para este aluno.",
              iconData: Icons.fitness_center, // Ícone temático
              buttonText: "Criar Primeiro Plano",
              onButtonPressed: _showCreatePlanDialog, // Reutiliza a função existente
            );
          }
          // --- FIM DA ALTERAÇÃO ---

          final plans = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8.0),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final createdAt = DateTime.parse(plan['created_at']);
              final formattedDate = DateFormat('dd/MM/yyyy').format(createdAt);

              return ListTile(
                leading: const Icon(Icons.fitness_center, color: Colors.amber),
                title: Text(plan['plan_name']),
                subtitle: Text('Criado em $formattedDate'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigateToPlanDetails(plan['id'], plan['plan_name']),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlanDialog,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}