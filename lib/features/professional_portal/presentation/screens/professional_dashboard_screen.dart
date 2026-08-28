// lib/features/professional_portal/presentation/screens/professional_dashboard_screen.dart

import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:bldr_fitness/services/auth_service.dart'; // Ajuste o caminho se necessário
import 'package:flutter/material.dart';

import 'package:bldr_fitness/features/professional_portal/presentation/screens/client_diet_screen.dart';
import 'package:bldr_fitness/features/professional_portal/presentation/screens/client_workout_list_screen.dart';

// --- IMPORTS ATUALIZADOS (V2.0 VISUAL + PAYWALL) ---
import 'package:bldr_fitness/features/professional_portal/presentation/widgets/client_card_widget.dart';
import 'package:bldr_fitness/features/professional_portal/presentation/widgets/empty_state_widget.dart';
import 'package:bldr_fitness/features/professional_portal/presentation/screens/professional_paywall_screen.dart';
// --- FIM DOS IMPORTS ---


class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalDashboardScreen> createState() => _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState extends State<ProfessionalDashboardScreen> {
  final _repository = ProfessionalRepository();

  String? _professionalRole;
  String _errorMessage = '';

  // --- VARIÁVEIS DE ESTADO DO PAYWALL ---
  String _subscriptionStatus = 'inactive'; // Começa como 'inactive' por segurança
  // --- FIM DAS VARIÁVEIS ---

  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // --- LÓGICA DE CARREGAMENTO ATUALIZADA (PAYWALL) ---
  Future<void> _loadInitialData() async {
    try {
      // 1. Busca o perfil completo (role e status)
      // Chama a função com o nome correto: getMyProfessionalProfile
      final profile = await _repository.getMyProfessionalProfile();
      final role = profile['role'] as String?;
      final status = profile['subscription_status'] as String?;

      // 2. Se o status for inativo, não precisamos carregar os clientes.
      if (status != 'active') {
        if (mounted) {
          setState(() {
            _professionalRole = role;
            _subscriptionStatus = status ?? 'inactive';
            _isLoading = false;
          });
        }
        return; // Para aqui. Vai mostrar o Paywall.
      }

      // 3. Se estiver ativo, carrega os clientes.
      final clientIds = await _repository.getMyClientsIds();
      final clientProfiles = await Future.wait(
          clientIds.map((id) => _repository.getClientProfileById(id))
      );

      if (mounted) {
        setState(() {
          _professionalRole = role;
          _subscriptionStatus = status!;
          _clients = clientProfiles.map((profile) {
            return {
              'id': profile['id'],
              'full_name': profile['full_name'] ?? 'Nome não encontrado',
              'avatar_url': profile['avatar_url']
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }
  // --- FIM DA ATUALIZAÇÃO ---

  // Esta função é chamada pelo Paywall após um pagamento bem-sucedido
  void _refreshAllData() {
    setState(() { _isLoading = true; });
    _loadInitialData();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login-screen', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showAddClientDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Cliente'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail do Cliente'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || !value.contains('@')) ? 'E-mail inválido' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final email = emailController.text.trim();
                  Navigator.of(context).pop();

                  try {
                    final successMessage = await _repository.addClientByEmail(email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
                    );
                    _refreshAllData(); // Atualiza a lista
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToClient(Map<String, dynamic> client) {
    final clientName = client['full_name'] ?? 'Cliente';
    final clientId = client['id'];

    if (_professionalRole == 'personal') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientWorkoutListScreen(
            clientId: clientId,
            clientName: clientName,
          ),
        ),
      );
    } else if (_professionalRole == 'nutritionist') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDietScreen(
            clientId: clientId,
            clientName: clientName,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _professionalRole == 'personal'
              ? 'Meus Alunos (Personal)'
              : _professionalRole == 'nutritionist'
              ? 'Meus Pacientes (Nutri)'
              : 'Painel do Profissional',
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _subscriptionStatus == 'active'
          ? FloatingActionButton(
        onPressed: _showAddClientDialog,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      )
          : null,
    );
  }

  // --- _buildBody() ATUALIZADO COM A LÓGICA DO PAYWALL ---
  Widget _buildBody() {
    // 1. Estado de Carregamento
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Estado de Erro
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text('Erro: $_errorMessage'));
    }

    // 3. A "MURALHA" (PAYWALL)
    // Se o status não for 'active', mostra a tela de pagamento.
    if (_subscriptionStatus != 'active') {
      return ProfessionalPaywallScreen(
        onSubscriptionSuccess: _refreshAllData,
      );
    }
    // --- FIM DA MURALHA ---

    // 4. Estado de Lista Vazia (só é mostrado se estiver 'active')
    if (_clients.isEmpty) {
      return EmptyStateWidget(
        title: "Nenhum Cliente Adicionado",
        message: "Clique no botão '+' para adicionar seu primeiro cliente pelo e-mail.",
        iconData: Icons.people_outline,
        buttonText: "Adicionar Cliente",
        onButtonPressed: _showAddClientDialog,
      );
    }

    // 5. Estado de Sucesso (só é mostrado se estiver 'active')
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.8,
      ),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];

        return InkWell(
          onTap: () => _navigateToClient(client),
          borderRadius: BorderRadius.circular(16),
          child: ClientCardWidget(
            clientName: client['full_name'] ?? 'Nome não encontrado',
            avatarUrl: client['avatar_url'],
          ),
        );
      },
    );
  }
}