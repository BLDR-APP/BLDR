// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get common_continue_btn => 'Continue';

  @override
  String get common_finish_btn => 'Finish';

  @override
  String get common_back_btn => 'Back';

  @override
  String get common_next_btn => 'Next';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_ok => 'OK';

  @override
  String get common_resend => 'Resend';

  @override
  String get common_or => 'or';

  @override
  String get common_retry => 'Riprova';

  @override
  String get common_start_btn => 'Start';

  @override
  String get common_got_it_btn => 'Got It';

  @override
  String get login_title => 'Welcome!';

  @override
  String get login_subtitle => 'Log in to continue your fitness journey';

  @override
  String get login_email_label => 'Email';

  @override
  String get login_email_hint => 'Enter your email address';

  @override
  String get login_email_required_error => 'Email is required';

  @override
  String get login_email_invalid_error => 'Enter a valid email address';

  @override
  String get login_password_label => 'Password';

  @override
  String get login_password_hint => 'Enter your password';

  @override
  String get login_password_required_error => 'Password is required';

  @override
  String get login_remember_me => 'Remember me';

  @override
  String get login_forgot_password => 'Forgot password?';

  @override
  String get login_btn => 'Log In';

  @override
  String get login_apple_btn => 'Continue with Apple';

  @override
  String get login_google_btn => 'Continue with Google';

  @override
  String get login_no_account => 'Don\'t have an account? ';

  @override
  String get login_create_account_link => 'Create account';

  @override
  String get login_email_not_confirmed_title => 'Email not confirmed';

  @override
  String get login_email_not_confirmed_body =>
      'You need to confirm your email before logging in. Check your inbox and click the confirmation link.';

  @override
  String get login_email_confirmation_resent => 'Confirmation email resent';

  @override
  String login_resend_email_error(String message) {
    return 'Error resending email: $message';
  }

  @override
  String get login_recover_password_title => 'Recover Password';

  @override
  String get login_recover_password_body =>
      'Enter your email to receive a 6-digit code.';

  @override
  String get login_enter_email_hint => 'Enter your email';

  @override
  String get login_enter_email_error => 'Please enter an email.';

  @override
  String get login_send_code_btn => 'Send Code';

  @override
  String login_send_code_error(String message) {
    return 'Error sending code: $message';
  }

  @override
  String login_error(String message) {
    return 'Login failed: $message';
  }

  @override
  String get signup_title => 'Create Account';

  @override
  String get signup_subtitle =>
      'Join BLDR and start your fitness journey with personalized workouts and nutrition tracking.';

  @override
  String get signup_form_title => 'Join BLDR';

  @override
  String get signup_form_subtitle => 'Start your fitness transformation today';

  @override
  String get signup_full_name_label => 'Full name';

  @override
  String get signup_full_name_hint => 'Enter your full name';

  @override
  String get signup_full_name_required_error => 'Full name is required';

  @override
  String get signup_full_name_min_length_error =>
      'Full name must be at least 2 characters';

  @override
  String get signup_password_min_length_error =>
      'Password must be at least 8 characters';

  @override
  String get signup_password_uppercase_error =>
      'Password must contain at least one uppercase letter';

  @override
  String get signup_password_number_error =>
      'Password must contain at least one number';

  @override
  String get signup_confirm_password_label => 'Confirm Password';

  @override
  String get signup_confirm_password_hint => 'Confirm your password';

  @override
  String get signup_confirm_password_required_error =>
      'Please confirm your password';

  @override
  String get signup_passwords_mismatch_error => 'Passwords do not match';

  @override
  String get signup_agree_terms_prefix => 'I agree to the ';

  @override
  String get signup_terms_of_service => 'Terms of Service';

  @override
  String get signup_privacy_policy => 'Privacy Policy';

  @override
  String get signup_must_agree_terms_error =>
      'Please agree to the Terms of Service';

  @override
  String signup_error(String message) {
    return 'Signup error: $message';
  }

  @override
  String get signup_create_account_btn => 'Create Account';

  @override
  String get signup_already_have_account => 'Already have an account? ';

  @override
  String get signup_confirm_email_title => 'Confirm Your Email';

  @override
  String get signup_confirm_email_sent_to => 'We sent a confirmation email to:';

  @override
  String get signup_confirm_email_instruction =>
      'Click the link in the email to confirm your account and continue.';

  @override
  String get signup_resend_email_btn => 'Resend Email';

  @override
  String get signup_back_to_login_btn => 'Back to Login';

  @override
  String get wait_confirm_email_body =>
      'We sent a confirmation link to your email address. Please click the link to activate your account.';

  @override
  String get wait_confirm_no_email_error => 'Could not find the user\'s email.';

  @override
  String get wait_confirm_email_resent_success =>
      'Confirmation email resent successfully!';

  @override
  String get wait_confirm_back_to_login_btn => 'Back to Login';

  @override
  String get otp_title => 'Verify Code';

  @override
  String get otp_heading => 'Enter the Code';

  @override
  String get otp_body => 'We sent a 6-digit code to your email:';

  @override
  String get otp_validator_error => 'Enter the 6-digit code';

  @override
  String get otp_verify_btn => 'Verify & Continue';

  @override
  String get otp_invalid_code_error =>
      'Invalid or expired code. Please try again.';

  @override
  String get new_password_title => 'Create New Password';

  @override
  String get new_password_heading => 'Set Your New Password';

  @override
  String get new_password_body =>
      'Please enter a strong new password for your account.';

  @override
  String get new_password_field_label => 'New Password';

  @override
  String get new_password_field_hint => 'Enter your new password';

  @override
  String get new_password_min_length_error =>
      'Password must be at least 8 characters';

  @override
  String get new_password_confirm_label => 'Confirm New Password';

  @override
  String get new_password_confirm_hint => 'Confirm your new password';

  @override
  String get new_password_passwords_mismatch_error => 'Passwords do not match';

  @override
  String get new_password_save_btn => 'Save New Password';

  @override
  String get new_password_success => 'Password updated successfully!';

  @override
  String new_password_error(String message) {
    return 'Error updating password: $message';
  }

  @override
  String get new_password_confirm_required_error =>
      'Please confirm your password';

  @override
  String onboarding_step_indicator(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboarding_exit_dialog_title => 'Exit Setup?';

  @override
  String get onboarding_exit_dialog_body => 'Your progress will be lost.';

  @override
  String get onboarding_exit_dialog_exit_btn => 'Exit';

  @override
  String onboarding_completion_error(String error) {
    return 'Failed to complete setup: $error';
  }

  @override
  String get onboarding_welcome_title => 'Welcome to BLDR.';

  @override
  String get onboarding_welcome_body =>
      'Let\'s build your 100% personalized plan with HAVOK AI.';

  @override
  String get onboarding_welcome_bullet_nutrition =>
      'Personalized nutrition plan';

  @override
  String get onboarding_welcome_bullet_workout => 'Workout generated by HAVOK';

  @override
  String get onboarding_welcome_bullet_adjustments =>
      'Continuous adjustments as you progress';

  @override
  String get onboarding_welcome_duration_hint =>
      'This will only take a few minutes.';

  @override
  String get onboarding_goal_title => 'What is your main goal?';

  @override
  String get onboarding_goal_body =>
      'This will set the direction of your nutrition plan.';

  @override
  String get onboarding_pace_title => 'What pace do you prefer?';

  @override
  String get onboarding_pace_body =>
      'Aggressive pace brings faster results but requires more discipline.';

  @override
  String get onboarding_profile_title => 'About you';

  @override
  String get onboarding_profile_body =>
      'Essential for calculating your nutrition goals.';

  @override
  String get onboarding_profile_age => 'Age';

  @override
  String get onboarding_profile_height => 'Height';

  @override
  String get onboarding_profile_weight => 'Weight';

  @override
  String get onboarding_activity_title => 'How active is your daily life?';

  @override
  String get onboarding_activity_body =>
      'Excluding workouts and sports — defines your NEAT.';

  @override
  String get onboarding_workout_config_title => 'Configuring your workout';

  @override
  String get onboarding_workout_config_body =>
      'This information guides HAVOK AI in creating your plan.';

  @override
  String get onboarding_experience_section_title => 'Experience level';

  @override
  String get onboarding_freq_days_label => 'Days per week';

  @override
  String get onboarding_duration_section_title => 'Average session length';

  @override
  String get onboarding_environment_title => 'Where will you train?';

  @override
  String get onboarding_environment_body =>
      'This tells HAVOK which exercises to include.';

  @override
  String get onboarding_equipment_title => 'What equipment do you have?';

  @override
  String get onboarding_equipment_body => 'Select all that apply.';

  @override
  String get onboarding_activities_title => 'Activities & muscle focus';

  @override
  String get onboarding_activities_body =>
      'What activities you do and where you want to focus.';

  @override
  String get onboarding_activities_section_title => 'Physical activities';

  @override
  String get onboarding_muscles_section_title => 'Muscle groups';

  @override
  String get onboarding_muscles_body =>
      'Select the muscles you want to prioritize.';

  @override
  String get onboarding_split_injuries_title => 'Split & injuries';

  @override
  String get onboarding_split_injuries_body =>
      'Last details for HAVOK to build your workout.';

  @override
  String get onboarding_split_section_title => 'Workout split';

  @override
  String get onboarding_split_body => 'If unsure, let HAVOK decide.';

  @override
  String get onboarding_injuries_section_title => 'Injuries or limitations';

  @override
  String get onboarding_injuries_body =>
      'HAVOK will avoid exercises that hinder your recovery.';

  @override
  String get onboarding_injury_other_hint => 'Describe your injury…';

  @override
  String get onboarding_summary_title => 'All set!';

  @override
  String get onboarding_summary_body =>
      'Your personalized plan has been calculated.';

  @override
  String get onboarding_summary_nutrition_section => 'Nutrition';

  @override
  String onboarding_summary_tdee(String tdee) {
    return 'TDEE: $tdee kcal/day';
  }

  @override
  String get onboarding_calorie_goal_label => 'Calorie goal';

  @override
  String get onboarding_protein_label => 'Protein';

  @override
  String get onboarding_summary_carbs_label => 'Carbs';

  @override
  String get onboarding_summary_fat_label => 'Fat';

  @override
  String get onboarding_summary_hydration_label => 'Hydration';

  @override
  String get onboarding_summary_workout_section => 'Workout';

  @override
  String get onboarding_summary_goal_label => 'Goal';

  @override
  String get onboarding_summary_level_label => 'Level';

  @override
  String get onboarding_summary_frequency_label => 'Frequency';

  @override
  String get onboarding_summary_duration_label => 'Duration';

  @override
  String get onboarding_summary_environment_label => 'Environment';

  @override
  String get onboarding_summary_split_label => 'Split';

  @override
  String get onboarding_summary_focus_label => 'Focus';

  @override
  String get onboarding_summary_confirm_hint =>
      'By confirming, HAVOK will generate your personalized workout plan.';

  @override
  String get onboarding_tdee_info_title => 'What is TDEE?';

  @override
  String get onboarding_tdee_info_body =>
      'TDEE (Total Daily Energy Expenditure) is the number of calories your body burns per day. We use this as a baseline to calculate your goals.';

  @override
  String get onboarding_completion_generating_title => 'Building your week';

  @override
  String get onboarding_completion_generating_body =>
      'I\'m using what you told me to design your first plan.';

  @override
  String get onboarding_completion_ready_title => 'Your week is ready';

  @override
  String get onboarding_completion_plan_fallback_desc =>
      'Personalized plan by HAVOK';

  @override
  String get onboarding_completion_starts_today_label => 'Starts today';

  @override
  String get onboarding_rest_day => 'Rest';

  @override
  String get onboarding_completion_adjust_hint =>
      'You can adjust everything later in Workouts and Settings.';

  @override
  String get onboarding_completion_regenerate_btn => 'Try a different split';

  @override
  String get onboarding_completion_fallback_title =>
      'Couldn\'t generate right now.';

  @override
  String get onboarding_completion_fallback_body_with_plan =>
      'I created a base plan to get you started — adjust whenever you want.';

  @override
  String get onboarding_completion_fallback_body_no_plan =>
      'Try again in a moment — you can build your workout manually in Workouts.';

  @override
  String get onboarding_completion_today_workout_label => 'Today\'s workout';

  @override
  String get onboarding_summary_review_title => 'Review Your Choices';

  @override
  String get onboarding_summary_perfect_body =>
      'Perfect! We\'ll use this information to create your personalized fitness experience!';

  @override
  String get onboarding_summary_edit_btn => 'Edit';

  @override
  String get common_loading => 'Loading…';

  @override
  String get dashboard_greeting_morning => 'Good Morning';

  @override
  String get dashboard_greeting_afternoon => 'Good Afternoon';

  @override
  String get dashboard_greeting_evening => 'Good Evening';

  @override
  String get dashboard_guest_user => 'Guest';

  @override
  String get dashboard_streak_label => 'Streak';

  @override
  String get dashboard_workouts_month_label => 'Workouts/month';

  @override
  String get dashboard_total_time_label => 'Total time';

  @override
  String get dashboard_achievements_label => 'Achievements';

  @override
  String dashboard_streak_value(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get dashboard_continue_workout_label => 'Continue';

  @override
  String get dashboard_delete_paused_title => 'Delete paused workout?';

  @override
  String get dashboard_delete_paused_body =>
      'Do you want to delete this paused workout? Progress will not be recovered.';

  @override
  String get dashboard_delete_btn => 'Delete';

  @override
  String get dashboard_workout_today_title => 'Today\'s workout';

  @override
  String get dashboard_workout_load_error_title => 'Could not load workouts';

  @override
  String get dashboard_workout_load_error_body =>
      'Check your connection and try again';

  @override
  String get dashboard_welcome_title => 'Welcome to BLDR';

  @override
  String get dashboard_welcome_subtitle => 'Log in to track your workouts';

  @override
  String get dashboard_login_btn => 'Log In';

  @override
  String get dashboard_workout_in_progress => 'Workout in progress';

  @override
  String get dashboard_finish_workout_btn => 'Finish workout';

  @override
  String get dashboard_workout_ready => 'Ready to train?';

  @override
  String get dashboard_workout_havok_generated =>
      'Generated by HAVOK during onboarding';

  @override
  String get dashboard_workout_next_session => 'Start next session';

  @override
  String get dashboard_workout_start_btn => 'Start workout';

  @override
  String get dashboard_finish_workout_dialog_title => 'Finish Workout';

  @override
  String get dashboard_finish_workout_dialog_body =>
      'Are you sure you want to complete your current workout?';

  @override
  String get dashboard_complete_workout_btn => 'Complete';

  @override
  String get dashboard_workout_completed_success =>
      'Workout finished successfully!';

  @override
  String get dashboard_workout_done_label => 'Completato';

  @override
  String get dashboard_done_duration_label => 'Durata';

  @override
  String get dashboard_done_sets_label => 'Serie';

  @override
  String get dashboard_done_volume_label => 'Volume';

  @override
  String dashboard_finish_workout_error(String error) {
    return 'Failed to finish workout: $error';
  }

  @override
  String get dashboard_no_workouts_available =>
      'No workouts available right now';

  @override
  String get dashboard_weight_goal_label => 'Target weight';

  @override
  String dashboard_goal_target(String value, String unit) {
    return 'goal $value $unit';
  }

  @override
  String get dashboard_goal_empty_title => 'Set your goal';

  @override
  String get dashboard_goal_empty_subtitle =>
      'Create a goal in the Progress tab';

  @override
  String get dashboard_calories_label => 'Calories';

  @override
  String dashboard_calories_of_target(int target) {
    return 'of $target kcal';
  }

  @override
  String get dashboard_macros_label => 'Macros';

  @override
  String get dashboard_macro_protein_abbrev => 'P';

  @override
  String get dashboard_macro_carbs_abbrev => 'C';

  @override
  String get dashboard_macro_fat_abbrev => 'F';

  @override
  String get dashboard_seven_days => '7 days';

  @override
  String dashboard_workouts_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '$count workout',
    );
    return '$_temp0';
  }

  @override
  String get dashboard_havok_insight_title => 'Your week at a glance';

  @override
  String get dashboard_havok_insight_body =>
      'Soon HAVOK will comment on your plan adherence, protein, and streak right here.';

  @override
  String get dashboard_havok_insight_action_btn => 'View progress';

  @override
  String dashboard_level_label(String level) {
    return 'Level $level';
  }

  @override
  String get dashboard_partners_title => 'Partners';

  @override
  String get dashboard_partner_view_offer_btn => 'View offer';

  @override
  String get dashboard_partner_copy_coupon_btn => 'Copy coupon';

  @override
  String get dashboard_partners_view_all_btn => 'View all';

  @override
  String dashboard_partner_coupon_copied(String coupon) {
    return 'Coupon \"$coupon\" copied!';
  }

  @override
  String get dashboard_quick_log_title => 'Quick Log';

  @override
  String get dashboard_quick_log_meal => 'Log Meal';

  @override
  String get dashboard_quick_log_workout => 'Log Exercise';

  @override
  String get dashboard_quick_log_weight => 'Log Weight';

  @override
  String get dashboard_quick_log_water => 'Log Water';

  @override
  String get whoop_card_connect_subtitle =>
      'Connect your Whoop to see Sleep, Recovery, and Strain.';

  @override
  String get whoop_card_connect_btn => 'Connect';

  @override
  String get whoop_card_today => 'Today';

  @override
  String get whoop_card_sleep_label => 'SLEEP';

  @override
  String get whoop_card_recovery_label => 'RECOVERY';

  @override
  String get whoop_card_strain_label => 'STRAIN';

  @override
  String get whoop_card_recovery_tip_low =>
      'Low recovery — prioritize rest today.';

  @override
  String get whoop_card_recovery_tip_med =>
      'Moderate recovery — light or technical workout.';

  @override
  String get whoop_card_recovery_tip_high =>
      'High recovery — ideal day for intense effort.';

  @override
  String get nav_tab_dashboard => 'Dashboard';

  @override
  String get nav_tab_workouts => 'Workouts';

  @override
  String get nav_tab_community => 'Comunità';

  @override
  String get nav_tab_nutrition => 'Nutrition';

  @override
  String get nav_tab_profile => 'Profile';

  @override
  String get nav_club_label => 'BLDR Club';

  @override
  String get component_workout_start_btn => 'Start';

  @override
  String component_series_label(int index) {
    return 'Set $index';
  }

  @override
  String get component_current_badge => 'Current';

  @override
  String component_kcal_label(int calories) {
    return '$calories kcal';
  }

  @override
  String component_macro_detail(
      String protein, String carbs, String fat, String portion) {
    return 'P ${protein}g · C ${carbs}g · F ${fat}g · $portion';
  }

  @override
  String get common_delete => 'Delete';

  @override
  String get workouts_title => 'Workouts';

  @override
  String get workouts_search_hint => 'Search workout…';

  @override
  String get workouts_today_hero_label => 'Today\'s workout';

  @override
  String workouts_today_with_label(String label) {
    return 'Today · $label';
  }

  @override
  String get workouts_today_hero_subtitle => 'Tap to see the full weekly plan';

  @override
  String get workouts_continue_title => 'Continue';

  @override
  String get workouts_active_banner_text => 'Workout in progress — continue';

  @override
  String get workouts_my_workouts => 'My workouts';

  @override
  String get workouts_created_by_me => 'Created by me';

  @override
  String get workouts_from_my_trainer => 'From my trainer';

  @override
  String get workouts_empty_state => 'No workouts created yet';

  @override
  String get workouts_empty_subtitle =>
      'Create your first personalized workout';

  @override
  String get workouts_create_btn => 'Create workout';

  @override
  String get workouts_from_photo_btn => 'From photo';

  @override
  String get workouts_photo_camera => 'Camera';

  @override
  String get workouts_photo_gallery => 'Gallery';

  @override
  String get workouts_photo_no_exercises =>
      'Could not identify exercises in the image. Try another photo.';

  @override
  String workouts_photo_error(String error) {
    return 'Error analyzing photo: $error';
  }

  @override
  String get workouts_trainer_empty_state => 'Trainer workouts — coming soon';

  @override
  String get workouts_trainer_empty_subtitle =>
      'Soon you\'ll be able to receive workouts from your personal trainer.';

  @override
  String get workouts_bldr_library => 'BLDR Library';

  @override
  String get workouts_see_less => 'See less';

  @override
  String get workouts_see_all => 'See all';

  @override
  String get workouts_bldr_empty => 'No BLDR workouts available';

  @override
  String get workouts_start_workout_btn => 'Start workout';

  @override
  String get workouts_exercises_header => 'Exercises';

  @override
  String workouts_exercises_count(int exercises, int sets) {
    return '$exercises · $sets sets';
  }

  @override
  String workouts_sets(int count) {
    return '$count sets';
  }

  @override
  String workouts_reps(int count) {
    return '$count reps';
  }

  @override
  String get workouts_no_exercises => 'No exercises';

  @override
  String get workouts_technique_unavailable =>
      'Technique not available for this exercise.';

  @override
  String get workouts_delete_title => 'Delete workout';

  @override
  String workouts_delete_body(String name) {
    return 'Are you sure you want to delete \"$name\"?\nThis action cannot be undone.';
  }

  @override
  String workouts_deleted_snackbar(String name) {
    return '\"$name\" deleted';
  }

  @override
  String workouts_delete_error(String error) {
    return 'Error deleting: $error';
  }

  @override
  String get workouts_start_error => 'Failed to start workout';

  @override
  String workouts_difficulty_label(int level) {
    return 'Level $level';
  }

  @override
  String get plan_current_week => 'Current week';

  @override
  String get plan_see_plan => 'See plan →';

  @override
  String get plan_workout_done => 'Workout done';

  @override
  String get plan_workout_not_done => 'Workout not done';

  @override
  String get plan_no_record => 'No record for this day.';

  @override
  String get plan_view_week_btn => 'View weekly plan';

  @override
  String get plan_title => 'My plan';

  @override
  String get plan_change_btn => 'Change';

  @override
  String plan_of_total_workouts(int total) {
    return 'of $total workouts';
  }

  @override
  String plan_workouts_count(int count) {
    return '$count workouts';
  }

  @override
  String plan_remaining(int count) {
    return '$count remaining this week';
  }

  @override
  String get plan_streak_singular => 'day in a row';

  @override
  String get plan_streak_plural => 'days in a row';

  @override
  String get plan_xp_week => 'XP this week';

  @override
  String plan_xp_earned(int xp) {
    return '+$xp XP';
  }

  @override
  String get plan_edit_sheet_title => 'Edit weekly plan';

  @override
  String get plan_split_section => 'Workout split';

  @override
  String get plan_days_section => 'Days of the week';

  @override
  String plan_training_rest_summary(int training, int rest) {
    return '$training workout · $rest rest';
  }

  @override
  String get plan_days_toggle_hint =>
      'Tap a day to toggle between workout and rest';

  @override
  String get plan_save_btn => 'Save changes';

  @override
  String get plan_save_success => 'Plan updated successfully!';

  @override
  String plan_save_error(String error) {
    return 'Error saving: $error';
  }

  @override
  String get plan_pro_title => 'Unlock the premium plan';

  @override
  String get plan_pro_subtitle => 'Customize each day of your week';

  @override
  String get plan_see_plans_btn => 'View plans';

  @override
  String get plan_pro_feature_1 => 'Choose a specific workout per day';

  @override
  String get plan_pro_feature_2 => 'Change the plan freely';

  @override
  String get plan_pro_feature_3 => 'Use custom workouts in your plan';

  @override
  String get plan_pro_feature_4 => 'Apple Watch sync';

  @override
  String get plan_pro_feature_5 => 'Advanced progress analytics';

  @override
  String get plan_do_now_btn => 'Do now';

  @override
  String get plan_today_sheet_title => 'Today\'s workout';

  @override
  String get plan_next_workout => 'View workout';

  @override
  String get plan_rest_day => 'Rest';

  @override
  String get plan_not_done => 'Not done';

  @override
  String get plan_extra_badge => 'Extra';

  @override
  String get plan_extras_label => 'Extras';

  @override
  String get plan_delete_record_btn => 'Delete record';

  @override
  String get plan_delete_record_title => 'Delete record?';

  @override
  String get plan_delete_record_body =>
      'Do you want to delete this workout record? This action cannot be undone.';

  @override
  String get plan_delete_record_error => 'Error deleting record.';

  @override
  String get plan_edit_btn => 'Edit plan';

  @override
  String get plan_register_extra_btn => 'Log extra';

  @override
  String get plan_extra_sheet_title => 'Log extra activity';

  @override
  String get plan_extra_sheet_subtitle => 'Activity outside the plan · +50 XP';

  @override
  String get plan_extra_type_label => 'Activity type';

  @override
  String get plan_extra_duration_label => 'Duration';

  @override
  String get plan_extra_notes_label => 'Notes (optional)';

  @override
  String get plan_extra_notes_hint => 'e.g. pickup soccer game with friends';

  @override
  String get plan_extra_register_btn => 'Log + 50 XP';

  @override
  String plan_extra_register_error(String error) {
    return 'Error logging: $error';
  }

  @override
  String get plan_extra_register_success => 'Activity logged! +50 XP';

  @override
  String get plan_paywall_muscle_message =>
      'Unlock full muscle analysis — BLDR CLUB';

  @override
  String get plan_paywall_muscle_btn => 'Explore BLDR Club';

  @override
  String get workout_stop_title => 'Finish workout now?';

  @override
  String get workout_stop_body =>
      'The session will be completed with the progress recorded so far.';

  @override
  String get workout_stop_btn => 'Finish now';

  @override
  String get workout_stop_label => 'Finish workout';

  @override
  String get workout_in_progress => 'IN PROGRESS';

  @override
  String get workout_time_label => 'TIME';

  @override
  String get workout_set_label => 'SET';

  @override
  String workout_exercise_of(int current, int total) {
    return 'Exercise $current of $total';
  }

  @override
  String workout_percent_done(int percent) {
    return '$percent% done';
  }

  @override
  String get workout_see_technique => 'View technique';

  @override
  String get workout_paywall_muscle_message =>
      'See which secondary muscles you\'re activating — BLDR Club';

  @override
  String get workout_technique_fallback => 'Technique';

  @override
  String get workout_execution_label => 'Execution';

  @override
  String get workout_no_instructions => 'No instructions available.';

  @override
  String get workout_load_kg => 'Load (kg)';

  @override
  String get workout_decrease_load => 'Decrease load';

  @override
  String get workout_increase_load => 'Increase load';

  @override
  String get workout_reps_label => 'Reps';

  @override
  String get workout_decrease_reps => 'Decrease reps';

  @override
  String get workout_increase_reps => 'Increase reps';

  @override
  String get workout_resting => 'RESTING';

  @override
  String workout_next_set(int set, int total) {
    return 'Next: set $set of $total';
  }

  @override
  String get workout_add_rest_label => 'Add 15 seconds to rest';

  @override
  String get workout_skip_rest => 'Skip rest';

  @override
  String get workout_exercises_label => 'Exercises';

  @override
  String get workout_set_current => 'Current';

  @override
  String get workout_next_up => 'Up next';

  @override
  String get workout_skip_exercise => 'Skip exercise';

  @override
  String get workout_confirm_set_btn => 'Confirm set';

  @override
  String get workout_rest_edit_label => 'Edit rest time';

  @override
  String get workout_rest_sheet_title => 'Rest time';

  @override
  String get workout_confirm_btn => 'Confirm';

  @override
  String get workout_finished_title => 'Workout Complete!';

  @override
  String get workout_stat_time => 'Time';

  @override
  String get workout_stat_sets => 'Sets';

  @override
  String get workout_finish_btn => 'Finish';

  @override
  String get common_today => 'Today';

  @override
  String get common_required_field => 'Required field';

  @override
  String get common_invalid_value => 'Invalid value';

  @override
  String get common_unauthenticated => 'User not authenticated.';

  @override
  String get nutrition_food_removed => 'Food removed successfully!';

  @override
  String get nutrition_remove_error => 'Failed to remove item.';

  @override
  String get nutrition_daily_summary => 'Daily summary';

  @override
  String get nutrition_protein => 'Protein';

  @override
  String get nutrition_carbs => 'Carbs';

  @override
  String get nutrition_fat => 'Fat';

  @override
  String get nutrition_remaining_today => 'Remaining today';

  @override
  String get nutrition_goal_exceeded => 'Goal exceeded';

  @override
  String get nutrition_iqd_gauge_label => 'DQI · /100';

  @override
  String get nutrition_fiber => 'Fiber';

  @override
  String get nutrition_sodium => 'Sodium';

  @override
  String get nutrition_sugars => 'Sugars';

  @override
  String get nutrition_iqd_premium_msg =>
      'Diet quality analysis (DQI)\\navailable on Premium';

  @override
  String get nutrition_iqd_premium_btn => 'Go Premium';

  @override
  String get nutrition_meals_section => 'Meals';

  @override
  String get nutrition_photo_meal_btn => 'Photo of meal';

  @override
  String get nutrition_search_btn => 'Search food';

  @override
  String get nutrition_no_food => 'No food';

  @override
  String get nutrition_add_btn => 'Add';

  @override
  String get nutrition_unnamed_food => 'Unnamed food';

  @override
  String get nutrition_item_id_missing => 'Food item ID not found.';

  @override
  String get nutrition_item_action_question =>
      'What do you want to do with this item?';

  @override
  String get nutrition_edit_quantity => 'Edit quantity';

  @override
  String get nutrition_remove_item => 'Remove item';

  @override
  String get nutrition_breakfast => 'Breakfast';

  @override
  String get nutrition_snack => 'Snack';

  @override
  String get nutrition_lunch => 'Lunch';

  @override
  String get nutrition_pre_workout => 'Pre-workout';

  @override
  String get nutrition_post_workout => 'Post-workout';

  @override
  String get nutrition_dinner => 'Dinner';

  @override
  String nutrition_add_to_meal(String mealType) {
    return 'Add to: $mealType';
  }

  @override
  String get nutrition_search_db_hint => 'Search food database...';

  @override
  String get nutrition_photo_auto_label =>
      'Meal photo — automatic identification';

  @override
  String get nutrition_coming_soon => 'Coming soon';

  @override
  String get nutrition_select_category => 'Select a category or search above.';

  @override
  String get nutrition_cat_meat => 'Meat & Poultry';

  @override
  String get nutrition_cat_fish => 'Fish & Seafood';

  @override
  String get nutrition_cat_eggs => 'Eggs';

  @override
  String get nutrition_cat_dairy => 'Dairy';

  @override
  String get nutrition_cat_fruits => 'Fruits';

  @override
  String get nutrition_cat_vegetables => 'Vegetables';

  @override
  String get nutrition_cat_grains => 'Grains & Cereals';

  @override
  String get nutrition_cat_fats => 'Fats & Oils';

  @override
  String get nutrition_cat_nuts => 'Nuts & Seeds';

  @override
  String get nutrition_cat_sweets => 'Sweets & Desserts';

  @override
  String get nutrition_cat_drinks => 'Beverages';

  @override
  String get nutrition_cat_fastfood => 'Fast Food';

  @override
  String get nutrition_cat_processed => 'Processed Foods';

  @override
  String get nutrition_cat_readymeals => 'Ready Meals';

  @override
  String get nutrition_cat_sauces => 'Sauces & Seasonings';

  @override
  String get nutrition_cat_supplements => 'Supplements';

  @override
  String get hydration_title => 'Hydration';

  @override
  String get hydration_loading => 'Loading...';

  @override
  String get hydration_consumed => 'Water consumed';

  @override
  String hydration_remaining(String value) {
    return '${value}L remaining';
  }

  @override
  String get hydration_total_today => 'Total today';

  @override
  String get hydration_entries => 'Entries';

  @override
  String get hydration_goal_percent => '% of goal';

  @override
  String get hydration_custom_amount => 'Custom amount';

  @override
  String get hydration_remove_last => 'Remove last entry';

  @override
  String get hydration_log_error => 'Failed to log water';

  @override
  String get hydration_add_btn => 'Add';

  @override
  String get hydration_no_data => 'You haven\'t logged any water today.';

  @override
  String get hydration_remove_title => 'Remove water';

  @override
  String get hydration_too_small => 'Amount too small to remove here.';

  @override
  String hydration_removed(int amount) {
    return 'Removed: ${amount}ml';
  }

  @override
  String get hydration_remove_error => 'Failed to remove water';

  @override
  String get nutrition_search_error => 'Search error.';

  @override
  String get nutrition_search_type_prompt => 'Type to search foods.';

  @override
  String get nutrition_no_results => 'No results found.';

  @override
  String get nutrition_img_not_implemented =>
      'Image recognition not yet implemented';

  @override
  String get nutrition_search_food_title => 'Search Food';

  @override
  String get nutrition_search_hint => 'Search foods...';

  @override
  String get nutrition_popular_foods => 'Popular Foods';

  @override
  String nutrition_search_results_count(int count) {
    return 'Search Results ($count)';
  }

  @override
  String get nutrition_scan_title => 'Scan Barcode';

  @override
  String get nutrition_scan_hint => 'Point the camera at the barcode';

  @override
  String get nutrition_scan_auto => 'The code will be detected automatically';

  @override
  String get nutrition_scan_flash => 'Flash';

  @override
  String get nutrition_scan_camera_label => 'Camera';

  @override
  String get nutrition_tab_recent => 'Recent';

  @override
  String get nutrition_tab_favorites => 'Favorites';

  @override
  String get nutrition_tab_manual => 'Manual';

  @override
  String get nutrition_category_empty => 'No food found for this category.';

  @override
  String get nutrition_recent_empty => 'No recent foods.';

  @override
  String get nutrition_favorites_empty => 'No favorites saved yet.';

  @override
  String get nutrition_favorites_hint =>
      'Use \"Manual\" and check \"Save to favorites\".';

  @override
  String get nutrition_iqd_impact_label => 'DQI impact';

  @override
  String get nutrition_saving => 'Saving...';

  @override
  String nutrition_add_meal_btn(String mealType) {
    return 'Add $mealType';
  }

  @override
  String get nutrition_food_name_label => 'Food name';

  @override
  String get nutrition_essential_label => 'Essential';

  @override
  String get nutrition_calories => 'Calories';

  @override
  String get nutrition_carbs_short => 'Carbs';

  @override
  String get nutrition_iqd_quality_data => 'Quality data (DQI)';

  @override
  String get nutrition_fibers => 'Fiber';

  @override
  String get nutrition_save_favorites => 'Save to favorites';

  @override
  String get nutrition_set_portion => 'Set portion';

  @override
  String get nutrition_grams => 'Grams';

  @override
  String get nutrition_food_label => 'Food';

  @override
  String get nutrition_unit => 'Unit';

  @override
  String get nutrition_unit_weight_label => 'Weight of 1 unit:';

  @override
  String get nutrition_unit_short => 'Unit';

  @override
  String get nutrition_quantity_label => 'Quantity:';

  @override
  String get nutrition_update_quantity => 'Update quantity';

  @override
  String get nutrition_add_food_btn => 'Add food';

  @override
  String get nutrition_favorites_load_error => 'Could not load favorites.';

  @override
  String get nutrition_fill_one_macro =>
      'Fill in at least one nutritional value.';

  @override
  String get nutrition_create_error => 'Failed to create item.';

  @override
  String nutrition_save_error(String error) {
    return 'Error saving: $error';
  }

  @override
  String get nutrition_item_updated => 'Item updated successfully!';

  @override
  String get nutrition_food_added => 'Food added successfully!';

  @override
  String nutrition_fail(String error) {
    return 'Failed: $error';
  }

  @override
  String get nutrition_scan_hint_qr => 'Point at the food barcode/QR code';

  @override
  String get progress_title => 'Progress';

  @override
  String get progress_load_error => 'Failed to load progress data';

  @override
  String get progress_period_7d => 'Last 7 days';

  @override
  String get progress_period_30d => 'Last 30 days';

  @override
  String get progress_period_3m => 'Last 3 months';

  @override
  String get progress_period_1y => 'Last year';

  @override
  String get progress_tab_general => 'General';

  @override
  String get progress_tab_body => 'Body';

  @override
  String get progress_tab_workouts => 'Workouts';

  @override
  String get progress_tab_nutrition => 'Nutrition';

  @override
  String get progress_loading => 'Loading data...';

  @override
  String get progress_export_compiling =>
      'Compiling full report (Body, Workout, Nutrition)...';

  @override
  String get progress_no_data_period => 'No data for this period.';

  @override
  String get progress_export_error => 'Error generating report.';

  @override
  String get achievements_title => 'Achievements';

  @override
  String achievements_unlocked_of_total(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String get achievements_category_first_steps => 'First Steps';

  @override
  String get achievements_category_workouts => 'Workouts';

  @override
  String get achievements_category_strength => 'Strength';

  @override
  String get achievements_category_milestones => 'Milestones';

  @override
  String get achievements_category_nutrition => 'Nutrition';

  @override
  String get goals_create_dialog_title => 'Create new goal';

  @override
  String get goals_title_field => 'Goal title';

  @override
  String get goals_description_field => 'Description';

  @override
  String get goals_target_value_field => 'Goal (target value)';

  @override
  String get goals_unit_field => 'Unit';

  @override
  String get goals_category_field => 'Category';

  @override
  String get goals_category_weight => 'Weight';

  @override
  String get goals_category_workout => 'Workout';

  @override
  String get goals_category_strength => 'Strength';

  @override
  String get goals_category_endurance => 'Endurance';

  @override
  String get goals_category_general => 'General';

  @override
  String get goals_set_deadline => 'Set deadline (optional)';

  @override
  String goals_deadline_set(String date) {
    return 'Deadline: $date';
  }

  @override
  String get goals_fill_required => 'Fill in title, goal, and unit';

  @override
  String get goals_create_btn => 'Create goal';

  @override
  String get goals_create_success => 'Goal created successfully!';

  @override
  String get goals_section_title => 'Goals';

  @override
  String get goals_create_first_btn => 'Create first goal';

  @override
  String get goals_empty_title => 'No active goals';

  @override
  String get goals_empty_instruction => 'Create goals to track your journey';

  @override
  String get goals_update_progress_title => 'Update progress';

  @override
  String get goals_update_progress_btn => 'Update progress';

  @override
  String goals_current_value_field(String unit) {
    return 'Current value ($unit)';
  }

  @override
  String get goals_update_btn => 'Update';

  @override
  String get goals_update_success => 'Progress updated successfully!';

  @override
  String get goals_more_options => 'More options';

  @override
  String get goals_pause => 'Pause goal';

  @override
  String get goals_paused => 'Goal paused';

  @override
  String get goals_delete => 'Delete goal';

  @override
  String get goals_deleted => 'Goal deleted';

  @override
  String get goals_overdue => 'Overdue';

  @override
  String get goals_due_today => 'Due today';

  @override
  String goals_days_remaining(int days) {
    return '${days}d remaining';
  }

  @override
  String get photo_progress_title => 'Progress photo';

  @override
  String get photo_add_sheet_title => 'Add photo';

  @override
  String get photo_option_camera => 'Camera';

  @override
  String get photo_option_gallery => 'Gallery';

  @override
  String get photo_permission_title => 'Permission required';

  @override
  String get photo_delete_title => 'Remove photo?';

  @override
  String get photo_delete_message => 'This cannot be undone.';

  @override
  String get photo_delete_btn => 'Remove';

  @override
  String get photo_deleted => 'Photo removed.';

  @override
  String get photo_comparison_title => 'Progress comparison';

  @override
  String get photo_comparison_before => 'Before';

  @override
  String get photo_comparison_after => 'After';

  @override
  String get photo_close_btn => 'Close';

  @override
  String get photo_swap_btn => 'Swap';

  @override
  String get photo_empty_title => 'No photos yet';

  @override
  String get photo_empty_instruction =>
      'Take photos to track your transformation';

  @override
  String get photo_compare_btn => 'Compare progress';

  @override
  String get photo_tips_title => 'Tips';

  @override
  String get photo_tips_content =>
      '• Take photos in the same lighting and pose\n• Wear similar clothes for consistency\n• Shoot from front, side, and back\n• Schedule weekly photos';

  @override
  String get photo_saved => 'Photo saved successfully!';

  @override
  String get photo_need_two => 'Add at least 2 photos to compare';

  @override
  String get photo_add_semantics => 'Add photo';

  @override
  String get progress_overview_title => 'Progress summary';

  @override
  String progress_overview_period(int days) {
    return 'Last $days days';
  }

  @override
  String get progress_stat_workouts => 'Workouts';

  @override
  String get progress_stat_time => 'Time';

  @override
  String get progress_stat_time_unit => 'hours';

  @override
  String get progress_stat_badges => 'Badges';

  @override
  String get progress_stat_badges_unit => 'unlocked';

  @override
  String get progress_stat_streak => 'Streak';

  @override
  String get progress_stat_streak_unit => 'days';

  @override
  String get progress_stat_total => 'total';

  @override
  String get measurements_label_weight => 'Weight';

  @override
  String get measurements_label_body_fat => 'Body Fat';

  @override
  String get measurements_label_muscle_mass => 'Muscle Mass';

  @override
  String measurements_add_dialog_title(String label) {
    return 'Add $label';
  }

  @override
  String measurements_value_field(String unit) {
    return 'Value ($unit)';
  }

  @override
  String get measurements_notes_field => 'Notes (optional)';

  @override
  String get measurements_save_success => 'Data saved successfully';

  @override
  String get measurements_save_error => 'Failed to save data';

  @override
  String measurements_empty_title(String label) {
    return 'No $label data yet';
  }

  @override
  String get measurements_empty_instruction =>
      'Log a value to track your progress';

  @override
  String measurements_current_label(String label) {
    return 'Current · $label';
  }

  @override
  String get measurements_recent_title => 'Recent entries';

  @override
  String measurements_register_btn(String label) {
    return 'Log $label';
  }

  @override
  String measurements_time_days_ago(int days) {
    return '${days}d ago';
  }

  @override
  String measurements_time_hours_ago(int hours) {
    return '${hours}h ago';
  }

  @override
  String measurements_time_minutes_ago(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get measurements_time_now => 'Now';

  @override
  String get export_title => 'Export Progress';

  @override
  String get export_subtitle => 'Choose how you want to view your data';

  @override
  String get export_pdf_title => 'Official Report (PDF)';

  @override
  String get export_pdf_desc =>
      'Formatted document with history and brand design';

  @override
  String get export_csv_title => 'Data Spreadsheet (CSV)';

  @override
  String get export_csv_desc => 'Raw file for external analysis or backup';

  @override
  String get export_share_title => 'Share Summary';

  @override
  String get export_share_desc => 'Quick text for WhatsApp or social media';

  @override
  String get workout_progress_consistency => 'Consistency';

  @override
  String get workout_progress_less => 'Less';

  @override
  String get workout_progress_more => 'More';

  @override
  String workout_progress_tooltip(int count, String date) {
    return '$count workouts on $date';
  }

  @override
  String get workout_progress_completed => 'Completed';

  @override
  String get workout_progress_avg_duration => 'Avg duration';

  @override
  String get workout_progress_total_time => 'Total time';

  @override
  String get workout_progress_recent_title => 'Recent workouts';

  @override
  String get workout_progress_empty => 'No workouts yet';

  @override
  String get workout_progress_today => 'Today';

  @override
  String get workout_progress_yesterday => 'Yesterday';

  @override
  String workout_progress_days_ago(int days) {
    return '${days}d ago';
  }

  @override
  String get workout_progress_recently => 'Recently';

  @override
  String get nutrition_analytics_avg_daily => 'Daily average';

  @override
  String get nutrition_analytics_days_on_target => 'Days on target';

  @override
  String get nutrition_analytics_adherence_title => 'Diet adherence';

  @override
  String get nutrition_analytics_calorie_goal => 'Calorie goal';

  @override
  String get nutrition_analytics_no_recent_data => 'No recent data';

  @override
  String get nutrition_analytics_log_meals_hint =>
      'Log your meals to see the chart';

  @override
  String get nutrition_analytics_calorie_history => 'Calorie history';

  @override
  String get nutrition_analytics_goal_label => 'Goal';

  @override
  String get nutrition_analytics_macros_title => 'Macros for the period';

  @override
  String get nutrition_analytics_no_meals => 'No meals logged for this period';

  @override
  String get nutrition_analytics_iqd_title => 'DQI evolution';

  @override
  String get nutrition_analytics_iqd_subtitle => 'Diet quality index';

  @override
  String get nutrition_analytics_no_iqd => 'Not enough data for DQI';

  @override
  String get nutrition_analytics_meals_title => 'Meals — last 7 days';

  @override
  String get nutrition_analytics_no_meals_7d =>
      'No meals logged in the last 7 days';

  @override
  String get nutrition_analytics_today => 'Today';

  @override
  String get nutrition_analytics_protein => 'Protein';

  @override
  String get nutrition_analytics_carbs => 'Carbs';

  @override
  String get nutrition_analytics_fat => 'Fat';

  @override
  String get nutrition_analytics_pct_of_goal => '% of goal';

  @override
  String get nutrition_meal_type_cafe => 'Breakfast';

  @override
  String get nutrition_meal_type_almoco => 'Lunch';

  @override
  String get nutrition_meal_type_lanche => 'Snack';

  @override
  String get nutrition_meal_type_jantar => 'Dinner';

  @override
  String get nutrition_meal_type_outro => 'Other';

  @override
  String get profile_title => 'My profile';

  @override
  String get profile_error => 'Error loading profile';

  @override
  String get profile_plan_choose_title => 'Choose Your Plan';

  @override
  String get profile_plan_choose_subtitle => 'Unlock BLDR\'s full potential';

  @override
  String get profile_plan_popular_badge => 'POPULAR';

  @override
  String profile_plan_annual_prefix(String price) {
    return 'or $price';
  }

  @override
  String get profile_plan_current => 'Current Plan';

  @override
  String get profile_plan_choose_btn => 'Choose Plan';

  @override
  String profile_plan_load_error(String error) {
    return 'Error loading plans: $error';
  }

  @override
  String get profile_photo_change_title => 'Change profile photo';

  @override
  String get profile_photo_remove_btn => 'Remove Photo';

  @override
  String get profile_measurements_title => 'Body Measurements';

  @override
  String get profile_measurements_height => 'Height (cm)';

  @override
  String get profile_measurements_target_weight => 'Target Weight (kg)';

  @override
  String get profile_measurements_saved => 'Measurements saved!';

  @override
  String get profile_cancel_subscription_title => 'Cancel Subscription';

  @override
  String get profile_cancel_subscription_before =>
      'We\'re implementing automatic in-app cancellation for your subscription.\n\nIf you\'d like to cancel, please contact us at ';

  @override
  String get profile_cancel_subscription_after =>
      ' and we\'ll process your cancellation.\n\nThank you for your understanding — we\'ll miss you in the BLDR CLUB community.';

  @override
  String get profile_permission_title => 'Permission Required';

  @override
  String get profile_permission_body =>
      'Notifications are blocked in device settings. To re-enable them, go to the app settings.';

  @override
  String get profile_open_settings_btn => 'Open Settings';

  @override
  String get profile_updated => 'Profile updated successfully!';

  @override
  String profile_update_error(String error) {
    return 'Error updating profile: $error';
  }

  @override
  String get profile_photo_updated => 'Profile photo updated!';

  @override
  String profile_photo_update_error(String error) {
    return 'Error updating photo: $error';
  }

  @override
  String get profile_photo_removed => 'Profile photo removed!';

  @override
  String profile_photo_remove_error(String error) {
    return 'Error removing photo: $error';
  }

  @override
  String profile_camera_error(String error) {
    return 'Error using camera: $error';
  }

  @override
  String profile_gallery_error(String error) {
    return 'Error choosing image: $error';
  }

  @override
  String profile_notifications_error(String error) {
    return 'Error updating notifications: $error';
  }

  @override
  String get profile_plan_free => 'Free Plan';

  @override
  String get profile_plan_premium => 'Premium Plan';

  @override
  String profile_xp_bar_level(int level, int xp) {
    return 'Level $level · $xp XP';
  }

  @override
  String profile_xp_bar_next_level(int nextLevel, int xpNext) {
    return 'Level $nextLevel in $xpNext XP';
  }

  @override
  String profile_xp_bar_to_next(int toNext) {
    return '+$toNext XP to level up';
  }

  @override
  String get profile_stat_total_workouts => 'Total workouts';

  @override
  String get profile_stat_hours_trained => 'Hours trained';

  @override
  String get profile_stat_current_streak => 'Current streak';

  @override
  String get profile_stat_achievements => 'Achievements';

  @override
  String get profile_duels_title => 'Duels';

  @override
  String get profile_duels_wins => 'Wins';

  @override
  String get profile_duels_losses => 'Losses';

  @override
  String get profile_duels_win_rate => 'Win rate';

  @override
  String get profile_badges_section => 'Achievements';

  @override
  String get profile_next_achievement => 'Next achievement';

  @override
  String get profile_achievement_almost => 'Almost there!';

  @override
  String profile_achievement_do_workout_singular(int n) {
    return 'Do $n more workout';
  }

  @override
  String profile_achievement_do_workout_plural(int n) {
    return 'Do $n more workouts';
  }

  @override
  String profile_achievement_maintain_streak_singular(int n) {
    return 'Keep your streak for $n more day';
  }

  @override
  String profile_achievement_maintain_streak_plural(int n) {
    return 'Keep your streak for $n more days';
  }

  @override
  String profile_achievement_calorie_goal_singular(int n) {
    return 'Hit your calorie goal for $n more day';
  }

  @override
  String profile_achievement_calorie_goal_plural(int n) {
    return 'Hit your calorie goal for $n more days';
  }

  @override
  String profile_achievement_log_meal_singular(int n) {
    return 'Log $n more meal';
  }

  @override
  String profile_achievement_log_meal_plural(int n) {
    return 'Log $n more meals';
  }

  @override
  String profile_achievement_earn_xp(int n) {
    return 'Earn $n more XP';
  }

  @override
  String profile_achievement_reach_level(int n) {
    return 'Reach level $n in the Club';
  }

  @override
  String profile_achievement_complete_workout_singular(int n) {
    return 'Complete $n more workout';
  }

  @override
  String profile_achievement_complete_workout_plural(int n) {
    return 'Complete $n more workouts';
  }

  @override
  String get profile_achievement_keep_going => 'Keep pushing!';

  @override
  String get profile_weight_card_title => 'Weight · last 30 days';

  @override
  String get profile_see_all => 'See all →';

  @override
  String get profile_progress_section => 'Your progress';

  @override
  String get profile_stat_total_time => 'Total time';

  @override
  String profile_rank_position(int position) {
    return '#$position in ranking';
  }

  @override
  String get profile_sign_in_message =>
      'Check out my BLDR profile!\n\nJoin the BLDR CLUB community!';

  @override
  String get profile_notifications_enabled => 'Enabled';

  @override
  String get profile_notifications_disabled => 'Disabled';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_section_account => 'Account';

  @override
  String get settings_edit_profile => 'Edit profile';

  @override
  String get settings_edit_profile_subtitle => 'Name, email, phone';

  @override
  String get settings_share_profile => 'Share profile';

  @override
  String get settings_section_plan => 'Plan & subscription';

  @override
  String get settings_current_plan_row => 'Current plan';

  @override
  String get settings_manage_subscription => 'Manage subscription';

  @override
  String get settings_manage_subscription_subtitle =>
      'Payment, invoices, cancel';

  @override
  String get settings_section_workout => 'Workout';

  @override
  String get settings_workout_preferences => 'Workout preferences';

  @override
  String get settings_workout_preferences_subtitle =>
      'Update your initial preferences';

  @override
  String get settings_goals_row => 'Goals';

  @override
  String get settings_goals_subtitle => 'Weight, calories, macros';

  @override
  String get settings_section_app => 'App';

  @override
  String get settings_notifications_row => 'Notifications';

  @override
  String get settings_notifications_enabled => 'Enabled';

  @override
  String get settings_notifications_disabled => 'Disabled';

  @override
  String get settings_language_row => 'Language';

  @override
  String get settings_language_subtitle => 'Português, English, Italiano';

  @override
  String get settings_privacy_row => 'Privacy';

  @override
  String get settings_privacy_subtitle => 'Ranking and feed visibility';

  @override
  String get settings_section_integrations => 'Integrations';

  @override
  String get settings_whoop_synced => 'Recovery, Strain, and Sleep synced';

  @override
  String get settings_whoop_connected_badge => 'Connected';

  @override
  String get settings_whoop_disconnect_btn => 'Disconnect';

  @override
  String get settings_whoop_connect_subtitle => 'Connect your Whoop';

  @override
  String get settings_apple_health => 'Apple Health';

  @override
  String get settings_soon_badge => 'Coming soon';

  @override
  String get settings_watchables => 'Watches & wearables';

  @override
  String get settings_section_support => 'Support';

  @override
  String get settings_help_center => 'Help center';

  @override
  String get settings_terms => 'Terms of use';

  @override
  String get settings_privacy_policy_row => 'Privacy policy';

  @override
  String get settings_section_about => 'About';

  @override
  String get settings_version_row => 'Version';

  @override
  String settings_copyright(int year) {
    return '© $year BLDR Fitness. All rights reserved.';
  }

  @override
  String get settings_sign_out_row => 'Sign out';

  @override
  String get settings_delete_account_row => 'Delete account';

  @override
  String settings_version_footer(String version) {
    return 'BLDR · version $version';
  }

  @override
  String get settings_manage_sub_sheet_title => 'Manage subscription';

  @override
  String get settings_upgrade_btn => 'Upgrade';

  @override
  String get settings_upgrade_subtitle => 'Unlock premium features';

  @override
  String get settings_cancel_sub_btn => 'Cancel subscription';

  @override
  String get settings_cancel_sub_subtitle => 'End your BLDR CLUB subscription';

  @override
  String get settings_sign_out_dialog_title => 'Sign out';

  @override
  String get settings_sign_out_dialog_message =>
      'Are you sure you want to sign out?';

  @override
  String get settings_sign_out_dialog_confirm => 'Sign out';

  @override
  String settings_sign_out_error(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get settings_delete_account_dialog_title => 'Delete Account';

  @override
  String get settings_delete_account_dialog_message =>
      'Are you sure you want to delete your account?\n\nAll your data and your subscription will be permanently removed. This action cannot be undone.';

  @override
  String get settings_delete_account_dialog_confirm => 'Yes, Delete';

  @override
  String settings_delete_account_error(String error) {
    return 'Error deleting account: $error';
  }

  @override
  String settings_cancel_sub_error(String error) {
    return 'Error loading plans: $error';
  }

  @override
  String get goals_screen_title => 'Goals';

  @override
  String get goals_macros_exceed => 'Sum of macros exceeds calorie goal.';

  @override
  String get goals_saved => 'Goals saved successfully!';

  @override
  String get goals_section_weight => 'WEIGHT';

  @override
  String get goals_current_weight_label => 'Current weight';

  @override
  String get goals_editable_in_progress => 'Editable in Progress';

  @override
  String get goals_target_weight_label => 'Target weight';

  @override
  String get goals_pace_title => 'Pace';

  @override
  String get goals_pace_subtitle => 'Speed of progress toward target';

  @override
  String get goals_section_nutrition => 'NUTRITION';

  @override
  String get goals_calorie_goal_label => 'Daily calorie goal';

  @override
  String get goals_calorie_calculated => 'Calculated by HAVOK';

  @override
  String get goals_use_calculated => 'Use calculated';

  @override
  String get goals_customize => 'Customize';

  @override
  String get goals_macros_title => 'Macronutrients';

  @override
  String get goals_macro_protein => 'Protein';

  @override
  String get goals_macro_carbs => 'Carbs';

  @override
  String get goals_macro_fat => 'Fat';

  @override
  String goals_macro_pct_calories(String pct) {
    return '$pct% of calories';
  }

  @override
  String get goals_footer_note =>
      'Changes affect Dashboard, Nutrition, and HAVOK context.';

  @override
  String get goals_save_btn => 'Save';

  @override
  String get privacy_title => 'Privacy';

  @override
  String get privacy_nickname_required =>
      'Enter a nickname or use your real name.';

  @override
  String get privacy_saved => 'Privacy updated.';

  @override
  String get privacy_section_identity => 'IDENTITY IN RANKING AND FEED';

  @override
  String get privacy_name_toggle_title => 'Name in ranking and feed';

  @override
  String get privacy_name_active_label => 'Nickname';

  @override
  String get privacy_name_inactive_label => 'Real name';

  @override
  String get privacy_name_inactive_subtitle => 'Real name (default)';

  @override
  String get privacy_nickname_hint => 'Nickname (max. 20 chars)';

  @override
  String get privacy_photo_toggle_title => 'Profile photo visible';

  @override
  String get privacy_photo_active_subtitle => 'Visible to everyone';

  @override
  String get privacy_photo_inactive_subtitle => 'Squad members only';

  @override
  String get privacy_photo_active_label => 'Everyone';

  @override
  String get privacy_photo_inactive_label => 'Squad';

  @override
  String get privacy_section_feed => 'ACTIVITY FEED';

  @override
  String get privacy_feed_toggle_title => 'Appear in community feed';

  @override
  String get privacy_feed_active_subtitle =>
      'Your activities appear in the feed';

  @override
  String get privacy_feed_inactive_subtitle =>
      'Activities don\'t appear to others';

  @override
  String get privacy_yes => 'Yes';

  @override
  String get privacy_no => 'No';

  @override
  String get privacy_reactions_toggle_title => 'Allow reactions';

  @override
  String get privacy_reactions_subtitle =>
      'Others can react to your activities';

  @override
  String get privacy_section_ranking => 'RANKING';

  @override
  String get privacy_ranking_toggle_title => 'Participate in public ranking';

  @override
  String get privacy_ranking_active_subtitle => 'Appears in global ranking';

  @override
  String get privacy_ranking_inactive_subtitle =>
      'Hidden from global ranking (squad not affected)';

  @override
  String get privacy_legal_text =>
      'Your data is processed in accordance with our Privacy Policy.';

  @override
  String get privacy_legal_link => 'View policy →';

  @override
  String get privacy_save_btn => 'Save';

  @override
  String get language_sheet_title => 'App language';

  @override
  String get language_havok_note =>
      'Content generated by HAVOK will also be in the selected language.';

  @override
  String get language_pt_region => 'Brazil';

  @override
  String get language_en_region => 'United States';

  @override
  String get language_it_region => 'Italy';

  @override
  String get language_soon_badge => 'Presto';

  @override
  String get edit_profile_dialog_title => 'Edit Profile';

  @override
  String get edit_profile_name_label => 'Full Name';

  @override
  String get edit_profile_email_label => 'Email';

  @override
  String get edit_profile_email_tooltip => 'Email cannot be changed';

  @override
  String get edit_profile_phone_label => 'Phone (optional)';

  @override
  String get edit_profile_name_required => 'Name is required';

  @override
  String get edit_profile_save_btn => 'Save';

  @override
  String get edit_profile_cancel_btn => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get photo_camera_permission_body =>
      'Enable camera access in settings to record your progress.';

  @override
  String get photo_gallery_permission_body =>
      'Enable photo access in settings.';

  @override
  String get goals_create_semantics => 'Create goal';

  @override
  String get club_events_title => 'Events';

  @override
  String get club_announcements_title => 'Announcements';

  @override
  String get club_workouts_title => 'Workouts';

  @override
  String get club_workouts_subtitle => 'Library · Programs';

  @override
  String get club_sports_title => 'Sports';

  @override
  String get club_sports_subtitle => 'Run · Protocols';

  @override
  String get club_community_title => 'Community';

  @override
  String get club_community_subtitle => 'Feed · Challenges';

  @override
  String get club_competition_title => 'Competition';

  @override
  String get club_competition_subtitle => 'Squads · Operations';

  @override
  String get club_weekly_operation => 'WEEKLY OPERATION';

  @override
  String get club_operation_completed => 'COMPLETED ✓';

  @override
  String club_operation_progress(Object current, Object goal, String unit) {
    return '$current of $goal $unit';
  }

  @override
  String club_operation_xp_reward(Object xp) {
    return '+$xp XP on completion';
  }

  @override
  String club_level(Object level) {
    return 'Level $level';
  }

  @override
  String club_ranking_badge(Object position) {
    return '#$position in ranking';
  }

  @override
  String club_xp_progress(Object current, Object total) {
    return '$current / $total XP';
  }

  @override
  String get havok_sheet_title => 'HAVOK';

  @override
  String get havok_sheet_subtitle => 'YOUR BLDR COACH';

  @override
  String get havok_input_placeholder => 'Ask HAVOK…';

  @override
  String get havok_disclaimer =>
      'HAVOK is an AI and can make mistakes. It does not replace medical or nutritional guidance.';

  @override
  String get havok_error_open => 'Couldn\'t open the conversation.';

  @override
  String get havok_no_reply => 'HAVOK didn\'t respond. Try again.';

  @override
  String havok_workout_exercises_tap(Object count) {
    return '$count exercises · tap to view';
  }

  @override
  String get club_competition_hub_title => 'OPERATIONS CENTER';

  @override
  String get club_create_operation => 'CREATE\nOPERATION';

  @override
  String get club_be_the_leader => 'Be the leader.';

  @override
  String get club_join_now => 'JOIN\nNOW';

  @override
  String get club_enter_code => 'Paste the code.';

  @override
  String get club_game_modes_header => 'GAME MODES';

  @override
  String get club_game_mode_survivor => 'SURVIVOR';

  @override
  String get club_game_mode_alfa => 'ALPHA';

  @override
  String get club_game_mode_roadrunner => 'ROADRUNNER';

  @override
  String get club_game_mode_hustle => 'HUSTLE';

  @override
  String get club_survivor_description =>
      'Anyone who goes 2 days without training is automatically eliminated.';

  @override
  String get club_alfa_description =>
      'Whoever accumulates the most total XP wins — all workouts count.';

  @override
  String get club_roadrunner_description =>
      'Whoever accumulates the most distance running wins.';

  @override
  String get club_hustle_description =>
      'The workout doesn\'t matter, showing up does. Most training days wins.';

  @override
  String get club_my_active_squads => 'MY ACTIVE SQUADS';

  @override
  String get club_no_active_operation => 'No active operation.';

  @override
  String get club_community_tab => 'Community';

  @override
  String get club_challenges_tab => 'Challenges';

  @override
  String get club_ranking_week => 'Weekly ranking';

  @override
  String get club_see_all => 'See all ›';

  @override
  String get club_my_duels => 'YOUR DUELS';

  @override
  String get club_collective_challenges => 'COLLECTIVE CHALLENGES';

  @override
  String get club_create => 'Create';

  @override
  String get club_duel_history => 'DUEL HISTORY';

  @override
  String get club_no_active_duel => 'No active duel';

  @override
  String get club_go_to_ranking => 'Go to Ranking and challenge someone!';

  @override
  String get club_no_collective_challenge => 'No active collective challenge';

  @override
  String get club_create_first_challenge => 'Tap \"Create\" and be the first!';

  @override
  String get club_no_ended_duel => 'No ended duels yet.';

  @override
  String get club_recent_activity => 'Recent activity';

  @override
  String get club_no_recent_activity => 'No recent activity.';

  @override
  String get club_your_position => 'Your position';

  @override
  String club_xp_to_next_position(Object xp, Object pos) {
    return '+$xp XP for #$pos';
  }

  @override
  String club_morale_sent(String name) {
    return 'You sent some hype to $name! 👊🔥';
  }

  @override
  String get ranking_duel_accepted =>
      'Challenge ACCEPTED! The battle has begun. 🔥';

  @override
  String get ranking_duel_refused => 'Challenge refused.';

  @override
  String get ranking_win_snackbar => 'CONGRATS! You won the duel! 🏆';

  @override
  String get ranking_you_suffix => ' (You)';

  @override
  String get ranking_you_label => 'YOU';

  @override
  String get ranking_rival_label => 'RIVAL';

  @override
  String get ranking_vs => 'VS';

  @override
  String get ranking_challenge_received => 'CHALLENGE RECEIVED';

  @override
  String get ranking_challenge_prompt =>
      ' challenged you to a duel!\nAre you in or out?';

  @override
  String get ranking_refuse_btn => 'Refuse';

  @override
  String get ranking_accept_btn => 'ACCEPT';

  @override
  String get ranking_yourself_msg => 'That\'s you, champ! Keep focused. 🔥';

  @override
  String get ranking_duel_title => '⚔️ START DUEL';

  @override
  String get ranking_duel_subtitle => 'First to hit the goal wins';

  @override
  String get ranking_xp_goal => 'XP GOAL';

  @override
  String get ranking_deadline => 'DEADLINE';

  @override
  String get ranking_winner_label => 'Winner';

  @override
  String get ranking_deadline_label => 'Deadline';

  @override
  String get ranking_badge_label => 'Badge';

  @override
  String get ranking_duelista => 'Duelist';

  @override
  String ranking_duel_sent(Object xp, String name) {
    return '⚔️ $xp XP duel sent to $name!';
  }

  @override
  String get ranking_duel_send_error => 'Error sending challenge.';

  @override
  String ranking_who_bets(Object xp, String prazo) {
    return 'First to hit $xp XP in $prazo wins';
  }

  @override
  String ranking_start_duel_btn(Object xp) {
    return 'START $xp XP DUEL';
  }

  @override
  String get havok_loading => 'Loading...';

  @override
  String havok_hello(String name) {
    return 'Hey, $name';
  }

  @override
  String get havok_tagline => 'Ready to push your limits?';

  @override
  String get havok_generate_training => 'WORKOUT GENERATION';

  @override
  String get havok_generate_btn => 'GENERATE HAVOK WORKOUT';

  @override
  String get havok_error_generate => 'Error generating workout. Try again.';

  @override
  String get havok_guest => 'Guest';

  @override
  String get havok_user_default => 'User';

  @override
  String get havok_loading_step1 => 'Fetching your profile info...';

  @override
  String get havok_loading_step2 => 'Generating your personalized workout...';

  @override
  String get havok_loading_step3 => 'All done!';

  @override
  String get free_workout_title => 'FREE WORKOUT';

  @override
  String get free_workout_describe => 'Describe the workout you want';

  @override
  String get free_workout_hint => 'Type your command here...';

  @override
  String get free_workout_btn => 'GENERATE WITH HAVOK';

  @override
  String get workout_library_title => 'HAVOK LIBRARY';

  @override
  String get workout_library_empty =>
      'You haven\'t generated any workouts yet.';

  @override
  String get workout_library_go_hub => 'Go to the HAVOK Hub to create one.';

  @override
  String get workout_library_error =>
      'An error occurred while fetching your workouts.';

  @override
  String get workout_detail_save => 'Save to library';

  @override
  String get workout_detail_saved => 'Saved ✓';

  @override
  String get workout_detail_start_now => 'Start now';

  @override
  String get workout_detail_add_plan => 'Add to plan';

  @override
  String get workout_detail_which_day => 'Which day of the week?';

  @override
  String get club_my_workouts => 'My workouts';

  @override
  String get club_created_by_me => 'Created by me';

  @override
  String get club_from_trainer => 'From my trainer';

  @override
  String get club_start_workout_btn => 'Start workout';

  @override
  String get club_no_workout_created => 'No workouts created yet';

  @override
  String get club_create_first_workout =>
      'Create your first personalized workout';

  @override
  String get club_trainer_programs_soon => 'Coming soon';

  @override
  String get club_trainer_programs_soon_desc =>
      'Soon you\'ll be able to receive\nworkouts from your personal trainer.';

  @override
  String get club_programs_title => 'Club Programs';

  @override
  String get club_programs_subtitle =>
      'Structured sequences · Exclusive to BLDR CLUB';

  @override
  String get club_see_all_arrow => 'See all →';

  @override
  String get club_no_workout_found => 'No workout found.';

  @override
  String get club_fail_start => 'Failed to start workout';

  @override
  String get club_create_workout => 'Create workout';

  @override
  String get club_from_photo => 'From photo';

  @override
  String get club_trainer_workouts => 'Trainer workouts';

  @override
  String get club_programs_soon => 'Programs coming soon';

  @override
  String get club_cardio_saved => 'Cardio session saved! 🔥';

  @override
  String get club_camera => 'Camera';

  @override
  String get club_gallery => 'Gallery';

  @override
  String get club_no_exercise_in_photo =>
      'Could not identify exercises in the image. Try another photo.';

  @override
  String get club_analyzing_photo => 'Analyzing workout sheet…';

  @override
  String get club_start_btn => 'Start';

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_mark_read => 'Mark as read';

  @override
  String get notifications_empty => 'No notifications';

  @override
  String get notifications_up_to_date => 'You\'re all caught up!';

  @override
  String get notifications_now => 'Now';

  @override
  String get notifications_today => 'Today';

  @override
  String get notifications_yesterday => 'Yesterday';

  @override
  String get notifications_this_week => 'This week';

  @override
  String get notifications_older => 'Older';

  @override
  String get notifications_general => 'General';

  @override
  String get notifications_see_duel => 'View duel';

  @override
  String get notifications_see_ranking => 'View ranking';

  @override
  String get notifications_see_challenge => 'View challenge';

  @override
  String get sports_title => 'Sports & Performance';

  @override
  String get sports_active_protocols => 'Active protocols';

  @override
  String get sports_trackers => 'Trackers';

  @override
  String get sports_round_timer => 'Round Timer';

  @override
  String get sports_round_timer_subtitle =>
      'Boxing · MMA · Jiu-Jitsu · Muay Thai';

  @override
  String get sports_match_tracker => 'Match Tracker';

  @override
  String get sports_match_tracker_subtitle => 'Tennis · Padel · Beach Tennis';

  @override
  String get sports_detected => 'Detected sports';

  @override
  String get sports_other => 'Other';

  @override
  String get sports_recommended => 'Recommended for you';

  @override
  String get sports_challenge_havok => 'Challenge HAVOK';

  @override
  String get sports_generate_workout => 'Generate workout plan';

  @override
  String get sports_select_sport => 'Select a sport or type another';

  @override
  String get sports_other_sport_hint => 'Or type another sport…';

  @override
  String get sports_generate_strategy => 'Generate strategy';

  @override
  String get sports_havok_processing => 'HAVOK processing…';

  @override
  String get sports_creating_strategy =>
      'Creating a personalized performance strategy.';

  @override
  String get sports_weekly => 'Your week';

  @override
  String sports_day_of(Object current, Object total) {
    return 'Day $current of $total';
  }

  @override
  String sports_active_time(String time) {
    return 'Active time: $time';
  }

  @override
  String get sports_corridas_sync => 'Runs synced · others on this device only';

  @override
  String get profile_retry => 'Try again';

  @override
  String get profile_duel => 'Challenge to duel';

  @override
  String get profile_react => '👊 React';

  @override
  String get profile_react_sent => '👊 Reaction sent!';

  @override
  String profile_ranking_position(Object pos) {
    return '#$pos Ranking';
  }

  @override
  String get profile_workouts_label => 'Workouts';

  @override
  String get profile_streak_label => 'Streak';

  @override
  String get profile_duels_label => 'Duels';

  @override
  String get profile_wins => 'Wins';

  @override
  String get profile_losses => 'Losses';

  @override
  String get profile_winrate => 'Win rate';

  @override
  String get profile_achievements => 'ACHIEVEMENTS';

  @override
  String get profile_activity => 'RECENT ACTIVITY';

  @override
  String get profile_athlete_bldr => 'BLDR Athlete';

  @override
  String get profile_athlete => 'Athlete';

  @override
  String profile_level(Object level) {
    return 'Level $level';
  }

  @override
  String profile_xp_to_next(Object next, Object xp) {
    return 'Level $next in $xp XP';
  }

  @override
  String get join_squad_title => 'Join Operation';

  @override
  String get join_squad_subtitle => 'Paste the invite code (e.g. K9X-2M1).';

  @override
  String get join_squad_code_label => 'ACCESS CODE';

  @override
  String get join_squad_btn => 'JOIN NOW';

  @override
  String get join_squad_not_found => 'No Squad found with this code.';

  @override
  String get join_squad_already_member =>
      'You\'re already a member of this Squad!';

  @override
  String join_squad_welcome(String name) {
    return 'Welcome to Squad $name! 👊';
  }

  @override
  String get squad_settings_saved => 'Settings saved! ✅';

  @override
  String get squad_settings_error => 'Error saving.';

  @override
  String get squad_now_private => 'Squad is now PRIVATE 🔒';

  @override
  String get squad_now_public => 'Squad is now PUBLIC 🌍';

  @override
  String get squad_edit_title => 'Edit Operation';

  @override
  String get squad_name_label => 'Squad name';

  @override
  String get squad_mission_label => 'Mission (Description)';

  @override
  String get squad_cancel => 'CANCEL';

  @override
  String get squad_save => 'SAVE';

  @override
  String get squad_daily_mission => 'Daily Mission';

  @override
  String get squad_daily_challenge => 'Daily Challenge';

  @override
  String get squad_define => 'SET';

  @override
  String get squad_score_limits => 'Score Limits';

  @override
  String get squad_score_limits_desc =>
      'Maximum XP a user can earn per day to prevent abuse.';

  @override
  String get paywall_title => 'Train at your limit, not others\'';

  @override
  String get paywall_subtitle =>
      'Unlock BLDR Club: workouts, challenges, and community all in one place.';

  @override
  String paywall_trial_badge(String days) {
    return '$days DAYS FREE';
  }

  @override
  String paywall_save_percent(String percent) {
    return 'SAVE $percent%';
  }

  @override
  String get paywall_plan_weekly => 'Weekly';

  @override
  String get paywall_plan_weekly_badge => 'MOST FLEXIBLE';

  @override
  String get paywall_per_week => '/week';

  @override
  String get paywall_best_value => 'BEST VALUE';

  @override
  String get paywall_plan_monthly => 'Monthly';

  @override
  String get paywall_plan_annual => 'Annual';

  @override
  String paywall_monthly_equiv(String price) {
    return 'equivalent to $price/month';
  }

  @override
  String get paywall_benefits_title => 'Included in all plans';

  @override
  String get paywall_subscribe_weekly_btn => 'Subscribe to weekly plan';

  @override
  String get paywall_subscribe_annual_btn => 'Subscribe to annual plan';

  @override
  String paywall_start_trial_btn(String days) {
    return 'Start $days days free';
  }

  @override
  String get paywall_subscribe_monthly_btn => 'Subscribe to monthly plan';

  @override
  String get paywall_processing => 'Processing…';

  @override
  String get paywall_redeem => 'Redeem code';

  @override
  String get paywall_restore => 'Restore purchases';

  @override
  String get paywall_load_error =>
      'Could not load plans right now. Please try again in a moment.';

  @override
  String get paywall_billing_title => 'Billing details';

  @override
  String get paywall_billing_name_label => 'Full name';

  @override
  String get paywall_billing_email_label => 'Email';

  @override
  String get checkout_screen_title => 'BLDR Checkout';

  @override
  String get checkout_choose_plan_title => 'Choose Your Plan';

  @override
  String get checkout_choose_plan_subtitle =>
      'Select the plan that best fits your goals';

  @override
  String get checkout_billing_info_title => 'Billing Information';

  @override
  String get checkout_billing_info_subtitle =>
      'Fill in your details to continue';

  @override
  String get checkout_name_label => 'Full Name';

  @override
  String get checkout_email_label => 'Email';

  @override
  String get checkout_continue_payment_btn => 'Continue to Payment';

  @override
  String get checkout_payment_title => 'Complete Payment';

  @override
  String get checkout_payment_subtitle =>
      'Confirm your details and finalize your subscription';

  @override
  String get checkout_order_summary => 'Order Summary';

  @override
  String get checkout_billing_annual => 'Annual billing';

  @override
  String get checkout_billing_monthly => 'Monthly billing';

  @override
  String get checkout_coupon_title => 'Discount Coupon (Optional)';

  @override
  String get checkout_coupon_label => 'Coupon code';

  @override
  String get checkout_coupon_apply_btn => 'Apply';

  @override
  String checkout_coupon_applied(String code) {
    return 'Coupon \"$code\" applied!';
  }

  @override
  String get checkout_apple_payment_title => 'Payment via App Store';

  @override
  String get checkout_apple_payment_subtitle =>
      'You\'ll be charged through your Apple account.';

  @override
  String get checkout_subscribe_btn => 'Subscribe';

  @override
  String get checkout_redeem_btn => 'Redeem offer code';

  @override
  String get checkout_privacy_policy => 'Privacy Policy';

  @override
  String get checkout_terms_of_use => 'Terms of Use (EULA)';

  @override
  String get checkout_success_title => 'Success!';

  @override
  String get checkout_success_default_message =>
      'Your subscription has been activated successfully!';

  @override
  String get checkout_success_active_message =>
      'Subscription activated successfully!';

  @override
  String get checkout_apple_success_message =>
      'Subscription completed successfully!';

  @override
  String checkout_success_plan(String name) {
    return 'Plan: $name';
  }

  @override
  String checkout_field_required(String field) {
    return 'Please fill in the $field field';
  }

  @override
  String get checkout_email_invalid => 'Please enter a valid email';

  @override
  String get checkout_card_info_title => 'Card Information';

  @override
  String get checkout_card_data_label => 'Card Details';

  @override
  String get checkout_card_helper => 'Enter your card number, expiry, and CVV';

  @override
  String get checkout_processing => 'Processing...';

  @override
  String get checkout_finalize_btn => 'Complete Payment';

  @override
  String get checkout_toggle_save_badge => 'SAVE';

  @override
  String get checkout_plan_popular_badge => 'POPULAR';

  @override
  String get checkout_trial_badge => '🎉 7 DAYS FREE INCLUDED';

  @override
  String checkout_savings_amount(String amount) {
    return 'Save $amount';
  }

  @override
  String get splash_tagline => 'BUILD YOUR BEST SELF';

  @override
  String get splash_connection_error_title => 'Connection Error';

  @override
  String get splash_init_error_msg =>
      'Failed to initialize the app. Please try again.';

  @override
  String get splash_retry_btn => 'Try again';

  @override
  String get splash_connection_failed => 'Connection Failed';

  @override
  String get splash_retry_shortly => 'The retry option will appear shortly';

  @override
  String app_init_error(String details) {
    return 'Error starting the app. Details: $details';
  }

  @override
  String get feedback_title => 'Feedback';

  @override
  String get feedback_report_bug => 'Report a bug';

  @override
  String get feedback_send_suggestion => 'Send a suggestion';

  @override
  String get feedback_chip_bug => 'Bug';

  @override
  String get feedback_chip_suggestion => 'Suggestion';

  @override
  String get feedback_chip_complaint => 'Complaint';

  @override
  String get feedback_chip_other => 'Other';

  @override
  String get feedback_bldr_greeting => 'Hi! How can I help you today?';

  @override
  String get feedback_bldr_select_type =>
      'Choose the type of feedback to get started.';

  @override
  String get feedback_bldr_bug_step1 =>
      'Got it! Describe the bug in as much detail as possible. What happened?';

  @override
  String get feedback_bldr_bug_step2 =>
      'Would you like to include a screenshot? (optional)';

  @override
  String get feedback_bldr_suggestion_step1 =>
      'Great! What is your suggestion? Describe what you\'d like to see in the app.';

  @override
  String get feedback_bldr_suggestion_step2 =>
      'Would you like to include an image to illustrate? (optional)';

  @override
  String get feedback_bldr_complaint_step1 =>
      'We\'re sorry you\'re having issues. Describe what happened.';

  @override
  String get feedback_bldr_complaint_step2 =>
      'Would you like to include a screenshot? (optional)';

  @override
  String get feedback_bldr_other_step1 =>
      'Go ahead! What would you like to share?';

  @override
  String get feedback_bldr_other_step2 =>
      'Would you like to include an image? (optional)';

  @override
  String get feedback_bldr_sending => 'Sending your feedback...';

  @override
  String get feedback_bldr_success => 'Message sent!';

  @override
  String feedback_bldr_protocol(String protocolo) {
    return 'Protocol: #$protocolo';
  }

  @override
  String get feedback_bldr_thanks =>
      'Thank you for your feedback. Our team will review it shortly.';

  @override
  String get feedback_hint_message => 'Type your message...';

  @override
  String get feedback_add_screenshot => 'Add image';

  @override
  String get feedback_remove_screenshot => 'Remove';

  @override
  String get feedback_send => 'Send';

  @override
  String get feedback_skip => 'Skip';

  @override
  String get feedback_error_retry => 'Try again';

  @override
  String feedback_chars_remaining(int count) {
    return '$count / 500';
  }

  @override
  String get paywall_club_logo_semantics => 'Logo BLDR CLUB';

  @override
  String get paywall_elevate_performance => 'ELEVA LE TUE PRESTAZIONI';

  @override
  String get paywall_performance_subtitle =>
      'Allenamento, nutrizione e intelligenza connessi per aiutarti a migliorare davvero.';

  @override
  String get paywall_choose_plan => 'Scegli il tuo piano';

  @override
  String get paywall_weekly_description => 'Accesso completo per una settimana';

  @override
  String get paywall_monthly_description => 'Accesso completo, mese per mese';

  @override
  String get paywall_annual_description =>
      'Il modo migliore per migliorare tutto l\'anno';

  @override
  String get paywall_per_month => 'al mese';

  @override
  String get paywall_per_year => 'all\'anno';

  @override
  String get paywall_join_cta => 'Abbonati a BLDR CLUB';

  @override
  String paywall_selected_price_caption(String price) {
    return '$price · Annulla quando vuoi';
  }

  @override
  String get paywall_load_error_title =>
      'Non è stato possibile caricare i piani.';

  @override
  String get paywall_load_error_body => 'Riprova tra qualche istante.';

  @override
  String get paywall_feature => 'FUNZIONE';

  @override
  String get paywall_free => 'GRATIS';

  @override
  String get paywall_club => 'CLUB';

  @override
  String get paywall_comparison_semantics =>
      'Confronto tra il piano gratuito e BLDR CLUB';

  @override
  String get paywall_benefit_community => 'Community BLDR';

  @override
  String get paywall_benefit_havok => 'HAVOK AI';

  @override
  String get paywall_benefit_photo_workout => 'Allenamento da foto';

  @override
  String get paywall_benefit_analytics => 'Analisi';

  @override
  String get paywall_benefit_library => 'Libreria';

  @override
  String get paywall_benefit_nutrition => 'Nutrizione';

  @override
  String get paywall_limited => 'Limitato';

  @override
  String get paywall_complete => 'Completo';

  @override
  String get paywall_unavailable => '—';

  @override
  String get paywall_available => 'Disponibile';

  @override
  String get paywall_basic => 'Base';

  @override
  String get paywall_advanced => 'Avanzato';

  @override
  String get paywall_terms => 'Termini di utilizzo';

  @override
  String get paywall_privacy => 'Informativa sulla privacy';

  @override
  String get bootstrap_init_failed_title =>
      'Non è stato possibile avviare BLDR.';

  @override
  String get bootstrap_init_failed_body =>
      'Controlla la connessione e riprova.';

  @override
  String get paywall_sign_in_required => 'Accedi per continuare.';

  @override
  String get paywall_options_unavailable =>
      'Le opzioni di abbonamento non sono ancora disponibili.';

  @override
  String get paywall_options_retry_later =>
      'Le opzioni di abbonamento non sono ancora disponibili. Riprova più tardi.';

  @override
  String get paywall_option_unavailable =>
      'Questa opzione di abbonamento non è disponibile.';

  @override
  String get paywall_access_confirmation_failed =>
      'Non è stato possibile confermare l\'accesso a BLDR CLUB.';

  @override
  String get paywall_payment_pending =>
      'Il pagamento è in attesa della conferma dello store.';

  @override
  String get paywall_redeem_unavailable =>
      'Il riscatto del codice sarà disponibile quando le opzioni di abbonamento saranno caricate.';

  @override
  String get paywall_restore_unavailable =>
      'Il ripristino sarà disponibile quando le opzioni di abbonamento saranno caricate.';

  @override
  String get paywall_restore_after_update =>
      'Il ripristino sarà disponibile dopo l\'aggiornamento degli abbonamenti.';

  @override
  String get havok_entry_semantics => 'Apri HAVOK';

  @override
  String dashboard_v2_level_xp(String current, String target) {
    return '$current / $target';
  }

  @override
  String get dashboard_v2_workout_today_label => 'ALLENAMENTO DI OGGI';

  @override
  String get dashboard_v2_start_workout_cta => 'INIZIA ALLENAMENTO';

  @override
  String dashboard_v2_exercises_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esercizi',
      one: '$count esercizio',
    );
    return '$_temp0';
  }

  @override
  String dashboard_v2_workout_duration(int minutes) {
    return '~$minutes min';
  }

  @override
  String dashboard_v2_calories_of_target(String target) {
    return 'di $target kcal';
  }

  @override
  String get whoop_card_today_caps => 'OGGI';

  @override
  String get wearable_connect_label => 'LE TUE INTEGRAZIONI';

  @override
  String get wearable_connect_title_first => 'Collega il tuo wearable';

  @override
  String get wearable_connect_title_other => 'Collega un altro dispositivo';

  @override
  String get wearable_connect_body =>
      'Monitora sonno, recupero e attività con i dati WHOOP.';

  @override
  String get wearable_connect_cta => 'COLLEGA DISPOSITIVO';

  @override
  String get whoop_unavailable_title => 'Dati non disponibili';

  @override
  String get whoop_unavailable_body =>
      'Non abbiamo ancora ricevuto i dati di oggi.';

  @override
  String get whoop_unavailable_cta => 'VERIFICA CONNESSIONE';

  @override
  String get garmin_body_battery => 'BODY BATTERY';

  @override
  String get garmin_resting_hr => 'FC A RIPOSO';

  @override
  String get garmin_sleep => 'SONNO';

  @override
  String get garmin_footer => 'Dati Garmin · aggiornati oggi';

  @override
  String get havok_insight_label => 'HAVOK · INSIGHT';

  @override
  String get havok_insight_chat_cta => 'PARLA CON HAVOK';

  @override
  String get havok_insight_dismiss_semantics => 'Ignora insight';

  @override
  String wearable_stack_position(int index, int total) {
    return 'Scheda $index di $total';
  }

  @override
  String get dashboard_rest_title => 'Giorno di riposo';

  @override
  String get dashboard_rest_subtitle =>
      'Oggi si recupera per tornare più forti.';

  @override
  String get dashboard_rest_meta => 'Il recupero fa parte dell\'evoluzione';

  @override
  String get dashboard_rest_cta => 'VEDI IL MIO PIANO';

  @override
  String get dashboard_noplan_title => 'Nessun allenamento pianificato';

  @override
  String get dashboard_noplan_subtitle =>
      'Organizza la tua settimana per iniziare.';

  @override
  String get dashboard_noplan_meta => 'Il tuo prossimo allenamento inizia qui';

  @override
  String get dashboard_noplan_cta => 'CREA IL MIO PIANO';

  @override
  String get dashboard_v2_in_progress_label => 'ALLENAMENTO IN CORSO';

  @override
  String get dashboard_v2_done_label => 'ALLENAMENTO COMPLETATO';

  @override
  String get dashboard_v2_resume_cta => 'RIPRENDI ALLENAMENTO';

  @override
  String dashboard_v2_exercises_progress(int done, int total) {
    return '$done di $total esercizi';
  }

  @override
  String get dashboard_v2_done_duration => 'DURATA';

  @override
  String get dashboard_v2_done_sets => 'SERIE';

  @override
  String get dashboard_v2_done_volume => 'VOLUME';

  @override
  String get dashboard_v2_done_via_whoop => 'Completato via WHOOP';

  @override
  String get cw_eyebrow => 'CREA ALLENAMENTO';

  @override
  String get cw_title => 'Crea il tuo allenamento';

  @override
  String get cw_subtitle => 'Inizia dalle basi. I dettagli li regoli dopo.';

  @override
  String get cw_name_label => 'NOME ALLENAMENTO';

  @override
  String get cw_name_hint => 'Nome allenamento';

  @override
  String get cw_type_label => 'TIPO DI ALLENAMENTO';

  @override
  String get cw_type_strength => 'Pesi';

  @override
  String get cw_type_hiit => 'HIIT';

  @override
  String get cw_type_cardio => 'Indoor Cardio';

  @override
  String get cw_type_yoga => 'Yoga';

  @override
  String get cw_type_pilates => 'Pilates';

  @override
  String get cw_type_hyrox => 'Hyrox';

  @override
  String get cw_soon => 'In arrivo';

  @override
  String get cw_add_exercises => 'AGGIUNGI ESERCIZI';

  @override
  String get cw_setup_hint =>
      'Imposti serie, ripetizioni e recupero dopo aver scelto gli esercizi.';

  @override
  String get cw_build_title => 'Componi allenamento';

  @override
  String cw_build_eyebrow(String name) {
    return '$name · PESI';
  }

  @override
  String cw_selected_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionati',
      one: '$count selezionato',
    );
    return '$_temp0';
  }

  @override
  String get cw_create => 'CREA';

  @override
  String get cw_hud_exercises => 'ESERCIZI';

  @override
  String get cw_hud_sets => 'SERIE';

  @override
  String get cw_hud_minutes => 'MINUTI';

  @override
  String get cw_hud_avg_rest => 'RECUPERO MEDIO';

  @override
  String get cw_hud_helper => 'Si aggiorna con esercizi e preferenze';

  @override
  String get cw_selected_header => 'SELEZIONATI';

  @override
  String get cw_selected_hint => 'tocca i valori per modificare';

  @override
  String get cw_value_sets => 'SERIE';

  @override
  String get cw_value_reps => 'RIP.';

  @override
  String get cw_value_rest => 'REC.';

  @override
  String get cw_personalize => 'PERSONALIZZA SERIE';

  @override
  String get cw_advanced_hint => 'Regola carico e ripetizioni per serie';

  @override
  String get cw_add_set => 'AGGIUNGI SERIE';

  @override
  String get cw_add_exercise => 'AGGIUNGI ESERCIZIO';

  @override
  String get cw_add_exercise_hint =>
      'Cerca e seleziona esercizi nella libreria';

  @override
  String get cw_sheet_title => 'Aggiungi esercizi';

  @override
  String get cw_search_hint => 'Cerca esercizio';

  @override
  String get cw_all_exercises => 'TUTTI GLI ESERCIZI';

  @override
  String cw_exercise_count(int count) {
    return '$count esercizi';
  }

  @override
  String cw_add_n(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'AGGIUNGI $count ESERCIZI',
      one: 'AGGIUNGI $count ESERCIZIO',
    );
    return '$_temp0';
  }

  @override
  String get cw_filter_all => 'Tutti';

  @override
  String get cw_filter_back => 'Schiena';

  @override
  String get cw_filter_biceps => 'Bicipiti';

  @override
  String get cw_filter_chest => 'Petto';

  @override
  String get cw_filter_shoulders => 'Spalle';

  @override
  String get cw_filter_legs => 'Gambe';

  @override
  String get cw_filter_triceps => 'Tricipiti';

  @override
  String get cw_filter_core => 'Core';

  @override
  String get cw_filter_glutes => 'Glutei';

  @override
  String get cw_set_edit => 'Modifica serie';

  @override
  String get cw_set_remove => 'Rimuovi serie';

  @override
  String get cw_edit_sets_title => 'Serie';

  @override
  String get cw_edit_reps_title => 'Ripetizioni';

  @override
  String get cw_edit_rest_title => 'Recupero';

  @override
  String get cw_confirm => 'Conferma';

  @override
  String get cw_overwrite_title => 'Sostituire le serie personalizzate?';

  @override
  String get cw_overwrite_body =>
      'Le serie di questo esercizio hanno valori diversi. Il nuovo valore verrà applicato a tutte.';

  @override
  String get cw_overwrite_confirm => 'Sostituisci';

  @override
  String get cw_cancel => 'Annulla';

  @override
  String get hub_tab_workout => 'Allenamento';

  @override
  String get hub_tab_sports => 'Sport';

  @override
  String get hub_search => 'Cerca';

  @override
  String get hub_today_label => 'Allenamento di oggi';

  @override
  String get hub_today_hint => 'Tocca per cambiare allenamento';

  @override
  String get hub_start => 'Inizia allenamento';

  @override
  String get hub_done => 'Completato';

  @override
  String get hub_done_sub => 'Allenamento completato';

  @override
  String hub_meta(int count, int minutes) {
    return '$count esercizi • ~$minutes min';
  }

  @override
  String get hub_week_title => 'LA MIA SETTIMANA';

  @override
  String get hub_week_see => 'Vedi settimana';

  @override
  String get hub_week_workouts => 'Allenamenti';

  @override
  String get hub_week_extras => 'Extra';

  @override
  String get hub_week_xp => 'XP';

  @override
  String get hub_my_workouts => 'I MIEI ALLENAMENTI';

  @override
  String get hub_create => 'Crea allenamento';

  @override
  String get hub_from_photo => 'Da foto';

  @override
  String hub_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allenamenti',
      one: '$count allenamento',
    );
    return '$_temp0';
  }

  @override
  String hub_card_stats(int count, int minutes) {
    return '$count esercizi · ~$minutes min';
  }

  @override
  String get hub_empty_title => 'Nessun allenamento creato';

  @override
  String get hub_empty_sub => 'Crea il tuo primo allenamento';

  @override
  String get hub_explore => 'ESPLORA';

  @override
  String get hub_explore_club => 'BLDR CLUB';

  @override
  String get hub_explore_club_sub => 'Funzioni esclusive';

  @override
  String get hub_explore_library => 'LIBRERIA BLDR';

  @override
  String get hub_explore_library_sub => 'Allenamenti creati dal team BLDR';

  @override
  String get hub_explore_programs => 'Programmi';

  @override
  String get hub_explore_programs_sub => 'Programmi strutturati';

  @override
  String get hub_library_button => 'Libreria di allenamenti';

  @override
  String get hub_library_tip => 'Esplora e crea i tuoi allenamenti qui.';

  @override
  String get hub_menu_library_title => 'LIBRERIA BLDR';

  @override
  String get hub_menu_library_sub =>
      'Una libreria di allenamenti creati per te. Scegli, aggiungi,';

  @override
  String get hub_menu_library_highlight => 'costruisci';

  @override
  String get hub_menu_programs_title => 'PROGRAMMI DI ALLENAMENTO';

  @override
  String get hub_menu_programs_sub =>
      'Sequenze strutturate di esercizi con obiettivi specifici.';

  @override
  String get hub_menu_create_title => 'CREA ALLENAMENTO';

  @override
  String get hub_menu_create_sub => 'Crea il tuo allenamento. Scegli tu come.';

  @override
  String get hub_menu_photo_title => 'IMPORTA DA FOTO';

  @override
  String get hub_menu_photo_sub =>
      'Trasforma la tua scheda in un allenamento BLDR.';

  @override
  String hub_card_exercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esercizi',
      one: '$count esercizio',
    );
    return '$_temp0';
  }

  @override
  String hub_card_minutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get hub_card_options => 'Opzioni allenamento';

  @override
  String get hub_card_edit => 'Modifica';

  @override
  String get hub_empty_cta => 'CREA ALLENAMENTO';

  @override
  String get ed_eyebrow => 'MODIFICA ALLENAMENTO';

  @override
  String get ed_save => 'SALVA';

  @override
  String get ed_name_label => 'NOME ALLENAMENTO';

  @override
  String get ed_category_label => 'CATEGORIA';

  @override
  String get ed_section => 'ESERCIZI';

  @override
  String get ed_default => 'STANDARD DELL\'ESERCIZIO';

  @override
  String get ed_sets_header => 'SERIE · PERSONALIZZAZIONE OPZIONALE';

  @override
  String ed_chip_sets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serie',
      one: '$count serie',
    );
    return '$_temp0';
  }

  @override
  String ed_chip_reps(String reps) {
    return '$reps rip.';
  }

  @override
  String ed_default_rest(String rest) {
    return '$rest recupero';
  }

  @override
  String get ed_remove_exercise => 'Rimuovi esercizio';

  @override
  String get ed_edit_name => 'Modifica nome';

  @override
  String get ed_options => 'Opzioni esercizio';

  @override
  String get ed_cat_strength => 'Forza';

  @override
  String get ed_cat_hiit => 'HIIT';

  @override
  String get ed_cat_cardio => 'Cardio';

  @override
  String get ed_cat_mobility => 'Mobilità';

  @override
  String get ed_cat_mixed => 'Misto';

  @override
  String get aw_hr => 'FC';

  @override
  String get aw_bpm => 'BPM';

  @override
  String get aw_kcal => 'KCAL';

  @override
  String aw_set_of(int total) {
    return 'di $total';
  }

  @override
  String get aw_workout => 'ALLENAMENTO';

  @override
  String get aw_current => 'ESERCIZIO ATTUALE';

  @override
  String aw_set_badge(int current, int total) {
    return 'SERIE $current/$total';
  }

  @override
  String get aw_execution => 'ESECUZIONE';

  @override
  String aw_target(int reps) {
    return 'OBIETTIVO  $reps rip.';
  }

  @override
  String get aw_next_set => 'LA TUA PROSSIMA SERIE';

  @override
  String get aw_load => 'CARICO';

  @override
  String get aw_reps => 'RIP.';

  @override
  String get aw_rest => 'RECUPERO';

  @override
  String get aw_add15 => '+15 s';

  @override
  String get aw_confirm => 'COMPLETA SERIE';

  @override
  String get aw_next => 'PROSSIMO';

  @override
  String get aw_last => 'Fine allenamento';

  @override
  String get aw_pause => 'Metti in pausa';

  @override
  String get aw_sheet_load => 'REGOLA CARICO';

  @override
  String get aw_sheet_reps => 'REGOLA RIPETIZIONI';

  @override
  String get sm_done_badge => 'COMPLETATO';

  @override
  String get sm_message => 'Ottima sessione. Ecco cosa hai costruito oggi.';

  @override
  String get sm_session => 'RIEPILOGO SESSIONE';

  @override
  String get sm_duration => 'DURATA';

  @override
  String get sm_volume => 'VOLUME';

  @override
  String get sm_kg => 'KG';

  @override
  String get sm_sets => 'SERIE';

  @override
  String get sm_exercises => 'ESERCIZI';

  @override
  String get sm_highlights => 'IN EVIDENZA';

  @override
  String get sm_new_pr => 'NUOVO PR';

  @override
  String sm_pr_value(String exercise, String kg) {
    return '$exercise · $kg kg';
  }

  @override
  String sm_pr_delta(String kg) {
    return '+$kg kg rispetto al record precedente';
  }

  @override
  String get sm_xp => 'XP GUADAGNATI';

  @override
  String get sm_xp_hint => 'in questa sessione';

  @override
  String get sm_muscles => 'MUSCOLI ALLENATI';

  @override
  String get sm_emphasis_back => 'Enfasi posteriore';

  @override
  String get sm_emphasis_front => 'Enfasi anteriore';

  @override
  String sm_phrase_two(String a, String b) {
    return '$a e $b hanno ricevuto la maggior parte dello stimolo.';
  }

  @override
  String sm_phrase_one(String a) {
    return '$a ha ricevuto la maggior parte dello stimolo.';
  }

  @override
  String get sm_level_high => 'ALTO';

  @override
  String get sm_level_moderate => 'MODERATO';

  @override
  String get sm_share => 'CONDIVIDI ALLENAMENTO';

  @override
  String get sm_finish => 'FINE';

  @override
  String get sh_title => 'CONDIVIDI';

  @override
  String get sh_subtitle => 'Scegli come il tuo allenamento va nella Story';

  @override
  String get sh_tab_overlay => 'OVERLAY';

  @override
  String get sh_tab_card => 'CARD';

  @override
  String get sh_preview_overlay => 'ANTEPRIMA OVERLAY';

  @override
  String get sh_preview_card => 'ANTEPRIMA CARD';

  @override
  String get sh_transparent => 'SFONDO TRASPARENTE';

  @override
  String get sh_transparent_note =>
      'Il contenuto sopra viene esportato con sfondo trasparente.';

  @override
  String get sh_card_hint => 'Esportato a 1080 × 1920';

  @override
  String get sh_overlay_title => 'Overlay essenziale';

  @override
  String get sh_overlay_body =>
      'Nome, Muscle Map e metriche. Niente card, PR o informazioni ridondanti.';

  @override
  String get sh_card_title => 'Card editoriale BLDR';

  @override
  String get sh_card_body =>
      'Muscle Map in primo piano, metriche integrate e meno linguaggio d\'interfaccia.';

  @override
  String get sh_share => 'CONDIVIDI';

  @override
  String get sh_sharing => 'GENERAZIONE IMMAGINE…';

  @override
  String get sh_note => 'Formato ottimizzato per le Instagram Stories';

  @override
  String get sh_publish => 'Pubblica nella community';

  @override
  String get sh_completed => 'WORKOUT COMPLETED';

  @override
  String get sh_duration => 'DURATA';

  @override
  String get sh_volume => 'VOLUME';

  @override
  String get sh_sets => 'SERIE';

  @override
  String get sh_share_text => 'Allenamento completato su BLDR';

  @override
  String get sh_share_error =>
      'L\'immagine è stata creata, ma non è stato possibile aprire la condivisione.';

  @override
  String get sh_export_error => 'Impossibile creare l\'immagine. Riprova.';

  @override
  String get wk_extra_done_title => 'Attività completata';

  @override
  String wk_workout_done(String name) {
    return '$name — completato.';
  }

  @override
  String wk_extra_done(String name) {
    return '$name — completata.';
  }

  @override
  String get wk_extra_also => 'Anche l\'attività extra è stata registrata.';

  @override
  String get wk_workout_fallback => 'Allenamento';

  @override
  String ed_set_title(int n) {
    return 'SERIE $n';
  }

  @override
  String sm_more_prs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n PR',
      one: '+1 PR',
    );
    return '$_temp0';
  }

  @override
  String get sm_less_prs => 'Mostra meno';

  @override
  String get wd_eyebrow => 'DETTAGLI ALLENAMENTO';

  @override
  String get wd_duration => 'DURATA';

  @override
  String get wd_exercises => 'ESERCIZI';

  @override
  String get wd_volume => 'VOLUME';

  @override
  String get wd_last_time => 'ULTIMA VOLTA';

  @override
  String get wd_muscle_map => 'MUSCLE MAP';

  @override
  String wd_minutes(int n) {
    return '$n min';
  }

  @override
  String wd_ex_count(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n esercizi',
      one: '1 esercizio',
    );
    return '$_temp0';
  }

  @override
  String wd_sets_count(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n serie',
      one: '1 serie',
    );
    return '$_temp0';
  }

  @override
  String wd_reps(String range) {
    return '$range rip.';
  }

  @override
  String get wd_start => 'INIZIA ALLENAMENTO';

  @override
  String get wd_preview_note => 'Anteprima · modifica dal menu';

  @override
  String get wd_edit => 'Modifica allenamento';

  @override
  String get wd_duplicate => 'Duplica allenamento';

  @override
  String get wd_delete => 'Elimina allenamento';

  @override
  String get wd_delete_title => 'Eliminare l\'allenamento?';

  @override
  String wd_delete_body(String name) {
    return '$name verrà rimosso dai tuoi allenamenti. L\'azione non può essere annullata.';
  }

  @override
  String get wd_error => 'Impossibile caricare l\'allenamento.';

  @override
  String get wd_retry => 'Riprova';

  @override
  String get wd_empty => 'Questo allenamento non ha ancora esercizi.';

  @override
  String get wd_options => 'Opzioni allenamento';

  @override
  String get ex_title => 'ESERCIZIO';

  @override
  String get ex_equipment => 'ATTREZZATURA';

  @override
  String get ex_sets => 'SERIE';

  @override
  String get ex_how => 'COME ESEGUIRE';

  @override
  String get ex_tip => 'CONSIGLIO DI ESECUZIONE';

  @override
  String get ex_back => 'TORNA ALL\'ALLENAMENTO';

  @override
  String wd_copy_name(String name) {
    return '$name (copia)';
  }

  @override
  String get wd_duplicated => 'Allenamento duplicato';

  @override
  String get wd_duplicate_error => 'Impossibile duplicare l\'allenamento.';

  @override
  String get ms_title => 'LA MIA SETTIMANA';

  @override
  String get ms_subtitle => 'TOCCA O TRASCINA PER MODIFICARE';

  @override
  String ms_workouts_planned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n allenamenti programmati',
      one: '1 allenamento programmato',
    );
    return '$_temp0';
  }

  @override
  String ms_rest_days(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni di riposo',
      one: '1 giorno di riposo',
    );
    return '$_temp0';
  }

  @override
  String get ms_instruction =>
      'TRASCINA O TOCCA UN ALLENAMENTO PER RIORGANIZZARE';

  @override
  String get ms_read_only => 'SETTIMANA PASSATA · SOLA LETTURA';

  @override
  String get ms_club_hint => 'LE MODIFICHE SETTIMANALI SONO BLDR CLUB';

  @override
  String get ms_state_today => 'OGGI';

  @override
  String get ms_state_planned => 'PREVISTO';

  @override
  String get ms_state_free => 'LIBERO';

  @override
  String get ms_state_done => 'FATTO';

  @override
  String get ms_state_missed => 'SALTATO';

  @override
  String get ms_state_in_progress => 'IN CORSO';

  @override
  String get ms_rest => 'RIPOSO';

  @override
  String get ms_free_day => 'Giorno libero';

  @override
  String get ms_add_workout => 'Aggiungi allenamento';

  @override
  String get ms_management => 'GESTIONE';

  @override
  String get ms_edit_plan => 'MODIFICA PIANO';

  @override
  String get ms_register_extra => 'REGISTRA EXTRA';

  @override
  String get ms_footer =>
      'Tocca per gestire · tieni premuta la maniglia per trascinare';

  @override
  String get ms_workout_fallback => 'Allenamento';

  @override
  String get ms_actions_title => 'Azioni del giorno';

  @override
  String get ms_swap => 'Cambia allenamento';

  @override
  String get ms_swap_sub => 'Scegli un altro allenamento del piano';

  @override
  String get ms_move => 'Sposta a un altro giorno';

  @override
  String get ms_move_sub => 'Riprogramma questo allenamento';

  @override
  String get ms_rest_action => 'Trasforma in riposo';

  @override
  String get ms_rest_action_sub =>
      'Togli da questo giorno senza eliminare l\'allenamento';

  @override
  String get ms_start => 'Inizia allenamento';

  @override
  String get ms_start_sub => 'Inizia ora questo allenamento';

  @override
  String get ms_swap_hint => 'scegli un allenamento del piano';

  @override
  String get ms_confirm_swap => 'CONFERMA CAMBIO';

  @override
  String get ms_add_title => 'Aggiungi allenamento';

  @override
  String get ms_confirm_add => 'AGGIUNGI ALLENAMENTO';

  @override
  String get ms_move_title => 'Sposta allenamento';

  @override
  String get ms_move_hint => 'seleziona il giorno di destinazione';

  @override
  String ms_dest_busy(String name) {
    return '$name · occupato';
  }

  @override
  String get ms_dest_free => 'Riposo · libero';

  @override
  String get ms_dest_note =>
      'Giorno occupato: gli allenamenti si scambieranno.';

  @override
  String get ms_scope_title => 'APPLICA A';

  @override
  String get ms_scope_week => 'Solo questa settimana';

  @override
  String get ms_scope_all => 'Tutte le settimane';

  @override
  String get ms_no_templates =>
      'Non hai ancora allenamenti. Creane uno in Allenamenti.';

  @override
  String get ms_club_section => 'BLDR CLUB';

  @override
  String get ms_saved_title => 'Settimana aggiornata';

  @override
  String ms_saved_moved(String name, String day) {
    return '$name spostato a $day';
  }

  @override
  String ms_saved_swapped(String a, String b) {
    return '$a e $b si sono scambiati';
  }

  @override
  String ms_saved_rest(String day) {
    return '$day ora è riposo';
  }

  @override
  String ms_saved_set(String name, String day) {
    return '$name il $day';
  }

  @override
  String get ms_undo => 'ANNULLA';

  @override
  String get ms_save_error =>
      'Impossibile salvare. La settimana è stata ripristinata.';

  @override
  String get ms_undo_error => 'Impossibile annullare.';

  @override
  String get ms_soon => 'Presto';

  @override
  String get ms_split_label => 'DIVISIONE';

  @override
  String get ms_days_label => 'GIORNI DELLA SETTIMANA';

  @override
  String ms_days_summary(int t, int r) {
    return '$t allenamenti · $r riposi';
  }

  @override
  String get ms_prev_week => 'Settimana precedente';

  @override
  String get ms_next_week => 'Settimana successiva';

  @override
  String get ms_weekdays_short => 'LUN,MAR,MER,GIO,VEN,SAB,DOM';

  @override
  String get ms_weekdays_long =>
      'lunedì,martedì,mercoledì,giovedì,venerdì,sabato,domenica';

  @override
  String get ms_weekdays_letter => 'L,M,M,G,V,S,D';

  @override
  String get ms_months =>
      'GENNAIO,FEBBRAIO,MARZO,APRILE,MAGGIO,GIUGNO,LUGLIO,AGOSTO,SETTEMBRE,OTTOBRE,NOVEMBRE,DICEMBRE';

  @override
  String get ms_months_short =>
      'GEN,FEB,MAR,APR,MAG,GIU,LUG,AGO,SET,OTT,NOV,DIC';

  @override
  String get comm_shortcut_search => 'Cerca nella community';

  @override
  String get comm_shortcut_private => 'Post privati';

  @override
  String get comm_shortcut_challenges => 'Sfide';

  @override
  String get comm_shortcut_ranking => 'Classifica';

  @override
  String get comm_shortcut_notifications => 'Notifiche';

  @override
  String get comm_create_post => 'Crea post';

  @override
  String get comm_tab_explore => 'Esplora';

  @override
  String get comm_tab_following => 'Seguiti';

  @override
  String get comm_tab_squads => 'Squad';

  @override
  String get comm_new_posts => 'Nuovi post';

  @override
  String get comm_follow => 'SEGUI';

  @override
  String get comm_following_btn => 'SEGUITO';

  @override
  String get comm_time_now => 'ora';

  @override
  String comm_time_min(int n) {
    return '$n min';
  }

  @override
  String comm_time_hour(int n) {
    return '$n h';
  }

  @override
  String comm_time_day(int n) {
    return '$n g';
  }

  @override
  String get comm_type_workout => 'ALLENAMENTO COMPLETATO';

  @override
  String get comm_type_pr => 'NUOVO PR';

  @override
  String get comm_type_streak => 'SERIE';

  @override
  String get comm_type_activity => 'ATTIVITÀ';

  @override
  String get comm_type_imported => 'ATTIVITÀ IMPORTATA';

  @override
  String comm_metric_volume(String value) {
    return '$value kg volume';
  }

  @override
  String comm_metric_sets(int n) {
    return '$n serie';
  }

  @override
  String comm_metric_prs(int n) {
    return '$n PR';
  }

  @override
  String get comm_view_workout => 'Vedi allenamento';

  @override
  String get comm_label_distance => 'DISTANZA';

  @override
  String get comm_label_duration => 'DURATA';

  @override
  String get comm_label_hr => 'FC MEDIA';

  @override
  String get comm_label_strain => 'STRAIN';

  @override
  String get comm_label_load => 'CARICO';

  @override
  String get comm_label_reps => 'RIPETIZIONI';

  @override
  String get comm_label_e1rm => '1RM STIMATO';

  @override
  String comm_streak_title(int n) {
    return '$n giorni di fila';
  }

  @override
  String get comm_activity_default => 'Attività';

  @override
  String get comm_empty_title => 'Ancora nessun post';

  @override
  String get comm_empty_body => 'Sii il primo a condividere!';

  @override
  String get comm_error_title => 'Errore nel caricare il feed';

  @override
  String get comm_retry => 'RIPROVA';

  @override
  String get comm_following_empty_title => 'Segui atleti';

  @override
  String get comm_following_empty_body => 'Qui vedi i post di chi segui.';

  @override
  String get comm_following_empty_cta => 'CERCA ATLETI';

  @override
  String get comm_my_squad => 'IL MIO SQUAD';

  @override
  String get comm_my_squads => 'I MIEI SQUAD';

  @override
  String comm_squad_meta(String mode, int members) {
    return 'Modalità $mode · $members membri';
  }

  @override
  String comm_squad_week(int week) {
    return 'Settimana $week';
  }

  @override
  String get comm_mode_alpha => 'Alfa';

  @override
  String get comm_mode_survivor => 'Survivor';

  @override
  String get comm_mode_roadrunner => 'Roadrunner';

  @override
  String get comm_mode_hustle => 'Hustle';

  @override
  String get comm_squad_trained_today => 'ALLENATI OGGI';

  @override
  String get comm_squad_ranking => 'CLASSIFICA';

  @override
  String get comm_activity_section => 'ATTIVITÀ RECENTE';

  @override
  String get comm_activity_checkin => 'Ha fatto check-in nello squad.';

  @override
  String get comm_squad_create_join => '+  CREA O ENTRA IN UNO SQUAD';

  @override
  String get comm_squad_sheet_title => 'CREA O ENTRA';

  @override
  String get comm_squad_code => 'Ho un codice invito';

  @override
  String get comm_squad_code_sub => 'Entra in uno Squad privato.';

  @override
  String get comm_squad_new => 'Crea un nuovo Squad';

  @override
  String get comm_squad_new_sub => 'Definisci le regole e invita i tuoi amici.';

  @override
  String get comm_squad_empty_title => 'Non sei in nessuno squad';

  @override
  String get comm_squad_empty_body =>
      'Crea o entra in uno squad per sfidare gli amici.';

  @override
  String get comm_actions_title => 'Azioni del post';

  @override
  String get comm_action_delete => 'Elimina post';

  @override
  String get comm_action_delete_sub =>
      'Rimuove il post, i commenti e le reazioni';

  @override
  String get comm_action_block => 'Blocca profilo';

  @override
  String get comm_action_block_sub =>
      'Non vedrete più i post l\'uno dell\'altro';

  @override
  String get comm_action_report => 'Segnala';

  @override
  String get comm_action_report_sub =>
      'Contenuto inappropriato o che viola le regole';

  @override
  String get comm_delete_title => 'Eliminare il post?';

  @override
  String get comm_delete_msg =>
      'Il post, i commenti e le reazioni verranno rimossi.';

  @override
  String get comm_delete_confirm => 'Elimina';

  @override
  String get comm_cancel => 'Annulla';

  @override
  String comm_block_title(String name) {
    return 'Bloccare $name?';
  }

  @override
  String get comm_block_msg =>
      'Non vedrete più i post l\'uno dell\'altro nella community.';

  @override
  String get comm_block_confirm => 'Blocca';

  @override
  String get comm_report_title => 'Segnala post';

  @override
  String get comm_report_spam => 'Spam';

  @override
  String get comm_report_spam_sub => 'Contenuto ripetitivo o pubblicità';

  @override
  String get comm_report_harassment => 'Molestie';

  @override
  String get comm_report_harassment_sub => 'Offese o attacchi a qualcuno';

  @override
  String get comm_report_inappropriate => 'Contenuto inappropriato';

  @override
  String get comm_report_inappropriate_sub =>
      'Nudità, violenza o contenuti sensibili';

  @override
  String get comm_report_false => 'Informazione falsa';

  @override
  String get comm_report_false_sub => 'Dati o risultati ingannevoli';

  @override
  String get comm_report_other => 'Altro motivo';

  @override
  String get comm_report_other_sub => 'Qualcosa che non è nell\'elenco';

  @override
  String get comm_deleted => 'Post eliminato.';

  @override
  String get comm_blocked => 'Profilo bloccato.';

  @override
  String get comm_reported => 'Segnalazione inviata per la revisione.';

  @override
  String get comm_react_title => 'Reagisci';

  @override
  String get comm_react_label => 'Reagisci al post';

  @override
  String get comm_comments_label => 'Commenti';

  @override
  String get comm_share_label => 'Condividi';

  @override
  String get comm_more_label => 'Altre azioni';

  @override
  String comm_share_text(String name, String detail) {
    return '$name su BLDR: $detail';
  }

  @override
  String comm_share_text_simple(String name) {
    return 'Guarda il post di $name su BLDR.';
  }

  @override
  String get comm_view_activity => 'Vedi attività';

  @override
  String get comm_view_evolution => 'Vedi progressi';

  @override
  String get comm_action_edit => 'Modifica post';

  @override
  String get comm_action_edit_sub => 'Modifica il testo di questo post';

  @override
  String get comm_edit_hint => 'Scrivi la didascalia';

  @override
  String get comm_edit_save => 'SALVA';

  @override
  String get comm_edited => 'Post aggiornato.';

  @override
  String comm_workout_by(String handle) {
    return 'Allenamento di $handle';
  }

  @override
  String get comm_label_volume => 'VOLUME';

  @override
  String get comm_label_sets => 'SERIE';

  @override
  String get comm_section_exercises => 'ESERCIZI';

  @override
  String get comm_exercises_empty => 'Nessun esercizio trovato.';

  @override
  String get comm_copy_note =>
      'Una copia modificabile verrà aggiunta a I miei allenamenti.';

  @override
  String get comm_copy_cta => 'AGGIUNGI AI MIEI ALLENAMENTI';

  @override
  String get comm_copying => 'AGGIUNTA…';

  @override
  String get comm_copy_done => 'Allenamento aggiunto a I miei allenamenti.';

  @override
  String get comm_copy_limit =>
      'Hai raggiunto il limite di 3 copie questo mese. Passa al Club.';

  @override
  String comm_set_line(int n) {
    return 'Serie $n';
  }

  @override
  String comm_imported_by(String handle) {
    return 'Importata da $handle';
  }

  @override
  String get comm_label_pace => 'PASSO MEDIO';

  @override
  String get comm_label_calories => 'CALORIE';

  @override
  String get comm_label_hr_max => 'FC MAX';

  @override
  String get comm_section_details => 'DETTAGLI';

  @override
  String get comm_detail_source => 'Fonte';

  @override
  String get comm_detail_start => 'Inizio';

  @override
  String get comm_activity_note =>
      'Dati condivisi dall\'utente dall\'attività importata.';

  @override
  String comm_pr_by(String handle) {
    return 'Nuovo PR di $handle';
  }

  @override
  String comm_pr_delta(String value) {
    return '$value kg rispetto al PR precedente';
  }

  @override
  String get comm_label_prev_pr => 'PR PRECEDENTE';

  @override
  String get comm_label_evolution => 'PROGRESSO';

  @override
  String get comm_section_recent => 'PROGRESSI RECENTI';

  @override
  String get comm_today => 'Oggi';

  @override
  String get comm_pr_note => 'PR registrato nello storico dell\'atleta.';

  @override
  String get comm_pr_private =>
      'Lo storico di questo atleta non è disponibile.';

  @override
  String get comm_compose_prompt => 'Cosa vuoi condividere?';

  @override
  String get comm_compose_workout => 'Allenamento';

  @override
  String get comm_compose_wearable => 'Wearable';

  @override
  String get comm_compose_photo => 'Foto';

  @override
  String get comm_visibility => 'Visibilità';

  @override
  String get comm_vis_public => 'Community';

  @override
  String get comm_vis_public_sub => 'Chiunque può vederlo';

  @override
  String get comm_vis_squad => 'Uno squad';

  @override
  String get comm_vis_squad_sub => 'Scegli uno squad di cui fai parte';

  @override
  String get comm_vis_private => 'Solo io';

  @override
  String get comm_vis_private_sub => 'Visibile solo a te';

  @override
  String get comm_vis_no_squad => 'Non fai parte di nessuno squad.';

  @override
  String get comm_pick_squad => 'Scegli squad';

  @override
  String get comm_publish => 'PUBBLICA';

  @override
  String get comm_change => 'CAMBIA';

  @override
  String get comm_workout_selected => 'ALLENAMENTO SELEZIONATO';

  @override
  String comm_wearable_selected(String source) {
    return '$source · SELEZIONATO';
  }

  @override
  String get comm_workout_fallback => 'Allenamento completato';

  @override
  String get comm_include_prs => 'Includi i PR nel post';

  @override
  String get comm_add_photo => 'Aggiungi foto';

  @override
  String get comm_optional => 'Facoltativo';

  @override
  String get comm_photo_attached => 'FOTO ALLEGATA';

  @override
  String get comm_photo_one => '1 foto';

  @override
  String get comm_photo_swap => 'CAMBIA';

  @override
  String get comm_photo_remove => 'RIMUOVI';

  @override
  String get comm_photo_gallery => 'Galleria';

  @override
  String get comm_photo_camera => 'Scatta foto';

  @override
  String get comm_pick_workout => 'Seleziona allenamento';

  @override
  String get comm_pick_workout_empty => 'Nessun allenamento recente.';

  @override
  String get comm_pick_wearable => 'Scegli origine';

  @override
  String get comm_wearable_recent => 'Vedi 10 registri recenti';

  @override
  String get comm_wearable_soon => 'In arrivo';

  @override
  String get comm_wearable_note =>
      'Selezionando un\'origine vedrai i 10 allenamenti e attività più recenti.';

  @override
  String get comm_records_title => 'Registri recenti';

  @override
  String get comm_records_empty => 'Nessuna attività recente.';

  @override
  String get comm_publish_error => 'Impossibile pubblicare. Riprova.';

  @override
  String get comm_post_title => 'Post';

  @override
  String get comm_section_comments => 'COMMENTI';

  @override
  String get comm_comment_hint => 'Aggiungi un commento...';

  @override
  String get comm_comment_reply => 'Rispondi';

  @override
  String get comm_comment_send => 'Invia commento';

  @override
  String get comm_comment_edited => 'modificato';

  @override
  String get comm_comment_empty => 'Commenta per primo.';

  @override
  String get comm_comment_edit => 'Modifica commento';

  @override
  String get comm_comment_edit_sub => 'Modifica il testo del commento';

  @override
  String get comm_comment_delete => 'Elimina commento';

  @override
  String get comm_comment_delete_sub => 'Rimuove questo commento dal post';

  @override
  String get comm_comment_delete_msg =>
      'Questo commento verrà rimosso dal post.';

  @override
  String get comm_comment_actions => 'Azioni del commento';

  @override
  String comm_reply_to(String handle) {
    return 'Risposta a $handle';
  }

  @override
  String get comm_reply_hint => 'Scrivi una risposta...';

  @override
  String get comm_reply_send => 'INVIA';

  @override
  String get comm_label_kg_volume => 'KG VOLUME';

  @override
  String get comm_label_prs => 'PR';

  @override
  String get comm_view_workout_cta => 'VEDI ALLENAMENTO';

  @override
  String comm_rank_status(int n) {
    return '#$n CLASSIFICA';
  }

  @override
  String comm_followers(int n) {
    return '$n follower';
  }

  @override
  String comm_following_count(int n) {
    return '$n seguiti';
  }

  @override
  String get comm_section_performance => 'PERFORMANCE';

  @override
  String get comm_label_workouts => 'ALLENAMENTI';

  @override
  String get comm_section_achievements => 'TRAGUARDI';

  @override
  String get comm_section_posts => 'POST';

  @override
  String get comm_profile_no_posts => 'Ancora nessun post.';

  @override
  String get comm_profile_error => 'Impossibile caricare questo profilo.';

  @override
  String get comm_profile_actions => 'Azioni del profilo';

  @override
  String comm_open_profile(String name) {
    return 'Apri il profilo di $name';
  }

  @override
  String get comm_label_active_weeks => 'SETTIMANE ATTIVE';

  @override
  String get comm_section_best_prs => 'MIGLIORI PR';

  @override
  String get sq_new_title => 'Nuovo Squad';

  @override
  String get sq_new_heading => 'Crea il tuo Squad';

  @override
  String get sq_new_sub => 'Definite come competerete.';

  @override
  String get sq_field_name => 'NOME DELLO SQUAD';

  @override
  String get sq_field_name_hint => 'Es: Squadra Élite';

  @override
  String get sq_field_stake => 'POSTA DELLO SQUAD · FACOLTATIVA';

  @override
  String get sq_field_stake_hint => 'Es: L\'ultimo offre il frullato.';

  @override
  String get sq_field_desc => 'DESCRIZIONE · FACOLTATIVA';

  @override
  String get sq_field_desc_hint => 'Racconta l\'obiettivo dello Squad.';

  @override
  String get sq_field_mode => 'MODALITÀ';

  @override
  String get sq_field_validation => 'VALIDAZIONE';

  @override
  String get sq_field_duration => 'DURATA';

  @override
  String sq_duration_days(int n) {
    return '$n GIORNI';
  }

  @override
  String get sq_mode_survivor_sub => 'Ultimo in piedi';

  @override
  String get sq_mode_alpha_sub => 'XP accumulati';

  @override
  String get sq_mode_roadrunner_sub => 'Maggiore distanza';

  @override
  String get sq_mode_hustle_sub => 'Giorni allenati';

  @override
  String get sq_mode_survivor_info =>
      'Chi resta senza vite è eliminato. Validazione con foto.';

  @override
  String get sq_mode_alpha_info => 'Vince chi accumula più XP nel periodo.';

  @override
  String get sq_mode_roadrunner_info =>
      'Vince chi accumula più chilometri. Validazione con check-in.';

  @override
  String get sq_mode_hustle_info =>
      'Vince chi si allena più giorni. Validazione con check-in.';

  @override
  String get sq_validation_photo => 'FOTO';

  @override
  String get sq_validation_photo_sub => 'Foto obbligatoria e voto';

  @override
  String get sq_validation_honor => 'ONORE';

  @override
  String get sq_validation_honor_sub => 'Check-in manuale';

  @override
  String get sq_create_cta => 'CREA SQUAD';

  @override
  String get sq_name_required => 'Dai un nome al tuo Squad.';

  @override
  String get sq_created => 'Squad creato. Invita la tua squadra.';

  @override
  String get sq_create_error => 'Impossibile creare lo Squad.';

  @override
  String sq_quota_create(int left, int limit) {
    return 'Hai $left di $limit creazioni rimanenti questo mese.';
  }

  @override
  String sq_quota_create_full(int limit) {
    return 'Hai usato le $limit creazioni gratuite di questo mese. Abbonati a BLDR Club per crearne senza limiti.';
  }

  @override
  String sq_quota_join(int left, int limit) {
    return 'Hai $left di $limit partecipazioni rimanenti questo mese.';
  }

  @override
  String sq_quota_join_full(int limit) {
    return 'Hai usato le $limit partecipazioni gratuite di questo mese. Abbonati a BLDR Club per continuare.';
  }

  @override
  String get sq_subscribe => 'ABBONATI A BLDR CLUB';

  @override
  String get sq_join_title => 'Entra con codice';

  @override
  String get sq_join_sub =>
      'Inserisci il codice di invito inviato dall\'amministratore.';

  @override
  String get sq_join_label => 'CODICE DI INVITO';

  @override
  String get sq_join_hint => 'Es: BLD-8K2';

  @override
  String get sq_join_cta => 'ENTRA NELLO SQUAD';

  @override
  String get sq_join_not_found => 'Nessuno Squad trovato con questo codice.';

  @override
  String get sq_join_already => 'Fai già parte di questo Squad.';

  @override
  String sq_join_welcome(String name) {
    return 'Benvenuto nello Squad $name.';
  }

  @override
  String get sq_join_error => 'Impossibile entrare nello Squad.';

  @override
  String get sq_tab_overview => 'PANORAMICA';

  @override
  String get sq_tab_feed => 'FEED';

  @override
  String get sq_tab_ranking => 'CLASSIFICA';

  @override
  String get sq_label_today => 'OGGI';

  @override
  String sq_days_left(int n) {
    return '$n giorni rimanenti';
  }

  @override
  String get sq_day_left => 'Termina domani';

  @override
  String get sq_last_day => 'Ultimo giorno';

  @override
  String get sq_finished => 'Squad terminato';

  @override
  String get sq_goal_section => 'OBIETTIVO DI OGGI';

  @override
  String get sq_goal_default => 'Allenati oggi';

  @override
  String get sq_goal_sub => 'Il tuo check-in mantiene la serie dello Squad.';

  @override
  String get sq_status_pending => 'Check-in in revisione';

  @override
  String get sq_status_approved => 'Check-in approvato';

  @override
  String get sq_status_rejected => 'Check-in rifiutato';

  @override
  String get sq_stake_section => 'POSTA';

  @override
  String get sq_about_section => 'INFO';

  @override
  String get sq_activity_section => 'ATTIVITÀ DELLO SQUAD';

  @override
  String get sq_activity_empty => 'Ancora nessuna attività.';

  @override
  String get sq_activity_checkin => 'ha fatto check-in';

  @override
  String get sq_tribunal => 'Tribunale';

  @override
  String get sq_tribunal_sub => 'Prove fotografiche e voto dei membri';

  @override
  String get sq_history => 'Storico dello Squad';

  @override
  String get sq_history_sub => 'Check-in e punti registrati';

  @override
  String get sq_feed_section => 'ATTIVITÀ RECENTE';

  @override
  String get sq_feed_checkin => 'CHECK-IN';

  @override
  String sq_week(int week) {
    return 'SETTIMANA $week';
  }

  @override
  String get sq_you => 'Tu';

  @override
  String sq_score_days(int n) {
    return '$n giorni';
  }

  @override
  String sq_score_points(int n) {
    return '$n pt';
  }

  @override
  String sq_score_km(String value) {
    return '$value km';
  }

  @override
  String sq_lives(int n) {
    return '$n vite';
  }

  @override
  String get sq_eliminated_section => 'ELIMINATI';

  @override
  String get sq_chat => 'CHAT';

  @override
  String get sq_checkin => 'CHECK-IN';

  @override
  String get sq_checkin_closed => 'TERMINATO';

  @override
  String get sq_checkin_done => 'Attività registrata nello Squad.';

  @override
  String get sq_load_error => 'Impossibile caricare questo Squad.';

  @override
  String get sq_settings_label => 'Impostazioni dello Squad';

  @override
  String get sq_share_label => 'Condividi Squad';

  @override
  String sq_share_sub(String name) {
    return 'Invita persone in $name';
  }

  @override
  String get sq_share_invite => 'Condividi invito';

  @override
  String get sq_share_invite_sub => 'Invia con la tua app preferita.';

  @override
  String get sq_share_link => 'Copia link';

  @override
  String get sq_share_link_sub => 'Link diretto allo Squad.';

  @override
  String get sq_share_code => 'Copia codice';

  @override
  String get sq_copied => 'Copiato.';

  @override
  String sq_invite_text(String name, String link, String code) {
    return 'Entra nello Squad $name su BLDR.\n\nLink: $link\nCodice: $code';
  }

  @override
  String get sq_chat_title => 'Chat dello Squad';

  @override
  String get sq_chat_info => 'Messaggi visibili solo ai membri dello Squad.';

  @override
  String get sq_chat_hint => 'Messaggio per lo Squad...';

  @override
  String get sq_chat_empty => 'Ancora nessun messaggio.';

  @override
  String get sq_chat_send => 'Invia messaggio';

  @override
  String get sq_chat_error => 'Impossibile inviare il messaggio.';

  @override
  String get sq_section_general => 'GENERALE';

  @override
  String get sq_section_rules => 'REGOLE';

  @override
  String get sq_section_danger => 'ZONA PERICOLOSA';

  @override
  String get sq_info => 'Informazioni dello Squad';

  @override
  String get sq_info_sub => 'Nome, posta e dettagli.';

  @override
  String get sq_info_sheet_sub => 'Modifica i dati principali del gruppo.';

  @override
  String get sq_members => 'Membri';

  @override
  String sq_members_count(int n) {
    return '$n membri';
  }

  @override
  String get sq_members_sub => 'Gestisci chi partecipa allo Squad.';

  @override
  String get sq_role_admin => 'Amministratore';

  @override
  String get sq_role_member => 'Membro';

  @override
  String get sq_role_eliminated => 'Eliminato';

  @override
  String get sq_invite_members => 'INVITA MEMBRI';

  @override
  String get sq_kick => 'Rimuovi dallo Squad';

  @override
  String sq_kick_sub(String name) {
    return '$name non parteciperà più.';
  }

  @override
  String sq_kick_msg(String name) {
    return '$name perde l\'accesso a feed, chat e classifica.';
  }

  @override
  String get sq_kick_confirm => 'Rimuovi';

  @override
  String get sq_goal => 'Obiettivo giornaliero';

  @override
  String get sq_goal_none => 'Nessun obiettivo personalizzato.';

  @override
  String get sq_goal_sheet_sub =>
      'Imposta un obiettivo facoltativo per il gruppo.';

  @override
  String get sq_goal_label => 'DESCRIZIONE';

  @override
  String get sq_goal_hint => 'Es: completare almeno un allenamento.';

  @override
  String get sq_goal_help =>
      'L\'obiettivo appare nella Panoramica e si può modificare in qualsiasi momento.';

  @override
  String get sq_goal_save => 'SALVA OBIETTIVO';

  @override
  String get sq_rules => 'Regole di punteggio';

  @override
  String get sq_rules_sheet_sub => 'Scopri come funziona la classifica.';

  @override
  String get sq_rules_label => 'MODALITÀ ATTUALE';

  @override
  String get sq_rules_note =>
      'La modalità non può essere cambiata dopo la creazione.';

  @override
  String get sq_rules_ok => 'HO CAPITO';

  @override
  String get sq_rules_alpha =>
      'Check-in +10 XP · al minuto +1 XP · al km +10 XP · attività diversa nel giorno +15 XP.';

  @override
  String get sq_rules_survivor =>
      'Ognuno parte con 2 vite. Una foto non approvata toglie 1 vita; a 0 vite si è eliminati.';

  @override
  String get sq_rules_roadrunner =>
      'Classifica per chilometri accumulati. Ogni check-in registra i km, sul sistema d\'onore.';

  @override
  String get sq_rules_hustle =>
      'Classifica per giorni allenati. Più allenamenti nello stesso giorno valgono 1 punto.';

  @override
  String get sq_xp_limit => 'LIMITE XP GIORNALIERO';

  @override
  String get sq_xp_limit_hint => '0 = nessun limite';

  @override
  String get sq_save => 'SALVA MODIFICHE';

  @override
  String get sq_saved => 'Modifiche salvate.';

  @override
  String get sq_save_error => 'Impossibile salvare.';

  @override
  String get sq_leave => 'Esci dallo Squad';

  @override
  String get sq_leave_sub => 'Non parteciperai più.';

  @override
  String get sq_leave_body =>
      'Uscendo perdi l\'accesso a feed, chat e classifica di questo Squad.';

  @override
  String get sq_leave_note => 'Potrai rientrare solo con invito o codice.';

  @override
  String get sq_leave_cta => 'ESCI DALLO SQUAD';

  @override
  String get sq_end => 'Termina Squad';

  @override
  String get sq_end_sub => 'Elimina lo Squad definitivamente.';

  @override
  String get sq_end_body =>
      'Terminare lo Squad rimuove membri, storico, classifica e messaggi.';

  @override
  String get sq_end_note =>
      'Questa azione è permanente e non può essere annullata.';

  @override
  String get sq_end_cta => 'TERMINA SQUAD';

  @override
  String get sq_ended => 'Squad terminato.';

  @override
  String get chal_title => 'Sfide';

  @override
  String get chal_subtitle => 'Competi, migliora e segui i tuoi progressi.';

  @override
  String get chal_create => 'Crea';

  @override
  String get chal_tab_active => 'ATTIVE';

  @override
  String get chal_tab_discover => 'SCOPRI';

  @override
  String get chal_tab_done => 'CONCLUSE';

  @override
  String get chal_sec_featured => 'IN EVIDENZA';

  @override
  String get chal_sec_others => 'ALTRE SFIDE';

  @override
  String get chal_sec_ending => 'IN SCADENZA';

  @override
  String get chal_sec_recommended => 'CONSIGLIATE PER TE';

  @override
  String get chal_sec_trending => 'DI TENDENZA';

  @override
  String get chal_sec_new => 'NUOVE SFIDE';

  @override
  String get chal_sec_last => 'ULTIMO RISULTATO';

  @override
  String get chal_sec_history => 'CRONOLOGIA';

  @override
  String chal_days_left(int days) {
    return '$days giorni rimasti';
  }

  @override
  String get chal_last_day => 'Ultimo giorno';

  @override
  String chal_participants(String a) {
    return '$a partecipanti';
  }

  @override
  String chal_ends_in(int days, int pct) {
    return 'Termina tra $days giorni · $pct% completata';
  }

  @override
  String get chal_view => 'VEDI SFIDA';

  @override
  String chal_prog_xp(String a, String b) {
    return '$a / $b XP';
  }

  @override
  String chal_prog_workouts(String a, String b) {
    return '$a / $b allenamenti';
  }

  @override
  String chal_prog_streak(String a, String b) {
    return '$a / $b giorni';
  }

  @override
  String chal_goal(String a) {
    return 'OBIETTIVO · $a';
  }

  @override
  String chal_unit_xp(String a) {
    return '$a XP';
  }

  @override
  String chal_unit_workouts(String a) {
    return '$a allenamenti';
  }

  @override
  String chal_unit_streak(String a) {
    return '$a giorni di streak';
  }

  @override
  String chal_duration_days(int days) {
    return '$days giorni';
  }

  @override
  String chal_ended_on(String a) {
    return 'Terminata il $a';
  }

  @override
  String get chal_ended => 'TERMINATA';

  @override
  String get chal_position => 'POSIZIONE';

  @override
  String chal_of_total(String a) {
    return 'di $a';
  }

  @override
  String get chal_empty_active => 'Non partecipi ancora a nessuna sfida.';

  @override
  String get chal_empty_discover => 'Nessuna nuova sfida al momento.';

  @override
  String get chal_empty_done => 'Le tue sfide terminate appaiono qui.';

  @override
  String get chal_load_error => 'Impossibile caricare le sfide.';

  @override
  String get chal_retry => 'RIPROVA';

  @override
  String get chal_how => 'COME FUNZIONA';

  @override
  String get chal_how_xp =>
      'Ogni XP guadagnato durante la sfida conta per l\'obiettivo del gruppo.';

  @override
  String get chal_how_workouts =>
      'Ogni allenamento completato durante la sfida conta per l\'obiettivo del gruppo.';

  @override
  String get chal_how_streak =>
      'La tua serie più lunga durante la sfida conta per l\'obiettivo del gruppo.';

  @override
  String get chal_join => 'PARTECIPA ALLA SFIDA';

  @override
  String get chal_see_all => 'VEDI TUTTO';

  @override
  String get chal_new_title => 'Crea sfida';

  @override
  String get chal_step1 => '1 DI 3 · DETTAGLI';

  @override
  String get chal_step2 => '2 DI 3 · REGOLE';

  @override
  String get chal_step3 => '3 DI 3 · REVISIONE';

  @override
  String get chal_cover => 'IMMAGINE DI COPERTINA';

  @override
  String get chal_cover_add => 'Aggiungi copertina';

  @override
  String get chal_cover_hint => 'JPG o PNG · fino a 5 MB';

  @override
  String get chal_cover_big => 'L\'immagine deve essere al massimo 5 MB.';

  @override
  String get chal_cover_note =>
      'La copertina appare nell\'Hub e nei dettagli della sfida.';

  @override
  String get chal_name => 'NOME DELLA SFIDA';

  @override
  String get chal_name_hint => 'Es.: 30 giorni senza saltare';

  @override
  String get chal_desc => 'DESCRIZIONE';

  @override
  String get chal_desc_hint => 'Spiega la proposta della sfida...';

  @override
  String get chal_continue => 'CONTINUA';

  @override
  String get chal_counts => 'COSA CONTA?';

  @override
  String get chal_metric_workouts => 'Allenamenti completati';

  @override
  String get chal_metric_workouts_sub => 'Ogni allenamento finito in BLDR';

  @override
  String get chal_metric_streak => 'Streak più lunga';

  @override
  String get chal_metric_streak_sub => 'Costanza nei giorni consecutivi';

  @override
  String get chal_metric_xp => 'XP accumulati';

  @override
  String get chal_metric_xp_sub => 'Tutti gli XP guadagnati durante la sfida';

  @override
  String get chal_goal_label => 'OBIETTIVO';

  @override
  String get chal_duration => 'Durata';

  @override
  String get chal_duration_upper => 'DURATA';

  @override
  String get chal_who => 'CHI PUÒ PARTECIPARE?';

  @override
  String get chal_public => 'PUBBLICA';

  @override
  String get chal_friends_soon => 'AMICI · PRESTO';

  @override
  String get chal_squad_soon => 'SQUAD · PRESTO';

  @override
  String get chal_public_note =>
      'Le sfide pubbliche possono apparire in Scopri.';

  @override
  String get chal_metrics_title => 'Metriche disponibili';

  @override
  String get chal_metrics_list =>
      'Allenamenti completati · Streak più lunga · XP accumulati';

  @override
  String chal_review_meta(String a, int days) {
    return '$a · durata $days giorni';
  }

  @override
  String get chal_before => 'PRIMA DI PUBBLICARE';

  @override
  String get chal_before_title => 'La sfida inizia quando pubblichi.';

  @override
  String get chal_before_body =>
      'Dopo la pubblicazione puoi modificare l\'obiettivo nella schermata della sfida. La metrica principale non cambia.';

  @override
  String get chal_publish => 'PUBBLICA SFIDA';

  @override
  String get chal_publishing => 'PUBBLICAZIONE...';

  @override
  String get rank_title => 'Classifica';

  @override
  String get rank_subtitle => 'Confronta le tue prestazioni con la community.';

  @override
  String get rank_tab_global => 'GLOBALE';

  @override
  String get rank_period => 'PERIODO';

  @override
  String get rank_week => 'SETTIMANA';

  @override
  String get rank_month => 'MESE';

  @override
  String get rank_all => 'SEMPRE';

  @override
  String get rank_metric => 'METRICA';

  @override
  String get rank_volume => 'VOLUME';

  @override
  String get rank_consistency => 'COSTANZA';

  @override
  String get rank_progression => 'PROGRESSIONE';

  @override
  String get rank_mine => 'LA TUA POSIZIONE';

  @override
  String get rank_top3 => 'TOP 3';

  @override
  String get rank_list => 'CLASSIFICA';

  @override
  String get rank_you => 'Tu';

  @override
  String rank_workouts(String a) {
    return '$a allenamenti';
  }

  @override
  String get rank_lock => 'Vedi la top 50 con Club';

  @override
  String get rank_empty => 'Nessun dato in questo periodo.';

  @override
  String get rank_error => 'Impossibile caricare la classifica.';

  @override
  String get notif_mark_all => 'Segna come lette';

  @override
  String get notif_tab_all => 'TUTTE';

  @override
  String get notif_tab_social => 'SOCIAL';

  @override
  String get notif_tab_perf => 'PERFORMANCE';

  @override
  String get notif_today => 'OGGI';

  @override
  String get notif_yesterday => 'IERI';

  @override
  String get notif_week => 'QUESTA SETTIMANA';

  @override
  String get notif_older => 'PRECEDENTI';

  @override
  String notif_yesterday_at(String a) {
    return 'ieri, $a';
  }

  @override
  String get notif_empty_tab => 'Niente in questa scheda.';

  @override
  String get notif_confirm_workout => 'Conferma allenamento';

  @override
  String get notif_welcome => 'Dai il benvenuto';

  @override
  String get priv_title => 'Post privati';

  @override
  String get priv_subtitle => 'Visibili solo a te';

  @override
  String get priv_recent => 'RECENTI';

  @override
  String get priv_about => 'INFO SUI POST PRIVATI';

  @override
  String get priv_about_body =>
      'Scegli \"Solo io\" quando crei un post per tenerlo qui, fuori dal feed.';

  @override
  String get priv_empty => 'Non hai ancora pubblicato post privati.';

  @override
  String comm_pick_workout_sub(int n) {
    return '$n allenamenti più recenti';
  }

  @override
  String get comm_photo_sheet_sub => 'Aggiungi una foto al post';

  @override
  String get comm_photo_gallery_sub => 'Scegli una foto esistente';

  @override
  String get comm_photo_camera_sub => 'Apri la fotocamera';

  @override
  String get comm_add_photo_record => 'Aggiungi foto alla registrazione';

  @override
  String get comm_squad_sheet_sub =>
      'Scegli come vuoi partecipare a uno Squad.';

  @override
  String get comm_squad_cancel => 'ANNULLA';

  @override
  String get toast_undo => 'Annulla';

  @override
  String get toast_dismiss_hint => 'Scorri verso l\'alto per chiudere';

  @override
  String get toast_offline => 'Sei offline';

  @override
  String get toast_back_online => 'Connessione ripristinata';

  @override
  String get nutri2_eyebrow => 'NUTRIZIONE';

  @override
  String get nutri2_title => 'La tua giornata';

  @override
  String nutri2_date_today(String date) {
    return 'Oggi, $date';
  }

  @override
  String nutri2_date_yesterday(String date) {
    return 'Ieri, $date';
  }

  @override
  String get nutri2_pill_today => 'OGGI';

  @override
  String nutri2_kcal_goal(String goal) {
    return 'di $goal kcal';
  }

  @override
  String nutri2_macro_goal(String goal) {
    return 'di ${goal}g';
  }

  @override
  String get nutri2_protein => 'Proteine';

  @override
  String get nutri2_carbs => 'Carboidrati';

  @override
  String get nutri2_fat => 'Grassi';

  @override
  String get nutri2_iqd_title => 'INDICE DI QUALITÀ DELLA DIETA • IQD';

  @override
  String get nutri2_iqd_very_good => 'MOLTO BUONO';

  @override
  String get nutri2_iqd_regular => 'DISCRETO';

  @override
  String get nutri2_iqd_poor => 'SCARSO';

  @override
  String nutri2_iqd_delta_up(int n) {
    return '$n punti rispetto alla media settimanale';
  }

  @override
  String nutri2_iqd_delta_down(int n) {
    return '$n punti rispetto alla media settimanale';
  }

  @override
  String get nutri2_iqd_delta_same => 'Uguale alla media settimanale';

  @override
  String get nutri2_iqd_locked => 'IQD disponibile nel BLDR CLUB';

  @override
  String get nutri2_hydration => 'IDRATAZIONE';

  @override
  String nutri2_water_goal(String liters) {
    return 'di $liters L';
  }

  @override
  String get nutri2_water_add => 'Aggiungi acqua';

  @override
  String get nutri2_meals_today => 'PASTI DI OGGI';

  @override
  String get nutri2_meals_day => 'PASTI DEL GIORNO';

  @override
  String get nutri2_edit_meals => 'Modifica alimenti';

  @override
  String get nutri2_edit_done => 'Termina modifica';

  @override
  String get nutri2_add_food => 'AGGIUNGI ALIMENTO';

  @override
  String get nutri2_add_food_a11y => 'Aggiungi alimento';

  @override
  String get nutri2_meal_empty => 'Nessun alimento aggiunto';

  @override
  String get nutri2_macro_protein => 'PROTEINE';

  @override
  String get nutri2_macro_carbs => 'CARBOIDRATI';

  @override
  String get nutri2_macro_fat => 'GRASSI';

  @override
  String nutri2_food_macros(String kcal, String p, String c, String f) {
    return '$kcal kcal   P ${p}g   C ${c}g   G ${f}g';
  }

  @override
  String get nutri2_edit_food => 'Modifica alimento';

  @override
  String get nutri2_remove_food => 'Rimuovi alimento';

  @override
  String get nutri2_date_sheet_title => 'Scegli giorno';

  @override
  String get nutri2_today => 'Oggi';

  @override
  String get nutri2_yesterday => 'Ieri';

  @override
  String get nutri2_water_sheet_eyebrow => 'IDRATAZIONE';

  @override
  String get nutri2_water_sheet_title => 'Aggiungi acqua';

  @override
  String get nutri2_water_sheet_subtitle =>
      'Registra quanto hai appena bevuto.';

  @override
  String get nutri2_water_quick => 'AGGIUNTA RAPIDA';

  @override
  String get nutri2_water_custom => 'PERSONALIZZATO';

  @override
  String get nutri2_water_today => 'OGGI';

  @override
  String nutri2_water_today_value(String value, String goal) {
    return '$value L di $goal L';
  }

  @override
  String get nutri2_water_cta => 'AGGIUNGI ACQUA';

  @override
  String get nutri2_water_less => 'Diminuisci';

  @override
  String get nutri2_water_more => 'Aumenta';

  @override
  String get nutri2_water_remove_title => 'Rimuovi acqua';
}
