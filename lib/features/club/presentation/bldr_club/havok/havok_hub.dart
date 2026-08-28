import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

// Imports para as novas telas
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/workout_library_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/workout_detail_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/free_workout_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/recipe_results_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/recipe_library_screen.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

// --- CORES ---
const Color goldColor = Color(0xFFD4AF37);
const Color darkBackgroundColor = Color(0xFF121212);
const Color cardBackgroundColor = Color(0xFF1E1E1E);

class HavokHubScreen extends StatefulWidget {
  const HavokHubScreen({super.key});

  @override
  State<HavokHubScreen> createState() => _HavokHubScreenState();
}

class _HavokHubScreenState extends State<HavokHubScreen> {
  String _userName = '';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (!getIt<AuthRepository>().isAuthenticated) {
      if (mounted) setState(() { _userName = AppLocalizations.of(context).havok_guest; _isLoadingName = false; });
      return;
    }
    try {
      final profile = await UserService.instance.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userName = (profile?.fullName?.isNotEmpty ?? false) ? profile!.fullName! : (getIt<AuthRepository>().currentUser?.email?.split('@')[0] ?? AppLocalizations.of(context).havok_user_default);
          _isLoadingName = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _userName = AppLocalizations.of(context).havok_user_default; _isLoadingName = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context).havok_sheet_title, style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: ModelViewer(
                  src: 'assets/models/HAVOKNEW.glb',
                  alt: "Mascote Havok",
                  ar: false, autoRotate: true, disableZoom: true,
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 20),
              Text(_isLoadingName ? AppLocalizations.of(context).havok_loading : AppLocalizations.of(context).havok_hello(_userName), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).havok_tagline, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              const SizedBox(height: 30),
              const _TrainingModule(),
              const SizedBox(height: 24),
              const _NutritionModule(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingModule extends StatefulWidget {
  const _TrainingModule({super.key});

  @override
  State<_TrainingModule> createState() => _TrainingModuleState();
}

class _TrainingModuleState extends State<_TrainingModule> {
  bool _isLoading = false;
  String _loadingMessage = '';

  List<String> get _loadingSteps => [
    AppLocalizations.of(context).havok_loading_step1,
    AppLocalizations.of(context).havok_loading_step2,
    AppLocalizations.of(context).havok_loading_step3,
  ];

  Future<void> _gerarTreinoHavok() async {
    setState(() { _isLoading = true; _loadingMessage = _loadingSteps[0]; });

    try {
      // Avança mensagem enquanto aguarda a resposta
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isLoading) setState(() => _loadingMessage = _loadingSteps[1]);
      });

      final genResult = await getIt<GenerateHavokWorkout>()();
      final workout = genResult.valueOrNull;
      final genFailure = genResult.failureOrNull;
      if (genFailure != null || workout == null) {
        throw Exception(genFailure?.message);
      }

      if (!mounted) return;
      setState(() => _loadingMessage = _loadingSteps[2]);
      await Future.delayed(const Duration(milliseconds: 800));

      // Navega direto para o treino recém-gerado com o dado já devolvido
      // pela edge function — sem SELECT adicional (HAVOK_SPEC.md §10).
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workoutData: workout.workoutData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).havok_error_generate), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; _loadingMessage = ''; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: goldColor.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppLocalizations.of(context).havok_generate_training, textAlign: TextAlign.center, style: const TextStyle(color: goldColor, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
            onPressed: _isLoading ? null : _gerarTreinoHavok,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black))
                : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(AppLocalizations.of(context).havok_generate_btn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _loadingMessage,
                key: ValueKey(_loadingMessage),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // <<< CORREÇÃO DO OVERFLOW DE 164 PIXELS:
          // Usamos Wrap em vez de Row para que os botões pulem de linha se não couberem
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8,
            runSpacing: 0,
            children: [
              TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutLibraryScreen())),
                  child: const Text('Acessar Biblioteca', style: TextStyle(color: goldColor))
              ),
              TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FreeWorkoutScreen())),
                  child: const Text('Criar Treino Livre', style: TextStyle(color: goldColor))
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionModule extends StatefulWidget {
  const _NutritionModule({super.key});

  @override
  State<_NutritionModule> createState() => _NutritionModuleState();
}

class _NutritionModuleState extends State<_NutritionModule> {
  bool _isLoading = false;
  final _textController = TextEditingController();

  Future<void> _generateRecipe(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final result = await getIt<GenerateHavokRecipe>()(query);
      final data = result.valueOrNull;
      if (data != null && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeResultsScreen(recipeData: data)));
    } catch (e) { print(e); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  void dispose() { _textController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: goldColor.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('NUTRIÇÃO INTELIGENTE', textAlign: TextAlign.center, style: TextStyle(color: goldColor, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
          const SizedBox(height: 20),
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: 'Quais ingredientes tem aí?', hintStyle: TextStyle(color: Colors.grey[500]), prefixIcon: const Icon(Icons.search, color: goldColor), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey[700]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: goldColor))),
            onSubmitted: _generateRecipe,
          ),
          const SizedBox(height: 20),
          // <<< CORREÇÃO DO OVERFLOW DE 64 PIXELS:
          // Envolvemos cada ícone em um Expanded ou usamos um Layout Flexível
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _CategoryIcon(icon: Icons.local_fire_department, label: 'Pós-treino', onTap: () => _generateRecipe('Pós-treino'))),
              Expanded(child: _CategoryIcon(icon: Icons.breakfast_dining, label: 'Café da manhã', onTap: () => _generateRecipe('Café da manhã'))),
              Expanded(child: _CategoryIcon(icon: Icons.lunch_dining, label: 'Almoço', onTap: () => _generateRecipe('Almoço'))),
              Expanded(child: _CategoryIcon(icon: Icons.dinner_dining, label: 'Jantar', onTap: () => _generateRecipe('Jantar'))),
            ],
          ),
          const SizedBox(height: 12),
          Center(
              child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeLibraryScreen())),
                  child: const FittedBox( // <<< BLINDAGEM NO LINK DE RECEITAS
                    fit: BoxFit.scaleDown,
                    child: Text('Acessar Biblioteca de Receitas', style: TextStyle(color: goldColor)),
                  )
              )
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _CategoryIcon({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: Icon(icon, color: goldColor, size: 28), onPressed: onTap),
          const SizedBox(height: 4),
          // <<< BLINDAGEM NO TEXTO DA CATEGORIA
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
            ),
          )
        ]
    );
  }
}

