// ARQUIVO: lib/widgets/firebase_nutrition_search_widget.dart
//
// ⚠️ Consulta o Firestore diretamente (stream em tempo real), com
// capitalização própria da query — dívida conhecida (ARCHITECTURE.md).
// Redesign aqui é só visual: `_performSearch`/`dbAlimentos` intactos.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class FirebaseNutritionSearchWidget extends StatefulWidget {
  // O callback para devolver a comida selecionada
  final Function(Map<String, dynamic> foodItem) onFoodSelected;

  const FirebaseNutritionSearchWidget({
    Key? key,
    required this.onFoodSelected,
  }) : super(key: key);

  @override
  State<FirebaseNutritionSearchWidget> createState() =>
      _FirebaseNutritionSearchWidgetState();
}

class _FirebaseNutritionSearchWidgetState
    extends State<FirebaseNutritionSearchWidget> {
  final _searchController = TextEditingController();

  // Referência para o banco de dados do Projeto B (Alimentos)
  late FirebaseFirestore dbAlimentos;

  // Armazena os resultados da busca
  Stream<QuerySnapshot>? _searchResultsStream;

  @override
  void initState() {
    super.initState();
    // Tenta usar a instância nomeada se possível, senão usa a padrão
    try {
      dbAlimentos = FirebaseFirestore.instanceFor(app: Firebase.app('alimentosDB'));
    } catch(e) {
      dbAlimentos = FirebaseFirestore.instance;
    }
    // Inicia com um stream vazio
    _searchResultsStream = Stream.empty();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Executa a busca no Firebase
  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResultsStream = Stream.empty();
      });
      return;
    }

    // AJUSTE LÓGICO: Garante que a busca use a primeira letra maiúscula
    // Isso é importante porque 'arroz' não encontra 'Arroz' no Firestore
    String formattedQuery = query;
    if (formattedQuery.isNotEmpty) {
      formattedQuery = formattedQuery[0].toUpperCase() + formattedQuery.substring(1);
    }

    String startQuery = formattedQuery;
    String endQuery = formattedQuery + '\uf8ff';

    setState(() {
      _searchResultsStream = dbAlimentos
          .collection('alimentos')
          .where('name', isGreaterThanOrEqualTo: startQuery)
          .where('name', isLessThan: endQuery)
          .limit(20)
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Scaffold(
        backgroundColor: BldrColors.sheetBg,
        appBar: AppBar(
          backgroundColor: BldrColors.sheetBg,
          elevation: 0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
                color: BldrColors.textMuted,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
          child: Column(
            children: [
              // --- Campo de Busca ---
              TextFormField(
                controller: _searchController,
                autofocus: true,
                // AJUSTE DE UI: Ativa a capitalização de frases no teclado
                textCapitalization: TextCapitalization.sentences,
                style: BldrText.body,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).nutrition_search_db_hint,
                  hintStyle: BldrText.description,
                  prefixIcon: const Icon(Icons.search, color: BldrColors.goldBright, size: 20),
                  filled: true,
                  fillColor: BldrColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: BldrColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: BldrColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: BldrColors.goldBright, width: 2),
                  ),
                ),
                onChanged: _performSearch,
              ),
              const SizedBox(height: 20),

              // --- Resultados da Busca ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _searchResultsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: BldrColors.goldBright));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text(AppLocalizations.of(context).nutrition_search_error, style: BldrText.description));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      if (_searchController.text.isEmpty) {
                        return Center(child: Text(AppLocalizations.of(context).nutrition_search_type_prompt, style: BldrText.description));
                      }
                      return Center(child: Text(AppLocalizations.of(context).nutrition_no_results, style: BldrText.description));
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final foodData = doc.data() as Map<String, dynamic>;
                        foodData['id'] = doc.id;

                        return _buildFoodItem(foodData);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    final protein  = (food['protein_per_100g']  as num?)?.toInt() ?? 0;
    final carbs    = (food['carbs_per_100g']     as num?)?.toInt() ?? 0;
    final fat      = (food['fat_per_100g']       as num?)?.toInt() ?? 0;
    final calories = (food['calories_per_100g']  as num?)?.toInt() ?? 0;

    return BldrFoodItemRow(
      name: (food['name'] as String?) ?? AppLocalizations.of(context).nutrition_unnamed_food,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      onTap: () => widget.onFoodSelected(food),
    );
  }
}