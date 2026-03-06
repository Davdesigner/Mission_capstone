import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  // Keys for shared preferences
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserData = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  // Initialize shared preferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save auth token
  Future<bool> saveAuthToken(String token) async {
    await init();
    return await _prefs!.setString(_keyAuthToken, token);
  }

  // Get auth token
  Future<String?> getAuthToken() async {
    await init();
    return _prefs!.getString(_keyAuthToken);
  }

  // Save user data
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    await init();
    final userDataString = json.encode(userData);
    return await _prefs!.setString(_keyUserData, userDataString);
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    await init();
    final userDataString = _prefs!.getString(_keyUserData);
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }

  // Set logged in status
  Future<bool> setLoggedIn(bool value) async {
    await init();
    return await _prefs!.setBool(_keyIsLoggedIn, value);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    await init();
    return _prefs!.getBool(_keyIsLoggedIn) ?? false;
  }

  // Clear all stored data (logout)
  Future<bool> clearAll() async {
    await init();
    return await _prefs!.clear();
  }

  // Clear specific keys
  Future<void> logout() async {
    await init();
    await _prefs!.remove(_keyAuthToken);
    await _prefs!.remove(_keyUserData);
    await _prefs!.setBool(_keyIsLoggedIn, false);
  }
}
