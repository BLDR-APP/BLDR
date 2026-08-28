// lib/features/professional_portal/presentation/widgets/client_card_widget.dart

import 'package:flutter/material.dart';

class ClientCardWidget extends StatelessWidget {
  final String clientName;
  final String? avatarUrl;

  const ClientCardWidget({
    Key? key,
    required this.clientName,
    this.avatarUrl,
  }) : super(key: key);

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return parts[0][0].toUpperCase() + parts.last[0].toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(clientName);
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Card(
      color: Colors.grey.shade900, // Cor de fundo do card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800, width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey.shade800,
              // Tenta carregar a imagem da URL
              backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
              // Se não tiver imagem, mostra as iniciais
              child: hasImage
                  ? null
                  : Text(
                initials,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              clientName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}