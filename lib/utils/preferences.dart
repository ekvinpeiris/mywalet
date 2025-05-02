

import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String authTokenKey = 'auth_token';

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(authTokenKey);
  }

  static Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(authTokenKey, token);
  }

  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authTokenKey);
  }
}