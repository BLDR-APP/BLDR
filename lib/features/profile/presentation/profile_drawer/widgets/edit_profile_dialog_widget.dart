import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/theme/app_theme.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class EditProfileDialogWidget extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;
  final Function(String name, String email, String phone) onSave;

  const EditProfileDialogWidget({
    Key? key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditProfileDialogWidget> createState() =>
      _EditProfileDialogWidgetState();
}

class _EditProfileDialogWidgetState extends State<EditProfileDialogWidget> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: BldrColors.sheetBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BldrColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.edit_profile_dialog_title,
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),

            // Nome
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.edit_profile_name_label,
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.person, color: AppTheme.accentGold),
              ),
              style: TextStyle(color: AppTheme.textPrimary),
            ),

            SizedBox(height: 2.h),

            // Email (readonly para Supabase)
            TextFormField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: l10n.edit_profile_email_label,
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardDark.withAlpha(128),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.email, color: AppTheme.textSecondary),
                suffixIcon: Tooltip(
                  message: l10n.edit_profile_email_tooltip,
                  child: Icon(Icons.info, color: AppTheme.textSecondary),
                ),
              ),
              style: TextStyle(color: AppTheme.textSecondary),
            ),

            SizedBox(height: 2.h),

            // Telefone (opcional)
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.edit_profile_phone_label,
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.phone, color: AppTheme.accentGold),
              ),
              style: TextStyle(color: AppTheme.textPrimary),
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: 3.h),

        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                // <<< NOVO: FittedBox evita que a palavra quebre no meio
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.common_cancel),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.edit_profile_name_required),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  widget.onSave(
                    name,
                    _emailController.text.trim(),
                    _phoneController.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                ),
                // <<< NOVO: FittedBox garante o texto na mesma linha
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.edit_profile_save_btn, style: const TextStyle(color: Colors.black)), // Garanti a cor preta para contrastar com o dourado
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
