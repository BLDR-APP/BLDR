import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class ExportProgressWidget extends StatelessWidget {
  final Function(String format) onExport;

  const ExportProgressWidget({
    Key? key,
    required this.onExport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(4.w),
      // Adicionando uma cor de fundo explícita para garantir o visual dark no modal
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de "puxar"
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.dividerGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 3.h),

          Text(
            l10n.export_title,
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.export_subtitle,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 3.h),

          // Opção 1: PDF (Agora é um relatório oficial)
          _buildExportOption(
            l10n.export_pdf_title,
            l10n.export_pdf_desc,
            'picture_as_pdf',
            AppTheme.errorRed, // Mantém vermelho pois é padrão visual de PDF
            'PDF',
          ),
          SizedBox(height: 2.h),

          // Opção 2: CSV (Excel)
          _buildExportOption(
            l10n.export_csv_title,
            l10n.export_csv_desc,
            'table_view', // Ícone mais moderno para tabelas
            AppTheme.successGreen,
            'CSV',
          ),
          SizedBox(height: 2.h),

          // Opção 3: Compartilhar Texto
          _buildExportOption(
            l10n.export_share_title,
            l10n.export_share_desc,
            'ios_share', // Ícone de share nativo costuma ser mais reconhecível
            AppTheme.accentGold,
            'Share',
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildExportOption(
      String title,
      String description,
      String iconName,
      Color color,
      String format,
      ) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => onExport(format),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16), // Borda um pouco mais arredondada
            border: Border.all(color: AppTheme.dividerGray.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), // Transparência ajustada
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: color,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.2
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              CustomIconWidget(
                iconName: 'chevron_right',
                color: AppTheme.inactiveGray,
                size: 5.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}