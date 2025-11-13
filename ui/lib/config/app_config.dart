import 'dart:io';
import 'package:flutter/foundation.dart';

/// Application configuration constants
class AppConfig {
  // API Configuration
  // Use different URLs based on platform:
  // - Android emulator: 10.0.2.2 (maps to host machine's localhost)
  // - iOS simulator/Web/Desktop: localhost
  // - Physical device: Use your computer's local IP (e.g., 192.168.x.x)
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:4000/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000/v1';
    } else {
      // iOS simulator, desktop, or other platforms
      return 'http://localhost:4000/v1';
    }
  }

  // App Information
  static const String appName = 'Impart Belize';
  static const String appVersion = '1.0.0';

  // UI Configuration
  static const double mobileBreakpoint = 640;
  static const double tabletBreakpoint = 840;

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
}
