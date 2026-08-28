import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/theme/app_theme.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class EditProfileDialogWidget extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;
  final String? currentUsername;
  final Function(String name, String email, String phone, String? username) onSave;

  const EditProfileDialogWidget({
    Key? key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
    this.currentUsername,
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
  late TextEditingController _usernameController;
  late FocusNode _usernameFocusNode;

  String? _usernameError;
  bool _usernameAvailable = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _usernameController = TextEditingController(text: widget.currentUsername ?? '');
    _usernameFocusNode = FocusNode();
    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) {
        _validateUsername();
      }
    });
  }

  Future<void> _validateUsername() async {
    final value = _usernameController.text.trim();
    if (value.isEmpty) {
      setState(() {
        _usernameError = null;
        _usernameAvailable = false;
      });
      return;
    }
    if (value == widget.currentUsername) {
      setState(() {
        _usernameError = null;
        _usernameAvailable = true;
      });
      return;
    }
    try {
      final available = await UserService.instance.isUsernameAvailable(value);
      setState(() {
        _usernameError = available ? null : 'Username já em uso';
        _usernameAvailable = available;
      });
    } catch (_) {
      setState(() {
        _usernameError = null;
        _usernameAvailable = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _usernameFocusNode.dispose();
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

            // Username
            TextFormField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              onEditingComplete: () {
                _usernameFocusNode.unfocus();
              },
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                hintText: 'seu_username',
                hintStyle: TextStyle(color: AppTheme.textSecondary.withAlpha(128)),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.errorRed),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.errorRed),
                ),
                errorText: _usernameError,
                prefix: Text(
                  '@',
                  style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w600),
                ),
                suffixIcon: _usernameController.text.isNotEmpty && _usernameError == null && _usernameAvailable
                    ? const Icon(Icons.check_circle, color: AppTheme.successGreen)
                    : null,
                counterText: '',
              ),
              style: TextStyle(color: AppTheme.textPrimary),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
              ],
              maxLength: 20,
              onChanged: (_) {
                if (_usernameError != null || _usernameAvailable) {
                  setState(() {
                    _usernameError = null;
                    _usernameAvailable = false;
                  });
                }
              },
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
                  if (_usernameError != null) return;

                  final username = _usernameController.text.trim();
                  Navigator.pop(context);
                  widget.onSave(
                    name,
                    _emailController.text.trim(),
                    _phoneController.text.trim(),
                    username.isEmpty ? null : username,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.edit_profile_save_btn, style: const TextStyle(color: Colors.black)),
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
