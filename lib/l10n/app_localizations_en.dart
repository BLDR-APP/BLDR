// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get common_retry => 'Try Again';

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
  String get dashboard_workout_done_label => 'Completed';

  @override
  String get dashboard_done_duration_label => 'Duration';

  @override
  String get dashboard_done_sets_label => 'Sets';

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
  String get nav_tab_community => 'Community';

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
  String get language_soon_badge => 'Coming soon';

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
  String get paywall_club_logo_semantics => 'BLDR CLUB logo';

  @override
  String get paywall_elevate_performance => 'ELEVATE YOUR PERFORMANCE';

  @override
  String get paywall_performance_subtitle =>
      'Training, nutrition and intelligence connected so you can make real progress.';

  @override
  String get paywall_choose_plan => 'Choose your plan';

  @override
  String get paywall_weekly_description => 'Full access for one week';

  @override
  String get paywall_monthly_description => 'Full access, month to month';

  @override
  String get paywall_annual_description => 'The best way to progress all year';

  @override
  String get paywall_per_month => 'per month';

  @override
  String get paywall_per_year => 'per year';

  @override
  String get paywall_join_cta => 'Join BLDR CLUB';

  @override
  String paywall_selected_price_caption(String price) {
    return '$price · Cancel anytime';
  }

  @override
  String get paywall_load_error_title => 'We couldn\'t load plans right now.';

  @override
  String get paywall_load_error_body => 'Please try again in a moment.';

  @override
  String get paywall_feature => 'FEATURE';

  @override
  String get paywall_free => 'FREE';

  @override
  String get paywall_club => 'CLUB';

  @override
  String get paywall_comparison_semantics =>
      'Comparison between the free plan and BLDR CLUB';

  @override
  String get paywall_benefit_community => 'BLDR Community';

  @override
  String get paywall_benefit_havok => 'HAVOK AI';

  @override
  String get paywall_benefit_photo_workout => 'Workout from photo';

  @override
  String get paywall_benefit_analytics => 'Analytics';

  @override
  String get paywall_benefit_library => 'Library';

  @override
  String get paywall_benefit_nutrition => 'Nutrition';

  @override
  String get paywall_limited => 'Limited';

  @override
  String get paywall_complete => 'Full';

  @override
  String get paywall_unavailable => '—';

  @override
  String get paywall_available => 'Available';

  @override
  String get paywall_basic => 'Basic';

  @override
  String get paywall_advanced => 'Advanced';

  @override
  String get paywall_terms => 'Terms of use';

  @override
  String get paywall_privacy => 'Privacy policy';

  @override
  String get bootstrap_init_failed_title => 'BLDR couldn\'t start.';

  @override
  String get bootstrap_init_failed_body =>
      'Check your connection and try again.';

  @override
  String get paywall_sign_in_required => 'Sign in to continue.';

  @override
  String get paywall_options_unavailable =>
      'Subscription options aren\'t available yet.';

  @override
  String get paywall_options_retry_later =>
      'Subscription options aren\'t available yet. Please try again later.';

  @override
  String get paywall_option_unavailable =>
      'This subscription option isn\'t available.';

  @override
  String get paywall_access_confirmation_failed =>
      'We couldn\'t confirm your BLDR CLUB access.';

  @override
  String get paywall_payment_pending =>
      'Your payment is pending confirmation from the store.';

  @override
  String get paywall_redeem_unavailable =>
      'Code redemption will be available once subscription options finish loading.';

  @override
  String get paywall_restore_unavailable =>
      'Restore will be available once subscription options finish loading.';

  @override
  String get paywall_restore_after_update =>
      'Restore will be available after subscriptions are updated.';

  @override
  String get havok_entry_semantics => 'Open HAVOK';

  @override
  String dashboard_v2_level_xp(String current, String target) {
    return '$current / $target';
  }

  @override
  String get dashboard_v2_workout_today_label => 'TODAY\'S WORKOUT';

  @override
  String get dashboard_v2_start_workout_cta => 'START WORKOUT';

  @override
  String dashboard_v2_exercises_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$_temp0';
  }

  @override
  String dashboard_v2_workout_duration(int minutes) {
    return '~$minutes min';
  }

  @override
  String dashboard_v2_calories_of_target(String target) {
    return 'of $target kcal';
  }

  @override
  String get whoop_card_today_caps => 'TODAY';

  @override
  String get wearable_connect_label => 'YOUR INTEGRATIONS';

  @override
  String get wearable_connect_title_first => 'Connect your wearable';

  @override
  String get wearable_connect_title_other => 'Connect another device';

  @override
  String get wearable_connect_body =>
      'Track sleep, recovery and activity with WHOOP data.';

  @override
  String get wearable_connect_cta => 'CONNECT DEVICE';

  @override
  String get whoop_unavailable_title => 'Data unavailable';

  @override
  String get whoop_unavailable_body =>
      'We haven\'t received today\'s data yet.';

  @override
  String get whoop_unavailable_cta => 'CHECK CONNECTION';

  @override
  String get garmin_body_battery => 'BODY BATTERY';

  @override
  String get garmin_resting_hr => 'RESTING HR';

  @override
  String get garmin_sleep => 'SLEEP';

  @override
  String get garmin_footer => 'Garmin data · updated today';

  @override
  String get havok_insight_label => 'HAVOK · INSIGHT';

  @override
  String get havok_insight_chat_cta => 'CHAT WITH HAVOK';

  @override
  String get havok_insight_dismiss_semantics => 'Dismiss insight';

  @override
  String wearable_stack_position(int index, int total) {
    return 'Card $index of $total';
  }

  @override
  String get dashboard_rest_title => 'Rest day';

  @override
  String get dashboard_rest_subtitle =>
      'Today is for recovering and coming back stronger.';

  @override
  String get dashboard_rest_meta => 'Recovery is part of progress';

  @override
  String get dashboard_rest_cta => 'SEE MY PLAN';

  @override
  String get dashboard_noplan_title => 'No workout planned';

  @override
  String get dashboard_noplan_subtitle => 'Plan your week to get started.';

  @override
  String get dashboard_noplan_meta => 'Your next workout starts here';

  @override
  String get dashboard_noplan_cta => 'CREATE MY PLAN';

  @override
  String get dashboard_v2_in_progress_label => 'WORKOUT IN PROGRESS';

  @override
  String get dashboard_v2_done_label => 'WORKOUT COMPLETED';

  @override
  String get dashboard_v2_resume_cta => 'RESUME WORKOUT';

  @override
  String dashboard_v2_exercises_progress(int done, int total) {
    return '$done of $total exercises';
  }

  @override
  String get dashboard_v2_done_duration => 'DURATION';

  @override
  String get dashboard_v2_done_sets => 'SETS';

  @override
  String get dashboard_v2_done_volume => 'VOLUME';

  @override
  String get dashboard_v2_done_via_whoop => 'Completed via WHOOP';

  @override
  String get cw_eyebrow => 'CREATE WORKOUT';

  @override
  String get cw_title => 'Build your workout';

  @override
  String get cw_subtitle => 'Start with the basics. You can fine-tune later.';

  @override
  String get cw_name_label => 'WORKOUT NAME';

  @override
  String get cw_name_hint => 'Workout name';

  @override
  String get cw_type_label => 'WORKOUT TYPE';

  @override
  String get cw_type_strength => 'Strength';

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
  String get cw_soon => 'Coming soon';

  @override
  String get cw_add_exercises => 'ADD EXERCISES';

  @override
  String get cw_setup_hint =>
      'You set sets, reps and rest after selecting the exercises.';

  @override
  String get cw_build_title => 'Build workout';

  @override
  String cw_build_eyebrow(String name) {
    return '$name · STRENGTH';
  }

  @override
  String cw_selected_count(int count) {
    return '$count selected';
  }

  @override
  String get cw_create => 'CREATE';

  @override
  String get cw_hud_exercises => 'EXERCISES';

  @override
  String get cw_hud_sets => 'SETS';

  @override
  String get cw_hud_minutes => 'MINUTES';

  @override
  String get cw_hud_avg_rest => 'AVG. REST';

  @override
  String get cw_hud_helper => 'Updates with exercises and preferences';

  @override
  String get cw_selected_header => 'SELECTED';

  @override
  String get cw_selected_hint => 'tap values to edit';

  @override
  String get cw_value_sets => 'SETS';

  @override
  String get cw_value_reps => 'REPS';

  @override
  String get cw_value_rest => 'REST';

  @override
  String get cw_personalize => 'CUSTOMIZE SETS';

  @override
  String get cw_advanced_hint => 'Adjust load and reps per set';

  @override
  String get cw_add_set => 'ADD SET';

  @override
  String get cw_add_exercise => 'ADD EXERCISE';

  @override
  String get cw_add_exercise_hint =>
      'Search and select exercises in the library';

  @override
  String get cw_sheet_title => 'Add exercises';

  @override
  String get cw_search_hint => 'Search exercise';

  @override
  String get cw_all_exercises => 'ALL EXERCISES';

  @override
  String cw_exercise_count(int count) {
    return '$count exercises';
  }

  @override
  String cw_add_n(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ADD $count EXERCISES',
      one: 'ADD $count EXERCISE',
    );
    return '$_temp0';
  }

  @override
  String get cw_filter_all => 'All';

  @override
  String get cw_filter_back => 'Back';

  @override
  String get cw_filter_biceps => 'Biceps';

  @override
  String get cw_filter_chest => 'Chest';

  @override
  String get cw_filter_shoulders => 'Shoulders';

  @override
  String get cw_filter_legs => 'Legs';

  @override
  String get cw_filter_triceps => 'Triceps';

  @override
  String get cw_filter_core => 'Core';

  @override
  String get cw_filter_glutes => 'Glutes';

  @override
  String get cw_set_edit => 'Edit set';

  @override
  String get cw_set_remove => 'Remove set';

  @override
  String get cw_edit_sets_title => 'Sets';

  @override
  String get cw_edit_reps_title => 'Reps';

  @override
  String get cw_edit_rest_title => 'Rest';

  @override
  String get cw_confirm => 'Confirm';

  @override
  String get cw_overwrite_title => 'Replace custom sets?';

  @override
  String get cw_overwrite_body =>
      'This exercise\'s sets have different values. The new value will apply to all of them.';

  @override
  String get cw_overwrite_confirm => 'Replace';

  @override
  String get cw_cancel => 'Cancel';

  @override
  String get hub_tab_workout => 'Workout';

  @override
  String get hub_tab_sports => 'Sports';

  @override
  String get hub_search => 'Search';

  @override
  String get hub_today_label => 'Today\'s Workout';

  @override
  String get hub_today_hint => 'Tap to change the workout';

  @override
  String get hub_start => 'Start workout';

  @override
  String get hub_done => 'Completed';

  @override
  String get hub_done_sub => 'Workout completed';

  @override
  String hub_meta(int count, int minutes) {
    return '$count exercises • ~$minutes min';
  }

  @override
  String get hub_week_title => 'MY WEEK';

  @override
  String get hub_week_see => 'See week';

  @override
  String get hub_week_workouts => 'Workouts';

  @override
  String get hub_week_extras => 'Extras';

  @override
  String get hub_week_xp => 'XP';

  @override
  String get hub_my_workouts => 'MY WORKOUTS';

  @override
  String get hub_create => 'Create workout';

  @override
  String get hub_from_photo => 'From photo';

  @override
  String hub_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '$count workout',
    );
    return '$_temp0';
  }

  @override
  String hub_card_stats(int count, int minutes) {
    return '$count exercises · ~$minutes min';
  }

  @override
  String get hub_empty_title => 'No workouts created yet';

  @override
  String get hub_empty_sub => 'Create your first custom workout';

  @override
  String get hub_explore => 'EXPLORE';

  @override
  String get hub_explore_club => 'BLDR CLUB';

  @override
  String get hub_explore_club_sub => 'Exclusive features';

  @override
  String get hub_explore_library => 'BLDR LIBRARY';

  @override
  String get hub_explore_library_sub => 'Workouts built by the BLDR team';

  @override
  String get hub_explore_programs => 'Programs';

  @override
  String get hub_explore_programs_sub => 'Structured programs';

  @override
  String get hub_library_button => 'Workout library';

  @override
  String get hub_library_tip => 'Explore and create your workouts here.';

  @override
  String get hub_menu_library_title => 'BLDR LIBRARY';

  @override
  String get hub_menu_library_sub =>
      'A library of workouts made for you. Pick, add,';

  @override
  String get hub_menu_library_highlight => 'build';

  @override
  String get hub_menu_programs_title => 'TRAINING PROGRAMS';

  @override
  String get hub_menu_programs_sub =>
      'Structured exercise sequences with specific goals.';

  @override
  String get hub_menu_create_title => 'CREATE WORKOUT';

  @override
  String get hub_menu_create_sub => 'Build your own workout. You choose how.';

  @override
  String get hub_menu_photo_title => 'IMPORT FROM PHOTO';

  @override
  String get hub_menu_photo_sub =>
      'Turn your workout sheet into a BLDR workout.';

  @override
  String hub_card_exercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$_temp0';
  }

  @override
  String hub_card_minutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get hub_card_options => 'Workout options';

  @override
  String get hub_card_edit => 'Edit';

  @override
  String get hub_empty_cta => 'CREATE WORKOUT';

  @override
  String get ed_eyebrow => 'EDIT WORKOUT';

  @override
  String get ed_save => 'SAVE';

  @override
  String get ed_name_label => 'WORKOUT NAME';

  @override
  String get ed_category_label => 'CATEGORY';

  @override
  String get ed_section => 'EXERCISES';

  @override
  String get ed_default => 'EXERCISE DEFAULT';

  @override
  String get ed_sets_header => 'SETS · OPTIONAL CUSTOMIZATION';

  @override
  String ed_chip_sets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '$count set',
    );
    return '$_temp0';
  }

  @override
  String ed_chip_reps(String reps) {
    return '$reps reps';
  }

  @override
  String ed_default_rest(String rest) {
    return '$rest rest';
  }

  @override
  String get ed_remove_exercise => 'Remove exercise';

  @override
  String get ed_edit_name => 'Edit name';

  @override
  String get ed_options => 'Exercise options';

  @override
  String get ed_cat_strength => 'Strength';

  @override
  String get ed_cat_hiit => 'HIIT';

  @override
  String get ed_cat_cardio => 'Cardio';

  @override
  String get ed_cat_mobility => 'Mobility';

  @override
  String get ed_cat_mixed => 'Mixed';

  @override
  String get aw_hr => 'HR';

  @override
  String get aw_bpm => 'BPM';

  @override
  String get aw_kcal => 'KCAL';

  @override
  String aw_set_of(int total) {
    return 'of $total';
  }

  @override
  String get aw_workout => 'WORKOUT';

  @override
  String get aw_current => 'CURRENT EXERCISE';

  @override
  String aw_set_badge(int current, int total) {
    return 'SET $current/$total';
  }

  @override
  String get aw_execution => 'EXECUTION';

  @override
  String aw_target(int reps) {
    return 'TARGET  $reps reps';
  }

  @override
  String get aw_next_set => 'YOUR NEXT SET';

  @override
  String get aw_load => 'LOAD';

  @override
  String get aw_reps => 'REPS';

  @override
  String get aw_rest => 'REST';

  @override
  String get aw_add15 => '+15 s';

  @override
  String get aw_confirm => 'COMPLETE SET';

  @override
  String get aw_next => 'NEXT';

  @override
  String get aw_last => 'End of workout';

  @override
  String get aw_pause => 'Pause workout';

  @override
  String get aw_sheet_load => 'ADJUST LOAD';

  @override
  String get aw_sheet_reps => 'ADJUST REPS';

  @override
  String get sm_done_badge => 'COMPLETED';

  @override
  String get sm_message => 'Great session. Here\'s what you built today.';

  @override
  String get sm_session => 'SESSION SUMMARY';

  @override
  String get sm_duration => 'DURATION';

  @override
  String get sm_volume => 'VOLUME';

  @override
  String get sm_kg => 'KG';

  @override
  String get sm_sets => 'SETS';

  @override
  String get sm_exercises => 'EXERCISES';

  @override
  String get sm_highlights => 'HIGHLIGHTS';

  @override
  String get sm_new_pr => 'NEW PR';

  @override
  String sm_pr_value(String exercise, String kg) {
    return '$exercise · $kg kg';
  }

  @override
  String sm_pr_delta(String kg) {
    return '+$kg kg vs. previous best';
  }

  @override
  String get sm_xp => 'XP EARNED';

  @override
  String get sm_xp_hint => 'this session';

  @override
  String get sm_muscles => 'MUSCLES WORKED';

  @override
  String get sm_emphasis_back => 'Posterior emphasis';

  @override
  String get sm_emphasis_front => 'Anterior emphasis';

  @override
  String sm_phrase_two(String a, String b) {
    return '$a and $b took most of the stimulus this session.';
  }

  @override
  String sm_phrase_one(String a) {
    return '$a took most of the stimulus this session.';
  }

  @override
  String get sm_level_high => 'HIGH';

  @override
  String get sm_level_moderate => 'MODERATE';

  @override
  String get sm_share => 'SHARE WORKOUT';

  @override
  String get sm_finish => 'DONE';

  @override
  String get sh_title => 'SHARE';

  @override
  String get sh_subtitle => 'Choose how your workout goes to your Story';

  @override
  String get sh_tab_overlay => 'OVERLAY';

  @override
  String get sh_tab_card => 'CARD';

  @override
  String get sh_preview_overlay => 'OVERLAY PREVIEW';

  @override
  String get sh_preview_card => 'CARD PREVIEW';

  @override
  String get sh_transparent => 'TRANSPARENT BACKGROUND';

  @override
  String get sh_transparent_note =>
      'The content above is exported with a transparent background.';

  @override
  String get sh_card_hint => 'Exported at 1080 × 1920';

  @override
  String get sh_overlay_title => 'Essential overlay';

  @override
  String get sh_overlay_body =>
      'Name, Muscle Map and metrics. No card, PRs or redundant info.';

  @override
  String get sh_card_title => 'BLDR editorial card';

  @override
  String get sh_card_body =>
      'Muscle Map up front, integrated metrics and less interface language.';

  @override
  String get sh_share => 'SHARE';

  @override
  String get sh_sharing => 'GENERATING IMAGE…';

  @override
  String get sh_note => 'Optimized for Instagram Stories';

  @override
  String get sh_publish => 'Post to community';

  @override
  String get sh_completed => 'WORKOUT COMPLETED';

  @override
  String get sh_duration => 'DURATION';

  @override
  String get sh_volume => 'VOLUME';

  @override
  String get sh_sets => 'SETS';

  @override
  String get sh_share_text => 'Workout completed on BLDR';

  @override
  String get sh_share_error =>
      'The image was created, but sharing could not be opened.';

  @override
  String get sh_export_error => 'Could not create the image. Try again.';

  @override
  String get wk_extra_done_title => 'Activity completed';

  @override
  String wk_workout_done(String name) {
    return '$name — completed.';
  }

  @override
  String wk_extra_done(String name) {
    return '$name — completed.';
  }

  @override
  String get wk_extra_also => 'Extra activity also logged.';

  @override
  String get wk_workout_fallback => 'Workout';

  @override
  String ed_set_title(int n) {
    return 'SET $n';
  }

  @override
  String sm_more_prs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n PRs',
      one: '+1 PR',
    );
    return '$_temp0';
  }

  @override
  String get sm_less_prs => 'Show less';

  @override
  String get wd_eyebrow => 'WORKOUT DETAILS';

  @override
  String get wd_duration => 'DURATION';

  @override
  String get wd_exercises => 'EXERCISES';

  @override
  String get wd_volume => 'VOLUME';

  @override
  String get wd_last_time => 'LAST TIME';

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
      other: '$n exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String wd_sets_count(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String wd_reps(String range) {
    return '$range reps';
  }

  @override
  String get wd_start => 'START WORKOUT';

  @override
  String get wd_preview_note => 'Preview · edit from the menu';

  @override
  String get wd_edit => 'Edit workout';

  @override
  String get wd_duplicate => 'Duplicate workout';

  @override
  String get wd_delete => 'Delete workout';

  @override
  String get wd_delete_title => 'Delete workout?';

  @override
  String wd_delete_body(String name) {
    return '$name will be removed from your workouts. This can\'t be undone.';
  }

  @override
  String get wd_error => 'Couldn\'t load the workout.';

  @override
  String get wd_retry => 'Try again';

  @override
  String get wd_empty => 'This workout has no exercises yet.';

  @override
  String get wd_options => 'Workout options';

  @override
  String get ex_title => 'EXERCISE';

  @override
  String get ex_equipment => 'EQUIPMENT';

  @override
  String get ex_sets => 'SETS';

  @override
  String get ex_how => 'HOW TO DO IT';

  @override
  String get ex_tip => 'EXECUTION TIP';

  @override
  String get ex_back => 'BACK TO WORKOUT';

  @override
  String wd_copy_name(String name) {
    return '$name (copy)';
  }

  @override
  String get wd_duplicated => 'Workout duplicated';

  @override
  String get wd_duplicate_error => 'Couldn\'t duplicate the workout.';

  @override
  String get ms_title => 'MY WEEK';

  @override
  String get ms_subtitle => 'TAP OR DRAG TO ADJUST';

  @override
  String ms_workouts_planned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts planned',
      one: '1 workout planned',
    );
    return '$_temp0';
  }

  @override
  String ms_rest_days(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rest days',
      one: '1 rest day',
    );
    return '$_temp0';
  }

  @override
  String get ms_instruction => 'DRAG OR TAP A WORKOUT TO REORGANIZE';

  @override
  String get ms_read_only => 'PAST WEEK · READ ONLY';

  @override
  String get ms_club_hint => 'THIS-WEEK ADJUSTMENTS ARE BLDR CLUB';

  @override
  String get ms_state_today => 'TODAY';

  @override
  String get ms_state_planned => 'PLANNED';

  @override
  String get ms_state_free => 'FREE';

  @override
  String get ms_state_done => 'DONE';

  @override
  String get ms_state_missed => 'MISSED';

  @override
  String get ms_state_in_progress => 'IN PROGRESS';

  @override
  String get ms_rest => 'REST';

  @override
  String get ms_free_day => 'Free day';

  @override
  String get ms_add_workout => 'Add workout';

  @override
  String get ms_management => 'MANAGE';

  @override
  String get ms_edit_plan => 'EDIT PLAN';

  @override
  String get ms_register_extra => 'LOG EXTRA';

  @override
  String get ms_footer => 'Tap to manage · hold the handle to drag';

  @override
  String get ms_workout_fallback => 'Workout';

  @override
  String get ms_actions_title => 'Day actions';

  @override
  String get ms_swap => 'Swap workout';

  @override
  String get ms_swap_sub => 'Pick another workout from the plan';

  @override
  String get ms_move => 'Move to another day';

  @override
  String get ms_move_sub => 'Reschedule this workout';

  @override
  String get ms_rest_action => 'Make it a rest day';

  @override
  String get ms_rest_action_sub =>
      'Remove from this day without deleting the workout';

  @override
  String get ms_start => 'Start workout';

  @override
  String get ms_start_sub => 'Start this workout now';

  @override
  String get ms_swap_hint => 'pick a workout from the plan';

  @override
  String get ms_confirm_swap => 'CONFIRM SWAP';

  @override
  String get ms_add_title => 'Add workout';

  @override
  String get ms_confirm_add => 'ADD WORKOUT';

  @override
  String get ms_move_title => 'Move workout';

  @override
  String get ms_move_hint => 'select the target day';

  @override
  String ms_dest_busy(String name) {
    return '$name · taken';
  }

  @override
  String get ms_dest_free => 'Rest · free';

  @override
  String get ms_dest_note => 'Taken day: the workouts will swap places.';

  @override
  String get ms_scope_title => 'APPLY TO';

  @override
  String get ms_scope_week => 'This week only';

  @override
  String get ms_scope_all => 'Every week';

  @override
  String get ms_no_templates =>
      'You don\'t have workouts yet. Create one in Workouts.';

  @override
  String get ms_club_section => 'BLDR CLUB';

  @override
  String get ms_saved_title => 'Week updated';

  @override
  String ms_saved_moved(String name, String day) {
    return '$name moved to $day';
  }

  @override
  String ms_saved_swapped(String a, String b) {
    return '$a and $b swapped days';
  }

  @override
  String ms_saved_rest(String day) {
    return '$day is now a rest day';
  }

  @override
  String ms_saved_set(String name, String day) {
    return '$name on $day';
  }

  @override
  String get ms_undo => 'UNDO';

  @override
  String get ms_save_error => 'Couldn\'t save. Your week was restored.';

  @override
  String get ms_undo_error => 'Couldn\'t undo.';

  @override
  String get ms_soon => 'Coming soon';

  @override
  String get ms_split_label => 'TRAINING SPLIT';

  @override
  String get ms_days_label => 'DAYS OF THE WEEK';

  @override
  String ms_days_summary(int t, int r) {
    return '$t workouts · $r rest';
  }

  @override
  String get ms_prev_week => 'Previous week';

  @override
  String get ms_next_week => 'Next week';

  @override
  String get ms_weekdays_short => 'MON,TUE,WED,THU,FRI,SAT,SUN';

  @override
  String get ms_weekdays_long =>
      'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';

  @override
  String get ms_weekdays_letter => 'M,T,W,T,F,S,S';

  @override
  String get ms_months =>
      'JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER';

  @override
  String get ms_months_short =>
      'JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC';

  @override
  String get comm_shortcut_search => 'Search community';

  @override
  String get comm_shortcut_private => 'Private posts';

  @override
  String get comm_shortcut_challenges => 'Challenges';

  @override
  String get comm_shortcut_ranking => 'Leaderboard';

  @override
  String get comm_shortcut_notifications => 'Notifications';

  @override
  String get comm_create_post => 'Create post';

  @override
  String get comm_tab_explore => 'Explore';

  @override
  String get comm_tab_following => 'Following';

  @override
  String get comm_tab_squads => 'Squads';

  @override
  String get comm_new_posts => 'New posts';

  @override
  String get comm_follow => 'FOLLOW';

  @override
  String get comm_following_btn => 'FOLLOWING';

  @override
  String get comm_time_now => 'now';

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
    return '$n d';
  }

  @override
  String get comm_type_workout => 'WORKOUT COMPLETED';

  @override
  String get comm_type_pr => 'NEW PR';

  @override
  String get comm_type_streak => 'STREAK';

  @override
  String get comm_type_activity => 'ACTIVITY';

  @override
  String get comm_type_imported => 'IMPORTED ACTIVITY';

  @override
  String comm_metric_volume(String value) {
    return '$value kg volume';
  }

  @override
  String comm_metric_sets(int n) {
    return '$n sets';
  }

  @override
  String comm_metric_prs(int n) {
    return '$n PRs';
  }

  @override
  String get comm_view_workout => 'View workout';

  @override
  String get comm_label_distance => 'DISTANCE';

  @override
  String get comm_label_duration => 'DURATION';

  @override
  String get comm_label_hr => 'AVG HR';

  @override
  String get comm_label_strain => 'STRAIN';

  @override
  String get comm_label_load => 'LOAD';

  @override
  String get comm_label_reps => 'REPS';

  @override
  String get comm_label_e1rm => 'EST. 1RM';

  @override
  String comm_streak_title(int n) {
    return '$n days in a row';
  }

  @override
  String get comm_activity_default => 'Activity';

  @override
  String get comm_empty_title => 'No posts yet';

  @override
  String get comm_empty_body => 'Be the first to share!';

  @override
  String get comm_error_title => 'Couldn\'t load the feed';

  @override
  String get comm_retry => 'TRY AGAIN';

  @override
  String get comm_following_empty_title => 'Follow athletes';

  @override
  String get comm_following_empty_body =>
      'See posts from people you follow here.';

  @override
  String get comm_following_empty_cta => 'FIND ATHLETES';

  @override
  String get comm_my_squad => 'MY SQUAD';

  @override
  String get comm_my_squads => 'MY SQUADS';

  @override
  String comm_squad_meta(String mode, int members) {
    return '$mode mode · $members members';
  }

  @override
  String comm_squad_week(int week) {
    return 'Week $week';
  }

  @override
  String get comm_mode_alpha => 'Alpha';

  @override
  String get comm_mode_survivor => 'Survivor';

  @override
  String get comm_mode_roadrunner => 'Roadrunner';

  @override
  String get comm_mode_hustle => 'Hustle';

  @override
  String get comm_squad_trained_today => 'TRAINED TODAY';

  @override
  String get comm_squad_ranking => 'RANKING';

  @override
  String get comm_activity_section => 'RECENT ACTIVITY';

  @override
  String get comm_activity_checkin => 'Checked in to the squad.';

  @override
  String get comm_squad_create_join => '+  CREATE OR JOIN A SQUAD';

  @override
  String get comm_squad_sheet_title => 'CREATE OR JOIN';

  @override
  String get comm_squad_code => 'I have an invite code';

  @override
  String get comm_squad_code_sub => 'Join a private Squad.';

  @override
  String get comm_squad_new => 'Create a new Squad';

  @override
  String get comm_squad_new_sub => 'Set the rules and invite your friends.';

  @override
  String get comm_squad_empty_title => 'You\'re not in any squad';

  @override
  String get comm_squad_empty_body =>
      'Create or join a squad to compete with friends.';

  @override
  String get comm_actions_title => 'Post actions';

  @override
  String get comm_action_delete => 'Delete post';

  @override
  String get comm_action_delete_sub =>
      'Removes the post, comments and reactions';

  @override
  String get comm_action_block => 'Block profile';

  @override
  String get comm_action_block_sub => 'You\'ll stop seeing each other\'s posts';

  @override
  String get comm_action_report => 'Report';

  @override
  String get comm_action_report_sub =>
      'Inappropriate content or rule violation';

  @override
  String get comm_delete_title => 'Delete post?';

  @override
  String get comm_delete_msg =>
      'The post, its comments and reactions will be removed.';

  @override
  String get comm_delete_confirm => 'Delete';

  @override
  String get comm_cancel => 'Cancel';

  @override
  String comm_block_title(String name) {
    return 'Block $name?';
  }

  @override
  String get comm_block_msg =>
      'You\'ll stop seeing each other\'s posts in the community.';

  @override
  String get comm_block_confirm => 'Block';

  @override
  String get comm_report_title => 'Report post';

  @override
  String get comm_report_spam => 'Spam';

  @override
  String get comm_report_spam_sub => 'Repetitive content or advertising';

  @override
  String get comm_report_harassment => 'Harassment';

  @override
  String get comm_report_harassment_sub => 'Insults or attacks on someone';

  @override
  String get comm_report_inappropriate => 'Inappropriate content';

  @override
  String get comm_report_inappropriate_sub =>
      'Nudity, violence or sensitive content';

  @override
  String get comm_report_false => 'False information';

  @override
  String get comm_report_false_sub => 'Misleading data or results';

  @override
  String get comm_report_other => 'Other reason';

  @override
  String get comm_report_other_sub => 'Something not on the list';

  @override
  String get comm_deleted => 'Post deleted.';

  @override
  String get comm_blocked => 'Profile blocked.';

  @override
  String get comm_reported => 'Report sent for review.';

  @override
  String get comm_react_title => 'React';

  @override
  String get comm_react_label => 'React to post';

  @override
  String get comm_comments_label => 'Comments';

  @override
  String get comm_share_label => 'Share';

  @override
  String get comm_more_label => 'More actions';

  @override
  String comm_share_text(String name, String detail) {
    return '$name on BLDR: $detail';
  }

  @override
  String comm_share_text_simple(String name) {
    return 'Check out $name\'s post on BLDR.';
  }

  @override
  String get comm_view_activity => 'View activity';

  @override
  String get comm_view_evolution => 'View progress';

  @override
  String get comm_action_edit => 'Edit post';

  @override
  String get comm_action_edit_sub => 'Change the text of this post';

  @override
  String get comm_edit_hint => 'Write your caption';

  @override
  String get comm_edit_save => 'SAVE';

  @override
  String get comm_edited => 'Post updated.';

  @override
  String comm_workout_by(String handle) {
    return 'Workout by $handle';
  }

  @override
  String get comm_label_volume => 'VOLUME';

  @override
  String get comm_label_sets => 'SETS';

  @override
  String get comm_section_exercises => 'EXERCISES';

  @override
  String get comm_exercises_empty => 'No exercises found.';

  @override
  String get comm_copy_note => 'An editable copy will be added to My Workouts.';

  @override
  String get comm_copy_cta => 'ADD TO MY WORKOUTS';

  @override
  String get comm_copying => 'ADDING…';

  @override
  String get comm_copy_done => 'Workout added to My Workouts.';

  @override
  String get comm_copy_limit =>
      'You reached the limit of 3 copies this month. Upgrade to Club.';

  @override
  String comm_set_line(int n) {
    return 'Set $n';
  }

  @override
  String comm_imported_by(String handle) {
    return 'Imported by $handle';
  }

  @override
  String get comm_label_pace => 'AVG PACE';

  @override
  String get comm_label_calories => 'CALORIES';

  @override
  String get comm_label_hr_max => 'MAX HR';

  @override
  String get comm_section_details => 'DETAILS';

  @override
  String get comm_detail_source => 'Source';

  @override
  String get comm_detail_start => 'Start';

  @override
  String get comm_activity_note =>
      'Data shared by the user from the imported activity.';

  @override
  String comm_pr_by(String handle) {
    return 'New PR by $handle';
  }

  @override
  String comm_pr_delta(String value) {
    return '$value kg vs. previous PR';
  }

  @override
  String get comm_label_prev_pr => 'PREVIOUS PR';

  @override
  String get comm_label_evolution => 'PROGRESS';

  @override
  String get comm_section_recent => 'RECENT PROGRESS';

  @override
  String get comm_today => 'Today';

  @override
  String get comm_pr_note =>
      'PR recorded in the athlete\'s performance history.';

  @override
  String get comm_pr_private => 'This athlete\'s history isn\'t available.';

  @override
  String get comm_compose_prompt => 'What do you want to share?';

  @override
  String get comm_compose_workout => 'Workout';

  @override
  String get comm_compose_wearable => 'Wearable';

  @override
  String get comm_compose_photo => 'Photo';

  @override
  String get comm_visibility => 'Visibility';

  @override
  String get comm_vis_public => 'Community';

  @override
  String get comm_vis_public_sub => 'Anyone can see it';

  @override
  String get comm_vis_squad => 'A squad';

  @override
  String get comm_vis_squad_sub => 'Choose a squad you belong to';

  @override
  String get comm_vis_private => 'Only me';

  @override
  String get comm_vis_private_sub => 'Visible only to you';

  @override
  String get comm_vis_no_squad => 'You\'re not in any squad.';

  @override
  String get comm_pick_squad => 'Choose squad';

  @override
  String get comm_publish => 'PUBLISH';

  @override
  String get comm_change => 'CHANGE';

  @override
  String get comm_workout_selected => 'SELECTED WORKOUT';

  @override
  String comm_wearable_selected(String source) {
    return '$source · SELECTED';
  }

  @override
  String get comm_workout_fallback => 'Completed workout';

  @override
  String get comm_include_prs => 'Include PRs in the post';

  @override
  String get comm_add_photo => 'Add photo';

  @override
  String get comm_optional => 'Optional';

  @override
  String get comm_photo_attached => 'PHOTO ATTACHED';

  @override
  String get comm_photo_one => '1 photo';

  @override
  String get comm_photo_swap => 'SWAP';

  @override
  String get comm_photo_remove => 'REMOVE';

  @override
  String get comm_photo_gallery => 'Gallery';

  @override
  String get comm_photo_camera => 'Take photo';

  @override
  String get comm_pick_workout => 'Select workout';

  @override
  String get comm_pick_workout_empty => 'No recent workouts.';

  @override
  String get comm_pick_wearable => 'Choose source';

  @override
  String get comm_wearable_recent => 'View 10 recent records';

  @override
  String get comm_wearable_soon => 'Coming soon';

  @override
  String get comm_wearable_note =>
      'When you select a source, you\'ll see its 10 most recent workouts and activities.';

  @override
  String get comm_records_title => 'Recent records';

  @override
  String get comm_records_empty => 'No recent activity.';

  @override
  String get comm_publish_error => 'Couldn\'t publish. Try again.';

  @override
  String get comm_post_title => 'Post';

  @override
  String get comm_section_comments => 'COMMENTS';

  @override
  String get comm_comment_hint => 'Add a comment...';

  @override
  String get comm_comment_reply => 'Reply';

  @override
  String get comm_comment_send => 'Send comment';

  @override
  String get comm_comment_edited => 'edited';

  @override
  String get comm_comment_empty => 'Be the first to comment.';

  @override
  String get comm_comment_edit => 'Edit comment';

  @override
  String get comm_comment_edit_sub => 'Change your comment\'s text';

  @override
  String get comm_comment_delete => 'Delete comment';

  @override
  String get comm_comment_delete_sub => 'Removes this comment from the post';

  @override
  String get comm_comment_delete_msg =>
      'This comment will be removed from the post.';

  @override
  String get comm_comment_actions => 'Comment actions';

  @override
  String comm_reply_to(String handle) {
    return 'Replying to $handle';
  }

  @override
  String get comm_reply_hint => 'Write a reply...';

  @override
  String get comm_reply_send => 'SEND';

  @override
  String get comm_label_kg_volume => 'KG VOLUME';

  @override
  String get comm_label_prs => 'PRS';

  @override
  String get comm_view_workout_cta => 'VIEW WORKOUT';

  @override
  String comm_rank_status(int n) {
    return '#$n RANKING';
  }

  @override
  String comm_followers(int n) {
    return '$n followers';
  }

  @override
  String comm_following_count(int n) {
    return '$n following';
  }

  @override
  String get comm_section_performance => 'PERFORMANCE';

  @override
  String get comm_label_workouts => 'WORKOUTS';

  @override
  String get comm_section_achievements => 'ACHIEVEMENTS';

  @override
  String get comm_section_posts => 'POSTS';

  @override
  String get comm_profile_no_posts => 'No posts yet.';

  @override
  String get comm_profile_error => 'Couldn\'t load this profile.';

  @override
  String get comm_profile_actions => 'Profile actions';

  @override
  String comm_open_profile(String name) {
    return 'Open $name\'s profile';
  }

  @override
  String get comm_label_active_weeks => 'ACTIVE WEEKS';

  @override
  String get comm_section_best_prs => 'BEST PRS';

  @override
  String get sq_new_title => 'New Squad';

  @override
  String get sq_new_heading => 'Create your Squad';

  @override
  String get sq_new_sub => 'Define how you\'ll compete.';

  @override
  String get sq_field_name => 'SQUAD NAME';

  @override
  String get sq_field_name_hint => 'E.g. Elite Crew';

  @override
  String get sq_field_stake => 'SQUAD STAKE · OPTIONAL';

  @override
  String get sq_field_stake_hint => 'E.g. Last place buys the smoothies.';

  @override
  String get sq_field_desc => 'DESCRIPTION · OPTIONAL';

  @override
  String get sq_field_desc_hint => 'Tell the Squad\'s goal.';

  @override
  String get sq_field_mode => 'MODE';

  @override
  String get sq_field_validation => 'VALIDATION';

  @override
  String get sq_field_duration => 'DURATION';

  @override
  String sq_duration_days(int n) {
    return '$n DAYS';
  }

  @override
  String get sq_mode_survivor_sub => 'Last one standing';

  @override
  String get sq_mode_alpha_sub => 'Accumulated XP';

  @override
  String get sq_mode_roadrunner_sub => 'Longest distance';

  @override
  String get sq_mode_hustle_sub => 'Days trained';

  @override
  String get sq_mode_survivor_info =>
      'Run out of lives and you\'re out. Photo validation.';

  @override
  String get sq_mode_alpha_info => 'Most XP in the period wins.';

  @override
  String get sq_mode_roadrunner_info =>
      'Most kilometers wins. Check-in validation.';

  @override
  String get sq_mode_hustle_info =>
      'Most days trained wins. Check-in validation.';

  @override
  String get sq_validation_photo => 'PHOTO';

  @override
  String get sq_validation_photo_sub => 'Required photo and voting';

  @override
  String get sq_validation_honor => 'HONOR';

  @override
  String get sq_validation_honor_sub => 'Manual check-in';

  @override
  String get sq_create_cta => 'CREATE SQUAD';

  @override
  String get sq_name_required => 'Give your Squad a name.';

  @override
  String get sq_created => 'Squad created. Invite your crew.';

  @override
  String get sq_create_error => 'Couldn\'t create the Squad.';

  @override
  String sq_quota_create(int left, int limit) {
    return 'You have $left of $limit creations left this month.';
  }

  @override
  String sq_quota_create_full(int limit) {
    return 'You\'ve used your $limit free creations this month. Join BLDR Club for unlimited Squads.';
  }

  @override
  String sq_quota_join(int left, int limit) {
    return 'You have $left of $limit joins left this month.';
  }

  @override
  String sq_quota_join_full(int limit) {
    return 'You\'ve used your $limit free joins this month. Join BLDR Club to continue.';
  }

  @override
  String get sq_subscribe => 'JOIN BLDR CLUB';

  @override
  String get sq_join_title => 'Join with code';

  @override
  String get sq_join_sub => 'Enter the invite code sent by the Squad admin.';

  @override
  String get sq_join_label => 'INVITE CODE';

  @override
  String get sq_join_hint => 'E.g. BLD-8K2';

  @override
  String get sq_join_cta => 'JOIN SQUAD';

  @override
  String get sq_join_not_found => 'No Squad found with this code.';

  @override
  String get sq_join_already => 'You\'re already in this Squad.';

  @override
  String sq_join_welcome(String name) {
    return 'Welcome to Squad $name.';
  }

  @override
  String get sq_join_error => 'Couldn\'t join the Squad.';

  @override
  String get sq_tab_overview => 'OVERVIEW';

  @override
  String get sq_tab_feed => 'FEED';

  @override
  String get sq_tab_ranking => 'RANKING';

  @override
  String get sq_label_today => 'TODAY';

  @override
  String sq_days_left(int n) {
    return '$n days left';
  }

  @override
  String get sq_day_left => 'Ends tomorrow';

  @override
  String get sq_last_day => 'Last day';

  @override
  String get sq_finished => 'Squad ended';

  @override
  String get sq_goal_section => 'TODAY\'S GOAL';

  @override
  String get sq_goal_default => 'Train today';

  @override
  String get sq_goal_sub => 'Your check-in keeps the Squad\'s streak.';

  @override
  String get sq_status_pending => 'Check-in under review';

  @override
  String get sq_status_approved => 'Check-in approved';

  @override
  String get sq_status_rejected => 'Check-in rejected';

  @override
  String get sq_stake_section => 'STAKE';

  @override
  String get sq_about_section => 'ABOUT';

  @override
  String get sq_activity_section => 'SQUAD ACTIVITY';

  @override
  String get sq_activity_empty => 'No activity yet.';

  @override
  String get sq_activity_checkin => 'checked in';

  @override
  String get sq_tribunal => 'Tribunal';

  @override
  String get sq_tribunal_sub => 'Photo proofs and member voting';

  @override
  String get sq_history => 'Squad history';

  @override
  String get sq_history_sub => 'Recorded check-ins and points';

  @override
  String get sq_feed_section => 'RECENT ACTIVITY';

  @override
  String get sq_feed_checkin => 'CHECK-IN';

  @override
  String sq_week(int week) {
    return 'WEEK $week';
  }

  @override
  String get sq_you => 'You';

  @override
  String sq_score_days(int n) {
    return '$n days';
  }

  @override
  String sq_score_points(int n) {
    return '$n pts';
  }

  @override
  String sq_score_km(String value) {
    return '$value km';
  }

  @override
  String sq_lives(int n) {
    return '$n lives';
  }

  @override
  String get sq_eliminated_section => 'ELIMINATED';

  @override
  String get sq_chat => 'CHAT';

  @override
  String get sq_checkin => 'CHECK-IN';

  @override
  String get sq_checkin_closed => 'ENDED';

  @override
  String get sq_checkin_done => 'Activity logged to the Squad.';

  @override
  String get sq_load_error => 'Couldn\'t load this Squad.';

  @override
  String get sq_settings_label => 'Squad settings';

  @override
  String get sq_share_label => 'Share Squad';

  @override
  String sq_share_sub(String name) {
    return 'Invite people to $name';
  }

  @override
  String get sq_share_invite => 'Share invite';

  @override
  String get sq_share_invite_sub => 'Send with your favorite app.';

  @override
  String get sq_share_link => 'Copy link';

  @override
  String get sq_share_link_sub => 'Direct link to the Squad.';

  @override
  String get sq_share_code => 'Copy code';

  @override
  String get sq_copied => 'Copied.';

  @override
  String sq_invite_text(String name, String link, String code) {
    return 'Join Squad $name on BLDR.\n\nLink: $link\nCode: $code';
  }

  @override
  String get sq_chat_title => 'Squad chat';

  @override
  String get sq_chat_info => 'Messages visible only to Squad members.';

  @override
  String get sq_chat_hint => 'Message the Squad...';

  @override
  String get sq_chat_empty => 'No messages yet.';

  @override
  String get sq_chat_send => 'Send message';

  @override
  String get sq_chat_error => 'Couldn\'t send the message.';

  @override
  String get sq_section_general => 'GENERAL';

  @override
  String get sq_section_rules => 'RULES';

  @override
  String get sq_section_danger => 'DANGER ZONE';

  @override
  String get sq_info => 'Squad information';

  @override
  String get sq_info_sub => 'Name, stake and details.';

  @override
  String get sq_info_sheet_sub => 'Edit the group\'s main details.';

  @override
  String get sq_members => 'Members';

  @override
  String sq_members_count(int n) {
    return '$n members';
  }

  @override
  String get sq_members_sub => 'Manage who is in the Squad.';

  @override
  String get sq_role_admin => 'Admin';

  @override
  String get sq_role_member => 'Member';

  @override
  String get sq_role_eliminated => 'Eliminated';

  @override
  String get sq_invite_members => 'INVITE MEMBERS';

  @override
  String get sq_kick => 'Remove from Squad';

  @override
  String sq_kick_sub(String name) {
    return '$name will leave the Squad.';
  }

  @override
  String sq_kick_msg(String name) {
    return '$name loses access to this Squad\'s feed, chat and ranking.';
  }

  @override
  String get sq_kick_confirm => 'Remove';

  @override
  String get sq_goal => 'Daily goal';

  @override
  String get sq_goal_none => 'No custom goal.';

  @override
  String get sq_goal_sheet_sub => 'Set an optional goal for the group.';

  @override
  String get sq_goal_label => 'DESCRIPTION';

  @override
  String get sq_goal_hint => 'E.g. complete at least one workout.';

  @override
  String get sq_goal_help =>
      'The goal shows in the Overview and can be edited anytime.';

  @override
  String get sq_goal_save => 'SAVE GOAL';

  @override
  String get sq_rules => 'Scoring rules';

  @override
  String get sq_rules_sheet_sub => 'See how the Squad ranking works.';

  @override
  String get sq_rules_label => 'CURRENT MODE';

  @override
  String get sq_rules_note =>
      'The Squad mode can\'t be changed after creation.';

  @override
  String get sq_rules_ok => 'GOT IT';

  @override
  String get sq_rules_alpha =>
      'Check-in +10 XP · per minute +1 XP · per km +10 XP · different activity that day +15 XP.';

  @override
  String get sq_rules_survivor =>
      'Everyone starts with 2 lives. A rejected photo costs 1 life; at 0 lives you\'re eliminated.';

  @override
  String get sq_rules_roadrunner =>
      'Ranking by accumulated kilometers. Each check-in logs your km on the honor system.';

  @override
  String get sq_rules_hustle =>
      'Ranking by days trained. Several workouts in a day count as 1 point.';

  @override
  String get sq_xp_limit => 'DAILY XP CAP';

  @override
  String get sq_xp_limit_hint => '0 = no limit';

  @override
  String get sq_save => 'SAVE CHANGES';

  @override
  String get sq_saved => 'Changes saved.';

  @override
  String get sq_save_error => 'Couldn\'t save.';

  @override
  String get sq_leave => 'Leave Squad';

  @override
  String get sq_leave_sub => 'You\'ll stop participating.';

  @override
  String get sq_leave_body =>
      'If you leave, you lose access to this Squad\'s feed, chat and ranking.';

  @override
  String get sq_leave_note => 'You can only rejoin with an invite or code.';

  @override
  String get sq_leave_cta => 'LEAVE SQUAD';

  @override
  String get sq_end => 'End Squad';

  @override
  String get sq_end_sub => 'Delete the Squad permanently.';

  @override
  String get sq_end_body =>
      'Ending the Squad removes members, history, ranking and messages.';

  @override
  String get sq_end_note => 'This action is permanent and can\'t be undone.';

  @override
  String get sq_end_cta => 'END SQUAD';

  @override
  String get sq_ended => 'Squad ended.';

  @override
  String get chal_title => 'Challenges';

  @override
  String get chal_subtitle => 'Compete, improve and track your progress.';

  @override
  String get chal_create => 'Create';

  @override
  String get chal_tab_active => 'ACTIVE';

  @override
  String get chal_tab_discover => 'DISCOVER';

  @override
  String get chal_tab_done => 'COMPLETED';

  @override
  String get chal_sec_featured => 'FEATURED';

  @override
  String get chal_sec_others => 'OTHER CHALLENGES';

  @override
  String get chal_sec_ending => 'ENDING SOON';

  @override
  String get chal_sec_recommended => 'RECOMMENDED FOR YOU';

  @override
  String get chal_sec_trending => 'TRENDING';

  @override
  String get chal_sec_new => 'NEW CHALLENGES';

  @override
  String get chal_sec_last => 'LATEST RESULT';

  @override
  String get chal_sec_history => 'HISTORY';

  @override
  String chal_days_left(int days) {
    return '$days days left';
  }

  @override
  String get chal_last_day => 'Last day';

  @override
  String chal_participants(String a) {
    return '$a participants';
  }

  @override
  String chal_ends_in(int days, int pct) {
    return 'Ends in $days days · $pct% complete';
  }

  @override
  String get chal_view => 'VIEW CHALLENGE';

  @override
  String chal_prog_xp(String a, String b) {
    return '$a / $b XP';
  }

  @override
  String chal_prog_workouts(String a, String b) {
    return '$a / $b workouts';
  }

  @override
  String chal_prog_streak(String a, String b) {
    return '$a / $b days';
  }

  @override
  String chal_goal(String a) {
    return 'GOAL · $a';
  }

  @override
  String chal_unit_xp(String a) {
    return '$a XP';
  }

  @override
  String chal_unit_workouts(String a) {
    return '$a workouts';
  }

  @override
  String chal_unit_streak(String a) {
    return '$a streak days';
  }

  @override
  String chal_duration_days(int days) {
    return '$days days';
  }

  @override
  String chal_ended_on(String a) {
    return 'Ended on $a';
  }

  @override
  String get chal_ended => 'ENDED';

  @override
  String get chal_position => 'POSITION';

  @override
  String chal_of_total(String a) {
    return 'of $a';
  }

  @override
  String get chal_empty_active => 'You haven\'t joined any challenge yet.';

  @override
  String get chal_empty_discover => 'No new challenges right now.';

  @override
  String get chal_empty_done => 'Your finished challenges show up here.';

  @override
  String get chal_load_error => 'Couldn\'t load challenges.';

  @override
  String get chal_retry => 'TRY AGAIN';

  @override
  String get chal_how => 'HOW IT WORKS';

  @override
  String get chal_how_xp =>
      'Every XP earned during the challenge counts toward the group goal.';

  @override
  String get chal_how_workouts =>
      'Every workout completed during the challenge counts toward the group goal.';

  @override
  String get chal_how_streak =>
      'Your longest training streak during the challenge counts toward the group goal.';

  @override
  String get chal_join => 'JOIN CHALLENGE';

  @override
  String get chal_see_all => 'SEE ALL';

  @override
  String get chal_new_title => 'Create challenge';

  @override
  String get chal_step1 => '1 OF 3 · DETAILS';

  @override
  String get chal_step2 => '2 OF 3 · RULES';

  @override
  String get chal_step3 => '3 OF 3 · REVIEW';

  @override
  String get chal_cover => 'COVER IMAGE';

  @override
  String get chal_cover_add => 'Add cover image';

  @override
  String get chal_cover_hint => 'JPG or PNG · up to 5 MB';

  @override
  String get chal_cover_big => 'The image must be 5 MB or less.';

  @override
  String get chal_cover_note =>
      'The cover appears in the Hub and on the challenge details.';

  @override
  String get chal_name => 'CHALLENGE NAME';

  @override
  String get chal_name_hint => 'E.g. 30 days without missing';

  @override
  String get chal_desc => 'DESCRIPTION';

  @override
  String get chal_desc_hint => 'Explain what the challenge is about...';

  @override
  String get chal_continue => 'CONTINUE';

  @override
  String get chal_counts => 'WHAT COUNTS?';

  @override
  String get chal_metric_workouts => 'Completed workouts';

  @override
  String get chal_metric_workouts_sub => 'Each workout finished in BLDR';

  @override
  String get chal_metric_streak => 'Longest streak';

  @override
  String get chal_metric_streak_sub => 'Consistency over consecutive days';

  @override
  String get chal_metric_xp => 'Accumulated XP';

  @override
  String get chal_metric_xp_sub => 'All XP earned during the challenge';

  @override
  String get chal_goal_label => 'GOAL';

  @override
  String get chal_duration => 'Duration';

  @override
  String get chal_duration_upper => 'DURATION';

  @override
  String get chal_who => 'WHO CAN JOIN?';

  @override
  String get chal_public => 'PUBLIC';

  @override
  String get chal_friends_soon => 'FRIENDS · SOON';

  @override
  String get chal_squad_soon => 'SQUAD · SOON';

  @override
  String get chal_public_note => 'Public challenges may appear in Discover.';

  @override
  String get chal_metrics_title => 'Available metrics';

  @override
  String get chal_metrics_list =>
      'Completed workouts · Longest streak · Accumulated XP';

  @override
  String chal_review_meta(String a, int days) {
    return '$a · $days days long';
  }

  @override
  String get chal_before => 'BEFORE PUBLISHING';

  @override
  String get chal_before_title => 'The challenge starts when you publish.';

  @override
  String get chal_before_body =>
      'After publishing you can adjust the goal on the challenge screen. The main metric can\'t change.';

  @override
  String get chal_publish => 'PUBLISH CHALLENGE';

  @override
  String get chal_publishing => 'PUBLISHING...';

  @override
  String get rank_title => 'Ranking';

  @override
  String get rank_subtitle => 'Compare your performance with the community.';

  @override
  String get rank_tab_global => 'GLOBAL';

  @override
  String get rank_period => 'PERIOD';

  @override
  String get rank_week => 'WEEK';

  @override
  String get rank_month => 'MONTH';

  @override
  String get rank_all => 'ALL TIME';

  @override
  String get rank_metric => 'METRIC';

  @override
  String get rank_volume => 'VOLUME';

  @override
  String get rank_consistency => 'CONSISTENCY';

  @override
  String get rank_progression => 'PROGRESSION';

  @override
  String get rank_mine => 'YOUR POSITION';

  @override
  String get rank_top3 => 'TOP 3';

  @override
  String get rank_list => 'STANDINGS';

  @override
  String get rank_you => 'You';

  @override
  String rank_workouts(String a) {
    return '$a workouts';
  }

  @override
  String get rank_lock => 'See the top 50 with Club';

  @override
  String get rank_empty => 'No data for this period.';

  @override
  String get rank_error => 'Couldn\'t load the ranking.';

  @override
  String get notif_mark_all => 'Mark as read';

  @override
  String get notif_tab_all => 'ALL';

  @override
  String get notif_tab_social => 'SOCIAL';

  @override
  String get notif_tab_perf => 'PERFORMANCE';

  @override
  String get notif_today => 'TODAY';

  @override
  String get notif_yesterday => 'YESTERDAY';

  @override
  String get notif_week => 'THIS WEEK';

  @override
  String get notif_older => 'EARLIER';

  @override
  String notif_yesterday_at(String a) {
    return 'yesterday, $a';
  }

  @override
  String get notif_empty_tab => 'Nothing here in this tab.';

  @override
  String get notif_confirm_workout => 'Confirm workout';

  @override
  String get notif_welcome => 'Say welcome';

  @override
  String get priv_title => 'Private posts';

  @override
  String get priv_subtitle => 'Visible only to you';

  @override
  String get priv_recent => 'RECENT';

  @override
  String get priv_about => 'ABOUT PRIVATE POSTS';

  @override
  String get priv_about_body =>
      'Choose \"Only me\" when creating a post to keep it here, away from the feed.';

  @override
  String get priv_empty => 'You haven\'t published private posts yet.';

  @override
  String comm_pick_workout_sub(int n) {
    return '$n most recent workouts';
  }

  @override
  String get comm_photo_sheet_sub => 'Add a photo to the post';

  @override
  String get comm_photo_gallery_sub => 'Pick an existing photo';

  @override
  String get comm_photo_camera_sub => 'Open the camera';

  @override
  String get comm_add_photo_record => 'Add photo to the record';

  @override
  String get comm_squad_sheet_sub => 'Choose how you want to join a Squad.';

  @override
  String get comm_squad_cancel => 'CANCEL';

  @override
  String get toast_undo => 'Undo';

  @override
  String get toast_dismiss_hint => 'Swipe up to dismiss';

  @override
  String get toast_offline => 'You are offline';

  @override
  String get toast_back_online => 'Back online';

  @override
  String get nutri2_eyebrow => 'NUTRITION';

  @override
  String get nutri2_title => 'Your day';

  @override
  String nutri2_date_today(String date) {
    return 'Today, $date';
  }

  @override
  String nutri2_date_yesterday(String date) {
    return 'Yesterday, $date';
  }

  @override
  String get nutri2_pill_today => 'TODAY';

  @override
  String nutri2_kcal_goal(String goal) {
    return 'of $goal kcal';
  }

  @override
  String nutri2_macro_goal(String goal) {
    return 'of ${goal}g';
  }

  @override
  String get nutri2_protein => 'Protein';

  @override
  String get nutri2_carbs => 'Carbs';

  @override
  String get nutri2_fat => 'Fat';

  @override
  String get nutri2_iqd_title => 'DIET QUALITY INDEX • DQI';

  @override
  String get nutri2_iqd_very_good => 'VERY GOOD';

  @override
  String get nutri2_iqd_regular => 'FAIR';

  @override
  String get nutri2_iqd_poor => 'POOR';

  @override
  String nutri2_iqd_delta_up(int n) {
    return '$n points above the weekly average';
  }

  @override
  String nutri2_iqd_delta_down(int n) {
    return '$n points below the weekly average';
  }

  @override
  String get nutri2_iqd_delta_same => 'Same as the weekly average';

  @override
  String get nutri2_iqd_locked => 'DQI available in BLDR CLUB';

  @override
  String get nutri2_hydration => 'HYDRATION';

  @override
  String nutri2_water_goal(String liters) {
    return 'of $liters L';
  }

  @override
  String get nutri2_water_add => 'Add water';

  @override
  String get nutri2_meals_today => 'TODAY\'S MEALS';

  @override
  String get nutri2_meals_day => 'MEALS OF THE DAY';

  @override
  String get nutri2_edit_meals => 'Edit foods';

  @override
  String get nutri2_edit_done => 'Finish editing';

  @override
  String get nutri2_add_food => 'ADD FOOD';

  @override
  String get nutri2_add_food_a11y => 'Add food';

  @override
  String get nutri2_meal_empty => 'No food added';

  @override
  String get nutri2_macro_protein => 'PROTEIN';

  @override
  String get nutri2_macro_carbs => 'CARBS';

  @override
  String get nutri2_macro_fat => 'FAT';

  @override
  String nutri2_food_macros(String kcal, String p, String c, String f) {
    return '$kcal kcal   P ${p}g   C ${c}g   F ${f}g';
  }

  @override
  String get nutri2_edit_food => 'Edit food';

  @override
  String get nutri2_remove_food => 'Remove food';

  @override
  String get nutri2_date_sheet_title => 'Choose day';

  @override
  String get nutri2_today => 'Today';

  @override
  String get nutri2_yesterday => 'Yesterday';

  @override
  String get nutri2_water_sheet_eyebrow => 'HYDRATION';

  @override
  String get nutri2_water_sheet_title => 'Add water';

  @override
  String get nutri2_water_sheet_subtitle => 'Log how much you just drank.';

  @override
  String get nutri2_water_quick => 'QUICK ADD';

  @override
  String get nutri2_water_custom => 'CUSTOM';

  @override
  String get nutri2_water_today => 'TODAY';

  @override
  String nutri2_water_today_value(String value, String goal) {
    return '$value L of $goal L';
  }

  @override
  String get nutri2_water_cta => 'ADD WATER';

  @override
  String get nutri2_water_less => 'Decrease';

  @override
  String get nutri2_water_more => 'Increase';

  @override
  String get nutri2_water_remove_title => 'Remove water';

  @override
  String nutri2_toast_added(String meal) {
    return 'Food added to $meal';
  }

  @override
  String get nutri2_toast_updated => 'Food updated';

  @override
  String get nutri2_toast_removed => 'Food removed';

  @override
  String get nutri2_toast_remove_error => 'Could not remove the food';

  @override
  String get nutri2_toast_save_error => 'Could not save. Try again.';

  @override
  String nutri2_toast_water_added(String ml) {
    return '+$ml ml of water';
  }

  @override
  String nutri2_toast_water_removed(String ml) {
    return '−$ml ml of water';
  }

  @override
  String get nutri2_toast_water_error => 'Could not log water';

  @override
  String get nutri2_toast_goal_title => 'Daily goal reached!';

  @override
  String get nutri2_toast_water_goal => 'Hydration goal reached!';

  @override
  String get nutri2_toast_water_goal_desc => 'You reached your hydration goal.';

  @override
  String get nutri2_toast_water_goal_label => 'Daily hydration';

  @override
  String get nutri2_toast_protein_goal => 'Protein goal reached!';

  @override
  String get nutri2_toast_protein_goal_desc =>
      'You reached your daily protein goal.';

  @override
  String get nutri2_toast_protein_goal_label => 'Daily protein';

  @override
  String get nutri2_toast_targets_updated => 'Goals updated';
}
