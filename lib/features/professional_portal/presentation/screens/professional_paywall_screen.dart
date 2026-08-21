// lib/features/professional_portal/presentation/screens/professional_paywall_screen.dart

import 'package:bldr_fitness/features/professional_portal/data/repositories/professional_repository.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfessionalPaywallScreen extends StatefulWidget {
  // A função para recarregar o dashboard após o sucesso
  final VoidCallback onSubscriptionSuccess;

  const ProfessionalPaywallScreen({
    Key? key,
    required this.onSubscriptionSuccess,
  }) : super(key: key);

  @override
  State<ProfessionalPaywallScreen> createState() => _ProfessionalPaywallScreenState();
}

class _ProfessionalPaywallScreenState extends State<ProfessionalPaywallScreen> {
  final _repository = ProfessionalRepository();
  bool _isLoading = false;

  //
  // ================== ATENÇÃO AQUI ==================
  //
  // Cole aqui o ID do Plano Profissional que você criou no Stripe
  // (Ex: "price_1P...")
  //
  final String _professionalPriceId = "price_1ST5dyRyVeX3wSWAgGL2FKiz";
  //
  // ==================================================
  //

  Future<void> _subscribeNow() async {
    if (_professionalPriceId.contains("COLE_SEU_PRICE_ID")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: O Price ID do Stripe não foi configurado no código.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Chama a função que vamos criar no repositório
      // (Seu editor vai dar erro aqui por enquanto, é normal)
      final checkoutUrl = await _repository.createProfessionalCheckoutSession(
        priceId: _professionalPriceId,
      );

      // 2. Abre a URL do Stripe no navegador
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // NOTA: Não podemos confirmar o pagamento aqui.
        // O usuário precisa fechar o navegador e o app precisa
        // ser "notificado" pelo webhook.
        // Vamos recarregar o dashboard quando o app voltar ao foco.
        // (Isso é uma melhoria V2, por enquanto ele verá o paywall de novo
        // até o webhook atualizar o status e ele recarregar a tela)
      } else {
        throw Exception('Não foi possível abrir a página de pagamento.');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto para o paywall
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(
              Icons.lock_open_rounded,
              color: Colors.amber,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'Desbloqueie o Portal Profissional',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Acesse todas as ferramentas para gerenciar seus clientes e elevar seus resultados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            _buildBenefitItem('✅', 'Gerencie clientes ilimitados.'),
            _buildBenefitItem('✅', 'Crie planos de treino personalizados.'),
            _buildBenefitItem('✅', 'Monte dietas estruturadas (V2).'),
            _buildBenefitItem('✅', 'Acompanhe o progresso (V2).'),

            const Spacer(),

            // Botão de Assinatura
            ElevatedButton(
              onPressed: _isLoading ? null : _subscribeNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
              )
                  : const Text(
                'Assinar Agora (R\$ 70,00 / mês)', // Altere o preço se necessário
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pagamento seguro via Stripe. Cancele quando quiser.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}