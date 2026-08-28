// lib/features/professional_portal/presentation/screens/search_food_screen.dart

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/nutrition/presentation/mappers/legacy_ui_maps.dart';
import 'package:flutter/material.dart';

class SearchFoodScreen extends StatefulWidget {
  const SearchFoodScreen({Key? key}) : super(key: key);

  @override
  _SearchFoodScreenState createState() => _SearchFoodScreenState();
}

class _SearchFoodScreenState extends State<SearchFoodScreen> {
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _searchFood(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = '';
      });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final searchResult = await getIt<SearchFoods>()(query);
      final results = searchResult.fold(
        onSuccess: (items) => items.map(foodItemToLegacyMap).toList(),
        onFailure: (failure) => throw Exception(failure.message),
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
        if (results.isEmpty) {
          _errorMessage = 'Nenhum alimento encontrado para "$query".';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao buscar: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Alimento'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar no Firebase DB...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchFood(_searchController.text),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _searchFood,
            ),
          ),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: TextStyle(color: Colors.grey)));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Digite 2 ou mais letras para buscar.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        final foodName = food['name'] ?? 'Alimento sem nome';
        final cals = (food['calories_per_100g'] as num?)?.toDouble() ?? 0.0;

        return ListTile(
          title: Text(foodName),
          subtitle: Text('${cals.toStringAsFixed(0)} kcal por 100g'),
          trailing: const Icon(Icons.add),
          onTap: () {
            // Retorna o alimento selecionado para a tela anterior
            Navigator.of(context).pop(food);
          },
        );
      },
    );
  }
}