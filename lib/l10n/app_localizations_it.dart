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
  String get workout_stop_title => 'Stop workout?';

  @override
  String get workout_stop_body => 'Progress will be saved up to this point.';

  @override
  String get workout_stop_btn => 'Stop';

  @override
  String get workout_stop_label => 'Stop workout';

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
}
