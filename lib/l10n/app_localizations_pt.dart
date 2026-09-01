// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get common_continue_btn => 'Continuar';

  @override
  String get common_finish_btn => 'Concluir';

  @override
  String get common_back_btn => 'Voltar';

  @override
  String get common_next_btn => 'Avançar';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_ok => 'OK';

  @override
  String get common_resend => 'Reenviar';

  @override
  String get common_or => 'ou';

  @override
  String get common_retry => 'Tentar Novamente';

  @override
  String get common_start_btn => 'Começar';

  @override
  String get common_got_it_btn => 'Entendi';

  @override
  String get login_title => 'Bem-Vindo!';

  @override
  String get login_subtitle => 'Faça login para continuar sua jornada fitness';

  @override
  String get login_email_label => 'Email';

  @override
  String get login_email_hint => 'Insira seu endereço de e-mail';

  @override
  String get login_email_required_error => 'E-mail é obrigatório';

  @override
  String get login_email_invalid_error => 'Insira um endereço de e-mail válido';

  @override
  String get login_password_label => 'Senha';

  @override
  String get login_password_hint => 'Insira sua senha';

  @override
  String get login_password_required_error => 'Senha é obrigatória';

  @override
  String get login_remember_me => 'Lembrar-me';

  @override
  String get login_forgot_password => 'Esqueceu a senha?';

  @override
  String get login_btn => 'Entrar';

  @override
  String get login_apple_btn => 'Continuar com a Apple';

  @override
  String get login_google_btn => 'Continuar com o Google';

  @override
  String get login_no_account => 'Não possui uma conta? ';

  @override
  String get login_create_account_link => 'Criar conta';

  @override
  String get login_email_not_confirmed_title => 'E-mail não confirmado';

  @override
  String get login_email_not_confirmed_body =>
      'Você precisa confirmar seu e-mail antes de fazer login. Verifique sua caixa de entrada e clique no link de confirmação.';

  @override
  String get login_email_confirmation_resent =>
      'E-mail de confirmação reenviado';

  @override
  String login_resend_email_error(String message) {
    return 'Erro ao reenviar e-mail: $message';
  }

  @override
  String get login_recover_password_title => 'Recuperar Senha';

  @override
  String get login_recover_password_body =>
      'Insira seu e-mail para receber um código de 6 dígitos.';

  @override
  String get login_enter_email_hint => 'Insira seu e-mail';

  @override
  String get login_enter_email_error => 'Por favor, insira um e-mail.';

  @override
  String get login_send_code_btn => 'Enviar Código';

  @override
  String login_send_code_error(String message) {
    return 'Erro ao enviar código: $message';
  }

  @override
  String login_error(String message) {
    return 'Falha no login: $message';
  }

  @override
  String get signup_title => 'Criar Conta';

  @override
  String get signup_subtitle =>
      'Junte-se à BLDR e comece sua jornada fitness com treinos personalizados e acompanhamento nutricional.';

  @override
  String get signup_form_title => 'Juntar-se ao BLDR';

  @override
  String get signup_form_subtitle => 'Começe sua transformação fitness hoje';

  @override
  String get signup_full_name_label => 'Nome completo';

  @override
  String get signup_full_name_hint => 'Insira seu nome completo';

  @override
  String get signup_full_name_required_error => 'Nome completo é obrigatório';

  @override
  String get signup_full_name_min_length_error =>
      'Nome completo deve ter pelo menos 2 caractéres';

  @override
  String get signup_password_min_length_error =>
      'Senha deverá conter 8 caractéres';

  @override
  String get signup_password_uppercase_error =>
      'Senha deverá conter pelo menos um caractére em maiúsculo';

  @override
  String get signup_password_number_error =>
      'Senha deverá conter pelo menos um número';

  @override
  String get signup_confirm_password_label => 'Confirmar Senha';

  @override
  String get signup_confirm_password_hint => 'Confirme sua senha';

  @override
  String get signup_confirm_password_required_error =>
      'Por favor confirme sua senha';

  @override
  String get signup_passwords_mismatch_error => 'Senhas não coincidem';

  @override
  String get signup_agree_terms_prefix => 'Eu concordo com os ';

  @override
  String get signup_terms_of_service => 'Termos de Serviço';

  @override
  String get signup_privacy_policy => 'Privacidade';

  @override
  String get signup_must_agree_terms_error =>
      'Por favor concorde com os Termos de Serviço';

  @override
  String signup_error(String message) {
    return 'Erro no cadastro: $message';
  }

  @override
  String get signup_create_account_btn => 'Criar Conta';

  @override
  String get signup_already_have_account => 'Já possui uma conta? ';

  @override
  String get signup_confirm_email_title => 'Confirme seu E-mail';

  @override
  String get signup_confirm_email_sent_to =>
      'Enviamos um e-mail de confirmação para:';

  @override
  String get signup_confirm_email_instruction =>
      'Clique no link do e-mail para confirmar sua conta e continuar.';

  @override
  String get signup_resend_email_btn => 'Reenviar E-mail';

  @override
  String get signup_back_to_login_btn => 'Voltar ao Login';

  @override
  String get wait_confirm_email_body =>
      'Enviamos um link de confirmação para o seu endereço de e-mail. Por favor, clique no link para ativar sua conta.';

  @override
  String get wait_confirm_no_email_error =>
      'Não foi possível encontrar o e-mail do usuário.';

  @override
  String get wait_confirm_email_resent_success =>
      'E-mail de confirmação reenviado com sucesso!';

  @override
  String get wait_confirm_back_to_login_btn => 'Voltar para o Login';

  @override
  String get otp_title => 'Verificar Código';

  @override
  String get otp_heading => 'Digite o Código';

  @override
  String get otp_body => 'Enviamos um código de 6 dígitos para o seu e-mail:';

  @override
  String get otp_validator_error => 'Digite o código de 6 dígitos';

  @override
  String get otp_verify_btn => 'Verificar e Continuar';

  @override
  String get otp_invalid_code_error =>
      'Código inválido ou expirado. Tente novamente.';

  @override
  String get new_password_title => 'Criar Nova Senha';

  @override
  String get new_password_heading => 'Defina sua Nova Senha';

  @override
  String get new_password_body =>
      'Por favor, insira uma nova senha forte para sua conta.';

  @override
  String get new_password_field_label => 'Nova Senha';

  @override
  String get new_password_field_hint => 'Insira sua nova senha';

  @override
  String get new_password_min_length_error =>
      'Senha deverá conter pelo menos 8 caracteres';

  @override
  String get new_password_confirm_label => 'Confirmar Nova Senha';

  @override
  String get new_password_confirm_hint => 'Confirme sua nova senha';

  @override
  String get new_password_passwords_mismatch_error => 'As senhas não coincidem';

  @override
  String get new_password_save_btn => 'Salvar Nova Senha';

  @override
  String get new_password_success => 'Senha atualizada com sucesso!';

  @override
  String new_password_error(String message) {
    return 'Erro ao atualizar senha: $message';
  }

  @override
  String get new_password_confirm_required_error =>
      'Por favor, confirme sua senha';

  @override
  String onboarding_step_indicator(int step, int total) {
    return 'Passo $step de $total';
  }

  @override
  String get onboarding_exit_dialog_title => 'Sair da Configuração?';

  @override
  String get onboarding_exit_dialog_body => 'Seu progresso será perdido.';

  @override
  String get onboarding_exit_dialog_exit_btn => 'Sair';

  @override
  String onboarding_completion_error(String error) {
    return 'Falha ao concluir configuração: $error';
  }

  @override
  String get onboarding_welcome_title => 'Bem-vindo ao BLDR.';

  @override
  String get onboarding_welcome_body =>
      'Vamos configurar seu plano 100% personalizado com a IA HAVOK.';

  @override
  String get onboarding_welcome_bullet_nutrition =>
      'Plano de nutrição personalizado';

  @override
  String get onboarding_welcome_bullet_workout => 'Treino gerado pelo HAVOK';

  @override
  String get onboarding_welcome_bullet_adjustments =>
      'Ajustes contínuos conforme sua evolução';

  @override
  String get onboarding_welcome_duration_hint =>
      'Isso levará apenas alguns minutos.';

  @override
  String get onboarding_goal_title => 'Qual é a sua meta principal?';

  @override
  String get onboarding_goal_body =>
      'Isso definirá a direção do seu plano de nutrição.';

  @override
  String get onboarding_pace_title => 'Em qual ritmo você prefere ir?';

  @override
  String get onboarding_pace_body =>
      'Ritmo agressivo traz resultados mais rápidos, mas exige mais disciplina.';

  @override
  String get onboarding_profile_title => 'Sobre você';

  @override
  String get onboarding_profile_body =>
      'Essencial para calcular suas metas de nutrição.';

  @override
  String get onboarding_profile_age => 'Idade';

  @override
  String get onboarding_profile_height => 'Altura';

  @override
  String get onboarding_profile_weight => 'Peso';

  @override
  String get onboarding_activity_title => 'Como é o seu dia-a-dia?';

  @override
  String get onboarding_activity_body =>
      'Excluindo treinos e esportes — define seu NEAT.';

  @override
  String get onboarding_workout_config_title => 'Configurando seu treino';

  @override
  String get onboarding_workout_config_body =>
      'Essas informações guiam a IA HAVOK na criação do seu plano.';

  @override
  String get onboarding_experience_section_title => 'Nível de experiência';

  @override
  String get onboarding_freq_days_label => 'Dias por semana';

  @override
  String get onboarding_duration_section_title => 'Tempo médio por sessão';

  @override
  String get onboarding_environment_title => 'Onde você vai treinar?';

  @override
  String get onboarding_environment_body =>
      'Isso dirá ao HAVOK quais exercícios incluir.';

  @override
  String get onboarding_equipment_title => 'Quais equipamentos você tem?';

  @override
  String get onboarding_equipment_body => 'Selecione todos que se aplicam.';

  @override
  String get onboarding_activities_title => 'Atividades e foco muscular';

  @override
  String get onboarding_activities_body =>
      'Quais atividades você pratica e onde quer focar.';

  @override
  String get onboarding_activities_section_title => 'Atividades físicas';

  @override
  String get onboarding_muscles_section_title => 'Grupos musculares';

  @override
  String get onboarding_muscles_body =>
      'Selecione os músculos que quer priorizar.';

  @override
  String get onboarding_split_injuries_title => 'Divisão e lesões';

  @override
  String get onboarding_split_injuries_body =>
      'Últimas informações para o HAVOK montar seu treino.';

  @override
  String get onboarding_split_section_title => 'Divisão de treino';

  @override
  String get onboarding_split_body => 'Se não souber, deixe o HAVOK decidir.';

  @override
  String get onboarding_injuries_section_title => 'Lesões ou limitações';

  @override
  String get onboarding_injuries_body =>
      'O HAVOK evitará exercícios que prejudiquem sua recuperação.';

  @override
  String get onboarding_injury_other_hint => 'Descreva sua lesão...';

  @override
  String get onboarding_summary_title => 'Tudo pronto!';

  @override
  String get onboarding_summary_body =>
      'Seu plano personalizado foi calculado.';

  @override
  String get onboarding_summary_nutrition_section => 'Nutrição';

  @override
  String onboarding_summary_tdee(String tdee) {
    return 'TDEE: $tdee kcal/dia';
  }

  @override
  String get onboarding_calorie_goal_label => 'Meta calórica';

  @override
  String get onboarding_protein_label => 'Proteína';

  @override
  String get onboarding_summary_carbs_label => 'Carboidrato';

  @override
  String get onboarding_summary_fat_label => 'Gordura';

  @override
  String get onboarding_summary_hydration_label => 'Hidratação';

  @override
  String get onboarding_summary_workout_section => 'Treino';

  @override
  String get onboarding_summary_goal_label => 'Meta';

  @override
  String get onboarding_summary_level_label => 'Nível';

  @override
  String get onboarding_summary_frequency_label => 'Frequência';

  @override
  String get onboarding_summary_duration_label => 'Duração';

  @override
  String get onboarding_summary_environment_label => 'Ambiente';

  @override
  String get onboarding_summary_split_label => 'Split';

  @override
  String get onboarding_summary_focus_label => 'Foco';

  @override
  String get onboarding_summary_confirm_hint =>
      'Ao confirmar, o HAVOK gerará seu plano de treino personalizado.';

  @override
  String get onboarding_tdee_info_title => 'O que é TDEE?';

  @override
  String get onboarding_tdee_info_body =>
      'TDEE (Total Daily Energy Expenditure) é a quantidade de calorias que seu corpo gasta por dia. Usamos isso como base para calcular suas metas.';

  @override
  String get onboarding_completion_generating_title => 'Montando sua semana';

  @override
  String get onboarding_completion_generating_body =>
      'Estou usando o que você me contou para desenhar seu primeiro plano.';

  @override
  String get onboarding_completion_ready_title => 'Sua semana está pronta';

  @override
  String get onboarding_completion_plan_fallback_desc =>
      'Plano personalizado pelo HAVOK';

  @override
  String get onboarding_completion_starts_today_label => 'Começa hoje';

  @override
  String get onboarding_rest_day => 'Descanso';

  @override
  String get onboarding_completion_adjust_hint =>
      'Pode ajustar tudo depois em Treinos e Configurações.';

  @override
  String get onboarding_completion_regenerate_btn => 'Quero outra divisão';

  @override
  String get onboarding_completion_fallback_title =>
      'Não consegui gerar agora.';

  @override
  String get onboarding_completion_fallback_body_with_plan =>
      'Criei um plano base para você começar — ajuste quando quiser.';

  @override
  String get onboarding_completion_fallback_body_no_plan =>
      'Tente novamente em instantes — você pode montar seu treino manualmente em Treinos.';

  @override
  String get onboarding_completion_today_workout_label => 'Treino de hoje';

  @override
  String get onboarding_summary_review_title => 'Revise suas Escolhas';

  @override
  String get onboarding_summary_perfect_body =>
      'Perfeito! Usaremos essas informações para criar a sua experiência fitness personalizada!';

  @override
  String get onboarding_summary_edit_btn => 'Editar';

  @override
  String get common_loading => 'Carregando…';

  @override
  String get dashboard_greeting_morning => 'Bom Dia';

  @override
  String get dashboard_greeting_afternoon => 'Boa Tarde';

  @override
  String get dashboard_greeting_evening => 'Boa Noite';

  @override
  String get dashboard_guest_user => 'Convidado';

  @override
  String get dashboard_streak_label => 'Streak';

  @override
  String get dashboard_workouts_month_label => 'Treinos/mês';

  @override
  String get dashboard_total_time_label => 'Tempo total';

  @override
  String get dashboard_achievements_label => 'Conquistas';

  @override
  String dashboard_streak_value(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '$count dia',
    );
    return '$_temp0';
  }

  @override
  String get dashboard_continue_workout_label => 'Continuar';

  @override
  String get dashboard_delete_paused_title => 'Excluir treino pausado?';

  @override
  String get dashboard_delete_paused_body =>
      'Deseja excluir este treino pausado? O progresso não será recuperado.';

  @override
  String get dashboard_delete_btn => 'Excluir';

  @override
  String get dashboard_workout_today_title => 'Treino de hoje';

  @override
  String get dashboard_workout_load_error_title =>
      'Não foi possível carregar os treinos';

  @override
  String get dashboard_workout_load_error_body =>
      'Verifique sua conexão e tente novamente';

  @override
  String get dashboard_welcome_title => 'Bem vindo ao BLDR';

  @override
  String get dashboard_welcome_subtitle => 'Entre para acompanhar seus treinos';

  @override
  String get dashboard_login_btn => 'Entrar';

  @override
  String get dashboard_workout_in_progress => 'Treino em andamento';

  @override
  String get dashboard_finish_workout_btn => 'Finalizar treino';

  @override
  String get dashboard_workout_ready => 'Pronto para treinar?';

  @override
  String get dashboard_workout_havok_generated =>
      'Gerado pelo HAVOK no seu onboarding';

  @override
  String get dashboard_workout_next_session => 'Começar próxima sessão';

  @override
  String get dashboard_workout_start_btn => 'Iniciar treino';

  @override
  String get dashboard_finish_workout_dialog_title => 'Finalizar Treino';

  @override
  String get dashboard_finish_workout_dialog_body =>
      'Você tem certeza que quer completar seu treino atual?';

  @override
  String get dashboard_complete_workout_btn => 'Completar';

  @override
  String get dashboard_workout_completed_success =>
      'Treino finalizado com sucesso!';

  @override
  String get dashboard_workout_done_label => 'Concluído';

  @override
  String get dashboard_done_duration_label => 'Duração';

  @override
  String get dashboard_done_sets_label => 'Séries';

  @override
  String get dashboard_done_volume_label => 'Volume';

  @override
  String dashboard_finish_workout_error(String error) {
    return 'Falha ao finalizar treino: $error';
  }

  @override
  String get dashboard_no_workouts_available =>
      'Nenhum treino disponível no momento';

  @override
  String get dashboard_weight_goal_label => 'Peso alvo';

  @override
  String dashboard_goal_target(String value, String unit) {
    return 'meta $value $unit';
  }

  @override
  String get dashboard_goal_empty_title => 'Defina seu objetivo';

  @override
  String get dashboard_goal_empty_subtitle => 'Crie uma meta na aba Progresso';

  @override
  String get dashboard_calories_label => 'Calorias';

  @override
  String dashboard_calories_of_target(int target) {
    return 'de $target kcal';
  }

  @override
  String get dashboard_macros_label => 'Macros';

  @override
  String get dashboard_macro_protein_abbrev => 'P';

  @override
  String get dashboard_macro_carbs_abbrev => 'C';

  @override
  String get dashboard_macro_fat_abbrev => 'G';

  @override
  String get dashboard_seven_days => '7 dias';

  @override
  String dashboard_workouts_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count treinos',
      one: '$count treino',
    );
    return '$_temp0';
  }

  @override
  String get dashboard_havok_insight_title => 'Sua semana em um relance';

  @override
  String get dashboard_havok_insight_body =>
      'Em breve o HAVOK vai comentar sua aderência ao plano, proteína e streak diretamente aqui.';

  @override
  String get dashboard_havok_insight_action_btn => 'Ver progresso';

  @override
  String dashboard_level_label(String level) {
    return 'Nível $level';
  }

  @override
  String get dashboard_partners_title => 'Parceiros';

  @override
  String get dashboard_partner_view_offer_btn => 'Ver oferta';

  @override
  String get dashboard_partner_copy_coupon_btn => 'Copiar cupom';

  @override
  String get dashboard_partners_view_all_btn => 'Ver todos';

  @override
  String dashboard_partner_coupon_copied(String coupon) {
    return 'Cupom \"$coupon\" copiado!';
  }

  @override
  String get dashboard_quick_log_title => 'Registro Rápido';

  @override
  String get dashboard_quick_log_meal => 'Registrar Refeição';

  @override
  String get dashboard_quick_log_workout => 'Registrar Exercício';

  @override
  String get dashboard_quick_log_weight => 'Registrar Peso';

  @override
  String get dashboard_quick_log_water => 'Registrar Água';

  @override
  String get whoop_card_connect_subtitle =>
      'Conecte seu Whoop para ver Sleep, Recovery e Strain.';

  @override
  String get whoop_card_connect_btn => 'Conectar';

  @override
  String get whoop_card_today => 'Hoje';

  @override
  String get whoop_card_sleep_label => 'SLEEP';

  @override
  String get whoop_card_recovery_label => 'RECOVERY';

  @override
  String get whoop_card_strain_label => 'STRAIN';

  @override
  String get whoop_card_recovery_tip_low =>
      'Recovery baixo — priorize descanso hoje.';

  @override
  String get whoop_card_recovery_tip_med =>
      'Recovery moderado — treino leve ou técnico.';

  @override
  String get whoop_card_recovery_tip_high =>
      'Recovery alto — dia ideal para esforço intenso.';

  @override
  String get nav_tab_dashboard => 'Dashboard';

  @override
  String get nav_tab_workouts => 'Treinos';

  @override
  String get nav_tab_community => 'Comunidade';

  @override
  String get nav_tab_nutrition => 'Nutrição';

  @override
  String get nav_tab_profile => 'Perfil';

  @override
  String get nav_club_label => 'BLDR Club';

  @override
  String get component_workout_start_btn => 'Iniciar';

  @override
  String component_series_label(int index) {
    return 'Série $index';
  }

  @override
  String get component_current_badge => 'Atual';

  @override
  String component_kcal_label(int calories) {
    return '$calories kcal';
  }

  @override
  String component_macro_detail(
      String protein, String carbs, String fat, String portion) {
    return 'P ${protein}g · C ${carbs}g · G ${fat}g · $portion';
  }

  @override
  String get common_delete => 'Excluir';

  @override
  String get workouts_title => 'Treinos';

  @override
  String get workouts_search_hint => 'Buscar treino…';

  @override
  String get workouts_today_hero_label => 'Treino de hoje';

  @override
  String workouts_today_with_label(String label) {
    return 'Hoje · $label';
  }

  @override
  String get workouts_today_hero_subtitle =>
      'Toque para ver o plano completo da semana';

  @override
  String get workouts_continue_title => 'Continuar';

  @override
  String get workouts_active_banner_text => 'Treino em andamento — continuar';

  @override
  String get workouts_my_workouts => 'Meus treinos';

  @override
  String get workouts_created_by_me => 'Criados por mim';

  @override
  String get workouts_from_my_trainer => 'Do meu personal';

  @override
  String get workouts_empty_state => 'Nenhum treino criado ainda';

  @override
  String get workouts_empty_subtitle =>
      'Crie seu primeiro treino personalizado';

  @override
  String get workouts_create_btn => 'Criar treino';

  @override
  String get workouts_from_photo_btn => 'A partir de foto';

  @override
  String get workouts_photo_camera => 'Câmera';

  @override
  String get workouts_photo_gallery => 'Galeria';

  @override
  String get workouts_photo_no_exercises =>
      'Não foi possível identificar exercícios na imagem. Tente outra foto.';

  @override
  String workouts_photo_error(String error) {
    return 'Erro ao analisar foto: $error';
  }

  @override
  String get workouts_trainer_empty_state =>
      'Treinos do personal — em desenvolvimento';

  @override
  String get workouts_trainer_empty_subtitle =>
      'Em breve você poderá receber treinos direcionados pelo seu personal trainer.';

  @override
  String get workouts_bldr_library => 'Biblioteca BLDR';

  @override
  String get workouts_see_less => 'Ver menos';

  @override
  String get workouts_see_all => 'Ver tudo';

  @override
  String get workouts_bldr_empty => 'Nenhum treino BLDR disponível';

  @override
  String get workouts_start_workout_btn => 'Iniciar treino';

  @override
  String get workouts_exercises_header => 'Exercícios';

  @override
  String workouts_exercises_count(int exercises, int sets) {
    return '$exercises · $sets séries';
  }

  @override
  String workouts_sets(int count) {
    return '$count séries';
  }

  @override
  String workouts_reps(int count) {
    return '$count reps';
  }

  @override
  String get workouts_no_exercises => 'Nenhum exercício';

  @override
  String get workouts_technique_unavailable =>
      'Técnica não disponível para este exercício.';

  @override
  String get workouts_delete_title => 'Excluir treino';

  @override
  String workouts_delete_body(String name) {
    return 'Tem certeza que deseja excluir \"$name\"?\nEsta ação não pode ser desfeita.';
  }

  @override
  String workouts_deleted_snackbar(String name) {
    return '\"$name\" excluído';
  }

  @override
  String workouts_delete_error(String error) {
    return 'Erro ao excluir: $error';
  }

  @override
  String get workouts_start_error => 'Falha ao iniciar treino';

  @override
  String workouts_difficulty_label(int level) {
    return 'Nível $level';
  }

  @override
  String get plan_current_week => 'Semana atual';

  @override
  String get plan_see_plan => 'Ver plano →';

  @override
  String get plan_workout_done => 'Treino realizado';

  @override
  String get plan_workout_not_done => 'Treino não feito';

  @override
  String get plan_no_record => 'Sem registro para este dia.';

  @override
  String get plan_view_week_btn => 'Ver plano da semana';

  @override
  String get plan_title => 'Meu plano';

  @override
  String get plan_change_btn => 'Alterar';

  @override
  String plan_of_total_workouts(int total) {
    return 'de $total treinos';
  }

  @override
  String plan_workouts_count(int count) {
    return '$count treinos';
  }

  @override
  String plan_remaining(int count) {
    return '$count restantes nesta semana';
  }

  @override
  String get plan_streak_singular => 'dia seguido';

  @override
  String get plan_streak_plural => 'dias seguidos';

  @override
  String get plan_xp_week => 'XP esta semana';

  @override
  String plan_xp_earned(int xp) {
    return '+$xp XP';
  }

  @override
  String get plan_edit_sheet_title => 'Editar plano semanal';

  @override
  String get plan_split_section => 'Divisão de treinos';

  @override
  String get plan_days_section => 'Dias da semana';

  @override
  String plan_training_rest_summary(int training, int rest) {
    return '$training treino · $rest descanso';
  }

  @override
  String get plan_days_toggle_hint =>
      'Toque em um dia para alternar entre treino e descanso';

  @override
  String get plan_save_btn => 'Salvar alterações';

  @override
  String get plan_save_success => 'Plano atualizado com sucesso!';

  @override
  String plan_save_error(String error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get plan_pro_title => 'Desbloqueie o plano premium';

  @override
  String get plan_pro_subtitle => 'Personalize cada dia da sua semana';

  @override
  String get plan_see_plans_btn => 'Ver planos';

  @override
  String get plan_pro_feature_1 => 'Escolher treino específico por dia';

  @override
  String get plan_pro_feature_2 => 'Alterar o plano livremente';

  @override
  String get plan_pro_feature_3 => 'Usar treinos personalizados no plano';

  @override
  String get plan_pro_feature_4 => 'Sincronização com Apple Watch';

  @override
  String get plan_pro_feature_5 => 'Analytics avançados de progresso';

  @override
  String get plan_do_now_btn => 'Fazer agora';

  @override
  String get plan_today_sheet_title => 'Treino de hoje';

  @override
  String get plan_next_workout => 'Ver treino';

  @override
  String get plan_rest_day => 'Descanso';

  @override
  String get plan_not_done => 'Não feito';

  @override
  String get plan_extra_badge => 'Extra';

  @override
  String get plan_extras_label => 'Extras';

  @override
  String get plan_delete_record_btn => 'Excluir registro';

  @override
  String get plan_delete_record_title => 'Excluir registro?';

  @override
  String get plan_delete_record_body =>
      'Deseja excluir este registro de treino? Esta ação não pode ser desfeita.';

  @override
  String get plan_delete_record_error => 'Erro ao excluir registro.';

  @override
  String get plan_edit_btn => 'Editar plano';

  @override
  String get plan_register_extra_btn => 'Registrar extra';

  @override
  String get plan_extra_sheet_title => 'Registrar atividade extra';

  @override
  String get plan_extra_sheet_subtitle => 'Atividade fora do plano · +50 XP';

  @override
  String get plan_extra_type_label => 'Tipo de atividade';

  @override
  String get plan_extra_duration_label => 'Duração';

  @override
  String get plan_extra_notes_label => 'Notas (opcional)';

  @override
  String get plan_extra_notes_hint => 'Ex: partida de futebol com amigos';

  @override
  String get plan_extra_register_btn => 'Registrar + 50 XP';

  @override
  String plan_extra_register_error(String error) {
    return 'Erro ao registrar: $error';
  }

  @override
  String get plan_extra_register_success => 'Atividade registrada! +50 XP';

  @override
  String get plan_paywall_muscle_message =>
      'Desbloqueie a análise muscular completa — BLDR CLUB';

  @override
  String get plan_paywall_muscle_btn => 'Conhecer o BLDR Club';

  @override
  String get workout_stop_title => 'Concluir treino agora?';

  @override
  String get workout_stop_body =>
      'A sessão será concluída com o progresso registrado até aqui.';

  @override
  String get workout_stop_btn => 'Concluir agora';

  @override
  String get workout_stop_label => 'Concluir treino';

  @override
  String get workout_in_progress => 'EM ANDAMENTO';

  @override
  String get workout_time_label => 'TEMPO';

  @override
  String get workout_set_label => 'SÉRIE';

  @override
  String workout_exercise_of(int current, int total) {
    return 'Exercício $current de $total';
  }

  @override
  String workout_percent_done(int percent) {
    return '$percent% concluído';
  }

  @override
  String get workout_see_technique => 'Ver técnica';

  @override
  String get workout_paywall_muscle_message =>
      'Veja quais músculos secundários você está ativando — BLDR Club';

  @override
  String get workout_technique_fallback => 'Técnica';

  @override
  String get workout_execution_label => 'Execução';

  @override
  String get workout_no_instructions => 'Sem instruções disponíveis.';

  @override
  String get workout_load_kg => 'Carga (kg)';

  @override
  String get workout_decrease_load => 'Diminuir carga';

  @override
  String get workout_increase_load => 'Aumentar carga';

  @override
  String get workout_reps_label => 'Repetições';

  @override
  String get workout_decrease_reps => 'Diminuir repetições';

  @override
  String get workout_increase_reps => 'Aumentar repetições';

  @override
  String get workout_resting => 'DESCANSANDO';

  @override
  String workout_next_set(int set, int total) {
    return 'Próxima: série $set de $total';
  }

  @override
  String get workout_add_rest_label => 'Adicionar 15 segundos ao descanso';

  @override
  String get workout_skip_rest => 'Pular descanso';

  @override
  String get workout_exercises_label => 'Exercícios';

  @override
  String get workout_set_current => 'Atual';

  @override
  String get workout_next_up => 'A seguir';

  @override
  String get workout_skip_exercise => 'Pular exercício';

  @override
  String get workout_confirm_set_btn => 'Confirmar série';

  @override
  String get workout_rest_edit_label => 'Editar tempo de descanso';

  @override
  String get workout_rest_sheet_title => 'Tempo de descanso';

  @override
  String get workout_confirm_btn => 'Confirmar';

  @override
  String get workout_finished_title => 'Treino Concluído!';

  @override
  String get workout_stat_time => 'Tempo';

  @override
  String get workout_stat_sets => 'Séries';

  @override
  String get workout_finish_btn => 'Finalizar';

  @override
  String get common_today => 'Hoje';

  @override
  String get common_required_field => 'Campo obrigatório';

  @override
  String get common_invalid_value => 'Valor inválido';

  @override
  String get common_unauthenticated => 'Usuário não autenticado.';

  @override
  String get nutrition_food_removed => 'Comida removida com sucesso!';

  @override
  String get nutrition_remove_error => 'Falha ao remover item.';

  @override
  String get nutrition_daily_summary => 'Resumo diário';

  @override
  String get nutrition_protein => 'Proteína';

  @override
  String get nutrition_carbs => 'Carboidrato';

  @override
  String get nutrition_fat => 'Gordura';

  @override
  String get nutrition_remaining_today => 'Restantes hoje';

  @override
  String get nutrition_goal_exceeded => 'Meta ultrapassada';

  @override
  String get nutrition_iqd_gauge_label => 'IQD · /100';

  @override
  String get nutrition_fiber => 'Fibra';

  @override
  String get nutrition_sodium => 'Sódio';

  @override
  String get nutrition_sugars => 'Açúcares';

  @override
  String get nutrition_iqd_premium_msg =>
      'Análise de qualidade (IQD)\\ndisponível no Premium';

  @override
  String get nutrition_iqd_premium_btn => 'Seja Premium';

  @override
  String get nutrition_meals_section => 'Refeições';

  @override
  String get nutrition_photo_meal_btn => 'Foto do prato';

  @override
  String get nutrition_search_btn => 'Buscar alimento';

  @override
  String get nutrition_no_food => 'Nenhum alimento';

  @override
  String get nutrition_add_btn => 'Adicionar';

  @override
  String get nutrition_unnamed_food => 'Alimento sem nome';

  @override
  String get nutrition_item_id_missing =>
      'ID do item de comida não encontrado.';

  @override
  String get nutrition_item_action_question =>
      'O que você deseja fazer com este item?';

  @override
  String get nutrition_edit_quantity => 'Editar quantidade';

  @override
  String get nutrition_remove_item => 'Remover item';

  @override
  String get nutrition_breakfast => 'Café da manhã';

  @override
  String get nutrition_snack => 'Lanche';

  @override
  String get nutrition_lunch => 'Almoço';

  @override
  String get nutrition_pre_workout => 'Pré-treino';

  @override
  String get nutrition_post_workout => 'Pós-treino';

  @override
  String get nutrition_dinner => 'Jantar';

  @override
  String nutrition_add_to_meal(String mealType) {
    return 'Adicionar em: $mealType';
  }

  @override
  String get nutrition_search_db_hint => 'Buscar comida na base...';

  @override
  String get nutrition_photo_auto_label =>
      'Foto do prato — identificação automática';

  @override
  String get nutrition_coming_soon => 'Em breve';

  @override
  String get nutrition_select_category =>
      'Selecione uma categoria ou pesquise acima.';

  @override
  String get nutrition_cat_meat => 'Carnes & Aves';

  @override
  String get nutrition_cat_fish => 'Peixes & Frutos do Mar';

  @override
  String get nutrition_cat_eggs => 'Ovos';

  @override
  String get nutrition_cat_dairy => 'Laticínios';

  @override
  String get nutrition_cat_fruits => 'Frutas';

  @override
  String get nutrition_cat_vegetables => 'Legumes & Verduras';

  @override
  String get nutrition_cat_grains => 'Grãos & Cereais';

  @override
  String get nutrition_cat_fats => 'Gorduras & Óleos';

  @override
  String get nutrition_cat_nuts => 'Oleaginosas';

  @override
  String get nutrition_cat_sweets => 'Doces & Sobremesas';

  @override
  String get nutrition_cat_drinks => 'Bebidas';

  @override
  String get nutrition_cat_fastfood => 'Fast Food';

  @override
  String get nutrition_cat_processed => 'Industrializados';

  @override
  String get nutrition_cat_readymeals => 'Refeições Prontas';

  @override
  String get nutrition_cat_sauces => 'Molhos & Temperos';

  @override
  String get nutrition_cat_supplements => 'Suplementos';

  @override
  String get hydration_title => 'Hidratação';

  @override
  String get hydration_loading => 'Carregando...';

  @override
  String get hydration_consumed => 'Água consumida';

  @override
  String hydration_remaining(String value) {
    return '${value}L restantes';
  }

  @override
  String get hydration_total_today => 'Total hoje';

  @override
  String get hydration_entries => 'Entradas';

  @override
  String get hydration_goal_percent => '% da meta';

  @override
  String get hydration_custom_amount => 'Quantidade personalizada';

  @override
  String get hydration_remove_last => 'Remover última entrada';

  @override
  String get hydration_log_error => 'Falha ao registrar água';

  @override
  String get hydration_add_btn => 'Adicionar';

  @override
  String get hydration_no_data => 'Você ainda não registrou água hoje.';

  @override
  String get hydration_remove_title => 'Remover água';

  @override
  String get hydration_too_small =>
      'Quantidade muito pequena para remover por aqui.';

  @override
  String hydration_removed(int amount) {
    return 'Removido: ${amount}ml';
  }

  @override
  String get hydration_remove_error => 'Falha ao remover água';

  @override
  String get nutrition_search_error => 'Erro na busca.';

  @override
  String get nutrition_search_type_prompt => 'Digite para buscar alimentos.';

  @override
  String get nutrition_no_results => 'Nenhum resultado encontrado.';

  @override
  String get nutrition_img_not_implemented =>
      'Reconhecimento por imagem ainda não implementado';

  @override
  String get nutrition_search_food_title => 'Buscar Alimento';

  @override
  String get nutrition_search_hint => 'Buscar alimentos...';

  @override
  String get nutrition_popular_foods => 'Alimentos Populares';

  @override
  String nutrition_search_results_count(int count) {
    return 'Resultados da Busca ($count)';
  }

  @override
  String get nutrition_scan_title => 'Escanear Código';

  @override
  String get nutrition_scan_hint => 'Aponte a câmera para o código de barras';

  @override
  String get nutrition_scan_auto => 'O código será detectado automaticamente';

  @override
  String get nutrition_scan_flash => 'Flash';

  @override
  String get nutrition_scan_camera_label => 'Câmera';

  @override
  String get nutrition_tab_recent => 'Recentes';

  @override
  String get nutrition_tab_favorites => 'Favoritos';

  @override
  String get nutrition_tab_manual => 'Manual';

  @override
  String get nutrition_category_empty =>
      'Nenhum alimento encontrado para esta categoria.';

  @override
  String get nutrition_recent_empty => 'Nenhum alimento recente.';

  @override
  String get nutrition_favorites_empty => 'Nenhum favorito salvo ainda.';

  @override
  String get nutrition_favorites_hint =>
      'Use \"Manual\" e marque \"Salvar nos favoritos\".';

  @override
  String get nutrition_iqd_impact_label => 'Impacto no IQD';

  @override
  String get nutrition_saving => 'Salvando...';

  @override
  String nutrition_add_meal_btn(String mealType) {
    return 'Adicionar $mealType';
  }

  @override
  String get nutrition_food_name_label => 'Nome da comida';

  @override
  String get nutrition_essential_label => 'Essencial';

  @override
  String get nutrition_calories => 'Calorias';

  @override
  String get nutrition_carbs_short => 'Carbo';

  @override
  String get nutrition_iqd_quality_data => 'Dados de qualidade (IQD)';

  @override
  String get nutrition_fibers => 'Fibras';

  @override
  String get nutrition_save_favorites => 'Salvar nos favoritos';

  @override
  String get nutrition_set_portion => 'Definir porção';

  @override
  String get nutrition_grams => 'Gramas';

  @override
  String get nutrition_food_label => 'Alimento';

  @override
  String get nutrition_unit => 'Unidade';

  @override
  String get nutrition_unit_weight_label => 'Peso de 1 unidade:';

  @override
  String get nutrition_unit_short => 'Unid.';

  @override
  String get nutrition_quantity_label => 'Quantidade:';

  @override
  String get nutrition_update_quantity => 'Atualizar quantidade';

  @override
  String get nutrition_add_food_btn => 'Adicionar comida';

  @override
  String get nutrition_favorites_load_error =>
      'Não foi possível carregar os favoritos.';

  @override
  String get nutrition_fill_one_macro =>
      'Preencha pelo menos um valor nutricional.';

  @override
  String get nutrition_create_error => 'Falha ao criar item.';

  @override
  String nutrition_save_error(String error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get nutrition_item_updated => 'Item atualizado com sucesso!';

  @override
  String get nutrition_food_added => 'Comida adicionada com sucesso!';

  @override
  String nutrition_fail(String error) {
    return 'Falha: $error';
  }

  @override
  String get nutrition_scan_hint_qr =>
      'Aponte para o código de barras/QR do alimento';

  @override
  String get progress_title => 'Progresso';

  @override
  String get progress_load_error => 'Falha ao carregar dados do progresso';

  @override
  String get progress_period_7d => 'Últimos 7 dias';

  @override
  String get progress_period_30d => 'Últimos 30 dias';

  @override
  String get progress_period_3m => 'Últimos 3 meses';

  @override
  String get progress_period_1y => 'Último ano';

  @override
  String get progress_tab_general => 'Geral';

  @override
  String get progress_tab_body => 'Corpo';

  @override
  String get progress_tab_workouts => 'Treinos';

  @override
  String get progress_tab_nutrition => 'Nutri';

  @override
  String get progress_loading => 'Carregando dados...';

  @override
  String get progress_export_compiling =>
      'Compilando relatório completo (Corpo, Treino, Nutri)...';

  @override
  String get progress_no_data_period => 'Sem dados neste período.';

  @override
  String get progress_export_error => 'Erro ao gerar relatório.';

  @override
  String get achievements_title => 'Conquistas';

  @override
  String achievements_unlocked_of_total(int unlocked, int total) {
    return '$unlocked de $total desbloqueadas';
  }

  @override
  String get achievements_category_first_steps => 'Primeiros Passos';

  @override
  String get achievements_category_workouts => 'Treinos';

  @override
  String get achievements_category_strength => 'Força';

  @override
  String get achievements_category_milestones => 'Marcos';

  @override
  String get achievements_category_nutrition => 'Nutrição';

  @override
  String get goals_create_dialog_title => 'Criar novo objetivo';

  @override
  String get goals_title_field => 'Título do objetivo';

  @override
  String get goals_description_field => 'Descrição';

  @override
  String get goals_target_value_field => 'Objetivo (valor alvo)';

  @override
  String get goals_unit_field => 'Unidade';

  @override
  String get goals_category_field => 'Categoria';

  @override
  String get goals_category_weight => 'Peso';

  @override
  String get goals_category_workout => 'Treino';

  @override
  String get goals_category_strength => 'Força';

  @override
  String get goals_category_endurance => 'Resistência';

  @override
  String get goals_category_general => 'Geral';

  @override
  String get goals_set_deadline => 'Definir prazo (opcional)';

  @override
  String goals_deadline_set(String date) {
    return 'Prazo: $date';
  }

  @override
  String get goals_fill_required => 'Preencha título, objetivo e unidade';

  @override
  String get goals_create_btn => 'Criar objetivo';

  @override
  String get goals_create_success => 'Objetivo criado com sucesso!';

  @override
  String get goals_section_title => 'Objetivos';

  @override
  String get goals_create_first_btn => 'Criar primeiro objetivo';

  @override
  String get goals_empty_title => 'Sem objetivos ativos';

  @override
  String get goals_empty_instruction =>
      'Crie objetivos para acompanhar sua jornada';

  @override
  String get goals_update_progress_title => 'Atualizar progresso';

  @override
  String get goals_update_progress_btn => 'Atualizar progresso';

  @override
  String goals_current_value_field(String unit) {
    return 'Valor atual ($unit)';
  }

  @override
  String get goals_update_btn => 'Atualizar';

  @override
  String get goals_update_success => 'Progresso atualizado com sucesso!';

  @override
  String get goals_more_options => 'Mais opções';

  @override
  String get goals_pause => 'Pausar objetivo';

  @override
  String get goals_paused => 'Objetivo pausado';

  @override
  String get goals_delete => 'Deletar objetivo';

  @override
  String get goals_deleted => 'Objetivo deletado';

  @override
  String get goals_overdue => 'Atrasado';

  @override
  String get goals_due_today => 'Vence hoje';

  @override
  String goals_days_remaining(int days) {
    return '${days}d restantes';
  }

  @override
  String get photo_progress_title => 'Foto do progresso';

  @override
  String get photo_add_sheet_title => 'Adicionar foto';

  @override
  String get photo_option_camera => 'Câmera';

  @override
  String get photo_option_gallery => 'Galeria';

  @override
  String get photo_permission_title => 'Permissão necessária';

  @override
  String get photo_delete_title => 'Remover foto?';

  @override
  String get photo_delete_message => 'Isso não pode ser desfeito.';

  @override
  String get photo_delete_btn => 'Remover';

  @override
  String get photo_deleted => 'Foto removida.';

  @override
  String get photo_comparison_title => 'Comparação do progresso';

  @override
  String get photo_comparison_before => 'Antes';

  @override
  String get photo_comparison_after => 'Depois';

  @override
  String get photo_close_btn => 'Fechar';

  @override
  String get photo_swap_btn => 'Trocar';

  @override
  String get photo_empty_title => 'Sem fotos ainda';

  @override
  String get photo_empty_instruction =>
      'Tire fotos para acompanhar sua transformação';

  @override
  String get photo_compare_btn => 'Comparar progresso';

  @override
  String get photo_tips_title => 'Dicas';

  @override
  String get photo_tips_content =>
      '• Tire fotos na mesma luz e pose\n• Utilize roupas similares para consistência\n• Tire de frente, lado e de costas\n• Programe fotos semanais';

  @override
  String get photo_saved => 'Foto salva com sucesso!';

  @override
  String get photo_need_two => 'Adicione ao menos 2 fotos para comparar';

  @override
  String get photo_add_semantics => 'Adicionar foto';

  @override
  String get progress_overview_title => 'Resumo do progresso';

  @override
  String progress_overview_period(int days) {
    return 'Últimos $days dias';
  }

  @override
  String get progress_stat_workouts => 'Treinos';

  @override
  String get progress_stat_time => 'Tempo';

  @override
  String get progress_stat_time_unit => 'horas';

  @override
  String get progress_stat_badges => 'Badges';

  @override
  String get progress_stat_badges_unit => 'desbloqueadas';

  @override
  String get progress_stat_streak => 'Streak';

  @override
  String get progress_stat_streak_unit => 'dias';

  @override
  String get progress_stat_total => 'total';

  @override
  String get measurements_label_weight => 'Peso';

  @override
  String get measurements_label_body_fat => 'Gordura Corporal';

  @override
  String get measurements_label_muscle_mass => 'Massa Muscular';

  @override
  String measurements_add_dialog_title(String label) {
    return 'Adicionar $label';
  }

  @override
  String measurements_value_field(String unit) {
    return 'Valor ($unit)';
  }

  @override
  String get measurements_notes_field => 'Notas (opcional)';

  @override
  String get measurements_save_success => 'Dado salvo com sucesso';

  @override
  String get measurements_save_error => 'Falha ao salvar dado';

  @override
  String measurements_empty_title(String label) {
    return 'Sem dados de $label ainda';
  }

  @override
  String get measurements_empty_instruction =>
      'Registre um valor para acompanhar a evolução';

  @override
  String measurements_current_label(String label) {
    return 'Atual · $label';
  }

  @override
  String get measurements_recent_title => 'Últimos registros';

  @override
  String measurements_register_btn(String label) {
    return 'Registrar $label';
  }

  @override
  String measurements_time_days_ago(int days) {
    return '${days}d atrás';
  }

  @override
  String measurements_time_hours_ago(int hours) {
    return '${hours}h atrás';
  }

  @override
  String measurements_time_minutes_ago(int minutes) {
    return '${minutes}m atrás';
  }

  @override
  String get measurements_time_now => 'Agora';

  @override
  String get export_title => 'Exportar Progresso';

  @override
  String get export_subtitle => 'Escolha como deseja visualizar seus dados';

  @override
  String get export_pdf_title => 'Relatório Oficial (PDF)';

  @override
  String get export_pdf_desc =>
      'Documento formatado com histórico e design da marca';

  @override
  String get export_csv_title => 'Planilha de Dados (CSV)';

  @override
  String get export_csv_desc => 'Arquivo bruto para análise externa ou backup';

  @override
  String get export_share_title => 'Compartilhar Resumo';

  @override
  String get export_share_desc => 'Texto rápido para WhatsApp ou Redes Sociais';

  @override
  String get workout_progress_consistency => 'Consistência';

  @override
  String get workout_progress_less => 'Menos';

  @override
  String get workout_progress_more => 'Mais';

  @override
  String workout_progress_tooltip(int count, String date) {
    return '$count treinos em $date';
  }

  @override
  String get workout_progress_completed => 'Completos';

  @override
  String get workout_progress_avg_duration => 'Duração média';

  @override
  String get workout_progress_total_time => 'Tempo total';

  @override
  String get workout_progress_recent_title => 'Treinos recentes';

  @override
  String get workout_progress_empty => 'Ainda sem treinos';

  @override
  String get workout_progress_today => 'Hoje';

  @override
  String get workout_progress_yesterday => 'Ontem';

  @override
  String workout_progress_days_ago(int days) {
    return '${days}d atrás';
  }

  @override
  String get workout_progress_recently => 'Recentemente';

  @override
  String get nutrition_analytics_avg_daily => 'Média diária';

  @override
  String get nutrition_analytics_days_on_target => 'Dias na meta';

  @override
  String get nutrition_analytics_adherence_title => 'Aderência à dieta';

  @override
  String get nutrition_analytics_calorie_goal => 'Meta de calorias';

  @override
  String get nutrition_analytics_no_recent_data => 'Sem dados recentes';

  @override
  String get nutrition_analytics_log_meals_hint =>
      'Registre suas refeições para ver o gráfico';

  @override
  String get nutrition_analytics_calorie_history => 'Histórico de calorias';

  @override
  String get nutrition_analytics_goal_label => 'Meta';

  @override
  String get nutrition_analytics_macros_title => 'Macros no período';

  @override
  String get nutrition_analytics_no_meals =>
      'Sem refeições registradas no período';

  @override
  String get nutrition_analytics_iqd_title => 'Evolução do IQD';

  @override
  String get nutrition_analytics_iqd_subtitle => 'Índice de qualidade da dieta';

  @override
  String get nutrition_analytics_no_iqd => 'Sem dados suficientes para o IQD';

  @override
  String get nutrition_analytics_meals_title => 'Refeições — últimos 7 dias';

  @override
  String get nutrition_analytics_no_meals_7d =>
      'Nenhuma refeição registrada nos últimos 7 dias';

  @override
  String get nutrition_analytics_today => 'Hoje';

  @override
  String get nutrition_analytics_protein => 'Proteína';

  @override
  String get nutrition_analytics_carbs => 'Carboidrato';

  @override
  String get nutrition_analytics_fat => 'Gordura';

  @override
  String get nutrition_analytics_pct_of_goal => '% da meta';

  @override
  String get nutrition_meal_type_cafe => 'Café da manhã';

  @override
  String get nutrition_meal_type_almoco => 'Almoço';

  @override
  String get nutrition_meal_type_lanche => 'Lanche';

  @override
  String get nutrition_meal_type_jantar => 'Jantar';

  @override
  String get nutrition_meal_type_outro => 'Outro';

  @override
  String get profile_title => 'Meu perfil';

  @override
  String get profile_error => 'Erro ao carregar perfil';

  @override
  String get profile_plan_choose_title => 'Escolha seu Plano';

  @override
  String get profile_plan_choose_subtitle =>
      'Desbloqueie todo o potencial do BLDR';

  @override
  String get profile_plan_popular_badge => 'POPULAR';

  @override
  String profile_plan_annual_prefix(String price) {
    return 'ou $price';
  }

  @override
  String get profile_plan_current => 'Plano Atual';

  @override
  String get profile_plan_choose_btn => 'Escolher Plano';

  @override
  String profile_plan_load_error(String error) {
    return 'Erro ao carregar planos: $error';
  }

  @override
  String get profile_photo_change_title => 'Alterar foto de perfil';

  @override
  String get profile_photo_remove_btn => 'Remover Foto';

  @override
  String get profile_measurements_title => 'Medidas Corporais';

  @override
  String get profile_measurements_height => 'Altura (cm)';

  @override
  String get profile_measurements_target_weight => 'Peso Alvo (kg)';

  @override
  String get profile_measurements_saved => 'Medidas salvas!';

  @override
  String get profile_cancel_subscription_title => 'Cancelar Assinatura';

  @override
  String get profile_cancel_subscription_before =>
      'Estamos implementando o cancelamento automático via app de sua assinatura.\n\nSe deseja mesmo cancelar, entre em contato em ';

  @override
  String get profile_cancel_subscription_after =>
      ' que iremos realizar o seu cancelamento.\n\nDesde já agradeçemos a compreensão e sentiremos sua falta na comunidade BLDR CLUB.';

  @override
  String get profile_permission_title => 'Permissão Necessária';

  @override
  String get profile_permission_body =>
      'As notificações foram bloqueadas nas configurações do dispositivo. Para reativá-las, acesse as configurações do app.';

  @override
  String get profile_open_settings_btn => 'Abrir Configurações';

  @override
  String get profile_updated => 'Perfil atualizado com sucesso!';

  @override
  String profile_update_error(String error) {
    return 'Erro ao atualizar perfil: $error';
  }

  @override
  String get profile_photo_updated => 'Foto de perfil atualizada!';

  @override
  String profile_photo_update_error(String error) {
    return 'Erro ao atualizar foto: $error';
  }

  @override
  String get profile_photo_removed => 'Foto de perfil removida!';

  @override
  String profile_photo_remove_error(String error) {
    return 'Erro ao remover foto: $error';
  }

  @override
  String profile_camera_error(String error) {
    return 'Erro ao usar a câmera: $error';
  }

  @override
  String profile_gallery_error(String error) {
    return 'Erro ao escolher imagem: $error';
  }

  @override
  String profile_notifications_error(String error) {
    return 'Erro ao atualizar notificações: $error';
  }

  @override
  String get profile_plan_free => 'Plano Gratuito';

  @override
  String get profile_plan_premium => 'Plano Premium';

  @override
  String profile_xp_bar_level(int level, int xp) {
    return 'Nível $level · $xp XP';
  }

  @override
  String profile_xp_bar_next_level(int nextLevel, int xpNext) {
    return 'Nível $nextLevel em $xpNext XP';
  }

  @override
  String profile_xp_bar_to_next(int toNext) {
    return '+$toNext XP para subir de nível';
  }

  @override
  String get profile_stat_total_workouts => 'Treinos totais';

  @override
  String get profile_stat_hours_trained => 'Horas treinadas';

  @override
  String get profile_stat_current_streak => 'Streak atual';

  @override
  String get profile_stat_achievements => 'Conquistas';

  @override
  String get profile_duels_title => 'Duelos';

  @override
  String get profile_duels_wins => 'Vitórias';

  @override
  String get profile_duels_losses => 'Derrotas';

  @override
  String get profile_duels_win_rate => 'Aproveit.';

  @override
  String get profile_badges_section => 'Conquistas';

  @override
  String get profile_next_achievement => 'Próxima conquista';

  @override
  String get profile_achievement_almost => 'Quase lá!';

  @override
  String profile_achievement_do_workout_singular(int n) {
    return 'Faça mais $n treino';
  }

  @override
  String profile_achievement_do_workout_plural(int n) {
    return 'Faça mais $n treinos';
  }

  @override
  String profile_achievement_maintain_streak_singular(int n) {
    return 'Mantenha o streak por mais $n dia';
  }

  @override
  String profile_achievement_maintain_streak_plural(int n) {
    return 'Mantenha o streak por mais $n dias';
  }

  @override
  String profile_achievement_calorie_goal_singular(int n) {
    return 'Atinja sua meta calórica por mais $n dia';
  }

  @override
  String profile_achievement_calorie_goal_plural(int n) {
    return 'Atinja sua meta calórica por mais $n dias';
  }

  @override
  String profile_achievement_log_meal_singular(int n) {
    return 'Registre mais $n refeição';
  }

  @override
  String profile_achievement_log_meal_plural(int n) {
    return 'Registre mais $n refeições';
  }

  @override
  String profile_achievement_earn_xp(int n) {
    return 'Ganhe mais $n XP';
  }

  @override
  String profile_achievement_reach_level(int n) {
    return 'Alcance o nível $n no Club';
  }

  @override
  String profile_achievement_complete_workout_singular(int n) {
    return 'Complete mais $n treino';
  }

  @override
  String profile_achievement_complete_workout_plural(int n) {
    return 'Complete mais $n treinos';
  }

  @override
  String get profile_achievement_keep_going => 'Continue progredindo!';

  @override
  String get profile_weight_card_title => 'Peso · últimos 30 dias';

  @override
  String get profile_see_all => 'Ver tudo →';

  @override
  String get profile_progress_section => 'Seu progresso';

  @override
  String get profile_stat_total_time => 'Tempo total';

  @override
  String profile_rank_position(int position) {
    return '#$position no ranking';
  }

  @override
  String get profile_sign_in_message =>
      'Confira meu perfil do BLDR!\n\nJunte-se à comunidade BLDR CLUB!';

  @override
  String get profile_notifications_enabled => 'Ativado';

  @override
  String get profile_notifications_disabled => 'Desativado';

  @override
  String get settings_title => 'Configurações';

  @override
  String get settings_section_account => 'Conta';

  @override
  String get settings_edit_profile => 'Editar perfil';

  @override
  String get settings_edit_profile_subtitle => 'Nome, e-mail, telefone';

  @override
  String get settings_share_profile => 'Compartilhar perfil';

  @override
  String get settings_section_plan => 'Plano e assinatura';

  @override
  String get settings_current_plan_row => 'Plano atual';

  @override
  String get settings_manage_subscription => 'Gerenciar assinatura';

  @override
  String get settings_manage_subscription_subtitle =>
      'Pagamento, faturas, cancelar';

  @override
  String get settings_section_workout => 'Treino';

  @override
  String get settings_workout_preferences => 'Preferências de treino';

  @override
  String get settings_workout_preferences_subtitle =>
      'Atualizar suas preferências iniciais';

  @override
  String get settings_goals_row => 'Metas';

  @override
  String get settings_goals_subtitle => 'Peso, calorias, macros';

  @override
  String get settings_section_app => 'Aplicativo';

  @override
  String get settings_notifications_row => 'Notificações';

  @override
  String get settings_notifications_enabled => 'Ativado';

  @override
  String get settings_notifications_disabled => 'Desativado';

  @override
  String get settings_language_row => 'Idioma';

  @override
  String get settings_language_subtitle => 'Português, English, Italiano';

  @override
  String get settings_privacy_row => 'Privacidade';

  @override
  String get settings_privacy_subtitle => 'Visibilidade no ranking e feed';

  @override
  String get settings_section_integrations => 'Integrações';

  @override
  String get settings_whoop_synced => 'Recovery, Strain e Sleep sincronizados';

  @override
  String get settings_whoop_connected_badge => 'Conectado';

  @override
  String get settings_whoop_disconnect_btn => 'Desconectar';

  @override
  String get settings_whoop_connect_subtitle => 'Conecte seu Whoop';

  @override
  String get settings_apple_health => 'Apple Saúde';

  @override
  String get settings_soon_badge => 'Em breve';

  @override
  String get settings_watchables => 'Relógios e wearables';

  @override
  String get settings_section_support => 'Suporte';

  @override
  String get settings_help_center => 'Central de ajuda';

  @override
  String get settings_terms => 'Termos de uso';

  @override
  String get settings_privacy_policy_row => 'Política de privacidade';

  @override
  String get settings_section_about => 'Sobre';

  @override
  String get settings_version_row => 'Versão';

  @override
  String settings_copyright(int year) {
    return '© $year BLDR Fitness. Todos os direitos reservados.';
  }

  @override
  String get settings_sign_out_row => 'Sair da conta';

  @override
  String get settings_delete_account_row => 'Excluir conta';

  @override
  String settings_version_footer(String version) {
    return 'BLDR · versão $version';
  }

  @override
  String get settings_manage_sub_sheet_title => 'Gerenciar assinatura';

  @override
  String get settings_upgrade_btn => 'Fazer upgrade';

  @override
  String get settings_upgrade_subtitle => 'Desbloquear recursos premium';

  @override
  String get settings_cancel_sub_btn => 'Cancelar assinatura';

  @override
  String get settings_cancel_sub_subtitle =>
      'Encerrar sua assinatura BLDR CLUB';

  @override
  String get settings_sign_out_dialog_title => 'Sair';

  @override
  String get settings_sign_out_dialog_message => 'Tem certeza que deseja sair?';

  @override
  String get settings_sign_out_dialog_confirm => 'Sair';

  @override
  String settings_sign_out_error(String error) {
    return 'Erro ao sair: $error';
  }

  @override
  String get settings_delete_account_dialog_title => 'Excluir Conta';

  @override
  String get settings_delete_account_dialog_message =>
      'Tem certeza que deseja excluir sua conta?\n\nTodos os seus dados e sua assinatura serão removidos permanentemente. Esta ação não pode ser desfeita.';

  @override
  String get settings_delete_account_dialog_confirm => 'Sim, Excluir';

  @override
  String settings_delete_account_error(String error) {
    return 'Erro ao excluir conta: $error';
  }

  @override
  String settings_cancel_sub_error(String error) {
    return 'Erro ao carregar planos: $error';
  }

  @override
  String get goals_screen_title => 'Metas';

  @override
  String get goals_macros_exceed => 'Soma dos macros excede a meta calórica.';

  @override
  String get goals_saved => 'Metas salvas com sucesso!';

  @override
  String get goals_section_weight => 'PESO';

  @override
  String get goals_current_weight_label => 'Peso atual';

  @override
  String get goals_editable_in_progress => 'Editável em Progresso';

  @override
  String get goals_target_weight_label => 'Peso alvo';

  @override
  String get goals_pace_title => 'Ritmo';

  @override
  String get goals_pace_subtitle =>
      'Velocidade do progresso em relação ao alvo';

  @override
  String get goals_section_nutrition => 'NUTRIÇÃO';

  @override
  String get goals_calorie_goal_label => 'Meta calórica diária';

  @override
  String get goals_calorie_calculated => 'Calculado pelo HAVOK';

  @override
  String get goals_use_calculated => 'Usar calculado';

  @override
  String get goals_customize => 'Personalizar';

  @override
  String get goals_macros_title => 'Macronutrientes';

  @override
  String get goals_macro_protein => 'Proteína';

  @override
  String get goals_macro_carbs => 'Carboidrato';

  @override
  String get goals_macro_fat => 'Gordura';

  @override
  String goals_macro_pct_calories(String pct) {
    return '$pct% das calorias';
  }

  @override
  String get goals_footer_note =>
      'Alterações afetam Dashboard, Nutrição e o contexto do HAVOK.';

  @override
  String get goals_save_btn => 'Salvar';

  @override
  String get privacy_title => 'Privacidade';

  @override
  String get privacy_nickname_required =>
      'Informe um apelido ou use o nome real.';

  @override
  String get privacy_saved => 'Privacidade atualizada.';

  @override
  String get privacy_section_identity => 'IDENTIDADE NO RANKING E FEED';

  @override
  String get privacy_name_toggle_title => 'Nome no ranking e feed';

  @override
  String get privacy_name_active_label => 'Apelido';

  @override
  String get privacy_name_inactive_label => 'Nome real';

  @override
  String get privacy_name_inactive_subtitle => 'Nome real (padrão)';

  @override
  String get privacy_nickname_hint => 'Apelido (máx. 20 chars)';

  @override
  String get privacy_photo_toggle_title => 'Foto de perfil visível';

  @override
  String get privacy_photo_active_subtitle => 'Visível para todos';

  @override
  String get privacy_photo_inactive_subtitle => 'Só para membros do squad';

  @override
  String get privacy_photo_active_label => 'Todos';

  @override
  String get privacy_photo_inactive_label => 'Squad';

  @override
  String get privacy_section_feed => 'FEED DE ATIVIDADE';

  @override
  String get privacy_feed_toggle_title => 'Aparecer no feed da comunidade';

  @override
  String get privacy_feed_active_subtitle => 'Suas atividades aparecem no feed';

  @override
  String get privacy_feed_inactive_subtitle =>
      'Atividades não aparecem para outros';

  @override
  String get privacy_yes => 'Sim';

  @override
  String get privacy_no => 'Não';

  @override
  String get privacy_reactions_toggle_title => 'Permitir reações';

  @override
  String get privacy_reactions_subtitle =>
      'Outros podem reagir às suas atividades';

  @override
  String get privacy_section_ranking => 'RANKING';

  @override
  String get privacy_ranking_toggle_title => 'Participar do ranking público';

  @override
  String get privacy_ranking_active_subtitle => 'Aparece no ranking geral';

  @override
  String get privacy_ranking_inactive_subtitle =>
      'Oculto no ranking geral (squad não afetado)';

  @override
  String get privacy_legal_text =>
      'Seus dados são processados conforme nossa Política de Privacidade.';

  @override
  String get privacy_legal_link => 'Ver política →';

  @override
  String get privacy_save_btn => 'Salvar';

  @override
  String get language_sheet_title => 'Idioma do app';

  @override
  String get language_havok_note =>
      'O conteúdo gerado pelo HAVOK também será no idioma selecionado.';

  @override
  String get language_pt_region => 'Brasil';

  @override
  String get language_en_region => 'United States';

  @override
  String get language_it_region => 'Italia';

  @override
  String get language_soon_badge => 'Em breve';

  @override
  String get edit_profile_dialog_title => 'Editar Perfil';

  @override
  String get edit_profile_name_label => 'Nome Completo';

  @override
  String get edit_profile_email_label => 'Email';

  @override
  String get edit_profile_email_tooltip => 'Email não pode ser alterado';

  @override
  String get edit_profile_phone_label => 'Telefone (opcional)';

  @override
  String get edit_profile_name_required => 'Nome é obrigatório';

  @override
  String get edit_profile_save_btn => 'Salvar';

  @override
  String get edit_profile_cancel_btn => 'Cancelar';

  @override
  String get common_save => 'Salvar';

  @override
  String get photo_camera_permission_body =>
      'Habilite a câmera nas configurações para registrar seu progresso.';

  @override
  String get photo_gallery_permission_body =>
      'Habilite o acesso às fotos nas configurações.';

  @override
  String get goals_create_semantics => 'Criar objetivo';

  @override
  String get club_events_title => 'Eventos';

  @override
  String get club_announcements_title => 'Anúncios';

  @override
  String get club_workouts_title => 'Treinos';

  @override
  String get club_workouts_subtitle => 'Biblioteca · Programas';

  @override
  String get club_sports_title => 'Esportes';

  @override
  String get club_sports_subtitle => 'Run · Protocolos';

  @override
  String get club_community_title => 'Comunidade';

  @override
  String get club_community_subtitle => 'Feed · Desafios';

  @override
  String get club_competition_title => 'Competição';

  @override
  String get club_competition_subtitle => 'Squads · Operações';

  @override
  String get club_weekly_operation => 'OPERAÇÃO DA SEMANA';

  @override
  String get club_operation_completed => 'CONCLUÍDA ✓';

  @override
  String club_operation_progress(Object current, Object goal, String unit) {
    return '$current de $goal $unit';
  }

  @override
  String club_operation_xp_reward(Object xp) {
    return '+$xp XP ao completar';
  }

  @override
  String club_level(Object level) {
    return 'Nível $level';
  }

  @override
  String club_ranking_badge(Object position) {
    return '#$position no ranking';
  }

  @override
  String club_xp_progress(Object current, Object total) {
    return '$current / $total XP';
  }

  @override
  String get havok_sheet_title => 'HAVOK';

  @override
  String get havok_sheet_subtitle => 'SEU TREINADOR BLDR';

  @override
  String get havok_input_placeholder => 'Pergunte ao HAVOK…';

  @override
  String get havok_disclaimer =>
      'HAVOK é uma IA e pode errar. Não substitui orientação médica ou nutricional.';

  @override
  String get havok_error_open => 'Não consegui abrir a conversa.';

  @override
  String get havok_no_reply => 'O HAVOK não respondeu. Tente de novo.';

  @override
  String havok_workout_exercises_tap(Object count) {
    return '$count exercícios · toque para ver';
  }

  @override
  String get club_competition_hub_title => 'CENTRAL DE OPERAÇÕES';

  @override
  String get club_create_operation => 'CRIAR\nOPERAÇÃO';

  @override
  String get club_be_the_leader => 'Seja o líder.';

  @override
  String get club_join_now => 'ALISTAR-SE\nAGORA';

  @override
  String get club_enter_code => 'Cole o código.';

  @override
  String get club_game_modes_header => 'MODOS DE JOGO';

  @override
  String get club_game_mode_survivor => 'SURVIVOR';

  @override
  String get club_game_mode_alfa => 'ALFA';

  @override
  String get club_game_mode_roadrunner => 'ROADRUNNER';

  @override
  String get club_game_mode_hustle => 'HUSTLE';

  @override
  String get club_survivor_description =>
      'Quem ficar 2 dias sem treinar é eliminado automaticamente.';

  @override
  String get club_alfa_description =>
      'Ganha quem acumular mais XP total — todos os treinos contam.';

  @override
  String get club_roadrunner_description =>
      'Vence quem acumular a maior distância em corridas.';

  @override
  String get club_hustle_description =>
      'Não importa o treino, importa ir. Ganha quem treinar mais dias.';

  @override
  String get club_my_active_squads => 'MEUS SQUADS ATIVOS';

  @override
  String get club_no_active_operation => 'Nenhuma operação ativa.';

  @override
  String get club_community_tab => 'Comunidade';

  @override
  String get club_challenges_tab => 'Desafios';

  @override
  String get club_ranking_week => 'Ranking da semana';

  @override
  String get club_see_all => 'Ver tudo ›';

  @override
  String get club_my_duels => 'SEUS DUELOS';

  @override
  String get club_collective_challenges => 'DESAFIOS COLETIVOS';

  @override
  String get club_create => 'Criar';

  @override
  String get club_duel_history => 'HISTÓRICO DE DUELOS';

  @override
  String get club_no_active_duel => 'Nenhum duelo ativo';

  @override
  String get club_go_to_ranking => 'Vá ao Ranking e desafie alguém!';

  @override
  String get club_no_collective_challenge => 'Nenhum desafio coletivo ativo';

  @override
  String get club_create_first_challenge =>
      'Toque em \"Criar\" e seja o primeiro!';

  @override
  String get club_no_ended_duel => 'Nenhum duelo encerrado ainda.';

  @override
  String get club_recent_activity => 'Atividade recente';

  @override
  String get club_no_recent_activity => 'Nenhuma atividade recente.';

  @override
  String get club_your_position => 'Sua posição';

  @override
  String club_xp_to_next_position(Object xp, Object pos) {
    return '+$xp XP para o #$pos';
  }

  @override
  String club_morale_sent(String name) {
    return 'Você mandou moral para $name! 👊🔥';
  }

  @override
  String get ranking_duel_accepted => 'Desafio ACEITO! A guerra começou. 🔥';

  @override
  String get ranking_duel_refused => 'Desafio recusado.';

  @override
  String get ranking_win_snackbar => 'PARABÉNS! Você venceu o duelo! 🏆';

  @override
  String get ranking_you_suffix => ' (Você)';

  @override
  String get ranking_you_label => 'VOCÊ';

  @override
  String get ranking_rival_label => 'RIVAL';

  @override
  String get ranking_vs => 'VS';

  @override
  String get ranking_challenge_received => 'DESAFIO RECEBIDO';

  @override
  String get ranking_challenge_prompt =>
      ' te chamou para o duelo!\nVai encarar ou correr?';

  @override
  String get ranking_refuse_btn => 'Recusar';

  @override
  String get ranking_accept_btn => 'ACEITAR';

  @override
  String get ranking_yourself_msg =>
      'Esse é você, campeão! Continue focando. 🔥';

  @override
  String get ranking_duel_title => '⚔️ INICIAR DUELO';

  @override
  String get ranking_duel_subtitle => 'Quem bater a meta primeiro vence';

  @override
  String get ranking_xp_goal => 'META EM XP';

  @override
  String get ranking_deadline => 'PRAZO';

  @override
  String get ranking_winner_label => 'Vencedor';

  @override
  String get ranking_deadline_label => 'Prazo';

  @override
  String get ranking_badge_label => 'Badge';

  @override
  String get ranking_duelista => 'Duelista';

  @override
  String ranking_duel_sent(Object xp, String name) {
    return '⚔️ Duelo de $xp XP enviado para $name!';
  }

  @override
  String get ranking_duel_send_error => 'Erro ao enviar desafio.';

  @override
  String ranking_who_bets(Object xp, String prazo) {
    return 'Quem bater $xp xp primeiro em $prazo vence';
  }

  @override
  String ranking_start_duel_btn(Object xp) {
    return 'INICIAR DUELO DE $xp XP';
  }

  @override
  String get havok_loading => 'Carregando...';

  @override
  String havok_hello(String name) {
    return 'Olá, $name';
  }

  @override
  String get havok_tagline => 'Pronto para superar seus limites?';

  @override
  String get havok_generate_training => 'GERAÇÃO DE TREINO';

  @override
  String get havok_generate_btn => 'GERAR TREINO HAVOK';

  @override
  String get havok_error_generate => 'Erro ao gerar treino. Tente novamente.';

  @override
  String get havok_guest => 'Visitante';

  @override
  String get havok_user_default => 'Usuário';

  @override
  String get havok_loading_step1 => 'Buscando informações do seu perfil...';

  @override
  String get havok_loading_step2 => 'Gerando seu treino personalizado...';

  @override
  String get havok_loading_step3 => 'Tudo pronto!';

  @override
  String get free_workout_title => 'TREINO LIVRE';

  @override
  String get free_workout_describe => 'Descreva o treino que você quer';

  @override
  String get free_workout_hint => 'Digite seu comando aqui...';

  @override
  String get free_workout_btn => 'GERAR COM HAVOK';

  @override
  String get workout_library_title => 'BIBLIOTECA HAVOK';

  @override
  String get workout_library_empty => 'Você ainda não gerou nenhum treino.';

  @override
  String get workout_library_go_hub =>
      'Vá para o Hub do HAVOK para criar o seu.';

  @override
  String get workout_library_error => 'Ocorreu um erro ao buscar seus treinos.';

  @override
  String get workout_detail_save => 'Salvar na biblioteca';

  @override
  String get workout_detail_saved => 'Salvo ✓';

  @override
  String get workout_detail_start_now => 'Iniciar agora';

  @override
  String get workout_detail_add_plan => 'Adicionar ao plano';

  @override
  String get workout_detail_which_day => 'Em qual dia da semana?';

  @override
  String get club_my_workouts => 'Meus treinos';

  @override
  String get club_created_by_me => 'Criados por mim';

  @override
  String get club_from_trainer => 'Do meu personal';

  @override
  String get club_start_workout_btn => 'Iniciar treino';

  @override
  String get club_no_workout_created => 'Nenhum treino criado ainda';

  @override
  String get club_create_first_workout =>
      'Crie seu primeiro treino personalizado';

  @override
  String get club_trainer_programs_soon => 'Em breve';

  @override
  String get club_trainer_programs_soon_desc =>
      'Em breve você poderá receber treinos\ndirecionados pelo seu personal trainer.';

  @override
  String get club_programs_title => 'Programas Club';

  @override
  String get club_programs_subtitle =>
      'Sequências estruturadas · Exclusivo BLDR CLUB';

  @override
  String get club_see_all_arrow => 'Ver todos →';

  @override
  String get club_no_workout_found => 'Nenhum treino encontrado.';

  @override
  String get club_fail_start => 'Falha ao iniciar treino';

  @override
  String get club_create_workout => 'Criar treino';

  @override
  String get club_from_photo => 'A partir de foto';

  @override
  String get club_trainer_workouts => 'Treinos do personal';

  @override
  String get club_programs_soon => 'Programas em breve';

  @override
  String get club_cardio_saved => 'Sessão de cardio salva! 🔥';

  @override
  String get club_camera => 'Câmera';

  @override
  String get club_gallery => 'Galeria';

  @override
  String get club_no_exercise_in_photo =>
      'Não foi possível identificar exercícios na imagem. Tente outra foto.';

  @override
  String get club_analyzing_photo => 'Analisando ficha…';

  @override
  String get club_start_btn => 'Iniciar';

  @override
  String get notifications_title => 'Notificações';

  @override
  String get notifications_mark_read => 'Marcar lidas';

  @override
  String get notifications_empty => 'Sem notificações';

  @override
  String get notifications_up_to_date => 'Você está em dia com tudo!';

  @override
  String get notifications_now => 'Agora';

  @override
  String get notifications_today => 'Hoje';

  @override
  String get notifications_yesterday => 'Ontem';

  @override
  String get notifications_this_week => 'Esta semana';

  @override
  String get notifications_older => 'Mais antigo';

  @override
  String get notifications_general => 'Geral';

  @override
  String get notifications_see_duel => 'Ver duelo';

  @override
  String get notifications_see_ranking => 'Ver ranking';

  @override
  String get notifications_see_challenge => 'Ver desafio';

  @override
  String get sports_title => 'Esportes & Performance';

  @override
  String get sports_active_protocols => 'Protocolos ativos';

  @override
  String get sports_trackers => 'Trackers';

  @override
  String get sports_round_timer => 'Round Timer';

  @override
  String get sports_round_timer_subtitle =>
      'Boxe · MMA · Jiu Jitsu · Muay Thai';

  @override
  String get sports_match_tracker => 'Match Tracker';

  @override
  String get sports_match_tracker_subtitle => 'Tênis · Padel · Beach Tennis';

  @override
  String get sports_detected => 'Esportes detectados';

  @override
  String get sports_other => 'Outro';

  @override
  String get sports_recommended => 'Recomendado para você';

  @override
  String get sports_challenge_havok => 'Desafie o HAVOK';

  @override
  String get sports_generate_workout => 'Gerar ficha de treino';

  @override
  String get sports_select_sport => 'Selecione um esporte ou digite outro';

  @override
  String get sports_other_sport_hint => 'Ou digite outro esporte…';

  @override
  String get sports_generate_strategy => 'Gerar estratégia';

  @override
  String get sports_havok_processing => 'HAVOK processando…';

  @override
  String get sports_creating_strategy =>
      'Criando estratégia de performance personalizada.';

  @override
  String get sports_weekly => 'Sua semana';

  @override
  String sports_day_of(Object current, Object total) {
    return 'Dia $current de $total';
  }

  @override
  String sports_active_time(String time) {
    return 'Tempo ativo: $time';
  }

  @override
  String get sports_corridas_sync =>
      'Corridas sincronizadas · outros só neste dispositivo';

  @override
  String get profile_retry => 'Tentar novamente';

  @override
  String get profile_duel => 'Desafiar para duelo';

  @override
  String get profile_react => '👊 Reagir';

  @override
  String get profile_react_sent => '👊 Reação enviada!';

  @override
  String profile_ranking_position(Object pos) {
    return '#$pos Ranking';
  }

  @override
  String get profile_workouts_label => 'Treinos';

  @override
  String get profile_streak_label => 'Streak';

  @override
  String get profile_duels_label => 'Duelos';

  @override
  String get profile_wins => 'Vitórias';

  @override
  String get profile_losses => 'Derrotas';

  @override
  String get profile_winrate => 'Aproveit.';

  @override
  String get profile_achievements => 'CONQUISTAS';

  @override
  String get profile_activity => 'ATIVIDADE RECENTE';

  @override
  String get profile_athlete_bldr => 'Atleta BLDR';

  @override
  String get profile_athlete => 'Atleta';

  @override
  String profile_level(Object level) {
    return 'Nível $level';
  }

  @override
  String profile_xp_to_next(Object next, Object xp) {
    return 'Nível $next em $xp XP';
  }

  @override
  String get join_squad_title => 'Entrar em Operação';

  @override
  String get join_squad_subtitle => 'Cole o código de convite (Ex: K9X-2M1).';

  @override
  String get join_squad_code_label => 'CÓDIGO DE ACESSO';

  @override
  String get join_squad_btn => 'JUNTAR-SE AGORA';

  @override
  String get join_squad_not_found => 'Nenhum Squad encontrado com este código.';

  @override
  String get join_squad_already_member => 'Você já é membro deste Squad!';

  @override
  String join_squad_welcome(String name) {
    return 'Bem-vindo ao Squad $name! 👊';
  }

  @override
  String get squad_settings_saved => 'Configurações salvas! ✅';

  @override
  String get squad_settings_error => 'Erro ao salvar.';

  @override
  String get squad_now_private => 'Squad agora é PRIVADO 🔒';

  @override
  String get squad_now_public => 'Squad agora é PÚBLICO 🌍';

  @override
  String get squad_edit_title => 'Editar Operação';

  @override
  String get squad_name_label => 'Nome do Squad';

  @override
  String get squad_mission_label => 'Missão (Descrição)';

  @override
  String get squad_cancel => 'CANCELAR';

  @override
  String get squad_save => 'SALVAR';

  @override
  String get squad_daily_mission => 'Missão Diária';

  @override
  String get squad_daily_challenge => 'Desafio do Dia';

  @override
  String get squad_define => 'DEFINIR';

  @override
  String get squad_score_limits => 'Limites de Pontuação';

  @override
  String get squad_score_limits_desc =>
      'Limite máximo de XP que um usuário pode ganhar por dia para evitar fraudes.';

  @override
  String get paywall_title => 'Treine no seu limite, não no dos outros';

  @override
  String get paywall_subtitle =>
      'Desbloqueie o BLDR Club: treinos, desafios e comunidade num só lugar.';

  @override
  String paywall_trial_badge(String days) {
    return '$days DIAS GRÁTIS';
  }

  @override
  String paywall_save_percent(String percent) {
    return 'ECONOMIZE $percent%';
  }

  @override
  String get paywall_plan_weekly => 'Semanal';

  @override
  String get paywall_plan_weekly_badge => 'MAIS FLEXÍVEL';

  @override
  String get paywall_per_week => '/semana';

  @override
  String get paywall_best_value => 'MELHOR VALOR';

  @override
  String get paywall_plan_monthly => 'Mensal';

  @override
  String get paywall_plan_annual => 'Anual';

  @override
  String paywall_monthly_equiv(String price) {
    return 'equivale a $price/mês';
  }

  @override
  String get paywall_benefits_title => 'Incluso em todos os planos';

  @override
  String get paywall_subscribe_weekly_btn => 'Assinar plano semanal';

  @override
  String get paywall_subscribe_annual_btn => 'Assinar plano anual';

  @override
  String paywall_start_trial_btn(String days) {
    return 'Começar $days dias grátis';
  }

  @override
  String get paywall_subscribe_monthly_btn => 'Assinar plano mensal';

  @override
  String get paywall_processing => 'Processando…';

  @override
  String get paywall_redeem => 'Resgatar código';

  @override
  String get paywall_restore => 'Restaurar compras';

  @override
  String get paywall_load_error =>
      'Não foi possível carregar os planos agora. Tente novamente em instantes.';

  @override
  String get paywall_billing_title => 'Dados de cobrança';

  @override
  String get paywall_billing_name_label => 'Nome completo';

  @override
  String get paywall_billing_email_label => 'E-mail';

  @override
  String get checkout_screen_title => 'Checkout BLDR';

  @override
  String get checkout_choose_plan_title => 'Escolha seu Plano';

  @override
  String get checkout_choose_plan_subtitle =>
      'Selecione o plano que mais se adequa aos seus objetivos';

  @override
  String get checkout_billing_info_title => 'Informações de Cobrança';

  @override
  String get checkout_billing_info_subtitle =>
      'Preencha seus dados para continuar';

  @override
  String get checkout_name_label => 'Nome Completo';

  @override
  String get checkout_email_label => 'Email';

  @override
  String get checkout_continue_payment_btn => 'Continuar para Pagamento';

  @override
  String get checkout_payment_title => 'Finalizar Pagamento';

  @override
  String get checkout_payment_subtitle =>
      'Confirme os dados e finalize sua assinatura';

  @override
  String get checkout_order_summary => 'Resumo do Pedido';

  @override
  String get checkout_billing_annual => 'Cobrança anual';

  @override
  String get checkout_billing_monthly => 'Cobrança mensal';

  @override
  String get checkout_coupon_title => 'Cupom de Desconto (Opcional)';

  @override
  String get checkout_coupon_label => 'Código do cupom';

  @override
  String get checkout_coupon_apply_btn => 'Aplicar';

  @override
  String checkout_coupon_applied(String code) {
    return 'Cupom \"$code\" aplicado!';
  }

  @override
  String get checkout_apple_payment_title => 'Pagamento via App Store';

  @override
  String get checkout_apple_payment_subtitle =>
      'A cobrança será feita na sua conta Apple.';

  @override
  String get checkout_subscribe_btn => 'Assinar';

  @override
  String get checkout_redeem_btn => 'Resgatar código de oferta';

  @override
  String get checkout_privacy_policy => 'Política de Privacidade';

  @override
  String get checkout_terms_of_use => 'Termos de Uso (EULA)';

  @override
  String get checkout_success_title => 'Sucesso!';

  @override
  String get checkout_success_default_message =>
      'Sua assinatura foi ativada com sucesso!';

  @override
  String get checkout_success_active_message =>
      'Assinatura ativada com sucesso!';

  @override
  String get checkout_apple_success_message =>
      'Assinatura realizada com sucesso!';

  @override
  String checkout_success_plan(String name) {
    return 'Plano: $name';
  }

  @override
  String checkout_field_required(String field) {
    return 'Por favor, preencha o campo $field';
  }

  @override
  String get checkout_email_invalid => 'Por favor, insira um email válido';

  @override
  String get checkout_card_info_title => 'Informações do Cartão';

  @override
  String get checkout_card_data_label => 'Dados do Cartão';

  @override
  String get checkout_card_helper =>
      'Digite o número, validade e CVV do seu cartão';

  @override
  String get checkout_processing => 'Processando...';

  @override
  String get checkout_finalize_btn => 'Finalizar Pagamento';

  @override
  String get checkout_toggle_save_badge => 'ECONOMIZE';

  @override
  String get checkout_plan_popular_badge => 'POPULAR';

  @override
  String get checkout_trial_badge => '🎉 7 DIAS GRÁTIS INCLUÍDOS';

  @override
  String checkout_savings_amount(String amount) {
    return 'Economize $amount';
  }

  @override
  String get splash_tagline => 'CONSTRUA SUA MELHOR VERSÃO';

  @override
  String get splash_connection_error_title => 'Erro de Conexão';

  @override
  String get splash_init_error_msg =>
      'Falha ao inicializar o app. Tente novamente.';

  @override
  String get splash_retry_btn => 'Tentar novamente';

  @override
  String get splash_connection_failed => 'Falha na Conexão';

  @override
  String get splash_retry_shortly =>
      'A opção de tentar novamente aparecerá em breve';

  @override
  String app_init_error(String details) {
    return 'Erro ao iniciar o aplicativo. Detalhes: $details';
  }

  @override
  String get feedback_title => 'Feedback';

  @override
  String get feedback_report_bug => 'Reportar bug';

  @override
  String get feedback_send_suggestion => 'Enviar sugestão';

  @override
  String get feedback_chip_bug => 'Bug';

  @override
  String get feedback_chip_suggestion => 'Sugestão';

  @override
  String get feedback_chip_complaint => 'Reclamação';

  @override
  String get feedback_chip_other => 'Outro';

  @override
  String get feedback_bldr_greeting => 'Olá! Como posso te ajudar hoje?';

  @override
  String get feedback_bldr_select_type =>
      'Escolha o tipo de feedback para começar.';

  @override
  String get feedback_bldr_bug_step1 =>
      'Entendido! Descreva o bug com o máximo de detalhes possível. O que aconteceu?';

  @override
  String get feedback_bldr_bug_step2 =>
      'Quer incluir uma captura de tela? (opcional)';

  @override
  String get feedback_bldr_suggestion_step1 =>
      'Ótimo! Qual é a sua sugestão? Descreva o que você gostaria de ver no app.';

  @override
  String get feedback_bldr_suggestion_step2 =>
      'Quer incluir uma imagem para ilustrar? (opcional)';

  @override
  String get feedback_bldr_complaint_step1 =>
      'Lamentamos que você esteja tendo problemas. Descreva o que aconteceu.';

  @override
  String get feedback_bldr_complaint_step2 =>
      'Quer incluir uma captura de tela? (opcional)';

  @override
  String get feedback_bldr_other_step1 =>
      'Pode falar! O que você gostaria de compartilhar?';

  @override
  String get feedback_bldr_other_step2 => 'Quer incluir uma imagem? (opcional)';

  @override
  String get feedback_bldr_sending => 'Enviando seu feedback...';

  @override
  String get feedback_bldr_success => 'Mensagem enviada!';

  @override
  String feedback_bldr_protocol(String protocolo) {
    return 'Protocolo: #$protocolo';
  }

  @override
  String get feedback_bldr_thanks =>
      'Agradecemos seu feedback. Nossa equipe vai analisá-lo em breve.';

  @override
  String get feedback_hint_message => 'Digite sua mensagem...';

  @override
  String get feedback_add_screenshot => 'Adicionar imagem';

  @override
  String get feedback_remove_screenshot => 'Remover';

  @override
  String get feedback_send => 'Enviar';

  @override
  String get feedback_skip => 'Pular';

  @override
  String get feedback_error_retry => 'Tentar novamente';

  @override
  String feedback_chars_remaining(int count) {
    return '$count / 500';
  }

  @override
  String get paywall_club_logo_semantics => 'Logo do BLDR CLUB';

  @override
  String get paywall_elevate_performance => 'ELEVE SUA PERFORMANCE';

  @override
  String get paywall_performance_subtitle =>
      'Treino, nutrição e inteligência conectados para você evoluir de verdade.';

  @override
  String get paywall_choose_plan => 'Escolha seu plano';

  @override
  String get paywall_weekly_description => 'Acesso completo por uma semana';

  @override
  String get paywall_monthly_description => 'Acesso completo mês a mês';

  @override
  String get paywall_annual_description =>
      'A melhor forma de evoluir o ano todo';

  @override
  String get paywall_per_month => 'por mês';

  @override
  String get paywall_per_year => 'por ano';

  @override
  String get paywall_join_cta => 'Assinar BLDR CLUB';

  @override
  String paywall_selected_price_caption(String price) {
    return '$price · Cancele quando quiser';
  }

  @override
  String get paywall_load_error_title =>
      'Não foi possível carregar os planos agora.';

  @override
  String get paywall_load_error_body => 'Tente novamente em instantes.';

  @override
  String get paywall_feature => 'RECURSO';

  @override
  String get paywall_free => 'GRÁTIS';

  @override
  String get paywall_club => 'CLUB';

  @override
  String get paywall_comparison_semantics =>
      'Comparação entre o plano grátis e o BLDR CLUB';

  @override
  String get paywall_benefit_community => 'Comunidade BLDR';

  @override
  String get paywall_benefit_havok => 'HAVOK AI';

  @override
  String get paywall_benefit_photo_workout => 'Treino por foto';

  @override
  String get paywall_benefit_analytics => 'Analytics';

  @override
  String get paywall_benefit_library => 'Biblioteca';

  @override
  String get paywall_benefit_nutrition => 'Nutrição';

  @override
  String get paywall_limited => 'Limitada';

  @override
  String get paywall_complete => 'Completa';

  @override
  String get paywall_unavailable => '—';

  @override
  String get paywall_available => 'Disponível';

  @override
  String get paywall_basic => 'Básico';

  @override
  String get paywall_advanced => 'Avançado';

  @override
  String get paywall_terms => 'Termos de uso';

  @override
  String get paywall_privacy => 'Política de privacidade';

  @override
  String get bootstrap_init_failed_title => 'Não foi possível iniciar o BLDR.';

  @override
  String get bootstrap_init_failed_body =>
      'Verifique sua conexão e tente novamente.';

  @override
  String get paywall_sign_in_required => 'Entre na sua conta para continuar.';

  @override
  String get paywall_options_unavailable =>
      'As opções de assinatura ainda não estão disponíveis.';

  @override
  String get paywall_options_retry_later =>
      'As opções de assinatura ainda não estão disponíveis. Tente novamente mais tarde.';

  @override
  String get paywall_option_unavailable =>
      'Esta opção de assinatura não está disponível.';

  @override
  String get paywall_access_confirmation_failed =>
      'Não foi possível confirmar o acesso ao BLDR CLUB.';

  @override
  String get paywall_payment_pending =>
      'Seu pagamento está pendente de confirmação pela loja.';

  @override
  String get paywall_redeem_unavailable =>
      'O resgate de código estará disponível quando as opções de assinatura carregarem.';

  @override
  String get paywall_restore_unavailable =>
      'A restauração estará disponível quando as opções de assinatura carregarem.';

  @override
  String get paywall_restore_after_update =>
      'A restauração estará disponível após a atualização de assinaturas.';
}
