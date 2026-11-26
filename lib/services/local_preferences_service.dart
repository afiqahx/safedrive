import 'package:shared_preferences/shared_preferences.dart';

class LocalAlertPreferences {
  const LocalAlertPreferences({
    required this.buzzerEnabled,
    required this.mobileNotificationsEnabled,
  });

  final bool buzzerEnabled;
  final bool mobileNotificationsEnabled;
}

class LocalPreferencesService {
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static String _buzzerKey(int userID) => 'safedrive_buzzer_$userID';
  static String _notificationsKey(int userID) =>
      'safedrive_notifications_$userID';

  static Future<LocalAlertPreferences> loadAlertPreferences(int userID) async {
    return LocalAlertPreferences(
      buzzerEnabled: await _preferences.getBool(_buzzerKey(userID)) ?? true,
      mobileNotificationsEnabled:
          await _preferences.getBool(_notificationsKey(userID)) ?? true,
    );
  }

  static Future<void> saveAlertPreferences({
    required int userID,
    required bool buzzerEnabled,
    required bool mobileNotificationsEnabled,
  }) async {
    await _preferences.setBool(_buzzerKey(userID), buzzerEnabled);
    await _preferences.setBool(
      _notificationsKey(userID),
      mobileNotificationsEnabled,
    );
  }
}
