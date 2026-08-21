// lib/features/professional_portal/presentation/widgets/empty_state_widget.dart

import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData iconData;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.iconData,
    required this.buttonText,
    required this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 80,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.add, color: Colors.black),
              label: Text(
                buttonText,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, // Cor de destaque do BLDR
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}