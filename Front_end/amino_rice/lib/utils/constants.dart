import 'package:flutter/material.dart';

/// App-wide constants and configuration
class AppConstants {
  // App Information
  static const String appName = 'AminoRice';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'AI-powered rice quality assessment application';

  // API Configuration
  // Using hosted API endpoint
  static const String apiBaseUrl =
      'https://mission-capstone-1-hyqa.onrender.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF66BB6A);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryGreen,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: darkGreen,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 15.0;

  // Animation Assets
  static const String farmerAnimationPath = 'assets/farmer.json';
  static const String logisticsAnimationPath = 'assets/Farmer_Logistics.json';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;

  // Image Upload
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  static const int maxImageSizeMB = 10;

  // Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String serverErrorMessage =
      'Server error. Please try again later.';
  static const String unauthorizedMessage = 'Unauthorized. Please login again.';
  static const String successMessage = 'Operation successful!';
}

/// Route names for navigation
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String scanning = '/scanning';
  static const String history = '/history';
  static const String chatbot = '/chatbot';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// SharedPreferences keys
class PreferenceKeys {
  static const String isLoggedIn = 'is_logged_in';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String authToken = 'auth_token';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
}
