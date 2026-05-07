// lib/core/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';

  // Endpoints específicos
  static String get auth => '$baseUrl/auth';
  static String get operaciones => '$baseUrl/operaciones';
  static String get estaciones => '$baseUrl/estaciones';

  // Headers comunes
  static Map<String, String> headers({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}