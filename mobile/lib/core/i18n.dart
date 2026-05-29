class I18n {
  static const Map<String, String> _t = {
    'welcome_title': 'Welcome to Farmly',
    'welcome_sub':
        'Your personal agricultural assistant. Ask me anything or choose an option below.',
    'select_or_create_chat': 'Select or create a chat',
    'ask_hint': 'Ask Farmly for advice...',
    'recommend_crop': 'Recommend a crop',
    'check_weather': 'Check the weather',
    'diagnose_plant': 'Diagonise my plant',
    'fertilizer_advice': 'Fertilizer advice',
    'profile_title': 'Profile & Settings',
    'full_name': 'Full name',
    'phone_number': 'Phone number',
    'language': 'Language',
    'save_profile': 'Save profile',
    'cancel': 'Cancel',
    'change_password': 'Change password',
    'current_password': 'Current password',
    'new_password': 'New password',
    'confirm_new_password': 'Confirm new password',
    'change_password_btn': 'Change password',
    'logout': 'Logout',
    'passwords_must_match': 'Passwords must match',
    'profile_updated': 'Profile updated successfully',
    'password_changed': 'Password changed',
    'phone_updated': 'Phone number updated',
    'language_changed': 'Language changed',
    'error_validation': 'Please fix the errors and try again',
    'login_success': 'Logged in',
    'logout_success': 'Logged out',
    'saved_changes': 'Changes saved',
    'invalid_response': 'Invalid response from server.',
    'send_failed': 'Failed to send. Please try again.',
    'required': 'Required',
    'setup_profile_title': 'Set up your profile',
    'setup_profile_sub': 'Help us personalise your experience.',
    'choose_language': 'Choose Language',
    'preferred_language': 'Preferred Language',
    'location_label': 'Location',
    'crops_grown_optional': 'Crops Grown (optional)',
    'finish_setup': 'Finish Setup',
  };

  static String t(String key) => _t[key] ?? key;
  static String get lang => 'en';
  static Future<void> init() async {}
  static Future<void> setLanguage(String l) async {}
}
