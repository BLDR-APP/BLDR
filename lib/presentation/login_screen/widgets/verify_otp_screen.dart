import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:pinput/pinput.dart'; // Você precisará adicionar esta biblioteca!

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Chama a nova função de verificação
      final response = await AuthService.instance.verifyPasswordResetOtp(
        widget.email,
        _otpController.text,
      );

      // 2. Se for sucesso, o usuário está logado em uma sessão de reset
      if (response.user != null && mounted) {
        // 3. Navega para a tela de criar nova senha (que já existe!)
        Navigator.pushReplacementNamed(context, AppRoutes.createNewPasswordScreen);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Código inválido ou expirado. Tente novamente.'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema do Pinput (estilo dos quadradinhos)
    final defaultPinTheme = PinTheme(
      width: 13.w,
      height: 13.w,
      textStyle: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
        color: AppTheme.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withValues(alpha: 0.6),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Verificar Código'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.password_rounded,
                color: AppTheme.accentGold,
                size: 20.w,
              ),
              SizedBox(height: 4.h),
              Text(
                'Digite o Código',
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Enviamos um código de 6 dígitos para o seu e-mail:',
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                widget.email, // Mostra o e-mail que está recebendo o código
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),

              // Campo de Pinput para o OTP
              Pinput(
                controller: _otpController,
                length: 6,
                autofocus: true,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppTheme.accentGold),
                  ),
                ),
                validator: (s) {
                  return s?.length == 6 ? null : 'Digite o código de 6 dígitos';
                },
              ),
              SizedBox(height: 6.h),

              // Botão de Verificar
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryBlack,
                  ),
                )
                    : Text(
                  'Verificar e Continuar',
                  style: TextStyle(color: AppTheme.primaryBlack),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}