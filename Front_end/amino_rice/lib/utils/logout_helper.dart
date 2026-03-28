import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';

Future<void> logoutAndNavigateToWelcome(BuildContext context) async {
  await StorageService().logout();
  ApiService().clearAuthToken();

  if (!context.mounted) {
    return;
  }

  Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
}
