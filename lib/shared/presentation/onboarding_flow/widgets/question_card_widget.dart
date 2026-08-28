import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/theme/app_theme.dart';

class QuestionCardWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const QuestionCardWidget({
    Key? key,
    required this.title,
    this.subtitle,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Padding vertical reduzido levemente para ganhar espaço em telas pequenas
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // <<< BLINDAGEM 1: Título protegido >>>
          // Se a fonte for gigante, o texto diminui para caber na largura sem quebrar
          // muitas linhas e comer a tela toda.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 2, // Limita a 2 linhas para não dominar a tela
              style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (subtitle != null) ...[
            SizedBox(height: 1.5.h), // Espaçamento reduzido

            // <<< BLINDAGEM 2: Subtítulo protegido >>>
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                maxLines: 2,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],

          SizedBox(height: 3.h),

          // O conteúdo da tela (Inputs, Selectors, etc)
          child,
        ],
      ),
    );
  }
}