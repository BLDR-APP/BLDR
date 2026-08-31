import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_hub.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';

class PantherFab extends StatefulWidget {
  const PantherFab({super.key});

  @override
  State<PantherFab> createState() => _PantherFabState();
}

class _PantherFabState extends State<PantherFab> {
  late final Future<bool> _access = _loadAccess();

  Future<bool> _loadAccess() async =>
      (await getIt<ResolveClubAccess>()()).valueOrNull ?? false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _access,
      builder: (context, snapshot) {
        final hasClubAccess = snapshot.data ?? false;
        return GestureDetector(
          onTap: () {
            if (hasClubAccess) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HavokHubScreen()),
              );
            } else {
              ClubPaywallSheet.show(context);
            }
          },
          child: Container(
            width: 70.0,
            height: 70.0,
            decoration: BoxDecoration(
              // REMOVEMOS O BACKGROUND AQUI
              // borderRadius: BorderRadius.circular(16.0), // Se quiser borda, pode manter
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6), // Cor da sombra
                  blurRadius: 10, // Intensidade do blur
                  spreadRadius: 2, // Espalhamento da sombra
                  offset: const Offset(0, 4), // Posição da sombra (x, y)
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // A imagem da pantera
                Image.asset(
                  'assets/images/havoknew.png',
                  width: 70, // Ajustamos a largura para preencher o Container
                  height: 70, // Ajustamos a altura para preencher o Container
                  fit: BoxFit.contain, // Garante que a imagem se ajuste
                ),

                // O cadeado (só aparece se o usuário NÃO for premium)
                if (!hasClubAccess)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Icon(
                      Icons.lock,
                      color: Colors.amber.withOpacity(0.8),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
