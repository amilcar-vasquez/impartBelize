/// Application configuration constants
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:4000/v1';
  
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
