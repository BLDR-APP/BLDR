// lib/features/professional_portal/presentation/screens/client_diet_screen.dart

import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ATUALIZADOS (V2.0) ---
import 'package:bldr_fitness/features/professional_portal/presentation/widgets/empty_state_widget.dart';
// Este é o nosso próximo passo. Vamos criar este arquivo em seguida.
import 'package:bldr_fitness/features/professional_portal/presentation/screens/meal_plan_editor_screen.dart';
// --- FIM DOS IMPORTS ---

class ClientDietScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientDietScreen({
    Key? key,
    required this.clientId,
    required this.clientName,
  }) : super(key: key);

  @override
  _ClientDietScreenState createState() => _ClientDietScreenState();
}

class _ClientDietScreenState extends State<ClientDietScreen> {
  final _repository = ProfessionalRepository();
  // --- LÓGICA ATUALIZADA (V2.0) ---
  // Trocamos o futuro de 'diet_plans' (PDFs) para 'meal_plans' (Estruturado)
  late Future<List<Map<String, dynamic>>> _mealPlansFuture;
  // Não precisamos mais do _isUploading
  // --- FIM DA LÓGICA ---

  @override
  void initState() {
    super.initState();
    // Função renomeada para clareza
    _loadMealPlans();
  }

  // --- FUNÇÃO ATUALIZADA (V2.0) ---
  // Busca os novos planos estruturados
  void _loadMealPlans() {
    setState(() {
      _mealPlansFuture = _repository.getMealPlans(widget.clientId);
    });
  }
  // --- FIM DA FUNÇÃO ---

  // --- FUNÇÃO REMOVIDA (V2.0) ---
  // _pickAndUploadFile() foi removida.
  // _showTitleDialog() foi removida.
  // _openPdf() foi removida.
  // --- FIM DA REMOÇÃO ---

  // --- NOVA FUNÇÃO (V2.0) ---
  // Abre o diálogo para criar um novo plano de refeição
  Future<void> _showCreateMealPlanDialog() async {
    final planNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final planName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo Plano de Dieta'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: planNameController,
              decoration: const InputDecoration(hintText: "Ex: Plano Cutting - 2500kcal"),
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

    // Se o usuário inseriu um nome e clicou em "Criar"
    if (planName != null && planName.isNotEmpty) {
      try {
        await _repository.createMealPlan(
          planName: planName,
          clientId: widget.clientId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano criado com sucesso!'), backgroundColor: Colors.green),
        );
        _loadMealPlans(); // Recarrega a lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
  // --- FIM DA NOVA FUNÇÃO ---

  // --- NOVA FUNÇÃO (V2.0) ---
  // Navega para a tela de edição do plano (que criaremos a seguir)
  void _navigateToPlanEditor(Map<String, dynamic> plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealPlanEditorScreen(
          planId: plan['id'],
          planName: plan['plan_name'],
        ),
      ),
    ).then((_) {
      // Quando o Nutri voltar, recarregamos os planos
      _loadMealPlans();
    });
  }
  // --- FIM DA NOVA FUNÇÃO ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dietas de ${widget.clientName}'),
        backgroundColor: Colors.black,
      ),
      // --- UI ATUALIZADA (V2.0) ---
      // A Stack não é mais necessária
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _mealPlansFuture, // Usa o novo Future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          // Usa o EmptyStateWidget para os novos planos
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              title: "Nenhum Plano de Dieta Criado",
              message: "Clique no botão '+' para criar o primeiro plano de dieta estruturado.",
              iconData: Icons.restaurant_menu_outlined, // Novo ícone
              buttonText: "Criar Plano de Dieta",
              onButtonPressed: _showCreateMealPlanDialog, // Nova função
            );
          }

          // Lista os novos planos estruturados
          final plans = snapshot.data!;
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final createdAt = DateTime.parse(plan['created_at']);
              final formattedDate = DateFormat('dd/MM/yyyy').format(createdAt);

              return ListTile(
                leading: const Icon(Icons.restaurant_menu, color: Colors.green), // Novo ícone
                title: Text(plan['plan_name']),
                subtitle: Text('Criado em $formattedDate'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateToPlanEditor(plan), // Nova navegação
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMealPlanDialog, // Nova função
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black), // Ícone de "adicionar"
      ),
      // --- FIM DA ATUALIZAÇÃO DA UI ---
    );
  }
}