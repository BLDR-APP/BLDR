// lib/features/professional_portal/presentation/screens/meal_plan_editor_screen.dart

import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:bldr_fitness/features/professional_portal/presentation/screens/search_food_screen.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/professional_portal/presentation/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MealPlanEditorScreen extends StatefulWidget {
  final int planId;
  final String planName;

  const MealPlanEditorScreen({
    Key? key,
    required this.planId,
    required this.planName,
  }) : super(key: key);

  @override
  _MealPlanEditorScreenState createState() => _MealPlanEditorScreenState();
}

class _MealPlanEditorScreenState extends State<MealPlanEditorScreen> {
  final _repository = ProfessionalRepository();

  // O estado agora é o plano de refeição completo
  Map<String, dynamic>? _mealPlan;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPlanDetails();
  }

  Future<void> _loadPlanDetails() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final planDetails = await _repository.getMealPlanDetails(widget.planId);
      setState(() {
        _mealPlan = planDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddMealDialog() async {
    final mealNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final mealName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Refeição'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: mealNameController,
            decoration: const InputDecoration(hintText: "Ex: Lanche da Tarde"),
            validator: (v) => (v == null || v.isEmpty) ? 'Dê um nome' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(mealNameController.text);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (mealName != null && mealName.isNotEmpty) {
      try {
        final currentMeals = (_mealPlan?['meals'] as List?) ?? [];
        await _repository.createMeal(
          planId: widget.planId,
          mealName: mealName,
          order: currentMeals.length + 1,
        );
        _loadPlanDetails(); // Recarrega tudo
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _navigateAndAddFood(int mealId) async {
    // 1. Abre a tela de busca e espera a Nutri selecionar um alimento
    final foodFromFirebase = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const SearchFoodScreen()),
    );

    if (foodFromFirebase == null) return; // Nutri cancelou

    // 2. Se ela selecionou, pede a quantidade
    final foodDetails = await _showQuantityDialog(foodFromFirebase);

    if (foodDetails == null) return; // Nutri cancelou

    // 3. Salva o alimento na refeição
    try {
      final currentItems = ((_mealPlan?['meals'] as List?)
          ?.firstWhere((m) => m['id'] == mealId)['meal_items'] as List?) ?? [];

      await _repository.addFoodToMeal(
        mealId: mealId,
        foodDbId: foodDetails['foodDbId'],
        foodName: foodDetails['foodName'],
        quantity: foodDetails['quantity'],
        unit: foodDetails['unit'],
        order: currentItems.length + 1,
        calories: foodDetails['calories'],
        protein: foodDetails['protein'],
        carbs: foodDetails['carbs'],
        fat: foodDetails['fat'],
      );
      _loadPlanDetails(); // Recarrega tudo
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    }
  }

  // Pede a quantidade e calcula os macros
  Future<Map<String, dynamic>?> _showQuantityDialog(Map<String, dynamic> food) async {
    final quantityController = TextEditingController(text: '100');
    String unit = 'g'; // Unidade padrão

    // Calcula macros iniciais
    MacroNutrients macros = MacroNutrients.fromPer100g(
      quantityGrams: 100,
      caloriesPer100g: (food['calories_per_100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (food['protein_per_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (food['carbs_per_100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (food['fat_per_100g'] as num?)?.toDouble() ?? 0,
    );

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Adicionar ${food['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: quantityController,
                    decoration: InputDecoration(labelText: 'Quantidade', suffixText: unit),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final newQuantity = double.tryParse(value) ?? 0;
                      // Recalcula macros em tempo real
                      macros = MacroNutrients.fromPer100g(
                        quantityGrams: newQuantity,
                        caloriesPer100g: (food['calories_per_100g'] as num?)?.toDouble() ?? 0,
                        proteinPer100g: (food['protein_per_100g'] as num?)?.toDouble() ?? 0,
                        carbsPer100g: (food['carbs_per_100g'] as num?)?.toDouble() ?? 0,
                        fatPer100g: (food['fat_per_100g'] as num?)?.toDouble() ?? 0,
                      );
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  // Exibição dos macros calculados
                  Text(
                    '${macros.calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'P: ${macros.protein.toStringAsFixed(1)}g | C: ${macros.carbs.toStringAsFixed(1)}g | G: ${macros.fat.toStringAsFixed(1)}g',
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    // Retorna todos os dados necessários
                    Navigator.of(context).pop({
                      'foodDbId': food['id'],
                      'foodName': food['name'],
                      'quantity': double.tryParse(quantityController.text) ?? 100,
                      'unit': unit,
                      'calories': macros.calories,
                      'protein': macros.protein,
                      'carbs': macros.carbs,
                      'fat': macros.fat,
                    });
                  },
                  child: const Text('Adicionar'),
                ),
              ],
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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMealDialog,
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nova Refeição', style: TextStyle(color: Colors.black)),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty || _mealPlan == null) {
      return Center(child: Text('Erro: $_errorMessage'));
    }

    final meals = (_mealPlan!['meals'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (meals.isEmpty) {
      return EmptyStateWidget(
        title: "Plano Vazio",
        message: "Clique no botão '+' para adicionar a primeira refeição (ex: Café da Manhã) a este plano.",
        iconData: Icons.add_circle_outline,
        buttonText: "Adicionar Refeição",
        onButtonPressed: _showAddMealDialog,
      );
    }

    // Constrói a lista de refeições e seus itens
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        final mealItems = (meal['meal_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return _buildMealCard(meal, mealItems);
      },
    );
  }

  // Card para cada REFEIÇÃO
  Widget _buildMealCard(Map<String, dynamic> meal, List<Map<String, dynamic>> items) {
    // Calcula os macros totais da refeição
    double totalCalories = 0;
    items.forEach((item) => totalCalories += (item['calories'] as num?)?.toDouble() ?? 0);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade800)
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da Refeição
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meal['name'] ?? 'Refeição',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${totalCalories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(color: Colors.grey, height: 24),

            // Lista de Itens da Refeição
            ...items.map((item) => _buildMealItemTile(item)).toList(),

            // Botão de Adicionar Alimento
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _navigateAndAddFood(meal['id']),
              icon: const Icon(Icons.add, color: Colors.amber),
              label: const Text('Adicionar Alimento', style: TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      ),
    );
  }

  // ListTile para cada ITEM DE COMIDA
  Widget _buildMealItemTile(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item['food_name']}',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          Text(
            '${(item['quantity'] as num).toStringAsFixed(0)}${item['unit']}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
          ),
          SizedBox(width: 16),
          Text(
            '${(item['calories'] as num?)?.toStringAsFixed(0) ?? '0'} kcal',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}