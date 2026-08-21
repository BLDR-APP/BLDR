import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
    Locale('pt')
  ];

  /// No description provided for @common_continue_btn.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get common_continue_btn;

  /// No description provided for @common_finish_btn.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get common_finish_btn;

  /// No description provided for @common_back_btn.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get common_back_btn;

  /// No description provided for @common_next_btn.
  ///
  /// In pt, this message translates to:
  /// **'Avançar'**
  String get common_next_btn;

  /// No description provided for @common_cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get common_cancel;

  /// No description provided for @common_ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_resend.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar'**
  String get common_resend;

  /// No description provided for @common_or.
  ///
  /// In pt, this message translates to:
  /// **'ou'**
  String get common_or;

  /// No description provided for @common_retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get common_retry;

  /// No description provided for @common_start_btn.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get common_start_btn;

  /// No description provided for @common_got_it_btn.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get common_got_it_btn;

  /// No description provided for @login_title.
  ///
  /// In pt, this message translates to:
  /// **'Bem-Vindo!'**
  String get login_title;

  /// No description provided for @login_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Faça login para continuar sua jornada fitness'**
  String get login_subtitle;

  /// No description provided for @login_email_label.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get login_email_label;

  /// No description provided for @login_email_hint.
  ///
  /// In pt, this message translates to:
  /// **'Insira seu endereço de e-mail'**
  String get login_email_hint;

  /// No description provided for @login_email_required_error.
  ///
  /// In pt, this message translates to:
  /// **'E-mail é obrigatório'**
  String get login_email_required_error;

  /// No description provided for @login_email_invalid_error.
  ///
  /// In pt, this message translates to:
  /// **'Insira um endereço de e-mail válido'**
  String get login_email_invalid_error;

  /// No description provided for @login_password_label.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get login_password_label;

  /// No description provided for @login_password_hint.
  ///
  /// In pt, this message translates to:
  /// **'Insira sua senha'**
  String get login_password_hint;

  /// No description provided for @login_password_required_error.
  ///
  /// In pt, this message translates to:
  /// **'Senha é obrigatória'**
  String get login_password_required_error;

  /// No description provided for @login_remember_me.
  ///
  /// In pt, this message translates to:
  /// **'Lembrar-me'**
  String get login_remember_me;

  /// No description provided for @login_forgot_password.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu a senha?'**
  String get login_forgot_password;

  /// No description provided for @login_btn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get login_btn;

  /// No description provided for @login_apple_btn.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com a Apple'**
  String get login_apple_btn;

  /// No description provided for @login_google_btn.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com o Google'**
  String get login_google_btn;

  /// No description provided for @login_no_account.
  ///
  /// In pt, this message translates to:
  /// **'Não possui uma conta? '**
  String get login_no_account;

  /// No description provided for @login_create_account_link.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get login_create_account_link;

  /// No description provided for @login_email_not_confirmed_title.
  ///
  /// In pt, this message translates to:
  /// **'E-mail não confirmado'**
  String get login_email_not_confirmed_title;

  /// No description provided for @login_email_not_confirmed_body.
  ///
  /// In pt, this message translates to:
  /// **'Você precisa confirmar seu e-mail antes de fazer login. Verifique sua caixa de entrada e clique no link de confirmação.'**
  String get login_email_not_confirmed_body;

  /// No description provided for @login_email_confirmation_resent.
  ///
  /// In pt, this message translates to:
  /// **'E-mail de confirmação reenviado'**
  String get login_email_confirmation_resent;

  /// No description provided for @login_resend_email_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao reenviar e-mail: {message}'**
  String login_resend_email_error(String message);

  /// No description provided for @login_recover_password_title.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar Senha'**
  String get login_recover_password_title;

  /// No description provided for @login_recover_password_body.
  ///
  /// In pt, this message translates to:
  /// **'Insira seu e-mail para receber um código de 6 dígitos.'**
  String get login_recover_password_body;

  /// No description provided for @login_enter_email_hint.
  ///
  /// In pt, this message translates to:
  /// **'Insira seu e-mail'**
  String get login_enter_email_hint;

  /// No description provided for @login_enter_email_error.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira um e-mail.'**
  String get login_enter_email_error;

  /// No description provided for @login_send_code_btn.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Código'**
  String get login_send_code_btn;

  /// No description provided for @login_send_code_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar código: {message}'**
  String login_send_code_error(String message);

  /// No description provided for @login_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha no login: {message}'**
  String login_error(String message);

  /// No description provided for @signup_title.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get signup_title;

  /// No description provided for @signup_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Junte-se à BLDR e comece sua jornada fitness com treinos personalizados e acompanhamento nutricional.'**
  String get signup_subtitle;

  /// No description provided for @signup_form_title.
  ///
  /// In pt, this message translates to:
  /// **'Juntar-se ao BLDR'**
  String get signup_form_title;

  /// No description provided for @signup_form_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Começe sua transformação fitness hoje'**
  String get signup_form_subtitle;

  /// No description provided for @signup_full_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get signup_full_name_label;

  /// No description provided for @signup_full_name_hint.
  ///
  /// In pt, this message translates to:
  /// **'Insira seu nome completo'**
  String get signup_full_name_hint;

  /// No description provided for @signup_full_name_required_error.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo é obrigatório'**
  String get signup_full_name_required_error;

  /// No description provided for @signup_full_name_min_length_error.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo deve ter pelo menos 2 caractéres'**
  String get signup_full_name_min_length_error;

  /// No description provided for @signup_password_min_length_error.
  ///
  /// In pt, this message translates to:
  /// **'Senha deverá conter 8 caractéres'**
  String get signup_password_min_length_error;

  /// No description provided for @signup_password_uppercase_error.
  ///
  /// In pt, this message translates to:
  /// **'Senha deverá conter pelo menos um caractére em maiúsculo'**
  String get signup_password_uppercase_error;

  /// No description provided for @signup_password_number_error.
  ///
  /// In pt, this message translates to:
  /// **'Senha deverá conter pelo menos um número'**
  String get signup_password_number_error;

  /// No description provided for @signup_confirm_password_label.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha'**
  String get signup_confirm_password_label;

  /// No description provided for @signup_confirm_password_hint.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua senha'**
  String get signup_confirm_password_hint;

  /// No description provided for @signup_confirm_password_required_error.
  ///
  /// In pt, this message translates to:
  /// **'Por favor confirme sua senha'**
  String get signup_confirm_password_required_error;

  /// No description provided for @signup_passwords_mismatch_error.
  ///
  /// In pt, this message translates to:
  /// **'Senhas não coincidem'**
  String get signup_passwords_mismatch_error;

  /// No description provided for @signup_agree_terms_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Eu concordo com os '**
  String get signup_agree_terms_prefix;

  /// No description provided for @signup_terms_of_service.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Serviço'**
  String get signup_terms_of_service;

  /// No description provided for @signup_privacy_policy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get signup_privacy_policy;

  /// No description provided for @signup_must_agree_terms_error.
  ///
  /// In pt, this message translates to:
  /// **'Por favor concorde com os Termos de Serviço'**
  String get signup_must_agree_terms_error;

  /// No description provided for @signup_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro no cadastro: {message}'**
  String signup_error(String message);

  /// No description provided for @signup_create_account_btn.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get signup_create_account_btn;

  /// No description provided for @signup_already_have_account.
  ///
  /// In pt, this message translates to:
  /// **'Já possui uma conta? '**
  String get signup_already_have_account;

  /// No description provided for @signup_confirm_email_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirme seu E-mail'**
  String get signup_confirm_email_title;

  /// No description provided for @signup_confirm_email_sent_to.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um e-mail de confirmação para:'**
  String get signup_confirm_email_sent_to;

  /// No description provided for @signup_confirm_email_instruction.
  ///
  /// In pt, this message translates to:
  /// **'Clique no link do e-mail para confirmar sua conta e continuar.'**
  String get signup_confirm_email_instruction;

  /// No description provided for @signup_resend_email_btn.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar E-mail'**
  String get signup_resend_email_btn;

  /// No description provided for @signup_back_to_login_btn.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao Login'**
  String get signup_back_to_login_btn;

  /// No description provided for @wait_confirm_email_body.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um link de confirmação para o seu endereço de e-mail. Por favor, clique no link para ativar sua conta.'**
  String get wait_confirm_email_body;

  /// No description provided for @wait_confirm_no_email_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível encontrar o e-mail do usuário.'**
  String get wait_confirm_no_email_error;

  /// No description provided for @wait_confirm_email_resent_success.
  ///
  /// In pt, this message translates to:
  /// **'E-mail de confirmação reenviado com sucesso!'**
  String get wait_confirm_email_resent_success;

  /// No description provided for @wait_confirm_back_to_login_btn.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o Login'**
  String get wait_confirm_back_to_login_btn;

  /// No description provided for @otp_title.
  ///
  /// In pt, this message translates to:
  /// **'Verificar Código'**
  String get otp_title;

  /// No description provided for @otp_heading.
  ///
  /// In pt, this message translates to:
  /// **'Digite o Código'**
  String get otp_heading;

  /// No description provided for @otp_body.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um código de 6 dígitos para o seu e-mail:'**
  String get otp_body;

  /// No description provided for @otp_validator_error.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código de 6 dígitos'**
  String get otp_validator_error;

  /// No description provided for @otp_verify_btn.
  ///
  /// In pt, this message translates to:
  /// **'Verificar e Continuar'**
  String get otp_verify_btn;

  /// No description provided for @otp_invalid_code_error.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido ou expirado. Tente novamente.'**
  String get otp_invalid_code_error;

  /// No description provided for @new_password_title.
  ///
  /// In pt, this message translates to:
  /// **'Criar Nova Senha'**
  String get new_password_title;

  /// No description provided for @new_password_heading.
  ///
  /// In pt, this message translates to:
  /// **'Defina sua Nova Senha'**
  String get new_password_heading;

  /// No description provided for @new_password_body.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira uma nova senha forte para sua conta.'**
  String get new_password_body;

  /// No description provided for @new_password_field_label.
  ///
  /// In pt, this message translates to:
  /// **'Nova Senha'**
  String get new_password_field_label;

  /// No description provided for @new_password_field_hint.
  ///
  /// In pt, this message translates to:
  /// **'Insira sua nova senha'**
  String get new_password_field_hint;

  /// No description provided for @new_password_min_length_error.
  ///
  /// In pt, this message translates to:
  /// **'Senha deverá conter pelo menos 8 caracteres'**
  String get new_password_min_length_error;

  /// No description provided for @new_password_confirm_label.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Nova Senha'**
  String get new_password_confirm_label;

  /// No description provided for @new_password_confirm_hint.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua nova senha'**
  String get new_password_confirm_hint;

  /// No description provided for @new_password_passwords_mismatch_error.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get new_password_passwords_mismatch_error;

  /// No description provided for @new_password_save_btn.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Nova Senha'**
  String get new_password_save_btn;

  /// No description provided for @new_password_success.
  ///
  /// In pt, this message translates to:
  /// **'Senha atualizada com sucesso!'**
  String get new_password_success;

  /// No description provided for @new_password_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar senha: {message}'**
  String new_password_error(String message);

  /// No description provided for @new_password_confirm_required_error.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, confirme sua senha'**
  String get new_password_confirm_required_error;

  /// No description provided for @onboarding_step_indicator.
  ///
  /// In pt, this message translates to:
  /// **'Passo {step} de {total}'**
  String onboarding_step_indicator(int step, int total);

  /// No description provided for @onboarding_exit_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Sair da Configuração?'**
  String get onboarding_exit_dialog_title;

  /// No description provided for @onboarding_exit_dialog_body.
  ///
  /// In pt, this message translates to:
  /// **'Seu progresso será perdido.'**
  String get onboarding_exit_dialog_body;

  /// No description provided for @onboarding_exit_dialog_exit_btn.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get onboarding_exit_dialog_exit_btn;

  /// No description provided for @onboarding_completion_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao concluir configuração: {error}'**
  String onboarding_completion_error(String error);

  /// No description provided for @onboarding_welcome_title.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao BLDR.'**
  String get onboarding_welcome_title;

  /// No description provided for @onboarding_welcome_body.
  ///
  /// In pt, this message translates to:
  /// **'Vamos configurar seu plano 100% personalizado com a IA HAVOK.'**
  String get onboarding_welcome_body;

  /// No description provided for @onboarding_welcome_bullet_nutrition.
  ///
  /// In pt, this message translates to:
  /// **'Plano de nutrição personalizado'**
  String get onboarding_welcome_bullet_nutrition;

  /// No description provided for @onboarding_welcome_bullet_workout.
  ///
  /// In pt, this message translates to:
  /// **'Treino gerado pelo HAVOK'**
  String get onboarding_welcome_bullet_workout;

  /// No description provided for @onboarding_welcome_bullet_adjustments.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes contínuos conforme sua evolução'**
  String get onboarding_welcome_bullet_adjustments;

  /// No description provided for @onboarding_welcome_duration_hint.
  ///
  /// In pt, this message translates to:
  /// **'Isso levará apenas alguns minutos.'**
  String get onboarding_welcome_duration_hint;

  /// No description provided for @onboarding_goal_title.
  ///
  /// In pt, this message translates to:
  /// **'Qual é a sua meta principal?'**
  String get onboarding_goal_title;

  /// No description provided for @onboarding_goal_body.
  ///
  /// In pt, this message translates to:
  /// **'Isso definirá a direção do seu plano de nutrição.'**
  String get onboarding_goal_body;

  /// No description provided for @onboarding_pace_title.
  ///
  /// In pt, this message translates to:
  /// **'Em qual ritmo você prefere ir?'**
  String get onboarding_pace_title;

  /// No description provided for @onboarding_pace_body.
  ///
  /// In pt, this message translates to:
  /// **'Ritmo agressivo traz resultados mais rápidos, mas exige mais disciplina.'**
  String get onboarding_pace_body;

  /// No description provided for @onboarding_profile_title.
  ///
  /// In pt, this message translates to:
  /// **'Sobre você'**
  String get onboarding_profile_title;

  /// No description provided for @onboarding_profile_body.
  ///
  /// In pt, this message translates to:
  /// **'Essencial para calcular suas metas de nutrição.'**
  String get onboarding_profile_body;

  /// No description provided for @onboarding_profile_age.
  ///
  /// In pt, this message translates to:
  /// **'Idade'**
  String get onboarding_profile_age;

  /// No description provided for @onboarding_profile_height.
  ///
  /// In pt, this message translates to:
  /// **'Altura'**
  String get onboarding_profile_height;

  /// No description provided for @onboarding_profile_weight.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get onboarding_profile_weight;

  /// No description provided for @onboarding_activity_title.
  ///
  /// In pt, this message translates to:
  /// **'Como é o seu dia-a-dia?'**
  String get onboarding_activity_title;

  /// No description provided for @onboarding_activity_body.
  ///
  /// In pt, this message translates to:
  /// **'Excluindo treinos e esportes — define seu NEAT.'**
  String get onboarding_activity_body;

  /// No description provided for @onboarding_workout_config_title.
  ///
  /// In pt, this message translates to:
  /// **'Configurando seu treino'**
  String get onboarding_workout_config_title;

  /// No description provided for @onboarding_workout_config_body.
  ///
  /// In pt, this message translates to:
  /// **'Essas informações guiam a IA HAVOK na criação do seu plano.'**
  String get onboarding_workout_config_body;

  /// No description provided for @onboarding_experience_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Nível de experiência'**
  String get onboarding_experience_section_title;

  /// No description provided for @onboarding_freq_days_label.
  ///
  /// In pt, this message translates to:
  /// **'Dias por semana'**
  String get onboarding_freq_days_label;

  /// No description provided for @onboarding_duration_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio por sessão'**
  String get onboarding_duration_section_title;

  /// No description provided for @onboarding_environment_title.
  ///
  /// In pt, this message translates to:
  /// **'Onde você vai treinar?'**
  String get onboarding_environment_title;

  /// No description provided for @onboarding_environment_body.
  ///
  /// In pt, this message translates to:
  /// **'Isso dirá ao HAVOK quais exercícios incluir.'**
  String get onboarding_environment_body;

  /// No description provided for @onboarding_equipment_title.
  ///
  /// In pt, this message translates to:
  /// **'Quais equipamentos você tem?'**
  String get onboarding_equipment_title;

  /// No description provided for @onboarding_equipment_body.
  ///
  /// In pt, this message translates to:
  /// **'Selecione todos que se aplicam.'**
  String get onboarding_equipment_body;

  /// No description provided for @onboarding_activities_title.
  ///
  /// In pt, this message translates to:
  /// **'Atividades e foco muscular'**
  String get onboarding_activities_title;

  /// No description provided for @onboarding_activities_body.
  ///
  /// In pt, this message translates to:
  /// **'Quais atividades você pratica e onde quer focar.'**
  String get onboarding_activities_body;

  /// No description provided for @onboarding_activities_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Atividades físicas'**
  String get onboarding_activities_section_title;

  /// No description provided for @onboarding_muscles_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Grupos musculares'**
  String get onboarding_muscles_section_title;

  /// No description provided for @onboarding_muscles_body.
  ///
  /// In pt, this message translates to:
  /// **'Selecione os músculos que quer priorizar.'**
  String get onboarding_muscles_body;

  /// No description provided for @onboarding_split_injuries_title.
  ///
  /// In pt, this message translates to:
  /// **'Divisão e lesões'**
  String get onboarding_split_injuries_title;

  /// No description provided for @onboarding_split_injuries_body.
  ///
  /// In pt, this message translates to:
  /// **'Últimas informações para o HAVOK montar seu treino.'**
  String get onboarding_split_injuries_body;

  /// No description provided for @onboarding_split_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Divisão de treino'**
  String get onboarding_split_section_title;

  /// No description provided for @onboarding_split_body.
  ///
  /// In pt, this message translates to:
  /// **'Se não souber, deixe o HAVOK decidir.'**
  String get onboarding_split_body;

  /// No description provided for @onboarding_injuries_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Lesões ou limitações'**
  String get onboarding_injuries_section_title;

  /// No description provided for @onboarding_injuries_body.
  ///
  /// In pt, this message translates to:
  /// **'O HAVOK evitará exercícios que prejudiquem sua recuperação.'**
  String get onboarding_injuries_body;

  /// No description provided for @onboarding_injury_other_hint.
  ///
  /// In pt, this message translates to:
  /// **'Descreva sua lesão...'**
  String get onboarding_injury_other_hint;

  /// No description provided for @onboarding_summary_title.
  ///
  /// In pt, this message translates to:
  /// **'Tudo pronto!'**
  String get onboarding_summary_title;

  /// No description provided for @onboarding_summary_body.
  ///
  /// In pt, this message translates to:
  /// **'Seu plano personalizado foi calculado.'**
  String get onboarding_summary_body;

  /// No description provided for @onboarding_summary_nutrition_section.
  ///
  /// In pt, this message translates to:
  /// **'Nutrição'**
  String get onboarding_summary_nutrition_section;

  /// No description provided for @onboarding_summary_tdee.
  ///
  /// In pt, this message translates to:
  /// **'TDEE: {tdee} kcal/dia'**
  String onboarding_summary_tdee(String tdee);

  /// No description provided for @onboarding_calorie_goal_label.
  ///
  /// In pt, this message translates to:
  /// **'Meta calórica'**
  String get onboarding_calorie_goal_label;

  /// No description provided for @onboarding_protein_label.
  ///
  /// In pt, this message translates to:
  /// **'Proteína'**
  String get onboarding_protein_label;

  /// No description provided for @onboarding_summary_carbs_label.
  ///
  /// In pt, this message translates to:
  /// **'Carboidrato'**
  String get onboarding_summary_carbs_label;

  /// No description provided for @onboarding_summary_fat_label.
  ///
  /// In pt, this message translates to:
  /// **'Gordura'**
  String get onboarding_summary_fat_label;

  /// No description provided for @onboarding_summary_hydration_label.
  ///
  /// In pt, this message translates to:
  /// **'Hidratação'**
  String get onboarding_summary_hydration_label;

  /// No description provided for @onboarding_summary_workout_section.
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get onboarding_summary_workout_section;

  /// No description provided for @onboarding_summary_goal_label.
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get onboarding_summary_goal_label;

  /// No description provided for @onboarding_summary_level_label.
  ///
  /// In pt, this message translates to:
  /// **'Nível'**
  String get onboarding_summary_level_label;

  /// No description provided for @onboarding_summary_frequency_label.
  ///
  /// In pt, this message translates to:
  /// **'Frequência'**
  String get onboarding_summary_frequency_label;

  /// No description provided for @onboarding_summary_duration_label.
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get onboarding_summary_duration_label;

  /// No description provided for @onboarding_summary_environment_label.
  ///
  /// In pt, this message translates to:
  /// **'Ambiente'**
  String get onboarding_summary_environment_label;

  /// No description provided for @onboarding_summary_split_label.
  ///
  /// In pt, this message translates to:
  /// **'Split'**
  String get onboarding_summary_split_label;

  /// No description provided for @onboarding_summary_focus_label.
  ///
  /// In pt, this message translates to:
  /// **'Foco'**
  String get onboarding_summary_focus_label;

  /// No description provided for @onboarding_summary_confirm_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ao confirmar, o HAVOK gerará seu plano de treino personalizado.'**
  String get onboarding_summary_confirm_hint;

  /// No description provided for @onboarding_tdee_info_title.
  ///
  /// In pt, this message translates to:
  /// **'O que é TDEE?'**
  String get onboarding_tdee_info_title;

  /// No description provided for @onboarding_tdee_info_body.
  ///
  /// In pt, this message translates to:
  /// **'TDEE (Total Daily Energy Expenditure) é a quantidade de calorias que seu corpo gasta por dia. Usamos isso como base para calcular suas metas.'**
  String get onboarding_tdee_info_body;

  /// No description provided for @onboarding_completion_generating_title.
  ///
  /// In pt, this message translates to:
  /// **'Montando sua semana'**
  String get onboarding_completion_generating_title;

  /// No description provided for @onboarding_completion_generating_body.
  ///
  /// In pt, this message translates to:
  /// **'Estou usando o que você me contou para desenhar seu primeiro plano.'**
  String get onboarding_completion_generating_body;

  /// No description provided for @onboarding_completion_ready_title.
  ///
  /// In pt, this message translates to:
  /// **'Sua semana está pronta'**
  String get onboarding_completion_ready_title;

  /// No description provided for @onboarding_completion_plan_fallback_desc.
  ///
  /// In pt, this message translates to:
  /// **'Plano personalizado pelo HAVOK'**
  String get onboarding_completion_plan_fallback_desc;

  /// No description provided for @onboarding_completion_starts_today_label.
  ///
  /// In pt, this message translates to:
  /// **'Começa hoje'**
  String get onboarding_completion_starts_today_label;

  /// No description provided for @onboarding_rest_day.
  ///
  /// In pt, this message translates to:
  /// **'Descanso'**
  String get onboarding_rest_day;

  /// No description provided for @onboarding_completion_adjust_hint.
  ///
  /// In pt, this message translates to:
  /// **'Pode ajustar tudo depois em Treinos e Configurações.'**
  String get onboarding_completion_adjust_hint;

  /// No description provided for @onboarding_completion_regenerate_btn.
  ///
  /// In pt, this message translates to:
  /// **'Quero outra divisão'**
  String get onboarding_completion_regenerate_btn;

  /// No description provided for @onboarding_completion_fallback_title.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui gerar agora.'**
  String get onboarding_completion_fallback_title;

  /// No description provided for @onboarding_completion_fallback_body_with_plan.
  ///
  /// In pt, this message translates to:
  /// **'Criei um plano base para você começar — ajuste quando quiser.'**
  String get onboarding_completion_fallback_body_with_plan;

  /// No description provided for @onboarding_completion_fallback_body_no_plan.
  ///
  /// In pt, this message translates to:
  /// **'Tente novamente em instantes — você pode montar seu treino manualmente em Treinos.'**
  String get onboarding_completion_fallback_body_no_plan;

  /// No description provided for @onboarding_completion_today_workout_label.
  ///
  /// In pt, this message translates to:
  /// **'Treino de hoje'**
  String get onboarding_completion_today_workout_label;

  /// No description provided for @onboarding_summary_review_title.
  ///
  /// In pt, this message translates to:
  /// **'Revise suas Escolhas'**
  String get onboarding_summary_review_title;

  /// No description provided for @onboarding_summary_perfect_body.
  ///
  /// In pt, this message translates to:
  /// **'Perfeito! Usaremos essas informações para criar a sua experiência fitness personalizada!'**
  String get onboarding_summary_perfect_body;

  /// No description provided for @onboarding_summary_edit_btn.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get onboarding_summary_edit_btn;

  /// No description provided for @common_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando…'**
  String get common_loading;

  /// No description provided for @dashboard_greeting_morning.
  ///
  /// In pt, this message translates to:
  /// **'Bom Dia'**
  String get dashboard_greeting_morning;

  /// No description provided for @dashboard_greeting_afternoon.
  ///
  /// In pt, this message translates to:
  /// **'Boa Tarde'**
  String get dashboard_greeting_afternoon;

  /// No description provided for @dashboard_greeting_evening.
  ///
  /// In pt, this message translates to:
  /// **'Boa Noite'**
  String get dashboard_greeting_evening;

  /// No description provided for @dashboard_guest_user.
  ///
  /// In pt, this message translates to:
  /// **'Convidado'**
  String get dashboard_guest_user;

  /// No description provided for @dashboard_streak_label.
  ///
  /// In pt, this message translates to:
  /// **'Streak'**
  String get dashboard_streak_label;

  /// No description provided for @dashboard_workouts_month_label.
  ///
  /// In pt, this message translates to:
  /// **'Treinos/mês'**
  String get dashboard_workouts_month_label;

  /// No description provided for @dashboard_total_time_label.
  ///
  /// In pt, this message translates to:
  /// **'Tempo total'**
  String get dashboard_total_time_label;

  /// No description provided for @dashboard_achievements_label.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get dashboard_achievements_label;

  /// No description provided for @dashboard_streak_value.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{{count} dia} other{{count} dias}}'**
  String dashboard_streak_value(int count);

  /// No description provided for @dashboard_continue_workout_label.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get dashboard_continue_workout_label;

  /// No description provided for @dashboard_delete_paused_title.
  ///
  /// In pt, this message translates to:
  /// **'Excluir treino pausado?'**
  String get dashboard_delete_paused_title;

  /// No description provided for @dashboard_delete_paused_body.
  ///
  /// In pt, this message translates to:
  /// **'Deseja excluir este treino pausado? O progresso não será recuperado.'**
  String get dashboard_delete_paused_body;

  /// No description provided for @dashboard_delete_btn.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get dashboard_delete_btn;

  /// No description provided for @dashboard_workout_today_title.
  ///
  /// In pt, this message translates to:
  /// **'Treino de hoje'**
  String get dashboard_workout_today_title;

  /// No description provided for @dashboard_workout_load_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os treinos'**
  String get dashboard_workout_load_error_title;

  /// No description provided for @dashboard_workout_load_error_body.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua conexão e tente novamente'**
  String get dashboard_workout_load_error_body;

  /// No description provided for @dashboard_welcome_title.
  ///
  /// In pt, this message translates to:
  /// **'Bem vindo ao BLDR'**
  String get dashboard_welcome_title;

  /// No description provided for @dashboard_welcome_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre para acompanhar seus treinos'**
  String get dashboard_welcome_subtitle;

  /// No description provided for @dashboard_login_btn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get dashboard_login_btn;

  /// No description provided for @dashboard_workout_in_progress.
  ///
  /// In pt, this message translates to:
  /// **'Treino em andamento'**
  String get dashboard_workout_in_progress;

  /// No description provided for @dashboard_finish_workout_btn.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar treino'**
  String get dashboard_finish_workout_btn;

  /// No description provided for @dashboard_workout_ready.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para treinar?'**
  String get dashboard_workout_ready;

  /// No description provided for @dashboard_workout_havok_generated.
  ///
  /// In pt, this message translates to:
  /// **'Gerado pelo HAVOK no seu onboarding'**
  String get dashboard_workout_havok_generated;

  /// No description provided for @dashboard_workout_next_session.
  ///
  /// In pt, this message translates to:
  /// **'Começar próxima sessão'**
  String get dashboard_workout_next_session;

  /// No description provided for @dashboard_workout_start_btn.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar treino'**
  String get dashboard_workout_start_btn;

  /// No description provided for @dashboard_finish_workout_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar Treino'**
  String get dashboard_finish_workout_dialog_title;

  /// No description provided for @dashboard_finish_workout_dialog_body.
  ///
  /// In pt, this message translates to:
  /// **'Você tem certeza que quer completar seu treino atual?'**
  String get dashboard_finish_workout_dialog_body;

  /// No description provided for @dashboard_complete_workout_btn.
  ///
  /// In pt, this message translates to:
  /// **'Completar'**
  String get dashboard_complete_workout_btn;

  /// No description provided for @dashboard_workout_completed_success.
  ///
  /// In pt, this message translates to:
  /// **'Treino finalizado com sucesso!'**
  String get dashboard_workout_completed_success;

  /// No description provided for @dashboard_finish_workout_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao finalizar treino: {error}'**
  String dashboard_finish_workout_error(String error);

  /// No description provided for @dashboard_no_workouts_available.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum treino disponível no momento'**
  String get dashboard_no_workouts_available;

  /// No description provided for @dashboard_weight_goal_label.
  ///
  /// In pt, this message translates to:
  /// **'Peso alvo'**
  String get dashboard_weight_goal_label;

  /// No description provided for @dashboard_goal_target.
  ///
  /// In pt, this message translates to:
  /// **'meta {value} {unit}'**
  String dashboard_goal_target(String value, String unit);

  /// No description provided for @dashboard_goal_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Defina seu objetivo'**
  String get dashboard_goal_empty_title;

  /// No description provided for @dashboard_goal_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma meta na aba Progresso'**
  String get dashboard_goal_empty_subtitle;

  /// No description provided for @dashboard_calories_label.
  ///
  /// In pt, this message translates to:
  /// **'Calorias'**
  String get dashboard_calories_label;

  /// No description provided for @dashboard_calories_of_target.
  ///
  /// In pt, this message translates to:
  /// **'de {target} kcal'**
  String dashboard_calories_of_target(int target);

  /// No description provided for @dashboard_macros_label.
  ///
  /// In pt, this message translates to:
  /// **'Macros'**
  String get dashboard_macros_label;

  /// No description provided for @dashboard_macro_protein_abbrev.
  ///
  /// In pt, this message translates to:
  /// **'P'**
  String get dashboard_macro_protein_abbrev;

  /// No description provided for @dashboard_macro_carbs_abbrev.
  ///
  /// In pt, this message translates to:
  /// **'C'**
  String get dashboard_macro_carbs_abbrev;

  /// No description provided for @dashboard_macro_fat_abbrev.
  ///
  /// In pt, this message translates to:
  /// **'G'**
  String get dashboard_macro_fat_abbrev;

  /// No description provided for @dashboard_seven_days.
  ///
  /// In pt, this message translates to:
  /// **'7 dias'**
  String get dashboard_seven_days;

  /// No description provided for @dashboard_workouts_count.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{{count} treino} other{{count} treinos}}'**
  String dashboard_workouts_count(int count);

  /// No description provided for @dashboard_havok_insight_title.
  ///
  /// In pt, this message translates to:
  /// **'Sua semana em um relance'**
  String get dashboard_havok_insight_title;

  /// No description provided for @dashboard_havok_insight_body.
  ///
  /// In pt, this message translates to:
  /// **'Em breve o HAVOK vai comentar sua aderência ao plano, proteína e streak diretamente aqui.'**
  String get dashboard_havok_insight_body;

  /// No description provided for @dashboard_havok_insight_action_btn.
  ///
  /// In pt, this message translates to:
  /// **'Ver progresso'**
  String get dashboard_havok_insight_action_btn;

  /// No description provided for @dashboard_level_label.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level}'**
  String dashboard_level_label(String level);

  /// No description provided for @dashboard_partners_title.
  ///
  /// In pt, this message translates to:
  /// **'Parceiros'**
  String get dashboard_partners_title;

  /// No description provided for @dashboard_partner_view_offer_btn.
  ///
  /// In pt, this message translates to:
  /// **'Ver oferta'**
  String get dashboard_partner_view_offer_btn;

  /// No description provided for @dashboard_partner_copy_coupon_btn.
  ///
  /// In pt, this message translates to:
  /// **'Copiar cupom'**
  String get dashboard_partner_copy_coupon_btn;

  /// No description provided for @dashboard_partners_view_all_btn.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos'**
  String get dashboard_partners_view_all_btn;

  /// No description provided for @dashboard_partner_coupon_copied.
  ///
  /// In pt, this message translates to:
  /// **'Cupom \"{coupon}\" copiado!'**
  String dashboard_partner_coupon_copied(String coupon);

  /// No description provided for @dashboard_quick_log_title.
  ///
  /// In pt, this message translates to:
  /// **'Registro Rápido'**
  String get dashboard_quick_log_title;

  /// No description provided for @dashboard_quick_log_meal.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Refeição'**
  String get dashboard_quick_log_meal;

  /// No description provided for @dashboard_quick_log_workout.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Exercício'**
  String get dashboard_quick_log_workout;

  /// No description provided for @dashboard_quick_log_weight.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Peso'**
  String get dashboard_quick_log_weight;

  /// No description provided for @dashboard_quick_log_water.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Água'**
  String get dashboard_quick_log_water;

  /// No description provided for @whoop_card_connect_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Conecte seu Whoop para ver Sleep, Recovery e Strain.'**
  String get whoop_card_connect_subtitle;

  /// No description provided for @whoop_card_connect_btn.
  ///
  /// In pt, this message translates to:
  /// **'Conectar'**
  String get whoop_card_connect_btn;

  /// No description provided for @whoop_card_today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get whoop_card_today;

  /// No description provided for @whoop_card_sleep_label.
  ///
  /// In pt, this message translates to:
  /// **'SLEEP'**
  String get whoop_card_sleep_label;

  /// No description provided for @whoop_card_recovery_label.
  ///
  /// In pt, this message translates to:
  /// **'RECOVERY'**
  String get whoop_card_recovery_label;

  /// No description provided for @whoop_card_strain_label.
  ///
  /// In pt, this message translates to:
  /// **'STRAIN'**
  String get whoop_card_strain_label;

  /// No description provided for @whoop_card_recovery_tip_low.
  ///
  /// In pt, this message translates to:
  /// **'Recovery baixo — priorize descanso hoje.'**
  String get whoop_card_recovery_tip_low;

  /// No description provided for @whoop_card_recovery_tip_med.
  ///
  /// In pt, this message translates to:
  /// **'Recovery moderado — treino leve ou técnico.'**
  String get whoop_card_recovery_tip_med;

  /// No description provided for @whoop_card_recovery_tip_high.
  ///
  /// In pt, this message translates to:
  /// **'Recovery alto — dia ideal para esforço intenso.'**
  String get whoop_card_recovery_tip_high;

  /// No description provided for @nav_tab_dashboard.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get nav_tab_dashboard;

  /// No description provided for @nav_tab_workouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get nav_tab_workouts;

  /// No description provided for @nav_tab_nutrition.
  ///
  /// In pt, this message translates to:
  /// **'Nutrição'**
  String get nav_tab_nutrition;

  /// No description provided for @nav_tab_profile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get nav_tab_profile;

  /// No description provided for @nav_club_label.
  ///
  /// In pt, this message translates to:
  /// **'BLDR Club'**
  String get nav_club_label;

  /// No description provided for @component_workout_start_btn.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar'**
  String get component_workout_start_btn;

  /// No description provided for @component_series_label.
  ///
  /// In pt, this message translates to:
  /// **'Série {index}'**
  String component_series_label(int index);

  /// No description provided for @component_current_badge.
  ///
  /// In pt, this message translates to:
  /// **'Atual'**
  String get component_current_badge;

  /// No description provided for @component_kcal_label.
  ///
  /// In pt, this message translates to:
  /// **'{calories} kcal'**
  String component_kcal_label(int calories);

  /// No description provided for @component_macro_detail.
  ///
  /// In pt, this message translates to:
  /// **'P {protein}g · C {carbs}g · G {fat}g · {portion}'**
  String component_macro_detail(
      String protein, String carbs, String fat, String portion);

  /// No description provided for @common_delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get common_delete;

  /// No description provided for @workouts_title.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get workouts_title;

  /// No description provided for @workouts_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar treino…'**
  String get workouts_search_hint;

  /// No description provided for @workouts_today_hero_label.
  ///
  /// In pt, this message translates to:
  /// **'Treino de hoje'**
  String get workouts_today_hero_label;

  /// No description provided for @workouts_today_with_label.
  ///
  /// In pt, this message translates to:
  /// **'Hoje · {label}'**
  String workouts_today_with_label(String label);

  /// No description provided for @workouts_today_hero_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Toque para ver o plano completo da semana'**
  String get workouts_today_hero_subtitle;

  /// No description provided for @workouts_continue_title.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get workouts_continue_title;

  /// No description provided for @workouts_active_banner_text.
  ///
  /// In pt, this message translates to:
  /// **'Treino em andamento — continuar'**
  String get workouts_active_banner_text;

  /// No description provided for @workouts_my_workouts.
  ///
  /// In pt, this message translates to:
  /// **'Meus treinos'**
  String get workouts_my_workouts;

  /// No description provided for @workouts_created_by_me.
  ///
  /// In pt, this message translates to:
  /// **'Criados por mim'**
  String get workouts_created_by_me;

  /// No description provided for @workouts_from_my_trainer.
  ///
  /// In pt, this message translates to:
  /// **'Do meu personal'**
  String get workouts_from_my_trainer;

  /// No description provided for @workouts_empty_state.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum treino criado ainda'**
  String get workouts_empty_state;

  /// No description provided for @workouts_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie seu primeiro treino personalizado'**
  String get workouts_empty_subtitle;

  /// No description provided for @workouts_create_btn.
  ///
  /// In pt, this message translates to:
  /// **'Criar treino'**
  String get workouts_create_btn;

  /// No description provided for @workouts_from_photo_btn.
  ///
  /// In pt, this message translates to:
  /// **'A partir de foto'**
  String get workouts_from_photo_btn;

  /// No description provided for @workouts_photo_camera.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get workouts_photo_camera;

  /// No description provided for @workouts_photo_gallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get workouts_photo_gallery;

  /// No description provided for @workouts_photo_no_exercises.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível identificar exercícios na imagem. Tente outra foto.'**
  String get workouts_photo_no_exercises;

  /// No description provided for @workouts_photo_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao analisar foto: {error}'**
  String workouts_photo_error(String error);

  /// No description provided for @workouts_trainer_empty_state.
  ///
  /// In pt, this message translates to:
  /// **'Treinos do personal — em desenvolvimento'**
  String get workouts_trainer_empty_state;

  /// No description provided for @workouts_trainer_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Em breve você poderá receber treinos direcionados pelo seu personal trainer.'**
  String get workouts_trainer_empty_subtitle;

  /// No description provided for @workouts_bldr_library.
  ///
  /// In pt, this message translates to:
  /// **'Biblioteca BLDR'**
  String get workouts_bldr_library;

  /// No description provided for @workouts_see_less.
  ///
  /// In pt, this message translates to:
  /// **'Ver menos'**
  String get workouts_see_less;

  /// No description provided for @workouts_see_all.
  ///
  /// In pt, this message translates to:
  /// **'Ver tudo'**
  String get workouts_see_all;

  /// No description provided for @workouts_bldr_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum treino BLDR disponível'**
  String get workouts_bldr_empty;

  /// No description provided for @workouts_start_workout_btn.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar treino'**
  String get workouts_start_workout_btn;

  /// No description provided for @workouts_exercises_header.
  ///
  /// In pt, this message translates to:
  /// **'Exercícios'**
  String get workouts_exercises_header;

  /// No description provided for @workouts_exercises_count.
  ///
  /// In pt, this message translates to:
  /// **'{exercises} · {sets} séries'**
  String workouts_exercises_count(int exercises, int sets);

  /// No description provided for @workouts_sets.
  ///
  /// In pt, this message translates to:
  /// **'{count} séries'**
  String workouts_sets(int count);

  /// No description provided for @workouts_reps.
  ///
  /// In pt, this message translates to:
  /// **'{count} reps'**
  String workouts_reps(int count);

  /// No description provided for @workouts_no_exercises.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum exercício'**
  String get workouts_no_exercises;

  /// No description provided for @workouts_technique_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Técnica não disponível para este exercício.'**
  String get workouts_technique_unavailable;

  /// No description provided for @workouts_delete_title.
  ///
  /// In pt, this message translates to:
  /// **'Excluir treino'**
  String get workouts_delete_title;

  /// No description provided for @workouts_delete_body.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir \"{name}\"?\nEsta ação não pode ser desfeita.'**
  String workouts_delete_body(String name);

  /// No description provided for @workouts_deleted_snackbar.
  ///
  /// In pt, this message translates to:
  /// **'\"{name}\" excluído'**
  String workouts_deleted_snackbar(String name);

  /// No description provided for @workouts_delete_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir: {error}'**
  String workouts_delete_error(String error);

  /// No description provided for @workouts_start_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao iniciar treino'**
  String get workouts_start_error;

  /// No description provided for @workouts_difficulty_label.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level}'**
  String workouts_difficulty_label(int level);

  /// No description provided for @plan_current_week.
  ///
  /// In pt, this message translates to:
  /// **'Semana atual'**
  String get plan_current_week;

  /// No description provided for @plan_see_plan.
  ///
  /// In pt, this message translates to:
  /// **'Ver plano →'**
  String get plan_see_plan;

  /// No description provided for @plan_workout_done.
  ///
  /// In pt, this message translates to:
  /// **'Treino realizado'**
  String get plan_workout_done;

  /// No description provided for @plan_workout_not_done.
  ///
  /// In pt, this message translates to:
  /// **'Treino não feito'**
  String get plan_workout_not_done;

  /// No description provided for @plan_no_record.
  ///
  /// In pt, this message translates to:
  /// **'Sem registro para este dia.'**
  String get plan_no_record;

  /// No description provided for @plan_view_week_btn.
  ///
  /// In pt, this message translates to:
  /// **'Ver plano da semana'**
  String get plan_view_week_btn;

  /// No description provided for @plan_title.
  ///
  /// In pt, this message translates to:
  /// **'Meu plano'**
  String get plan_title;

  /// No description provided for @plan_change_btn.
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get plan_change_btn;

  /// No description provided for @plan_of_total_workouts.
  ///
  /// In pt, this message translates to:
  /// **'de {total} treinos'**
  String plan_of_total_workouts(int total);

  /// No description provided for @plan_workouts_count.
  ///
  /// In pt, this message translates to:
  /// **'{count} treinos'**
  String plan_workouts_count(int count);

  /// No description provided for @plan_remaining.
  ///
  /// In pt, this message translates to:
  /// **'{count} restantes nesta semana'**
  String plan_remaining(int count);

  /// No description provided for @plan_streak_singular.
  ///
  /// In pt, this message translates to:
  /// **'dia seguido'**
  String get plan_streak_singular;

  /// No description provided for @plan_streak_plural.
  ///
  /// In pt, this message translates to:
  /// **'dias seguidos'**
  String get plan_streak_plural;

  /// No description provided for @plan_xp_week.
  ///
  /// In pt, this message translates to:
  /// **'XP esta semana'**
  String get plan_xp_week;

  /// No description provided for @plan_xp_earned.
  ///
  /// In pt, this message translates to:
  /// **'+{xp} XP'**
  String plan_xp_earned(int xp);

  /// No description provided for @plan_edit_sheet_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar plano semanal'**
  String get plan_edit_sheet_title;

  /// No description provided for @plan_split_section.
  ///
  /// In pt, this message translates to:
  /// **'Divisão de treinos'**
  String get plan_split_section;

  /// No description provided for @plan_days_section.
  ///
  /// In pt, this message translates to:
  /// **'Dias da semana'**
  String get plan_days_section;

  /// No description provided for @plan_training_rest_summary.
  ///
  /// In pt, this message translates to:
  /// **'{training} treino · {rest} descanso'**
  String plan_training_rest_summary(int training, int rest);

  /// No description provided for @plan_days_toggle_hint.
  ///
  /// In pt, this message translates to:
  /// **'Toque em um dia para alternar entre treino e descanso'**
  String get plan_days_toggle_hint;

  /// No description provided for @plan_save_btn.
  ///
  /// In pt, this message translates to:
  /// **'Salvar alterações'**
  String get plan_save_btn;

  /// No description provided for @plan_save_success.
  ///
  /// In pt, this message translates to:
  /// **'Plano atualizado com sucesso!'**
  String get plan_save_success;

  /// No description provided for @plan_save_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar: {error}'**
  String plan_save_error(String error);

  /// No description provided for @plan_pro_title.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie o plano premium'**
  String get plan_pro_title;

  /// No description provided for @plan_pro_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Personalize cada dia da sua semana'**
  String get plan_pro_subtitle;

  /// No description provided for @plan_see_plans_btn.
  ///
  /// In pt, this message translates to:
  /// **'Ver planos'**
  String get plan_see_plans_btn;

  /// No description provided for @plan_pro_feature_1.
  ///
  /// In pt, this message translates to:
  /// **'Escolher treino específico por dia'**
  String get plan_pro_feature_1;

  /// No description provided for @plan_pro_feature_2.
  ///
  /// In pt, this message translates to:
  /// **'Alterar o plano livremente'**
  String get plan_pro_feature_2;

  /// No description provided for @plan_pro_feature_3.
  ///
  /// In pt, this message translates to:
  /// **'Usar treinos personalizados no plano'**
  String get plan_pro_feature_3;

  /// No description provided for @plan_pro_feature_4.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização com Apple Watch'**
  String get plan_pro_feature_4;

  /// No description provided for @plan_pro_feature_5.
  ///
  /// In pt, this message translates to:
  /// **'Analytics avançados de progresso'**
  String get plan_pro_feature_5;

  /// No description provided for @plan_do_now_btn.
  ///
  /// In pt, this message translates to:
  /// **'Fazer agora'**
  String get plan_do_now_btn;

  /// No description provided for @plan_today_sheet_title.
  ///
  /// In pt, this message translates to:
  /// **'Treino de hoje'**
  String get plan_today_sheet_title;

  /// No description provided for @plan_next_workout.
  ///
  /// In pt, this message translates to:
  /// **'Ver treino'**
  String get plan_next_workout;

  /// No description provided for @plan_rest_day.
  ///
  /// In pt, this message translates to:
  /// **'Descanso'**
  String get plan_rest_day;

  /// No description provided for @plan_not_done.
  ///
  /// In pt, this message translates to:
  /// **'Não feito'**
  String get plan_not_done;

  /// No description provided for @plan_extra_badge.
  ///
  /// In pt, this message translates to:
  /// **'Extra'**
  String get plan_extra_badge;

  /// No description provided for @plan_extras_label.
  ///
  /// In pt, this message translates to:
  /// **'Extras'**
  String get plan_extras_label;

  /// No description provided for @plan_delete_record_btn.
  ///
  /// In pt, this message translates to:
  /// **'Excluir registro'**
  String get plan_delete_record_btn;

  /// No description provided for @plan_delete_record_title.
  ///
  /// In pt, this message translates to:
  /// **'Excluir registro?'**
  String get plan_delete_record_title;

  /// No description provided for @plan_delete_record_body.
  ///
  /// In pt, this message translates to:
  /// **'Deseja excluir este registro de treino? Esta ação não pode ser desfeita.'**
  String get plan_delete_record_body;

  /// No description provided for @plan_delete_record_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir registro.'**
  String get plan_delete_record_error;

  /// No description provided for @plan_edit_btn.
  ///
  /// In pt, this message translates to:
  /// **'Editar plano'**
  String get plan_edit_btn;

  /// No description provided for @plan_register_extra_btn.
  ///
  /// In pt, this message translates to:
  /// **'Registrar extra'**
  String get plan_register_extra_btn;

  /// No description provided for @plan_extra_sheet_title.
  ///
  /// In pt, this message translates to:
  /// **'Registrar atividade extra'**
  String get plan_extra_sheet_title;

  /// No description provided for @plan_extra_sheet_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Atividade fora do plano · +50 XP'**
  String get plan_extra_sheet_subtitle;

  /// No description provided for @plan_extra_type_label.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de atividade'**
  String get plan_extra_type_label;

  /// No description provided for @plan_extra_duration_label.
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get plan_extra_duration_label;

  /// No description provided for @plan_extra_notes_label.
  ///
  /// In pt, this message translates to:
  /// **'Notas (opcional)'**
  String get plan_extra_notes_label;

  /// No description provided for @plan_extra_notes_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: partida de futebol com amigos'**
  String get plan_extra_notes_hint;

  /// No description provided for @plan_extra_register_btn.
  ///
  /// In pt, this message translates to:
  /// **'Registrar + 50 XP'**
  String get plan_extra_register_btn;

  /// No description provided for @plan_extra_register_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao registrar: {error}'**
  String plan_extra_register_error(String error);

  /// No description provided for @plan_extra_register_success.
  ///
  /// In pt, this message translates to:
  /// **'Atividade registrada! +50 XP'**
  String get plan_extra_register_success;

  /// No description provided for @plan_paywall_muscle_message.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie a análise muscular completa — BLDR CLUB'**
  String get plan_paywall_muscle_message;

  /// No description provided for @plan_paywall_muscle_btn.
  ///
  /// In pt, this message translates to:
  /// **'Conhecer o BLDR Club'**
  String get plan_paywall_muscle_btn;

  /// No description provided for @workout_stop_title.
  ///
  /// In pt, this message translates to:
  /// **'Parar treino?'**
  String get workout_stop_title;

  /// No description provided for @workout_stop_body.
  ///
  /// In pt, this message translates to:
  /// **'O progresso será salvo até aqui.'**
  String get workout_stop_body;

  /// No description provided for @workout_stop_btn.
  ///
  /// In pt, this message translates to:
  /// **'Parar'**
  String get workout_stop_btn;

  /// No description provided for @workout_stop_label.
  ///
  /// In pt, this message translates to:
  /// **'Parar treino'**
  String get workout_stop_label;

  /// No description provided for @workout_in_progress.
  ///
  /// In pt, this message translates to:
  /// **'EM ANDAMENTO'**
  String get workout_in_progress;

  /// No description provided for @workout_time_label.
  ///
  /// In pt, this message translates to:
  /// **'TEMPO'**
  String get workout_time_label;

  /// No description provided for @workout_set_label.
  ///
  /// In pt, this message translates to:
  /// **'SÉRIE'**
  String get workout_set_label;

  /// No description provided for @workout_exercise_of.
  ///
  /// In pt, this message translates to:
  /// **'Exercício {current} de {total}'**
  String workout_exercise_of(int current, int total);

  /// No description provided for @workout_percent_done.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% concluído'**
  String workout_percent_done(int percent);

  /// No description provided for @workout_see_technique.
  ///
  /// In pt, this message translates to:
  /// **'Ver técnica'**
  String get workout_see_technique;

  /// No description provided for @workout_paywall_muscle_message.
  ///
  /// In pt, this message translates to:
  /// **'Veja quais músculos secundários você está ativando — BLDR Club'**
  String get workout_paywall_muscle_message;

  /// No description provided for @workout_technique_fallback.
  ///
  /// In pt, this message translates to:
  /// **'Técnica'**
  String get workout_technique_fallback;

  /// No description provided for @workout_execution_label.
  ///
  /// In pt, this message translates to:
  /// **'Execução'**
  String get workout_execution_label;

  /// No description provided for @workout_no_instructions.
  ///
  /// In pt, this message translates to:
  /// **'Sem instruções disponíveis.'**
  String get workout_no_instructions;

  /// No description provided for @workout_load_kg.
  ///
  /// In pt, this message translates to:
  /// **'Carga (kg)'**
  String get workout_load_kg;

  /// No description provided for @workout_decrease_load.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir carga'**
  String get workout_decrease_load;

  /// No description provided for @workout_increase_load.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar carga'**
  String get workout_increase_load;

  /// No description provided for @workout_reps_label.
  ///
  /// In pt, this message translates to:
  /// **'Repetições'**
  String get workout_reps_label;

  /// No description provided for @workout_decrease_reps.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir repetições'**
  String get workout_decrease_reps;

  /// No description provided for @workout_increase_reps.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar repetições'**
  String get workout_increase_reps;

  /// No description provided for @workout_resting.
  ///
  /// In pt, this message translates to:
  /// **'DESCANSANDO'**
  String get workout_resting;

  /// No description provided for @workout_next_set.
  ///
  /// In pt, this message translates to:
  /// **'Próxima: série {set} de {total}'**
  String workout_next_set(int set, int total);

  /// No description provided for @workout_add_rest_label.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar 15 segundos ao descanso'**
  String get workout_add_rest_label;

  /// No description provided for @workout_skip_rest.
  ///
  /// In pt, this message translates to:
  /// **'Pular descanso'**
  String get workout_skip_rest;

  /// No description provided for @workout_exercises_label.
  ///
  /// In pt, this message translates to:
  /// **'Exercícios'**
  String get workout_exercises_label;

  /// No description provided for @workout_set_current.
  ///
  /// In pt, this message translates to:
  /// **'Atual'**
  String get workout_set_current;

  /// No description provided for @workout_next_up.
  ///
  /// In pt, this message translates to:
  /// **'A seguir'**
  String get workout_next_up;

  /// No description provided for @workout_skip_exercise.
  ///
  /// In pt, this message translates to:
  /// **'Pular exercício'**
  String get workout_skip_exercise;

  /// No description provided for @workout_confirm_set_btn.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar série'**
  String get workout_confirm_set_btn;

  /// No description provided for @workout_rest_edit_label.
  ///
  /// In pt, this message translates to:
  /// **'Editar tempo de descanso'**
  String get workout_rest_edit_label;

  /// No description provided for @workout_rest_sheet_title.
  ///
  /// In pt, this message translates to:
  /// **'Tempo de descanso'**
  String get workout_rest_sheet_title;

  /// No description provided for @workout_confirm_btn.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get workout_confirm_btn;

  /// No description provided for @workout_finished_title.
  ///
  /// In pt, this message translates to:
  /// **'Treino Concluído!'**
  String get workout_finished_title;

  /// No description provided for @workout_stat_time.
  ///
  /// In pt, this message translates to:
  /// **'Tempo'**
  String get workout_stat_time;

  /// No description provided for @workout_stat_sets.
  ///
  /// In pt, this message translates to:
  /// **'Séries'**
  String get workout_stat_sets;

  /// No description provided for @workout_finish_btn.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar'**
  String get workout_finish_btn;

  /// No description provided for @common_today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get common_today;

  /// No description provided for @common_required_field.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório'**
  String get common_required_field;

  /// No description provided for @common_invalid_value.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido'**
  String get common_invalid_value;

  /// No description provided for @common_unauthenticated.
  ///
  /// In pt, this message translates to:
  /// **'Usuário não autenticado.'**
  String get common_unauthenticated;

  /// No description provided for @nutrition_food_removed.
  ///
  /// In pt, this message translates to:
  /// **'Comida removida com sucesso!'**
  String get nutrition_food_removed;

  /// No description provided for @nutrition_remove_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao remover item.'**
  String get nutrition_remove_error;

  /// No description provided for @nutrition_daily_summary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo diário'**
  String get nutrition_daily_summary;

  /// No description provided for @nutrition_protein.
  ///
  /// In pt, this message translates to:
  /// **'Proteína'**
  String get nutrition_protein;

  /// No description provided for @nutrition_carbs.
  ///
  /// In pt, this message translates to:
  /// **'Carboidrato'**
  String get nutrition_carbs;

  /// No description provided for @nutrition_fat.
  ///
  /// In pt, this message translates to:
  /// **'Gordura'**
  String get nutrition_fat;

  /// No description provided for @nutrition_remaining_today.
  ///
  /// In pt, this message translates to:
  /// **'Restantes hoje'**
  String get nutrition_remaining_today;

  /// No description provided for @nutrition_goal_exceeded.
  ///
  /// In pt, this message translates to:
  /// **'Meta ultrapassada'**
  String get nutrition_goal_exceeded;

  /// No description provided for @nutrition_iqd_gauge_label.
  ///
  /// In pt, this message translates to:
  /// **'IQD · /100'**
  String get nutrition_iqd_gauge_label;

  /// No description provided for @nutrition_fiber.
  ///
  /// In pt, this message translates to:
  /// **'Fibra'**
  String get nutrition_fiber;

  /// No description provided for @nutrition_sodium.
  ///
  /// In pt, this message translates to:
  /// **'Sódio'**
  String get nutrition_sodium;

  /// No description provided for @nutrition_sugars.
  ///
  /// In pt, this message translates to:
  /// **'Açúcares'**
  String get nutrition_sugars;

  /// No description provided for @nutrition_iqd_premium_msg.
  ///
  /// In pt, this message translates to:
  /// **'Análise de qualidade (IQD)\\ndisponível no Premium'**
  String get nutrition_iqd_premium_msg;

  /// No description provided for @nutrition_iqd_premium_btn.
  ///
  /// In pt, this message translates to:
  /// **'Seja Premium'**
  String get nutrition_iqd_premium_btn;

  /// No description provided for @nutrition_meals_section.
  ///
  /// In pt, this message translates to:
  /// **'Refeições'**
  String get nutrition_meals_section;

  /// No description provided for @nutrition_photo_meal_btn.
  ///
  /// In pt, this message translates to:
  /// **'Foto do prato'**
  String get nutrition_photo_meal_btn;

  /// No description provided for @nutrition_search_btn.
  ///
  /// In pt, this message translates to:
  /// **'Buscar alimento'**
  String get nutrition_search_btn;

  /// No description provided for @nutrition_no_food.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum alimento'**
  String get nutrition_no_food;

  /// No description provided for @nutrition_add_btn.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get nutrition_add_btn;

  /// No description provided for @nutrition_unnamed_food.
  ///
  /// In pt, this message translates to:
  /// **'Alimento sem nome'**
  String get nutrition_unnamed_food;

  /// No description provided for @nutrition_item_id_missing.
  ///
  /// In pt, this message translates to:
  /// **'ID do item de comida não encontrado.'**
  String get nutrition_item_id_missing;

  /// No description provided for @nutrition_item_action_question.
  ///
  /// In pt, this message translates to:
  /// **'O que você deseja fazer com este item?'**
  String get nutrition_item_action_question;

  /// No description provided for @nutrition_edit_quantity.
  ///
  /// In pt, this message translates to:
  /// **'Editar quantidade'**
  String get nutrition_edit_quantity;

  /// No description provided for @nutrition_remove_item.
  ///
  /// In pt, this message translates to:
  /// **'Remover item'**
  String get nutrition_remove_item;

  /// No description provided for @nutrition_breakfast.
  ///
  /// In pt, this message translates to:
  /// **'Café da manhã'**
  String get nutrition_breakfast;

  /// No description provided for @nutrition_snack.
  ///
  /// In pt, this message translates to:
  /// **'Lanche'**
  String get nutrition_snack;

  /// No description provided for @nutrition_lunch.
  ///
  /// In pt, this message translates to:
  /// **'Almoço'**
  String get nutrition_lunch;

  /// No description provided for @nutrition_pre_workout.
  ///
  /// In pt, this message translates to:
  /// **'Pré-treino'**
  String get nutrition_pre_workout;

  /// No description provided for @nutrition_post_workout.
  ///
  /// In pt, this message translates to:
  /// **'Pós-treino'**
  String get nutrition_post_workout;

  /// No description provided for @nutrition_dinner.
  ///
  /// In pt, this message translates to:
  /// **'Jantar'**
  String get nutrition_dinner;

  /// No description provided for @nutrition_add_to_meal.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar em: {mealType}'**
  String nutrition_add_to_meal(String mealType);

  /// No description provided for @nutrition_search_db_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar comida na base...'**
  String get nutrition_search_db_hint;

  /// No description provided for @nutrition_photo_auto_label.
  ///
  /// In pt, this message translates to:
  /// **'Foto do prato — identificação automática'**
  String get nutrition_photo_auto_label;

  /// No description provided for @nutrition_coming_soon.
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get nutrition_coming_soon;

  /// No description provided for @nutrition_select_category.
  ///
  /// In pt, this message translates to:
  /// **'Selecione uma categoria ou pesquise acima.'**
  String get nutrition_select_category;

  /// No description provided for @nutrition_cat_meat.
  ///
  /// In pt, this message translates to:
  /// **'Carnes & Aves'**
  String get nutrition_cat_meat;

  /// No description provided for @nutrition_cat_fish.
  ///
  /// In pt, this message translates to:
  /// **'Peixes & Frutos do Mar'**
  String get nutrition_cat_fish;

  /// No description provided for @nutrition_cat_eggs.
  ///
  /// In pt, this message translates to:
  /// **'Ovos'**
  String get nutrition_cat_eggs;

  /// No description provided for @nutrition_cat_dairy.
  ///
  /// In pt, this message translates to:
  /// **'Laticínios'**
  String get nutrition_cat_dairy;

  /// No description provided for @nutrition_cat_fruits.
  ///
  /// In pt, this message translates to:
  /// **'Frutas'**
  String get nutrition_cat_fruits;

  /// No description provided for @nutrition_cat_vegetables.
  ///
  /// In pt, this message translates to:
  /// **'Legumes & Verduras'**
  String get nutrition_cat_vegetables;

  /// No description provided for @nutrition_cat_grains.
  ///
  /// In pt, this message translates to:
  /// **'Grãos & Cereais'**
  String get nutrition_cat_grains;

  /// No description provided for @nutrition_cat_fats.
  ///
  /// In pt, this message translates to:
  /// **'Gorduras & Óleos'**
  String get nutrition_cat_fats;

  /// No description provided for @nutrition_cat_nuts.
  ///
  /// In pt, this message translates to:
  /// **'Oleaginosas'**
  String get nutrition_cat_nuts;

  /// No description provided for @nutrition_cat_sweets.
  ///
  /// In pt, this message translates to:
  /// **'Doces & Sobremesas'**
  String get nutrition_cat_sweets;

  /// No description provided for @nutrition_cat_drinks.
  ///
  /// In pt, this message translates to:
  /// **'Bebidas'**
  String get nutrition_cat_drinks;

  /// No description provided for @nutrition_cat_fastfood.
  ///
  /// In pt, this message translates to:
  /// **'Fast Food'**
  String get nutrition_cat_fastfood;

  /// No description provided for @nutrition_cat_processed.
  ///
  /// In pt, this message translates to:
  /// **'Industrializados'**
  String get nutrition_cat_processed;

  /// No description provided for @nutrition_cat_readymeals.
  ///
  /// In pt, this message translates to:
  /// **'Refeições Prontas'**
  String get nutrition_cat_readymeals;

  /// No description provided for @nutrition_cat_sauces.
  ///
  /// In pt, this message translates to:
  /// **'Molhos & Temperos'**
  String get nutrition_cat_sauces;

  /// No description provided for @nutrition_cat_supplements.
  ///
  /// In pt, this message translates to:
  /// **'Suplementos'**
  String get nutrition_cat_supplements;

  /// No description provided for @hydration_title.
  ///
  /// In pt, this message translates to:
  /// **'Hidratação'**
  String get hydration_title;

  /// No description provided for @hydration_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get hydration_loading;

  /// No description provided for @hydration_consumed.
  ///
  /// In pt, this message translates to:
  /// **'Água consumida'**
  String get hydration_consumed;

  /// No description provided for @hydration_remaining.
  ///
  /// In pt, this message translates to:
  /// **'{value}L restantes'**
  String hydration_remaining(String value);

  /// No description provided for @hydration_total_today.
  ///
  /// In pt, this message translates to:
  /// **'Total hoje'**
  String get hydration_total_today;

  /// No description provided for @hydration_entries.
  ///
  /// In pt, this message translates to:
  /// **'Entradas'**
  String get hydration_entries;

  /// No description provided for @hydration_goal_percent.
  ///
  /// In pt, this message translates to:
  /// **'% da meta'**
  String get hydration_goal_percent;

  /// No description provided for @hydration_custom_amount.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade personalizada'**
  String get hydration_custom_amount;

  /// No description provided for @hydration_remove_last.
  ///
  /// In pt, this message translates to:
  /// **'Remover última entrada'**
  String get hydration_remove_last;

  /// No description provided for @hydration_log_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao registrar água'**
  String get hydration_log_error;

  /// No description provided for @hydration_add_btn.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get hydration_add_btn;

  /// No description provided for @hydration_no_data.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não registrou água hoje.'**
  String get hydration_no_data;

  /// No description provided for @hydration_remove_title.
  ///
  /// In pt, this message translates to:
  /// **'Remover água'**
  String get hydration_remove_title;

  /// No description provided for @hydration_too_small.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade muito pequena para remover por aqui.'**
  String get hydration_too_small;

  /// No description provided for @hydration_removed.
  ///
  /// In pt, this message translates to:
  /// **'Removido: {amount}ml'**
  String hydration_removed(int amount);

  /// No description provided for @hydration_remove_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao remover água'**
  String get hydration_remove_error;

  /// No description provided for @nutrition_search_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro na busca.'**
  String get nutrition_search_error;

  /// No description provided for @nutrition_search_type_prompt.
  ///
  /// In pt, this message translates to:
  /// **'Digite para buscar alimentos.'**
  String get nutrition_search_type_prompt;

  /// No description provided for @nutrition_no_results.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado encontrado.'**
  String get nutrition_no_results;

  /// No description provided for @nutrition_img_not_implemented.
  ///
  /// In pt, this message translates to:
  /// **'Reconhecimento por imagem ainda não implementado'**
  String get nutrition_img_not_implemented;

  /// No description provided for @nutrition_search_food_title.
  ///
  /// In pt, this message translates to:
  /// **'Buscar Alimento'**
  String get nutrition_search_food_title;

  /// No description provided for @nutrition_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar alimentos...'**
  String get nutrition_search_hint;

  /// No description provided for @nutrition_popular_foods.
  ///
  /// In pt, this message translates to:
  /// **'Alimentos Populares'**
  String get nutrition_popular_foods;

  /// No description provided for @nutrition_search_results_count.
  ///
  /// In pt, this message translates to:
  /// **'Resultados da Busca ({count})'**
  String nutrition_search_results_count(int count);

  /// No description provided for @nutrition_scan_title.
  ///
  /// In pt, this message translates to:
  /// **'Escanear Código'**
  String get nutrition_scan_title;

  /// No description provided for @nutrition_scan_hint.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para o código de barras'**
  String get nutrition_scan_hint;

  /// No description provided for @nutrition_scan_auto.
  ///
  /// In pt, this message translates to:
  /// **'O código será detectado automaticamente'**
  String get nutrition_scan_auto;

  /// No description provided for @nutrition_scan_flash.
  ///
  /// In pt, this message translates to:
  /// **'Flash'**
  String get nutrition_scan_flash;

  /// No description provided for @nutrition_scan_camera_label.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get nutrition_scan_camera_label;

  /// No description provided for @nutrition_tab_recent.
  ///
  /// In pt, this message translates to:
  /// **'Recentes'**
  String get nutrition_tab_recent;

  /// No description provided for @nutrition_tab_favorites.
  ///
  /// In pt, this message translates to:
  /// **'Favoritos'**
  String get nutrition_tab_favorites;

  /// No description provided for @nutrition_tab_manual.
  ///
  /// In pt, this message translates to:
  /// **'Manual'**
  String get nutrition_tab_manual;

  /// No description provided for @nutrition_category_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum alimento encontrado para esta categoria.'**
  String get nutrition_category_empty;

  /// No description provided for @nutrition_recent_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum alimento recente.'**
  String get nutrition_recent_empty;

  /// No description provided for @nutrition_favorites_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum favorito salvo ainda.'**
  String get nutrition_favorites_empty;

  /// No description provided for @nutrition_favorites_hint.
  ///
  /// In pt, this message translates to:
  /// **'Use \"Manual\" e marque \"Salvar nos favoritos\".'**
  String get nutrition_favorites_hint;

  /// No description provided for @nutrition_iqd_impact_label.
  ///
  /// In pt, this message translates to:
  /// **'Impacto no IQD'**
  String get nutrition_iqd_impact_label;

  /// No description provided for @nutrition_saving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando...'**
  String get nutrition_saving;

  /// No description provided for @nutrition_add_meal_btn.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar {mealType}'**
  String nutrition_add_meal_btn(String mealType);

  /// No description provided for @nutrition_food_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome da comida'**
  String get nutrition_food_name_label;

  /// No description provided for @nutrition_essential_label.
  ///
  /// In pt, this message translates to:
  /// **'Essencial'**
  String get nutrition_essential_label;

  /// No description provided for @nutrition_calories.
  ///
  /// In pt, this message translates to:
  /// **'Calorias'**
  String get nutrition_calories;

  /// No description provided for @nutrition_carbs_short.
  ///
  /// In pt, this message translates to:
  /// **'Carbo'**
  String get nutrition_carbs_short;

  /// No description provided for @nutrition_iqd_quality_data.
  ///
  /// In pt, this message translates to:
  /// **'Dados de qualidade (IQD)'**
  String get nutrition_iqd_quality_data;

  /// No description provided for @nutrition_fibers.
  ///
  /// In pt, this message translates to:
  /// **'Fibras'**
  String get nutrition_fibers;

  /// No description provided for @nutrition_save_favorites.
  ///
  /// In pt, this message translates to:
  /// **'Salvar nos favoritos'**
  String get nutrition_save_favorites;

  /// No description provided for @nutrition_set_portion.
  ///
  /// In pt, this message translates to:
  /// **'Definir porção'**
  String get nutrition_set_portion;

  /// No description provided for @nutrition_grams.
  ///
  /// In pt, this message translates to:
  /// **'Gramas'**
  String get nutrition_grams;

  /// No description provided for @nutrition_food_label.
  ///
  /// In pt, this message translates to:
  /// **'Alimento'**
  String get nutrition_food_label;

  /// No description provided for @nutrition_unit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get nutrition_unit;

  /// No description provided for @nutrition_unit_weight_label.
  ///
  /// In pt, this message translates to:
  /// **'Peso de 1 unidade:'**
  String get nutrition_unit_weight_label;

  /// No description provided for @nutrition_unit_short.
  ///
  /// In pt, this message translates to:
  /// **'Unid.'**
  String get nutrition_unit_short;

  /// No description provided for @nutrition_quantity_label.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade:'**
  String get nutrition_quantity_label;

  /// No description provided for @nutrition_update_quantity.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar quantidade'**
  String get nutrition_update_quantity;

  /// No description provided for @nutrition_add_food_btn.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar comida'**
  String get nutrition_add_food_btn;

  /// No description provided for @nutrition_favorites_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os favoritos.'**
  String get nutrition_favorites_load_error;

  /// No description provided for @nutrition_fill_one_macro.
  ///
  /// In pt, this message translates to:
  /// **'Preencha pelo menos um valor nutricional.'**
  String get nutrition_fill_one_macro;

  /// No description provided for @nutrition_create_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao criar item.'**
  String get nutrition_create_error;

  /// No description provided for @nutrition_save_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar: {error}'**
  String nutrition_save_error(String error);

  /// No description provided for @nutrition_item_updated.
  ///
  /// In pt, this message translates to:
  /// **'Item atualizado com sucesso!'**
  String get nutrition_item_updated;

  /// No description provided for @nutrition_food_added.
  ///
  /// In pt, this message translates to:
  /// **'Comida adicionada com sucesso!'**
  String get nutrition_food_added;

  /// No description provided for @nutrition_fail.
  ///
  /// In pt, this message translates to:
  /// **'Falha: {error}'**
  String nutrition_fail(String error);

  /// No description provided for @nutrition_scan_hint_qr.
  ///
  /// In pt, this message translates to:
  /// **'Aponte para o código de barras/QR do alimento'**
  String get nutrition_scan_hint_qr;

  /// No description provided for @progress_title.
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get progress_title;

  /// No description provided for @progress_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar dados do progresso'**
  String get progress_load_error;

  /// No description provided for @progress_period_7d.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 7 dias'**
  String get progress_period_7d;

  /// No description provided for @progress_period_30d.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 30 dias'**
  String get progress_period_30d;

  /// No description provided for @progress_period_3m.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 3 meses'**
  String get progress_period_3m;

  /// No description provided for @progress_period_1y.
  ///
  /// In pt, this message translates to:
  /// **'Último ano'**
  String get progress_period_1y;

  /// No description provided for @progress_tab_general.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get progress_tab_general;

  /// No description provided for @progress_tab_body.
  ///
  /// In pt, this message translates to:
  /// **'Corpo'**
  String get progress_tab_body;

  /// No description provided for @progress_tab_workouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get progress_tab_workouts;

  /// No description provided for @progress_tab_nutrition.
  ///
  /// In pt, this message translates to:
  /// **'Nutri'**
  String get progress_tab_nutrition;

  /// No description provided for @progress_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando dados...'**
  String get progress_loading;

  /// No description provided for @progress_export_compiling.
  ///
  /// In pt, this message translates to:
  /// **'Compilando relatório completo (Corpo, Treino, Nutri)...'**
  String get progress_export_compiling;

  /// No description provided for @progress_no_data_period.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados neste período.'**
  String get progress_no_data_period;

  /// No description provided for @progress_export_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar relatório.'**
  String get progress_export_error;

  /// No description provided for @achievements_title.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get achievements_title;

  /// No description provided for @achievements_unlocked_of_total.
  ///
  /// In pt, this message translates to:
  /// **'{unlocked} de {total} desbloqueadas'**
  String achievements_unlocked_of_total(int unlocked, int total);

  /// No description provided for @achievements_category_first_steps.
  ///
  /// In pt, this message translates to:
  /// **'Primeiros Passos'**
  String get achievements_category_first_steps;

  /// No description provided for @achievements_category_workouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get achievements_category_workouts;

  /// No description provided for @achievements_category_strength.
  ///
  /// In pt, this message translates to:
  /// **'Força'**
  String get achievements_category_strength;

  /// No description provided for @achievements_category_milestones.
  ///
  /// In pt, this message translates to:
  /// **'Marcos'**
  String get achievements_category_milestones;

  /// No description provided for @achievements_category_nutrition.
  ///
  /// In pt, this message translates to:
  /// **'Nutrição'**
  String get achievements_category_nutrition;

  /// No description provided for @goals_create_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Criar novo objetivo'**
  String get goals_create_dialog_title;

  /// No description provided for @goals_title_field.
  ///
  /// In pt, this message translates to:
  /// **'Título do objetivo'**
  String get goals_title_field;

  /// No description provided for @goals_description_field.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get goals_description_field;

  /// No description provided for @goals_target_value_field.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo (valor alvo)'**
  String get goals_target_value_field;

  /// No description provided for @goals_unit_field.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get goals_unit_field;

  /// No description provided for @goals_category_field.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get goals_category_field;

  /// No description provided for @goals_category_weight.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get goals_category_weight;

  /// No description provided for @goals_category_workout.
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get goals_category_workout;

  /// No description provided for @goals_category_strength.
  ///
  /// In pt, this message translates to:
  /// **'Força'**
  String get goals_category_strength;

  /// No description provided for @goals_category_endurance.
  ///
  /// In pt, this message translates to:
  /// **'Resistência'**
  String get goals_category_endurance;

  /// No description provided for @goals_category_general.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get goals_category_general;

  /// No description provided for @goals_set_deadline.
  ///
  /// In pt, this message translates to:
  /// **'Definir prazo (opcional)'**
  String get goals_set_deadline;

  /// No description provided for @goals_deadline_set.
  ///
  /// In pt, this message translates to:
  /// **'Prazo: {date}'**
  String goals_deadline_set(String date);

  /// No description provided for @goals_fill_required.
  ///
  /// In pt, this message translates to:
  /// **'Preencha título, objetivo e unidade'**
  String get goals_fill_required;

  /// No description provided for @goals_create_btn.
  ///
  /// In pt, this message translates to:
  /// **'Criar objetivo'**
  String get goals_create_btn;

  /// No description provided for @goals_create_success.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo criado com sucesso!'**
  String get goals_create_success;

  /// No description provided for @goals_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Objetivos'**
  String get goals_section_title;

  /// No description provided for @goals_create_first_btn.
  ///
  /// In pt, this message translates to:
  /// **'Criar primeiro objetivo'**
  String get goals_create_first_btn;

  /// No description provided for @goals_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Sem objetivos ativos'**
  String get goals_empty_title;

  /// No description provided for @goals_empty_instruction.
  ///
  /// In pt, this message translates to:
  /// **'Crie objetivos para acompanhar sua jornada'**
  String get goals_empty_instruction;

  /// No description provided for @goals_update_progress_title.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar progresso'**
  String get goals_update_progress_title;

  /// No description provided for @goals_update_progress_btn.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar progresso'**
  String get goals_update_progress_btn;

  /// No description provided for @goals_current_value_field.
  ///
  /// In pt, this message translates to:
  /// **'Valor atual ({unit})'**
  String goals_current_value_field(String unit);

  /// No description provided for @goals_update_btn.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get goals_update_btn;

  /// No description provided for @goals_update_success.
  ///
  /// In pt, this message translates to:
  /// **'Progresso atualizado com sucesso!'**
  String get goals_update_success;

  /// No description provided for @goals_more_options.
  ///
  /// In pt, this message translates to:
  /// **'Mais opções'**
  String get goals_more_options;

  /// No description provided for @goals_pause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar objetivo'**
  String get goals_pause;

  /// No description provided for @goals_paused.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo pausado'**
  String get goals_paused;

  /// No description provided for @goals_delete.
  ///
  /// In pt, this message translates to:
  /// **'Deletar objetivo'**
  String get goals_delete;

  /// No description provided for @goals_deleted.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo deletado'**
  String get goals_deleted;

  /// No description provided for @goals_overdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasado'**
  String get goals_overdue;

  /// No description provided for @goals_due_today.
  ///
  /// In pt, this message translates to:
  /// **'Vence hoje'**
  String get goals_due_today;

  /// No description provided for @goals_days_remaining.
  ///
  /// In pt, this message translates to:
  /// **'{days}d restantes'**
  String goals_days_remaining(int days);

  /// No description provided for @photo_progress_title.
  ///
  /// In pt, this message translates to:
  /// **'Foto do progresso'**
  String get photo_progress_title;

  /// No description provided for @photo_add_sheet_title.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar foto'**
  String get photo_add_sheet_title;

  /// No description provided for @photo_option_camera.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get photo_option_camera;

  /// No description provided for @photo_option_gallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get photo_option_gallery;

  /// No description provided for @photo_permission_title.
  ///
  /// In pt, this message translates to:
  /// **'Permissão necessária'**
  String get photo_permission_title;

  /// No description provided for @photo_delete_title.
  ///
  /// In pt, this message translates to:
  /// **'Remover foto?'**
  String get photo_delete_title;

  /// No description provided for @photo_delete_message.
  ///
  /// In pt, this message translates to:
  /// **'Isso não pode ser desfeito.'**
  String get photo_delete_message;

  /// No description provided for @photo_delete_btn.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get photo_delete_btn;

  /// No description provided for @photo_deleted.
  ///
  /// In pt, this message translates to:
  /// **'Foto removida.'**
  String get photo_deleted;

  /// No description provided for @photo_comparison_title.
  ///
  /// In pt, this message translates to:
  /// **'Comparação do progresso'**
  String get photo_comparison_title;

  /// No description provided for @photo_comparison_before.
  ///
  /// In pt, this message translates to:
  /// **'Antes'**
  String get photo_comparison_before;

  /// No description provided for @photo_comparison_after.
  ///
  /// In pt, this message translates to:
  /// **'Depois'**
  String get photo_comparison_after;

  /// No description provided for @photo_close_btn.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get photo_close_btn;

  /// No description provided for @photo_swap_btn.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get photo_swap_btn;

  /// No description provided for @photo_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Sem fotos ainda'**
  String get photo_empty_title;

  /// No description provided for @photo_empty_instruction.
  ///
  /// In pt, this message translates to:
  /// **'Tire fotos para acompanhar sua transformação'**
  String get photo_empty_instruction;

  /// No description provided for @photo_compare_btn.
  ///
  /// In pt, this message translates to:
  /// **'Comparar progresso'**
  String get photo_compare_btn;

  /// No description provided for @photo_tips_title.
  ///
  /// In pt, this message translates to:
  /// **'Dicas'**
  String get photo_tips_title;

  /// No description provided for @photo_tips_content.
  ///
  /// In pt, this message translates to:
  /// **'• Tire fotos na mesma luz e pose\n• Utilize roupas similares para consistência\n• Tire de frente, lado e de costas\n• Programe fotos semanais'**
  String get photo_tips_content;

  /// No description provided for @photo_saved.
  ///
  /// In pt, this message translates to:
  /// **'Foto salva com sucesso!'**
  String get photo_saved;

  /// No description provided for @photo_need_two.
  ///
  /// In pt, this message translates to:
  /// **'Adicione ao menos 2 fotos para comparar'**
  String get photo_need_two;

  /// No description provided for @photo_add_semantics.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar foto'**
  String get photo_add_semantics;

  /// No description provided for @progress_overview_title.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do progresso'**
  String get progress_overview_title;

  /// No description provided for @progress_overview_period.
  ///
  /// In pt, this message translates to:
  /// **'Últimos {days} dias'**
  String progress_overview_period(int days);

  /// No description provided for @progress_stat_workouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get progress_stat_workouts;

  /// No description provided for @progress_stat_time.
  ///
  /// In pt, this message translates to:
  /// **'Tempo'**
  String get progress_stat_time;

  /// No description provided for @progress_stat_time_unit.
  ///
  /// In pt, this message translates to:
  /// **'horas'**
  String get progress_stat_time_unit;

  /// No description provided for @progress_stat_badges.
  ///
  /// In pt, this message translates to:
  /// **'Badges'**
  String get progress_stat_badges;

  /// No description provided for @progress_stat_badges_unit.
  ///
  /// In pt, this message translates to:
  /// **'desbloqueadas'**
  String get progress_stat_badges_unit;

  /// No description provided for @progress_stat_streak.
  ///
  /// In pt, this message translates to:
  /// **'Streak'**
  String get progress_stat_streak;

  /// No description provided for @progress_stat_streak_unit.
  ///
  /// In pt, this message translates to:
  /// **'dias'**
  String get progress_stat_streak_unit;

  /// No description provided for @progress_stat_total.
  ///
  /// In pt, this message translates to:
  /// **'total'**
  String get progress_stat_total;

  /// No description provided for @measurements_label_weight.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get measurements_label_weight;

  /// No description provided for @measurements_label_body_fat.
  ///
  /// In pt, this message translates to:
  /// **'Gordura Corporal'**
  String get measurements_label_body_fat;

  /// No description provided for @measurements_label_muscle_mass.
  ///
  /// In pt, this message translates to:
  /// **'Massa Muscular'**
  String get measurements_label_muscle_mass;

  /// No description provided for @measurements_add_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar {label}'**
  String measurements_add_dialog_title(String label);

  /// No description provided for @measurements_value_field.
  ///
  /// In pt, this message translates to:
  /// **'Valor ({unit})'**
  String measurements_value_field(String unit);

  /// No description provided for @measurements_notes_field.
  ///
  /// In pt, this message translates to:
  /// **'Notas (opcional)'**
  String get measurements_notes_field;

  /// No description provided for @measurements_save_success.
  ///
  /// In pt, this message translates to:
  /// **'Dado salvo com sucesso'**
  String get measurements_save_success;

  /// No description provided for @measurements_save_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar dado'**
  String get measurements_save_error;

  /// No description provided for @measurements_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados de {label} ainda'**
  String measurements_empty_title(String label);

  /// No description provided for @measurements_empty_instruction.
  ///
  /// In pt, this message translates to:
  /// **'Registre um valor para acompanhar a evolução'**
  String get measurements_empty_instruction;

  /// No description provided for @measurements_current_label.
  ///
  /// In pt, this message translates to:
  /// **'Atual · {label}'**
  String measurements_current_label(String label);

  /// No description provided for @measurements_recent_title.
  ///
  /// In pt, this message translates to:
  /// **'Últimos registros'**
  String get measurements_recent_title;

  /// No description provided for @measurements_register_btn.
  ///
  /// In pt, this message translates to:
  /// **'Registrar {label}'**
  String measurements_register_btn(String label);

  /// No description provided for @measurements_time_days_ago.
  ///
  /// In pt, this message translates to:
  /// **'{days}d atrás'**
  String measurements_time_days_ago(int days);

  /// No description provided for @measurements_time_hours_ago.
  ///
  /// In pt, this message translates to:
  /// **'{hours}h atrás'**
  String measurements_time_hours_ago(int hours);

  /// No description provided for @measurements_time_minutes_ago.
  ///
  /// In pt, this message translates to:
  /// **'{minutes}m atrás'**
  String measurements_time_minutes_ago(int minutes);

  /// No description provided for @measurements_time_now.
  ///
  /// In pt, this message translates to:
  /// **'Agora'**
  String get measurements_time_now;

  /// No description provided for @export_title.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Progresso'**
  String get export_title;

  /// No description provided for @export_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha como deseja visualizar seus dados'**
  String get export_subtitle;

  /// No description provided for @export_pdf_title.
  ///
  /// In pt, this message translates to:
  /// **'Relatório Oficial (PDF)'**
  String get export_pdf_title;

  /// No description provided for @export_pdf_desc.
  ///
  /// In pt, this message translates to:
  /// **'Documento formatado com histórico e design da marca'**
  String get export_pdf_desc;

  /// No description provided for @export_csv_title.
  ///
  /// In pt, this message translates to:
  /// **'Planilha de Dados (CSV)'**
  String get export_csv_title;

  /// No description provided for @export_csv_desc.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo bruto para análise externa ou backup'**
  String get export_csv_desc;

  /// No description provided for @export_share_title.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar Resumo'**
  String get export_share_title;

  /// No description provided for @export_share_desc.
  ///
  /// In pt, this message translates to:
  /// **'Texto rápido para WhatsApp ou Redes Sociais'**
  String get export_share_desc;

  /// No description provided for @workout_progress_consistency.
  ///
  /// In pt, this message translates to:
  /// **'Consistência'**
  String get workout_progress_consistency;

  /// No description provided for @workout_progress_less.
  ///
  /// In pt, this message translates to:
  /// **'Menos'**
  String get workout_progress_less;

  /// No description provided for @workout_progress_more.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get workout_progress_more;

  /// No description provided for @workout_progress_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'{count} treinos em {date}'**
  String workout_progress_tooltip(int count, String date);

  /// No description provided for @workout_progress_completed.
  ///
  /// In pt, this message translates to:
  /// **'Completos'**
  String get workout_progress_completed;

  /// No description provided for @workout_progress_avg_duration.
  ///
  /// In pt, this message translates to:
  /// **'Duração média'**
  String get workout_progress_avg_duration;

  /// No description provided for @workout_progress_total_time.
  ///
  /// In pt, this message translates to:
  /// **'Tempo total'**
  String get workout_progress_total_time;

  /// No description provided for @workout_progress_recent_title.
  ///
  /// In pt, this message translates to:
  /// **'Treinos recentes'**
  String get workout_progress_recent_title;

  /// No description provided for @workout_progress_empty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem treinos'**
  String get workout_progress_empty;

  /// No description provided for @workout_progress_today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get workout_progress_today;

  /// No description provided for @workout_progress_yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get workout_progress_yesterday;

  /// No description provided for @workout_progress_days_ago.
  ///
  /// In pt, this message translates to:
  /// **'{days}d atrás'**
  String workout_progress_days_ago(int days);

  /// No description provided for @workout_progress_recently.
  ///
  /// In pt, this message translates to:
  /// **'Recentemente'**
  String get workout_progress_recently;

  /// No description provided for @nutrition_analytics_avg_daily.
  ///
  /// In pt, this message translates to:
  /// **'Média diária'**
  String get nutrition_analytics_avg_daily;

  /// No description provided for @nutrition_analytics_days_on_target.
  ///
  /// In pt, this message translates to:
  /// **'Dias na meta'**
  String get nutrition_analytics_days_on_target;

  /// No description provided for @nutrition_analytics_adherence_title.
  ///
  /// In pt, this message translates to:
  /// **'Aderência à dieta'**
  String get nutrition_analytics_adherence_title;

  /// No description provided for @nutrition_analytics_calorie_goal.
  ///
  /// In pt, this message translates to:
  /// **'Meta de calorias'**
  String get nutrition_analytics_calorie_goal;

  /// No description provided for @nutrition_analytics_no_recent_data.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados recentes'**
  String get nutrition_analytics_no_recent_data;

  /// No description provided for @nutrition_analytics_log_meals_hint.
  ///
  /// In pt, this message translates to:
  /// **'Registre suas refeições para ver o gráfico'**
  String get nutrition_analytics_log_meals_hint;

  /// No description provided for @nutrition_analytics_calorie_history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de calorias'**
  String get nutrition_analytics_calorie_history;

  /// No description provided for @nutrition_analytics_goal_label.
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get nutrition_analytics_goal_label;

  /// No description provided for @nutrition_analytics_macros_title.
  ///
  /// In pt, this message translates to:
  /// **'Macros no período'**
  String get nutrition_analytics_macros_title;

  /// No description provided for @nutrition_analytics_no_meals.
  ///
  /// In pt, this message translates to:
  /// **'Sem refeições registradas no período'**
  String get nutrition_analytics_no_meals;

  /// No description provided for @nutrition_analytics_iqd_title.
  ///
  /// In pt, this message translates to:
  /// **'Evolução do IQD'**
  String get nutrition_analytics_iqd_title;

  /// No description provided for @nutrition_analytics_iqd_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Índice de qualidade da dieta'**
  String get nutrition_analytics_iqd_subtitle;

  /// No description provided for @nutrition_analytics_no_iqd.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados suficientes para o IQD'**
  String get nutrition_analytics_no_iqd;

  /// No description provided for @nutrition_analytics_meals_title.
  ///
  /// In pt, this message translates to:
  /// **'Refeições — últimos 7 dias'**
  String get nutrition_analytics_meals_title;

  /// No description provided for @nutrition_analytics_no_meals_7d.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma refeição registrada nos últimos 7 dias'**
  String get nutrition_analytics_no_meals_7d;

  /// No description provided for @nutrition_analytics_today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get nutrition_analytics_today;

  /// No description provided for @nutrition_analytics_protein.
  ///
  /// In pt, this message translates to:
  /// **'Proteína'**
  String get nutrition_analytics_protein;

  /// No description provided for @nutrition_analytics_carbs.
  ///
  /// In pt, this message translates to:
  /// **'Carboidrato'**
  String get nutrition_analytics_carbs;

  /// No description provided for @nutrition_analytics_fat.
  ///
  /// In pt, this message translates to:
  /// **'Gordura'**
  String get nutrition_analytics_fat;

  /// No description provided for @nutrition_analytics_pct_of_goal.
  ///
  /// In pt, this message translates to:
  /// **'% da meta'**
  String get nutrition_analytics_pct_of_goal;

  /// No description provided for @nutrition_meal_type_cafe.
  ///
  /// In pt, this message translates to:
  /// **'Café da manhã'**
  String get nutrition_meal_type_cafe;

  /// No description provided for @nutrition_meal_type_almoco.
  ///
  /// In pt, this message translates to:
  /// **'Almoço'**
  String get nutrition_meal_type_almoco;

  /// No description provided for @nutrition_meal_type_lanche.
  ///
  /// In pt, this message translates to:
  /// **'Lanche'**
  String get nutrition_meal_type_lanche;

  /// No description provided for @nutrition_meal_type_jantar.
  ///
  /// In pt, this message translates to:
  /// **'Jantar'**
  String get nutrition_meal_type_jantar;

  /// No description provided for @nutrition_meal_type_outro.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get nutrition_meal_type_outro;

  /// No description provided for @profile_title.
  ///
  /// In pt, this message translates to:
  /// **'Meu perfil'**
  String get profile_title;

  /// No description provided for @profile_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar perfil'**
  String get profile_error;

  /// No description provided for @profile_plan_choose_title.
  ///
  /// In pt, this message translates to:
  /// **'Escolha seu Plano'**
  String get profile_plan_choose_title;

  /// No description provided for @profile_plan_choose_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie todo o potencial do BLDR'**
  String get profile_plan_choose_subtitle;

  /// No description provided for @profile_plan_popular_badge.
  ///
  /// In pt, this message translates to:
  /// **'POPULAR'**
  String get profile_plan_popular_badge;

  /// No description provided for @profile_plan_annual_prefix.
  ///
  /// In pt, this message translates to:
  /// **'ou {price}'**
  String profile_plan_annual_prefix(String price);

  /// No description provided for @profile_plan_current.
  ///
  /// In pt, this message translates to:
  /// **'Plano Atual'**
  String get profile_plan_current;

  /// No description provided for @profile_plan_choose_btn.
  ///
  /// In pt, this message translates to:
  /// **'Escolher Plano'**
  String get profile_plan_choose_btn;

  /// No description provided for @profile_plan_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar planos: {error}'**
  String profile_plan_load_error(String error);

  /// No description provided for @profile_photo_change_title.
  ///
  /// In pt, this message translates to:
  /// **'Alterar foto de perfil'**
  String get profile_photo_change_title;

  /// No description provided for @profile_photo_remove_btn.
  ///
  /// In pt, this message translates to:
  /// **'Remover Foto'**
  String get profile_photo_remove_btn;

  /// No description provided for @profile_measurements_title.
  ///
  /// In pt, this message translates to:
  /// **'Medidas Corporais'**
  String get profile_measurements_title;

  /// No description provided for @profile_measurements_height.
  ///
  /// In pt, this message translates to:
  /// **'Altura (cm)'**
  String get profile_measurements_height;

  /// No description provided for @profile_measurements_target_weight.
  ///
  /// In pt, this message translates to:
  /// **'Peso Alvo (kg)'**
  String get profile_measurements_target_weight;

  /// No description provided for @profile_measurements_saved.
  ///
  /// In pt, this message translates to:
  /// **'Medidas salvas!'**
  String get profile_measurements_saved;

  /// No description provided for @profile_cancel_subscription_title.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar Assinatura'**
  String get profile_cancel_subscription_title;

  /// No description provided for @profile_cancel_subscription_before.
  ///
  /// In pt, this message translates to:
  /// **'Estamos implementando o cancelamento automático via app de sua assinatura.\n\nSe deseja mesmo cancelar, entre em contato em '**
  String get profile_cancel_subscription_before;

  /// No description provided for @profile_cancel_subscription_after.
  ///
  /// In pt, this message translates to:
  /// **' que iremos realizar o seu cancelamento.\n\nDesde já agradeçemos a compreensão e sentiremos sua falta na comunidade BLDR CLUB.'**
  String get profile_cancel_subscription_after;

  /// No description provided for @profile_permission_title.
  ///
  /// In pt, this message translates to:
  /// **'Permissão Necessária'**
  String get profile_permission_title;

  /// No description provided for @profile_permission_body.
  ///
  /// In pt, this message translates to:
  /// **'As notificações foram bloqueadas nas configurações do dispositivo. Para reativá-las, acesse as configurações do app.'**
  String get profile_permission_body;

  /// No description provided for @profile_open_settings_btn.
  ///
  /// In pt, this message translates to:
  /// **'Abrir Configurações'**
  String get profile_open_settings_btn;

  /// No description provided for @profile_updated.
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado com sucesso!'**
  String get profile_updated;

  /// No description provided for @profile_update_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar perfil: {error}'**
  String profile_update_error(String error);

  /// No description provided for @profile_photo_updated.
  ///
  /// In pt, this message translates to:
  /// **'Foto de perfil atualizada!'**
  String get profile_photo_updated;

  /// No description provided for @profile_photo_update_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar foto: {error}'**
  String profile_photo_update_error(String error);

  /// No description provided for @profile_photo_removed.
  ///
  /// In pt, this message translates to:
  /// **'Foto de perfil removida!'**
  String get profile_photo_removed;

  /// No description provided for @profile_photo_remove_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover foto: {error}'**
  String profile_photo_remove_error(String error);

  /// No description provided for @profile_camera_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao usar a câmera: {error}'**
  String profile_camera_error(String error);

  /// No description provided for @profile_gallery_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao escolher imagem: {error}'**
  String profile_gallery_error(String error);

  /// No description provided for @profile_notifications_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar notificações: {error}'**
  String profile_notifications_error(String error);

  /// No description provided for @profile_plan_free.
  ///
  /// In pt, this message translates to:
  /// **'Plano Gratuito'**
  String get profile_plan_free;

  /// No description provided for @profile_plan_premium.
  ///
  /// In pt, this message translates to:
  /// **'Plano Premium'**
  String get profile_plan_premium;

  /// No description provided for @profile_xp_bar_level.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level} · {xp} XP'**
  String profile_xp_bar_level(int level, int xp);

  /// No description provided for @profile_xp_bar_next_level.
  ///
  /// In pt, this message translates to:
  /// **'Nível {nextLevel} em {xpNext} XP'**
  String profile_xp_bar_next_level(int nextLevel, int xpNext);

  /// No description provided for @profile_xp_bar_to_next.
  ///
  /// In pt, this message translates to:
  /// **'+{toNext} XP para subir de nível'**
  String profile_xp_bar_to_next(int toNext);

  /// No description provided for @profile_stat_total_workouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos totais'**
  String get profile_stat_total_workouts;

  /// No description provided for @profile_stat_hours_trained.
  ///
  /// In pt, this message translates to:
  /// **'Horas treinadas'**
  String get profile_stat_hours_trained;

  /// No description provided for @profile_stat_current_streak.
  ///
  /// In pt, this message translates to:
  /// **'Streak atual'**
  String get profile_stat_current_streak;

  /// No description provided for @profile_stat_achievements.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get profile_stat_achievements;

  /// No description provided for @profile_duels_title.
  ///
  /// In pt, this message translates to:
  /// **'Duelos'**
  String get profile_duels_title;

  /// No description provided for @profile_duels_wins.
  ///
  /// In pt, this message translates to:
  /// **'Vitórias'**
  String get profile_duels_wins;

  /// No description provided for @profile_duels_losses.
  ///
  /// In pt, this message translates to:
  /// **'Derrotas'**
  String get profile_duels_losses;

  /// No description provided for @profile_duels_win_rate.
  ///
  /// In pt, this message translates to:
  /// **'Aproveit.'**
  String get profile_duels_win_rate;

  /// No description provided for @profile_badges_section.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get profile_badges_section;

  /// No description provided for @profile_next_achievement.
  ///
  /// In pt, this message translates to:
  /// **'Próxima conquista'**
  String get profile_next_achievement;

  /// No description provided for @profile_achievement_almost.
  ///
  /// In pt, this message translates to:
  /// **'Quase lá!'**
  String get profile_achievement_almost;

  /// No description provided for @profile_achievement_do_workout_singular.
  ///
  /// In pt, this message translates to:
  /// **'Faça mais {n} treino'**
  String profile_achievement_do_workout_singular(int n);

  /// No description provided for @profile_achievement_do_workout_plural.
  ///
  /// In pt, this message translates to:
  /// **'Faça mais {n} treinos'**
  String profile_achievement_do_workout_plural(int n);

  /// No description provided for @profile_achievement_maintain_streak_singular.
  ///
  /// In pt, this message translates to:
  /// **'Mantenha o streak por mais {n} dia'**
  String profile_achievement_maintain_streak_singular(int n);

  /// No description provided for @profile_achievement_maintain_streak_plural.
  ///
  /// In pt, this message translates to:
  /// **'Mantenha o streak por mais {n} dias'**
  String profile_achievement_maintain_streak_plural(int n);

  /// No description provided for @profile_achievement_calorie_goal_singular.
  ///
  /// In pt, this message translates to:
  /// **'Atinja sua meta calórica por mais {n} dia'**
  String profile_achievement_calorie_goal_singular(int n);

  /// No description provided for @profile_achievement_calorie_goal_plural.
  ///
  /// In pt, this message translates to:
  /// **'Atinja sua meta calórica por mais {n} dias'**
  String profile_achievement_calorie_goal_plural(int n);

  /// No description provided for @profile_achievement_log_meal_singular.
  ///
  /// In pt, this message translates to:
  /// **'Registre mais {n} refeição'**
  String profile_achievement_log_meal_singular(int n);

  /// No description provided for @profile_achievement_log_meal_plural.
  ///
  /// In pt, this message translates to:
  /// **'Registre mais {n} refeições'**
  String profile_achievement_log_meal_plural(int n);

  /// No description provided for @profile_achievement_earn_xp.
  ///
  /// In pt, this message translates to:
  /// **'Ganhe mais {n} XP'**
  String profile_achievement_earn_xp(int n);

  /// No description provided for @profile_achievement_reach_level.
  ///
  /// In pt, this message translates to:
  /// **'Alcance o nível {n} no Club'**
  String profile_achievement_reach_level(int n);

  /// No description provided for @profile_achievement_complete_workout_singular.
  ///
  /// In pt, this message translates to:
  /// **'Complete mais {n} treino'**
  String profile_achievement_complete_workout_singular(int n);

  /// No description provided for @profile_achievement_complete_workout_plural.
  ///
  /// In pt, this message translates to:
  /// **'Complete mais {n} treinos'**
  String profile_achievement_complete_workout_plural(int n);

  /// No description provided for @profile_achievement_keep_going.
  ///
  /// In pt, this message translates to:
  /// **'Continue progredindo!'**
  String get profile_achievement_keep_going;

  /// No description provided for @profile_weight_card_title.
  ///
  /// In pt, this message translates to:
  /// **'Peso · últimos 30 dias'**
  String get profile_weight_card_title;

  /// No description provided for @profile_see_all.
  ///
  /// In pt, this message translates to:
  /// **'Ver tudo →'**
  String get profile_see_all;

  /// No description provided for @profile_progress_section.
  ///
  /// In pt, this message translates to:
  /// **'Seu progresso'**
  String get profile_progress_section;

  /// No description provided for @profile_stat_total_time.
  ///
  /// In pt, this message translates to:
  /// **'Tempo total'**
  String get profile_stat_total_time;

  /// No description provided for @profile_rank_position.
  ///
  /// In pt, this message translates to:
  /// **'#{position} no ranking'**
  String profile_rank_position(int position);

  /// No description provided for @profile_sign_in_message.
  ///
  /// In pt, this message translates to:
  /// **'Confira meu perfil do BLDR!\n\nJunte-se à comunidade BLDR CLUB!'**
  String get profile_sign_in_message;

  /// No description provided for @profile_notifications_enabled.
  ///
  /// In pt, this message translates to:
  /// **'Ativado'**
  String get profile_notifications_enabled;

  /// No description provided for @profile_notifications_disabled.
  ///
  /// In pt, this message translates to:
  /// **'Desativado'**
  String get profile_notifications_disabled;

  /// No description provided for @settings_title.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings_title;

  /// No description provided for @settings_section_account.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get settings_section_account;

  /// No description provided for @settings_edit_profile.
  ///
  /// In pt, this message translates to:
  /// **'Editar perfil'**
  String get settings_edit_profile;

  /// No description provided for @settings_edit_profile_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Nome, e-mail, telefone'**
  String get settings_edit_profile_subtitle;

  /// No description provided for @settings_share_profile.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar perfil'**
  String get settings_share_profile;

  /// No description provided for @settings_section_plan.
  ///
  /// In pt, this message translates to:
  /// **'Plano e assinatura'**
  String get settings_section_plan;

  /// No description provided for @settings_current_plan_row.
  ///
  /// In pt, this message translates to:
  /// **'Plano atual'**
  String get settings_current_plan_row;

  /// No description provided for @settings_manage_subscription.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar assinatura'**
  String get settings_manage_subscription;

  /// No description provided for @settings_manage_subscription_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento, faturas, cancelar'**
  String get settings_manage_subscription_subtitle;

  /// No description provided for @settings_section_workout.
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get settings_section_workout;

  /// No description provided for @settings_workout_preferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências de treino'**
  String get settings_workout_preferences;

  /// No description provided for @settings_workout_preferences_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar suas preferências iniciais'**
  String get settings_workout_preferences_subtitle;

  /// No description provided for @settings_goals_row.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get settings_goals_row;

  /// No description provided for @settings_goals_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Peso, calorias, macros'**
  String get settings_goals_subtitle;

  /// No description provided for @settings_section_app.
  ///
  /// In pt, this message translates to:
  /// **'Aplicativo'**
  String get settings_section_app;

  /// No description provided for @settings_notifications_row.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get settings_notifications_row;

  /// No description provided for @settings_notifications_enabled.
  ///
  /// In pt, this message translates to:
  /// **'Ativado'**
  String get settings_notifications_enabled;

  /// No description provided for @settings_notifications_disabled.
  ///
  /// In pt, this message translates to:
  /// **'Desativado'**
  String get settings_notifications_disabled;

  /// No description provided for @settings_language_row.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settings_language_row;

  /// No description provided for @settings_language_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Português, English, Italiano'**
  String get settings_language_subtitle;

  /// No description provided for @settings_privacy_row.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get settings_privacy_row;

  /// No description provided for @settings_privacy_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Visibilidade no ranking e feed'**
  String get settings_privacy_subtitle;

  /// No description provided for @settings_section_integrations.
  ///
  /// In pt, this message translates to:
  /// **'Integrações'**
  String get settings_section_integrations;

  /// No description provided for @settings_whoop_synced.
  ///
  /// In pt, this message translates to:
  /// **'Recovery, Strain e Sleep sincronizados'**
  String get settings_whoop_synced;

  /// No description provided for @settings_whoop_connected_badge.
  ///
  /// In pt, this message translates to:
  /// **'Conectado'**
  String get settings_whoop_connected_badge;

  /// No description provided for @settings_whoop_disconnect_btn.
  ///
  /// In pt, this message translates to:
  /// **'Desconectar'**
  String get settings_whoop_disconnect_btn;

  /// No description provided for @settings_whoop_connect_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Conecte seu Whoop'**
  String get settings_whoop_connect_subtitle;

  /// No description provided for @settings_apple_health.
  ///
  /// In pt, this message translates to:
  /// **'Apple Saúde'**
  String get settings_apple_health;

  /// No description provided for @settings_soon_badge.
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get settings_soon_badge;

  /// No description provided for @settings_watchables.
  ///
  /// In pt, this message translates to:
  /// **'Relógios e wearables'**
  String get settings_watchables;

  /// No description provided for @settings_section_support.
  ///
  /// In pt, this message translates to:
  /// **'Suporte'**
  String get settings_section_support;

  /// No description provided for @settings_help_center.
  ///
  /// In pt, this message translates to:
  /// **'Central de ajuda'**
  String get settings_help_center;

  /// No description provided for @settings_terms.
  ///
  /// In pt, this message translates to:
  /// **'Termos de uso'**
  String get settings_terms;

  /// No description provided for @settings_privacy_policy_row.
  ///
  /// In pt, this message translates to:
  /// **'Política de privacidade'**
  String get settings_privacy_policy_row;

  /// No description provided for @settings_section_about.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get settings_section_about;

  /// No description provided for @settings_version_row.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get settings_version_row;

  /// No description provided for @settings_copyright.
  ///
  /// In pt, this message translates to:
  /// **'© {year} BLDR Fitness. Todos os direitos reservados.'**
  String settings_copyright(int year);

  /// No description provided for @settings_sign_out_row.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta'**
  String get settings_sign_out_row;

  /// No description provided for @settings_delete_account_row.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get settings_delete_account_row;

  /// No description provided for @settings_version_footer.
  ///
  /// In pt, this message translates to:
  /// **'BLDR · versão {version}'**
  String settings_version_footer(String version);

  /// No description provided for @settings_manage_sub_sheet_title.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar assinatura'**
  String get settings_manage_sub_sheet_title;

  /// No description provided for @settings_upgrade_btn.
  ///
  /// In pt, this message translates to:
  /// **'Fazer upgrade'**
  String get settings_upgrade_btn;

  /// No description provided for @settings_upgrade_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear recursos premium'**
  String get settings_upgrade_subtitle;

  /// No description provided for @settings_cancel_sub_btn.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar assinatura'**
  String get settings_cancel_sub_btn;

  /// No description provided for @settings_cancel_sub_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar sua assinatura BLDR CLUB'**
  String get settings_cancel_sub_subtitle;

  /// No description provided for @settings_sign_out_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get settings_sign_out_dialog_title;

  /// No description provided for @settings_sign_out_dialog_message.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja sair?'**
  String get settings_sign_out_dialog_message;

  /// No description provided for @settings_sign_out_dialog_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get settings_sign_out_dialog_confirm;

  /// No description provided for @settings_sign_out_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao sair: {error}'**
  String settings_sign_out_error(String error);

  /// No description provided for @settings_delete_account_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Conta'**
  String get settings_delete_account_dialog_title;

  /// No description provided for @settings_delete_account_dialog_message.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir sua conta?\n\nTodos os seus dados e sua assinatura serão removidos permanentemente. Esta ação não pode ser desfeita.'**
  String get settings_delete_account_dialog_message;

  /// No description provided for @settings_delete_account_dialog_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Sim, Excluir'**
  String get settings_delete_account_dialog_confirm;

  /// No description provided for @settings_delete_account_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir conta: {error}'**
  String settings_delete_account_error(String error);

  /// No description provided for @settings_cancel_sub_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar planos: {error}'**
  String settings_cancel_sub_error(String error);

  /// No description provided for @goals_screen_title.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get goals_screen_title;

  /// No description provided for @goals_macros_exceed.
  ///
  /// In pt, this message translates to:
  /// **'Soma dos macros excede a meta calórica.'**
  String get goals_macros_exceed;

  /// No description provided for @goals_saved.
  ///
  /// In pt, this message translates to:
  /// **'Metas salvas com sucesso!'**
  String get goals_saved;

  /// No description provided for @goals_section_weight.
  ///
  /// In pt, this message translates to:
  /// **'PESO'**
  String get goals_section_weight;

  /// No description provided for @goals_current_weight_label.
  ///
  /// In pt, this message translates to:
  /// **'Peso atual'**
  String get goals_current_weight_label;

  /// No description provided for @goals_editable_in_progress.
  ///
  /// In pt, this message translates to:
  /// **'Editável em Progresso'**
  String get goals_editable_in_progress;

  /// No description provided for @goals_target_weight_label.
  ///
  /// In pt, this message translates to:
  /// **'Peso alvo'**
  String get goals_target_weight_label;

  /// No description provided for @goals_pace_title.
  ///
  /// In pt, this message translates to:
  /// **'Ritmo'**
  String get goals_pace_title;

  /// No description provided for @goals_pace_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade do progresso em relação ao alvo'**
  String get goals_pace_subtitle;

  /// No description provided for @goals_section_nutrition.
  ///
  /// In pt, this message translates to:
  /// **'NUTRIÇÃO'**
  String get goals_section_nutrition;

  /// No description provided for @goals_calorie_goal_label.
  ///
  /// In pt, this message translates to:
  /// **'Meta calórica diária'**
  String get goals_calorie_goal_label;

  /// No description provided for @goals_calorie_calculated.
  ///
  /// In pt, this message translates to:
  /// **'Calculado pelo HAVOK'**
  String get goals_calorie_calculated;

  /// No description provided for @goals_use_calculated.
  ///
  /// In pt, this message translates to:
  /// **'Usar calculado'**
  String get goals_use_calculated;

  /// No description provided for @goals_customize.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar'**
  String get goals_customize;

  /// No description provided for @goals_macros_title.
  ///
  /// In pt, this message translates to:
  /// **'Macronutrientes'**
  String get goals_macros_title;

  /// No description provided for @goals_macro_protein.
  ///
  /// In pt, this message translates to:
  /// **'Proteína'**
  String get goals_macro_protein;

  /// No description provided for @goals_macro_carbs.
  ///
  /// In pt, this message translates to:
  /// **'Carboidrato'**
  String get goals_macro_carbs;

  /// No description provided for @goals_macro_fat.
  ///
  /// In pt, this message translates to:
  /// **'Gordura'**
  String get goals_macro_fat;

  /// No description provided for @goals_macro_pct_calories.
  ///
  /// In pt, this message translates to:
  /// **'{pct}% das calorias'**
  String goals_macro_pct_calories(String pct);

  /// No description provided for @goals_footer_note.
  ///
  /// In pt, this message translates to:
  /// **'Alterações afetam Dashboard, Nutrição e o contexto do HAVOK.'**
  String get goals_footer_note;

  /// No description provided for @goals_save_btn.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get goals_save_btn;

  /// No description provided for @privacy_title.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get privacy_title;

  /// No description provided for @privacy_nickname_required.
  ///
  /// In pt, this message translates to:
  /// **'Informe um apelido ou use o nome real.'**
  String get privacy_nickname_required;

  /// No description provided for @privacy_saved.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade atualizada.'**
  String get privacy_saved;

  /// No description provided for @privacy_section_identity.
  ///
  /// In pt, this message translates to:
  /// **'IDENTIDADE NO RANKING E FEED'**
  String get privacy_section_identity;

  /// No description provided for @privacy_name_toggle_title.
  ///
  /// In pt, this message translates to:
  /// **'Nome no ranking e feed'**
  String get privacy_name_toggle_title;

  /// No description provided for @privacy_name_active_label.
  ///
  /// In pt, this message translates to:
  /// **'Apelido'**
  String get privacy_name_active_label;

  /// No description provided for @privacy_name_inactive_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome real'**
  String get privacy_name_inactive_label;

  /// No description provided for @privacy_name_inactive_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Nome real (padrão)'**
  String get privacy_name_inactive_subtitle;

  /// No description provided for @privacy_nickname_hint.
  ///
  /// In pt, this message translates to:
  /// **'Apelido (máx. 20 chars)'**
  String get privacy_nickname_hint;

  /// No description provided for @privacy_photo_toggle_title.
  ///
  /// In pt, this message translates to:
  /// **'Foto de perfil visível'**
  String get privacy_photo_toggle_title;

  /// No description provided for @privacy_photo_active_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Visível para todos'**
  String get privacy_photo_active_subtitle;

  /// No description provided for @privacy_photo_inactive_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Só para membros do squad'**
  String get privacy_photo_inactive_subtitle;

  /// No description provided for @privacy_photo_active_label.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get privacy_photo_active_label;

  /// No description provided for @privacy_photo_inactive_label.
  ///
  /// In pt, this message translates to:
  /// **'Squad'**
  String get privacy_photo_inactive_label;

  /// No description provided for @privacy_section_feed.
  ///
  /// In pt, this message translates to:
  /// **'FEED DE ATIVIDADE'**
  String get privacy_section_feed;

  /// No description provided for @privacy_feed_toggle_title.
  ///
  /// In pt, this message translates to:
  /// **'Aparecer no feed da comunidade'**
  String get privacy_feed_toggle_title;

  /// No description provided for @privacy_feed_active_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Suas atividades aparecem no feed'**
  String get privacy_feed_active_subtitle;

  /// No description provided for @privacy_feed_inactive_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Atividades não aparecem para outros'**
  String get privacy_feed_inactive_subtitle;

  /// No description provided for @privacy_yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get privacy_yes;

  /// No description provided for @privacy_no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get privacy_no;

  /// No description provided for @privacy_reactions_toggle_title.
  ///
  /// In pt, this message translates to:
  /// **'Permitir reações'**
  String get privacy_reactions_toggle_title;

  /// No description provided for @privacy_reactions_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Outros podem reagir às suas atividades'**
  String get privacy_reactions_subtitle;

  /// No description provided for @privacy_section_ranking.
  ///
  /// In pt, this message translates to:
  /// **'RANKING'**
  String get privacy_section_ranking;

  /// No description provided for @privacy_ranking_toggle_title.
  ///
  /// In pt, this message translates to:
  /// **'Participar do ranking público'**
  String get privacy_ranking_toggle_title;

  /// No description provided for @privacy_ranking_active_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Aparece no ranking geral'**
  String get privacy_ranking_active_subtitle;

  /// No description provided for @privacy_ranking_inactive_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Oculto no ranking geral (squad não afetado)'**
  String get privacy_ranking_inactive_subtitle;

  /// No description provided for @privacy_legal_text.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados são processados conforme nossa Política de Privacidade.'**
  String get privacy_legal_text;

  /// No description provided for @privacy_legal_link.
  ///
  /// In pt, this message translates to:
  /// **'Ver política →'**
  String get privacy_legal_link;

  /// No description provided for @privacy_save_btn.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get privacy_save_btn;

  /// No description provided for @language_sheet_title.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do app'**
  String get language_sheet_title;

  /// No description provided for @language_havok_note.
  ///
  /// In pt, this message translates to:
  /// **'O conteúdo gerado pelo HAVOK também será no idioma selecionado.'**
  String get language_havok_note;

  /// No description provided for @language_pt_region.
  ///
  /// In pt, this message translates to:
  /// **'Brasil'**
  String get language_pt_region;

  /// No description provided for @language_en_region.
  ///
  /// In pt, this message translates to:
  /// **'United States'**
  String get language_en_region;

  /// No description provided for @language_it_region.
  ///
  /// In pt, this message translates to:
  /// **'Italia'**
  String get language_it_region;

  /// No description provided for @edit_profile_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get edit_profile_dialog_title;

  /// No description provided for @edit_profile_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get edit_profile_name_label;

  /// No description provided for @edit_profile_email_label.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get edit_profile_email_label;

  /// No description provided for @edit_profile_email_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Email não pode ser alterado'**
  String get edit_profile_email_tooltip;

  /// No description provided for @edit_profile_phone_label.
  ///
  /// In pt, this message translates to:
  /// **'Telefone (opcional)'**
  String get edit_profile_phone_label;

  /// No description provided for @edit_profile_name_required.
  ///
  /// In pt, this message translates to:
  /// **'Nome é obrigatório'**
  String get edit_profile_name_required;

  /// No description provided for @edit_profile_save_btn.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get edit_profile_save_btn;

  /// No description provided for @edit_profile_cancel_btn.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get edit_profile_cancel_btn;

  /// No description provided for @common_save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get common_save;

  /// No description provided for @photo_camera_permission_body.
  ///
  /// In pt, this message translates to:
  /// **'Habilite a câmera nas configurações para registrar seu progresso.'**
  String get photo_camera_permission_body;

  /// No description provided for @photo_gallery_permission_body.
  ///
  /// In pt, this message translates to:
  /// **'Habilite o acesso às fotos nas configurações.'**
  String get photo_gallery_permission_body;

  /// No description provided for @goals_create_semantics.
  ///
  /// In pt, this message translates to:
  /// **'Criar objetivo'**
  String get goals_create_semantics;

  /// No description provided for @club_events_title.
  ///
  /// In pt, this message translates to:
  /// **'Eventos'**
  String get club_events_title;

  /// No description provided for @club_announcements_title.
  ///
  /// In pt, this message translates to:
  /// **'Anúncios'**
  String get club_announcements_title;

  /// No description provided for @club_workouts_title.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get club_workouts_title;

  /// No description provided for @club_workouts_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Biblioteca · Programas'**
  String get club_workouts_subtitle;

  /// No description provided for @club_sports_title.
  ///
  /// In pt, this message translates to:
  /// **'Esportes'**
  String get club_sports_title;

  /// No description provided for @club_sports_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Run · Protocolos'**
  String get club_sports_subtitle;

  /// No description provided for @club_community_title.
  ///
  /// In pt, this message translates to:
  /// **'Comunidade'**
  String get club_community_title;

  /// No description provided for @club_community_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Feed · Desafios'**
  String get club_community_subtitle;

  /// No description provided for @club_competition_title.
  ///
  /// In pt, this message translates to:
  /// **'Competição'**
  String get club_competition_title;

  /// No description provided for @club_competition_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Squads · Operações'**
  String get club_competition_subtitle;

  /// No description provided for @club_weekly_operation.
  ///
  /// In pt, this message translates to:
  /// **'OPERAÇÃO DA SEMANA'**
  String get club_weekly_operation;

  /// No description provided for @club_operation_completed.
  ///
  /// In pt, this message translates to:
  /// **'CONCLUÍDA ✓'**
  String get club_operation_completed;

  /// No description provided for @club_operation_progress.
  ///
  /// In pt, this message translates to:
  /// **'{current} de {goal} {unit}'**
  String club_operation_progress(Object current, Object goal, String unit);

  /// No description provided for @club_operation_xp_reward.
  ///
  /// In pt, this message translates to:
  /// **'+{xp} XP ao completar'**
  String club_operation_xp_reward(Object xp);

  /// No description provided for @club_level.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level}'**
  String club_level(Object level);

  /// No description provided for @club_ranking_badge.
  ///
  /// In pt, this message translates to:
  /// **'#{position} no ranking'**
  String club_ranking_badge(Object position);

  /// No description provided for @club_xp_progress.
  ///
  /// In pt, this message translates to:
  /// **'{current} / {total} XP'**
  String club_xp_progress(Object current, Object total);

  /// No description provided for @havok_sheet_title.
  ///
  /// In pt, this message translates to:
  /// **'HAVOK'**
  String get havok_sheet_title;

  /// No description provided for @havok_sheet_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'SEU TREINADOR BLDR'**
  String get havok_sheet_subtitle;

  /// No description provided for @havok_input_placeholder.
  ///
  /// In pt, this message translates to:
  /// **'Pergunte ao HAVOK…'**
  String get havok_input_placeholder;

  /// No description provided for @havok_disclaimer.
  ///
  /// In pt, this message translates to:
  /// **'HAVOK é uma IA e pode errar. Não substitui orientação médica ou nutricional.'**
  String get havok_disclaimer;

  /// No description provided for @havok_error_open.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui abrir a conversa.'**
  String get havok_error_open;

  /// No description provided for @havok_no_reply.
  ///
  /// In pt, this message translates to:
  /// **'O HAVOK não respondeu. Tente de novo.'**
  String get havok_no_reply;

  /// No description provided for @havok_workout_exercises_tap.
  ///
  /// In pt, this message translates to:
  /// **'{count} exercícios · toque para ver'**
  String havok_workout_exercises_tap(Object count);

  /// No description provided for @club_competition_hub_title.
  ///
  /// In pt, this message translates to:
  /// **'CENTRAL DE OPERAÇÕES'**
  String get club_competition_hub_title;

  /// No description provided for @club_create_operation.
  ///
  /// In pt, this message translates to:
  /// **'CRIAR\nOPERAÇÃO'**
  String get club_create_operation;

  /// No description provided for @club_be_the_leader.
  ///
  /// In pt, this message translates to:
  /// **'Seja o líder.'**
  String get club_be_the_leader;

  /// No description provided for @club_join_now.
  ///
  /// In pt, this message translates to:
  /// **'ALISTAR-SE\nAGORA'**
  String get club_join_now;

  /// No description provided for @club_enter_code.
  ///
  /// In pt, this message translates to:
  /// **'Cole o código.'**
  String get club_enter_code;

  /// No description provided for @club_game_modes_header.
  ///
  /// In pt, this message translates to:
  /// **'MODOS DE JOGO'**
  String get club_game_modes_header;

  /// No description provided for @club_game_mode_survivor.
  ///
  /// In pt, this message translates to:
  /// **'SURVIVOR'**
  String get club_game_mode_survivor;

  /// No description provided for @club_game_mode_alfa.
  ///
  /// In pt, this message translates to:
  /// **'ALFA'**
  String get club_game_mode_alfa;

  /// No description provided for @club_game_mode_roadrunner.
  ///
  /// In pt, this message translates to:
  /// **'ROADRUNNER'**
  String get club_game_mode_roadrunner;

  /// No description provided for @club_game_mode_hustle.
  ///
  /// In pt, this message translates to:
  /// **'HUSTLE'**
  String get club_game_mode_hustle;

  /// No description provided for @club_survivor_description.
  ///
  /// In pt, this message translates to:
  /// **'Quem ficar 2 dias sem treinar é eliminado automaticamente.'**
  String get club_survivor_description;

  /// No description provided for @club_alfa_description.
  ///
  /// In pt, this message translates to:
  /// **'Ganha quem acumular mais XP total — todos os treinos contam.'**
  String get club_alfa_description;

  /// No description provided for @club_roadrunner_description.
  ///
  /// In pt, this message translates to:
  /// **'Vence quem acumular a maior distância em corridas.'**
  String get club_roadrunner_description;

  /// No description provided for @club_hustle_description.
  ///
  /// In pt, this message translates to:
  /// **'Não importa o treino, importa ir. Ganha quem treinar mais dias.'**
  String get club_hustle_description;

  /// No description provided for @club_my_active_squads.
  ///
  /// In pt, this message translates to:
  /// **'MEUS SQUADS ATIVOS'**
  String get club_my_active_squads;

  /// No description provided for @club_no_active_operation.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma operação ativa.'**
  String get club_no_active_operation;

  /// No description provided for @club_community_tab.
  ///
  /// In pt, this message translates to:
  /// **'Comunidade'**
  String get club_community_tab;

  /// No description provided for @club_challenges_tab.
  ///
  /// In pt, this message translates to:
  /// **'Desafios'**
  String get club_challenges_tab;

  /// No description provided for @club_ranking_week.
  ///
  /// In pt, this message translates to:
  /// **'Ranking da semana'**
  String get club_ranking_week;

  /// No description provided for @club_see_all.
  ///
  /// In pt, this message translates to:
  /// **'Ver tudo ›'**
  String get club_see_all;

  /// No description provided for @club_my_duels.
  ///
  /// In pt, this message translates to:
  /// **'SEUS DUELOS'**
  String get club_my_duels;

  /// No description provided for @club_collective_challenges.
  ///
  /// In pt, this message translates to:
  /// **'DESAFIOS COLETIVOS'**
  String get club_collective_challenges;

  /// No description provided for @club_create.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get club_create;

  /// No description provided for @club_duel_history.
  ///
  /// In pt, this message translates to:
  /// **'HISTÓRICO DE DUELOS'**
  String get club_duel_history;

  /// No description provided for @club_no_active_duel.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum duelo ativo'**
  String get club_no_active_duel;

  /// No description provided for @club_go_to_ranking.
  ///
  /// In pt, this message translates to:
  /// **'Vá ao Ranking e desafie alguém!'**
  String get club_go_to_ranking;

  /// No description provided for @club_no_collective_challenge.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum desafio coletivo ativo'**
  String get club_no_collective_challenge;

  /// No description provided for @club_create_first_challenge.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Criar\" e seja o primeiro!'**
  String get club_create_first_challenge;

  /// No description provided for @club_no_ended_duel.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum duelo encerrado ainda.'**
  String get club_no_ended_duel;

  /// No description provided for @club_recent_activity.
  ///
  /// In pt, this message translates to:
  /// **'Atividade recente'**
  String get club_recent_activity;

  /// No description provided for @club_no_recent_activity.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma atividade recente.'**
  String get club_no_recent_activity;

  /// No description provided for @club_your_position.
  ///
  /// In pt, this message translates to:
  /// **'Sua posição'**
  String get club_your_position;

  /// No description provided for @club_xp_to_next_position.
  ///
  /// In pt, this message translates to:
  /// **'+{xp} XP para o #{pos}'**
  String club_xp_to_next_position(Object xp, Object pos);

  /// No description provided for @club_morale_sent.
  ///
  /// In pt, this message translates to:
  /// **'Você mandou moral para {name}! 👊🔥'**
  String club_morale_sent(String name);

  /// No description provided for @ranking_duel_accepted.
  ///
  /// In pt, this message translates to:
  /// **'Desafio ACEITO! A guerra começou. 🔥'**
  String get ranking_duel_accepted;

  /// No description provided for @ranking_duel_refused.
  ///
  /// In pt, this message translates to:
  /// **'Desafio recusado.'**
  String get ranking_duel_refused;

  /// No description provided for @ranking_win_snackbar.
  ///
  /// In pt, this message translates to:
  /// **'PARABÉNS! Você venceu o duelo! 🏆'**
  String get ranking_win_snackbar;

  /// No description provided for @ranking_you_suffix.
  ///
  /// In pt, this message translates to:
  /// **' (Você)'**
  String get ranking_you_suffix;

  /// No description provided for @ranking_you_label.
  ///
  /// In pt, this message translates to:
  /// **'VOCÊ'**
  String get ranking_you_label;

  /// No description provided for @ranking_rival_label.
  ///
  /// In pt, this message translates to:
  /// **'RIVAL'**
  String get ranking_rival_label;

  /// No description provided for @ranking_vs.
  ///
  /// In pt, this message translates to:
  /// **'VS'**
  String get ranking_vs;

  /// No description provided for @ranking_challenge_received.
  ///
  /// In pt, this message translates to:
  /// **'DESAFIO RECEBIDO'**
  String get ranking_challenge_received;

  /// No description provided for @ranking_challenge_prompt.
  ///
  /// In pt, this message translates to:
  /// **' te chamou para o duelo!\nVai encarar ou correr?'**
  String get ranking_challenge_prompt;

  /// No description provided for @ranking_refuse_btn.
  ///
  /// In pt, this message translates to:
  /// **'Recusar'**
  String get ranking_refuse_btn;

  /// No description provided for @ranking_accept_btn.
  ///
  /// In pt, this message translates to:
  /// **'ACEITAR'**
  String get ranking_accept_btn;

  /// No description provided for @ranking_yourself_msg.
  ///
  /// In pt, this message translates to:
  /// **'Esse é você, campeão! Continue focando. 🔥'**
  String get ranking_yourself_msg;

  /// No description provided for @ranking_duel_title.
  ///
  /// In pt, this message translates to:
  /// **'⚔️ INICIAR DUELO'**
  String get ranking_duel_title;

  /// No description provided for @ranking_duel_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Quem bater a meta primeiro vence'**
  String get ranking_duel_subtitle;

  /// No description provided for @ranking_xp_goal.
  ///
  /// In pt, this message translates to:
  /// **'META EM XP'**
  String get ranking_xp_goal;

  /// No description provided for @ranking_deadline.
  ///
  /// In pt, this message translates to:
  /// **'PRAZO'**
  String get ranking_deadline;

  /// No description provided for @ranking_winner_label.
  ///
  /// In pt, this message translates to:
  /// **'Vencedor'**
  String get ranking_winner_label;

  /// No description provided for @ranking_deadline_label.
  ///
  /// In pt, this message translates to:
  /// **'Prazo'**
  String get ranking_deadline_label;

  /// No description provided for @ranking_badge_label.
  ///
  /// In pt, this message translates to:
  /// **'Badge'**
  String get ranking_badge_label;

  /// No description provided for @ranking_duelista.
  ///
  /// In pt, this message translates to:
  /// **'Duelista'**
  String get ranking_duelista;

  /// No description provided for @ranking_duel_sent.
  ///
  /// In pt, this message translates to:
  /// **'⚔️ Duelo de {xp} XP enviado para {name}!'**
  String ranking_duel_sent(Object xp, String name);

  /// No description provided for @ranking_duel_send_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar desafio.'**
  String get ranking_duel_send_error;

  /// No description provided for @ranking_who_bets.
  ///
  /// In pt, this message translates to:
  /// **'Quem bater {xp} xp primeiro em {prazo} vence'**
  String ranking_who_bets(Object xp, String prazo);

  /// No description provided for @ranking_start_duel_btn.
  ///
  /// In pt, this message translates to:
  /// **'INICIAR DUELO DE {xp} XP'**
  String ranking_start_duel_btn(Object xp);

  /// No description provided for @havok_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get havok_loading;

  /// No description provided for @havok_hello.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}'**
  String havok_hello(String name);

  /// No description provided for @havok_tagline.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para superar seus limites?'**
  String get havok_tagline;

  /// No description provided for @havok_generate_training.
  ///
  /// In pt, this message translates to:
  /// **'GERAÇÃO DE TREINO'**
  String get havok_generate_training;

  /// No description provided for @havok_generate_btn.
  ///
  /// In pt, this message translates to:
  /// **'GERAR TREINO HAVOK'**
  String get havok_generate_btn;

  /// No description provided for @havok_error_generate.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar treino. Tente novamente.'**
  String get havok_error_generate;

  /// No description provided for @havok_guest.
  ///
  /// In pt, this message translates to:
  /// **'Visitante'**
  String get havok_guest;

  /// No description provided for @havok_user_default.
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get havok_user_default;

  /// No description provided for @havok_loading_step1.
  ///
  /// In pt, this message translates to:
  /// **'Buscando informações do seu perfil...'**
  String get havok_loading_step1;

  /// No description provided for @havok_loading_step2.
  ///
  /// In pt, this message translates to:
  /// **'Gerando seu treino personalizado...'**
  String get havok_loading_step2;

  /// No description provided for @havok_loading_step3.
  ///
  /// In pt, this message translates to:
  /// **'Tudo pronto!'**
  String get havok_loading_step3;

  /// No description provided for @free_workout_title.
  ///
  /// In pt, this message translates to:
  /// **'TREINO LIVRE'**
  String get free_workout_title;

  /// No description provided for @free_workout_describe.
  ///
  /// In pt, this message translates to:
  /// **'Descreva o treino que você quer'**
  String get free_workout_describe;

  /// No description provided for @free_workout_hint.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu comando aqui...'**
  String get free_workout_hint;

  /// No description provided for @free_workout_btn.
  ///
  /// In pt, this message translates to:
  /// **'GERAR COM HAVOK'**
  String get free_workout_btn;

  /// No description provided for @workout_library_title.
  ///
  /// In pt, this message translates to:
  /// **'BIBLIOTECA HAVOK'**
  String get workout_library_title;

  /// No description provided for @workout_library_empty.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não gerou nenhum treino.'**
  String get workout_library_empty;

  /// No description provided for @workout_library_go_hub.
  ///
  /// In pt, this message translates to:
  /// **'Vá para o Hub do HAVOK para criar o seu.'**
  String get workout_library_go_hub;

  /// No description provided for @workout_library_error.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro ao buscar seus treinos.'**
  String get workout_library_error;

  /// No description provided for @workout_detail_save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar na biblioteca'**
  String get workout_detail_save;

  /// No description provided for @workout_detail_saved.
  ///
  /// In pt, this message translates to:
  /// **'Salvo ✓'**
  String get workout_detail_saved;

  /// No description provided for @workout_detail_start_now.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar agora'**
  String get workout_detail_start_now;

  /// No description provided for @workout_detail_add_plan.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao plano'**
  String get workout_detail_add_plan;

  /// No description provided for @workout_detail_which_day.
  ///
  /// In pt, this message translates to:
  /// **'Em qual dia da semana?'**
  String get workout_detail_which_day;

  /// No description provided for @club_my_workouts.
  ///
  /// In pt, this message translates to:
  /// **'Meus treinos'**
  String get club_my_workouts;

  /// No description provided for @club_created_by_me.
  ///
  /// In pt, this message translates to:
  /// **'Criados por mim'**
  String get club_created_by_me;

  /// No description provided for @club_from_trainer.
  ///
  /// In pt, this message translates to:
  /// **'Do meu personal'**
  String get club_from_trainer;

  /// No description provided for @club_start_workout_btn.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar treino'**
  String get club_start_workout_btn;

  /// No description provided for @club_no_workout_created.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum treino criado ainda'**
  String get club_no_workout_created;

  /// No description provided for @club_create_first_workout.
  ///
  /// In pt, this message translates to:
  /// **'Crie seu primeiro treino personalizado'**
  String get club_create_first_workout;

  /// No description provided for @club_trainer_programs_soon.
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get club_trainer_programs_soon;

  /// No description provided for @club_trainer_programs_soon_desc.
  ///
  /// In pt, this message translates to:
  /// **'Em breve você poderá receber treinos\ndirecionados pelo seu personal trainer.'**
  String get club_trainer_programs_soon_desc;

  /// No description provided for @club_programs_title.
  ///
  /// In pt, this message translates to:
  /// **'Programas Club'**
  String get club_programs_title;

  /// No description provided for @club_programs_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Sequências estruturadas · Exclusivo BLDR CLUB'**
  String get club_programs_subtitle;

  /// No description provided for @club_see_all_arrow.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos →'**
  String get club_see_all_arrow;

  /// No description provided for @club_no_workout_found.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum treino encontrado.'**
  String get club_no_workout_found;

  /// No description provided for @club_fail_start.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao iniciar treino'**
  String get club_fail_start;

  /// No description provided for @club_create_workout.
  ///
  /// In pt, this message translates to:
  /// **'Criar treino'**
  String get club_create_workout;

  /// No description provided for @club_from_photo.
  ///
  /// In pt, this message translates to:
  /// **'A partir de foto'**
  String get club_from_photo;

  /// No description provided for @club_trainer_workouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos do personal'**
  String get club_trainer_workouts;

  /// No description provided for @club_programs_soon.
  ///
  /// In pt, this message translates to:
  /// **'Programas em breve'**
  String get club_programs_soon;

  /// No description provided for @club_cardio_saved.
  ///
  /// In pt, this message translates to:
  /// **'Sessão de cardio salva! 🔥'**
  String get club_cardio_saved;

  /// No description provided for @club_camera.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get club_camera;

  /// No description provided for @club_gallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get club_gallery;

  /// No description provided for @club_no_exercise_in_photo.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível identificar exercícios na imagem. Tente outra foto.'**
  String get club_no_exercise_in_photo;

  /// No description provided for @club_analyzing_photo.
  ///
  /// In pt, this message translates to:
  /// **'Analisando ficha…'**
  String get club_analyzing_photo;

  /// No description provided for @club_start_btn.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar'**
  String get club_start_btn;

  /// No description provided for @notifications_title.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notifications_title;

  /// No description provided for @notifications_mark_read.
  ///
  /// In pt, this message translates to:
  /// **'Marcar lidas'**
  String get notifications_mark_read;

  /// No description provided for @notifications_empty.
  ///
  /// In pt, this message translates to:
  /// **'Sem notificações'**
  String get notifications_empty;

  /// No description provided for @notifications_up_to_date.
  ///
  /// In pt, this message translates to:
  /// **'Você está em dia com tudo!'**
  String get notifications_up_to_date;

  /// No description provided for @notifications_now.
  ///
  /// In pt, this message translates to:
  /// **'Agora'**
  String get notifications_now;

  /// No description provided for @notifications_today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get notifications_today;

  /// No description provided for @notifications_yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get notifications_yesterday;

  /// No description provided for @notifications_this_week.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get notifications_this_week;

  /// No description provided for @notifications_older.
  ///
  /// In pt, this message translates to:
  /// **'Mais antigo'**
  String get notifications_older;

  /// No description provided for @notifications_general.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get notifications_general;

  /// No description provided for @notifications_see_duel.
  ///
  /// In pt, this message translates to:
  /// **'Ver duelo'**
  String get notifications_see_duel;

  /// No description provided for @notifications_see_ranking.
  ///
  /// In pt, this message translates to:
  /// **'Ver ranking'**
  String get notifications_see_ranking;

  /// No description provided for @notifications_see_challenge.
  ///
  /// In pt, this message translates to:
  /// **'Ver desafio'**
  String get notifications_see_challenge;

  /// No description provided for @sports_title.
  ///
  /// In pt, this message translates to:
  /// **'Esportes & Performance'**
  String get sports_title;

  /// No description provided for @sports_active_protocols.
  ///
  /// In pt, this message translates to:
  /// **'Protocolos ativos'**
  String get sports_active_protocols;

  /// No description provided for @sports_trackers.
  ///
  /// In pt, this message translates to:
  /// **'Trackers'**
  String get sports_trackers;

  /// No description provided for @sports_round_timer.
  ///
  /// In pt, this message translates to:
  /// **'Round Timer'**
  String get sports_round_timer;

  /// No description provided for @sports_round_timer_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Boxe · MMA · Jiu Jitsu · Muay Thai'**
  String get sports_round_timer_subtitle;

  /// No description provided for @sports_match_tracker.
  ///
  /// In pt, this message translates to:
  /// **'Match Tracker'**
  String get sports_match_tracker;

  /// No description provided for @sports_match_tracker_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Tênis · Padel · Beach Tennis'**
  String get sports_match_tracker_subtitle;

  /// No description provided for @sports_detected.
  ///
  /// In pt, this message translates to:
  /// **'Esportes detectados'**
  String get sports_detected;

  /// No description provided for @sports_other.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get sports_other;

  /// No description provided for @sports_recommended.
  ///
  /// In pt, this message translates to:
  /// **'Recomendado para você'**
  String get sports_recommended;

  /// No description provided for @sports_challenge_havok.
  ///
  /// In pt, this message translates to:
  /// **'Desafie o HAVOK'**
  String get sports_challenge_havok;

  /// No description provided for @sports_generate_workout.
  ///
  /// In pt, this message translates to:
  /// **'Gerar ficha de treino'**
  String get sports_generate_workout;

  /// No description provided for @sports_select_sport.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um esporte ou digite outro'**
  String get sports_select_sport;

  /// No description provided for @sports_other_sport_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ou digite outro esporte…'**
  String get sports_other_sport_hint;

  /// No description provided for @sports_generate_strategy.
  ///
  /// In pt, this message translates to:
  /// **'Gerar estratégia'**
  String get sports_generate_strategy;

  /// No description provided for @sports_havok_processing.
  ///
  /// In pt, this message translates to:
  /// **'HAVOK processando…'**
  String get sports_havok_processing;

  /// No description provided for @sports_creating_strategy.
  ///
  /// In pt, this message translates to:
  /// **'Criando estratégia de performance personalizada.'**
  String get sports_creating_strategy;

  /// No description provided for @sports_weekly.
  ///
  /// In pt, this message translates to:
  /// **'Sua semana'**
  String get sports_weekly;

  /// No description provided for @sports_day_of.
  ///
  /// In pt, this message translates to:
  /// **'Dia {current} de {total}'**
  String sports_day_of(Object current, Object total);

  /// No description provided for @sports_active_time.
  ///
  /// In pt, this message translates to:
  /// **'Tempo ativo: {time}'**
  String sports_active_time(String time);

  /// No description provided for @sports_corridas_sync.
  ///
  /// In pt, this message translates to:
  /// **'Corridas sincronizadas · outros só neste dispositivo'**
  String get sports_corridas_sync;

  /// No description provided for @profile_retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get profile_retry;

  /// No description provided for @profile_duel.
  ///
  /// In pt, this message translates to:
  /// **'Desafiar para duelo'**
  String get profile_duel;

  /// No description provided for @profile_react.
  ///
  /// In pt, this message translates to:
  /// **'👊 Reagir'**
  String get profile_react;

  /// No description provided for @profile_react_sent.
  ///
  /// In pt, this message translates to:
  /// **'👊 Reação enviada!'**
  String get profile_react_sent;

  /// No description provided for @profile_ranking_position.
  ///
  /// In pt, this message translates to:
  /// **'#{pos} Ranking'**
  String profile_ranking_position(Object pos);

  /// No description provided for @profile_workouts_label.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get profile_workouts_label;

  /// No description provided for @profile_streak_label.
  ///
  /// In pt, this message translates to:
  /// **'Streak'**
  String get profile_streak_label;

  /// No description provided for @profile_duels_label.
  ///
  /// In pt, this message translates to:
  /// **'Duelos'**
  String get profile_duels_label;

  /// No description provided for @profile_wins.
  ///
  /// In pt, this message translates to:
  /// **'Vitórias'**
  String get profile_wins;

  /// No description provided for @profile_losses.
  ///
  /// In pt, this message translates to:
  /// **'Derrotas'**
  String get profile_losses;

  /// No description provided for @profile_winrate.
  ///
  /// In pt, this message translates to:
  /// **'Aproveit.'**
  String get profile_winrate;

  /// No description provided for @profile_achievements.
  ///
  /// In pt, this message translates to:
  /// **'CONQUISTAS'**
  String get profile_achievements;

  /// No description provided for @profile_activity.
  ///
  /// In pt, this message translates to:
  /// **'ATIVIDADE RECENTE'**
  String get profile_activity;

  /// No description provided for @profile_athlete_bldr.
  ///
  /// In pt, this message translates to:
  /// **'Atleta BLDR'**
  String get profile_athlete_bldr;

  /// No description provided for @profile_athlete.
  ///
  /// In pt, this message translates to:
  /// **'Atleta'**
  String get profile_athlete;

  /// No description provided for @profile_level.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level}'**
  String profile_level(Object level);

  /// No description provided for @profile_xp_to_next.
  ///
  /// In pt, this message translates to:
  /// **'Nível {next} em {xp} XP'**
  String profile_xp_to_next(Object next, Object xp);

  /// No description provided for @join_squad_title.
  ///
  /// In pt, this message translates to:
  /// **'Entrar em Operação'**
  String get join_squad_title;

  /// No description provided for @join_squad_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cole o código de convite (Ex: K9X-2M1).'**
  String get join_squad_subtitle;

  /// No description provided for @join_squad_code_label.
  ///
  /// In pt, this message translates to:
  /// **'CÓDIGO DE ACESSO'**
  String get join_squad_code_label;

  /// No description provided for @join_squad_btn.
  ///
  /// In pt, this message translates to:
  /// **'JUNTAR-SE AGORA'**
  String get join_squad_btn;

  /// No description provided for @join_squad_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum Squad encontrado com este código.'**
  String get join_squad_not_found;

  /// No description provided for @join_squad_already_member.
  ///
  /// In pt, this message translates to:
  /// **'Você já é membro deste Squad!'**
  String get join_squad_already_member;

  /// No description provided for @join_squad_welcome.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao Squad {name}! 👊'**
  String join_squad_welcome(String name);

  /// No description provided for @squad_settings_saved.
  ///
  /// In pt, this message translates to:
  /// **'Configurações salvas! ✅'**
  String get squad_settings_saved;

  /// No description provided for @squad_settings_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar.'**
  String get squad_settings_error;

  /// No description provided for @squad_now_private.
  ///
  /// In pt, this message translates to:
  /// **'Squad agora é PRIVADO 🔒'**
  String get squad_now_private;

  /// No description provided for @squad_now_public.
  ///
  /// In pt, this message translates to:
  /// **'Squad agora é PÚBLICO 🌍'**
  String get squad_now_public;

  /// No description provided for @squad_edit_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar Operação'**
  String get squad_edit_title;

  /// No description provided for @squad_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Squad'**
  String get squad_name_label;

  /// No description provided for @squad_mission_label.
  ///
  /// In pt, this message translates to:
  /// **'Missão (Descrição)'**
  String get squad_mission_label;

  /// No description provided for @squad_cancel.
  ///
  /// In pt, this message translates to:
  /// **'CANCELAR'**
  String get squad_cancel;

  /// No description provided for @squad_save.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR'**
  String get squad_save;

  /// No description provided for @squad_daily_mission.
  ///
  /// In pt, this message translates to:
  /// **'Missão Diária'**
  String get squad_daily_mission;

  /// No description provided for @squad_daily_challenge.
  ///
  /// In pt, this message translates to:
  /// **'Desafio do Dia'**
  String get squad_daily_challenge;

  /// No description provided for @squad_define.
  ///
  /// In pt, this message translates to:
  /// **'DEFINIR'**
  String get squad_define;

  /// No description provided for @squad_score_limits.
  ///
  /// In pt, this message translates to:
  /// **'Limites de Pontuação'**
  String get squad_score_limits;

  /// No description provided for @squad_score_limits_desc.
  ///
  /// In pt, this message translates to:
  /// **'Limite máximo de XP que um usuário pode ganhar por dia para evitar fraudes.'**
  String get squad_score_limits_desc;

  /// No description provided for @paywall_title.
  ///
  /// In pt, this message translates to:
  /// **'Treine no seu limite, não no dos outros'**
  String get paywall_title;

  /// No description provided for @paywall_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie o BLDR Club: treinos, desafios e comunidade num só lugar.'**
  String get paywall_subtitle;

  /// No description provided for @paywall_trial_badge.
  ///
  /// In pt, this message translates to:
  /// **'{days} DIAS GRÁTIS'**
  String paywall_trial_badge(String days);

  /// No description provided for @paywall_save_percent.
  ///
  /// In pt, this message translates to:
  /// **'ECONOMIZE {percent}%'**
  String paywall_save_percent(String percent);

  /// No description provided for @paywall_plan_weekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get paywall_plan_weekly;

  /// No description provided for @paywall_plan_weekly_badge.
  ///
  /// In pt, this message translates to:
  /// **'MAIS FLEXÍVEL'**
  String get paywall_plan_weekly_badge;

  /// No description provided for @paywall_per_week.
  ///
  /// In pt, this message translates to:
  /// **'/semana'**
  String get paywall_per_week;

  /// No description provided for @paywall_best_value.
  ///
  /// In pt, this message translates to:
  /// **'MELHOR VALOR'**
  String get paywall_best_value;

  /// No description provided for @paywall_plan_monthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get paywall_plan_monthly;

  /// No description provided for @paywall_plan_annual.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get paywall_plan_annual;

  /// No description provided for @paywall_monthly_equiv.
  ///
  /// In pt, this message translates to:
  /// **'equivale a {price}/mês'**
  String paywall_monthly_equiv(String price);

  /// No description provided for @paywall_benefits_title.
  ///
  /// In pt, this message translates to:
  /// **'Incluso em todos os planos'**
  String get paywall_benefits_title;

  /// No description provided for @paywall_subscribe_weekly_btn.
  ///
  /// In pt, this message translates to:
  /// **'Assinar plano semanal'**
  String get paywall_subscribe_weekly_btn;

  /// No description provided for @paywall_subscribe_annual_btn.
  ///
  /// In pt, this message translates to:
  /// **'Assinar plano anual'**
  String get paywall_subscribe_annual_btn;

  /// No description provided for @paywall_start_trial_btn.
  ///
  /// In pt, this message translates to:
  /// **'Começar {days} dias grátis'**
  String paywall_start_trial_btn(String days);

  /// No description provided for @paywall_subscribe_monthly_btn.
  ///
  /// In pt, this message translates to:
  /// **'Assinar plano mensal'**
  String get paywall_subscribe_monthly_btn;

  /// No description provided for @paywall_processing.
  ///
  /// In pt, this message translates to:
  /// **'Processando…'**
  String get paywall_processing;

  /// No description provided for @paywall_redeem.
  ///
  /// In pt, this message translates to:
  /// **'Resgatar código'**
  String get paywall_redeem;

  /// No description provided for @paywall_restore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar compras'**
  String get paywall_restore;

  /// No description provided for @paywall_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os planos agora. Tente novamente em instantes.'**
  String get paywall_load_error;

  /// No description provided for @paywall_billing_title.
  ///
  /// In pt, this message translates to:
  /// **'Dados de cobrança'**
  String get paywall_billing_title;

  /// No description provided for @paywall_billing_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get paywall_billing_name_label;

  /// No description provided for @paywall_billing_email_label.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get paywall_billing_email_label;

  /// No description provided for @checkout_screen_title.
  ///
  /// In pt, this message translates to:
  /// **'Checkout BLDR'**
  String get checkout_screen_title;

  /// No description provided for @checkout_choose_plan_title.
  ///
  /// In pt, this message translates to:
  /// **'Escolha seu Plano'**
  String get checkout_choose_plan_title;

  /// No description provided for @checkout_choose_plan_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o plano que mais se adequa aos seus objetivos'**
  String get checkout_choose_plan_subtitle;

  /// No description provided for @checkout_billing_info_title.
  ///
  /// In pt, this message translates to:
  /// **'Informações de Cobrança'**
  String get checkout_billing_info_title;

  /// No description provided for @checkout_billing_info_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Preencha seus dados para continuar'**
  String get checkout_billing_info_subtitle;

  /// No description provided for @checkout_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get checkout_name_label;

  /// No description provided for @checkout_email_label.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get checkout_email_label;

  /// No description provided for @checkout_continue_payment_btn.
  ///
  /// In pt, this message translates to:
  /// **'Continuar para Pagamento'**
  String get checkout_continue_payment_btn;

  /// No description provided for @checkout_payment_title.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar Pagamento'**
  String get checkout_payment_title;

  /// No description provided for @checkout_payment_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirme os dados e finalize sua assinatura'**
  String get checkout_payment_subtitle;

  /// No description provided for @checkout_order_summary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do Pedido'**
  String get checkout_order_summary;

  /// No description provided for @checkout_billing_annual.
  ///
  /// In pt, this message translates to:
  /// **'Cobrança anual'**
  String get checkout_billing_annual;

  /// No description provided for @checkout_billing_monthly.
  ///
  /// In pt, this message translates to:
  /// **'Cobrança mensal'**
  String get checkout_billing_monthly;

  /// No description provided for @checkout_coupon_title.
  ///
  /// In pt, this message translates to:
  /// **'Cupom de Desconto (Opcional)'**
  String get checkout_coupon_title;

  /// No description provided for @checkout_coupon_label.
  ///
  /// In pt, this message translates to:
  /// **'Código do cupom'**
  String get checkout_coupon_label;

  /// No description provided for @checkout_coupon_apply_btn.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get checkout_coupon_apply_btn;

  /// No description provided for @checkout_coupon_applied.
  ///
  /// In pt, this message translates to:
  /// **'Cupom \"{code}\" aplicado!'**
  String checkout_coupon_applied(String code);

  /// No description provided for @checkout_apple_payment_title.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento via App Store'**
  String get checkout_apple_payment_title;

  /// No description provided for @checkout_apple_payment_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'A cobrança será feita na sua conta Apple.'**
  String get checkout_apple_payment_subtitle;

  /// No description provided for @checkout_subscribe_btn.
  ///
  /// In pt, this message translates to:
  /// **'Assinar'**
  String get checkout_subscribe_btn;

  /// No description provided for @checkout_redeem_btn.
  ///
  /// In pt, this message translates to:
  /// **'Resgatar código de oferta'**
  String get checkout_redeem_btn;

  /// No description provided for @checkout_privacy_policy.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get checkout_privacy_policy;

  /// No description provided for @checkout_terms_of_use.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso (EULA)'**
  String get checkout_terms_of_use;

  /// No description provided for @checkout_success_title.
  ///
  /// In pt, this message translates to:
  /// **'Sucesso!'**
  String get checkout_success_title;

  /// No description provided for @checkout_success_default_message.
  ///
  /// In pt, this message translates to:
  /// **'Sua assinatura foi ativada com sucesso!'**
  String get checkout_success_default_message;

  /// No description provided for @checkout_success_active_message.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura ativada com sucesso!'**
  String get checkout_success_active_message;

  /// No description provided for @checkout_apple_success_message.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura realizada com sucesso!'**
  String get checkout_apple_success_message;

  /// No description provided for @checkout_success_plan.
  ///
  /// In pt, this message translates to:
  /// **'Plano: {name}'**
  String checkout_success_plan(String name);

  /// No description provided for @checkout_field_required.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, preencha o campo {field}'**
  String checkout_field_required(String field);

  /// No description provided for @checkout_email_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira um email válido'**
  String get checkout_email_invalid;

  /// No description provided for @checkout_card_info_title.
  ///
  /// In pt, this message translates to:
  /// **'Informações do Cartão'**
  String get checkout_card_info_title;

  /// No description provided for @checkout_card_data_label.
  ///
  /// In pt, this message translates to:
  /// **'Dados do Cartão'**
  String get checkout_card_data_label;

  /// No description provided for @checkout_card_helper.
  ///
  /// In pt, this message translates to:
  /// **'Digite o número, validade e CVV do seu cartão'**
  String get checkout_card_helper;

  /// No description provided for @checkout_processing.
  ///
  /// In pt, this message translates to:
  /// **'Processando...'**
  String get checkout_processing;

  /// No description provided for @checkout_finalize_btn.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar Pagamento'**
  String get checkout_finalize_btn;

  /// No description provided for @checkout_toggle_save_badge.
  ///
  /// In pt, this message translates to:
  /// **'ECONOMIZE'**
  String get checkout_toggle_save_badge;

  /// No description provided for @checkout_plan_popular_badge.
  ///
  /// In pt, this message translates to:
  /// **'POPULAR'**
  String get checkout_plan_popular_badge;

  /// No description provided for @checkout_trial_badge.
  ///
  /// In pt, this message translates to:
  /// **'🎉 7 DIAS GRÁTIS INCLUÍDOS'**
  String get checkout_trial_badge;

  /// No description provided for @checkout_savings_amount.
  ///
  /// In pt, this message translates to:
  /// **'Economize {amount}'**
  String checkout_savings_amount(String amount);

  /// No description provided for @splash_tagline.
  ///
  /// In pt, this message translates to:
  /// **'CONSTRUA SUA MELHOR VERSÃO'**
  String get splash_tagline;

  /// No description provided for @splash_connection_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Erro de Conexão'**
  String get splash_connection_error_title;

  /// No description provided for @splash_init_error_msg.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao inicializar o app. Tente novamente.'**
  String get splash_init_error_msg;

  /// No description provided for @splash_retry_btn.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get splash_retry_btn;

  /// No description provided for @splash_connection_failed.
  ///
  /// In pt, this message translates to:
  /// **'Falha na Conexão'**
  String get splash_connection_failed;

  /// No description provided for @splash_retry_shortly.
  ///
  /// In pt, this message translates to:
  /// **'A opção de tentar novamente aparecerá em breve'**
  String get splash_retry_shortly;

  /// No description provided for @app_init_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao iniciar o aplicativo. Detalhes: {details}'**
  String app_init_error(String details);

  /// No description provided for @feedback_title.
  ///
  /// In pt, this message translates to:
  /// **'Feedback'**
  String get feedback_title;

  /// No description provided for @feedback_report_bug.
  ///
  /// In pt, this message translates to:
  /// **'Reportar bug'**
  String get feedback_report_bug;

  /// No description provided for @feedback_send_suggestion.
  ///
  /// In pt, this message translates to:
  /// **'Enviar sugestão'**
  String get feedback_send_suggestion;

  /// No description provided for @feedback_chip_bug.
  ///
  /// In pt, this message translates to:
  /// **'Bug'**
  String get feedback_chip_bug;

  /// No description provided for @feedback_chip_suggestion.
  ///
  /// In pt, this message translates to:
  /// **'Sugestão'**
  String get feedback_chip_suggestion;

  /// No description provided for @feedback_chip_complaint.
  ///
  /// In pt, this message translates to:
  /// **'Reclamação'**
  String get feedback_chip_complaint;

  /// No description provided for @feedback_chip_other.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get feedback_chip_other;

  /// No description provided for @feedback_bldr_greeting.
  ///
  /// In pt, this message translates to:
  /// **'Olá! Como posso te ajudar hoje?'**
  String get feedback_bldr_greeting;

  /// No description provided for @feedback_bldr_select_type.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o tipo de feedback para começar.'**
  String get feedback_bldr_select_type;

  /// No description provided for @feedback_bldr_bug_step1.
  ///
  /// In pt, this message translates to:
  /// **'Entendido! Descreva o bug com o máximo de detalhes possível. O que aconteceu?'**
  String get feedback_bldr_bug_step1;

  /// No description provided for @feedback_bldr_bug_step2.
  ///
  /// In pt, this message translates to:
  /// **'Quer incluir uma captura de tela? (opcional)'**
  String get feedback_bldr_bug_step2;

  /// No description provided for @feedback_bldr_suggestion_step1.
  ///
  /// In pt, this message translates to:
  /// **'Ótimo! Qual é a sua sugestão? Descreva o que você gostaria de ver no app.'**
  String get feedback_bldr_suggestion_step1;

  /// No description provided for @feedback_bldr_suggestion_step2.
  ///
  /// In pt, this message translates to:
  /// **'Quer incluir uma imagem para ilustrar? (opcional)'**
  String get feedback_bldr_suggestion_step2;

  /// No description provided for @feedback_bldr_complaint_step1.
  ///
  /// In pt, this message translates to:
  /// **'Lamentamos que você esteja tendo problemas. Descreva o que aconteceu.'**
  String get feedback_bldr_complaint_step1;

  /// No description provided for @feedback_bldr_complaint_step2.
  ///
  /// In pt, this message translates to:
  /// **'Quer incluir uma captura de tela? (opcional)'**
  String get feedback_bldr_complaint_step2;

  /// No description provided for @feedback_bldr_other_step1.
  ///
  /// In pt, this message translates to:
  /// **'Pode falar! O que você gostaria de compartilhar?'**
  String get feedback_bldr_other_step1;

  /// No description provided for @feedback_bldr_other_step2.
  ///
  /// In pt, this message translates to:
  /// **'Quer incluir uma imagem? (opcional)'**
  String get feedback_bldr_other_step2;

  /// No description provided for @feedback_bldr_sending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando seu feedback...'**
  String get feedback_bldr_sending;

  /// No description provided for @feedback_bldr_success.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem enviada!'**
  String get feedback_bldr_success;

  /// No description provided for @feedback_bldr_protocol.
  ///
  /// In pt, this message translates to:
  /// **'Protocolo: #{protocolo}'**
  String feedback_bldr_protocol(String protocolo);

  /// No description provided for @feedback_bldr_thanks.
  ///
  /// In pt, this message translates to:
  /// **'Agradecemos seu feedback. Nossa equipe vai analisá-lo em breve.'**
  String get feedback_bldr_thanks;

  /// No description provided for @feedback_hint_message.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua mensagem...'**
  String get feedback_hint_message;

  /// No description provided for @feedback_add_screenshot.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar imagem'**
  String get feedback_add_screenshot;

  /// No description provided for @feedback_remove_screenshot.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get feedback_remove_screenshot;

  /// No description provided for @feedback_send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get feedback_send;

  /// No description provided for @feedback_skip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get feedback_skip;

  /// No description provided for @feedback_error_retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get feedback_error_retry;

  /// No description provided for @feedback_chars_remaining.
  ///
  /// In pt, this message translates to:
  /// **'{count} / 500'**
  String feedback_chars_remaining(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
