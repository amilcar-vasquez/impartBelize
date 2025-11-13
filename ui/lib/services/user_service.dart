import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class UserService {
  final String baseUrl = AppConfig.apiBaseUrl;

  /// Registers a new user. Sends username, email, password and default role_id = 3
  /// Throws an Exception on failure with a readable message.
  Future<void> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users');

    final payload = {
      'username': username,
      'email': email,
      'password': password,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // success - nothing else to do
        return;
      }

      // attempt to decode error message
      try {
        final body = json.decode(response.body);
        if (body is Map && (body['error'] != null || body['message'] != null)) {
          throw Exception(body['error'] ?? body['message']);
        }
      } catch (_) {
        // ignore decode errors
      }

      throw Exception('Failed to register user: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Activates a user account with the provided 6-digit activation code.
  /// Sends PUT request to /users/activated
  /// Throws an Exception on failure with a readable message.
  Future<void> activateUser(String code) async {
    final url = Uri.parse('$baseUrl/users/activated');

    final payload = {'token': code};

    try {
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // success
        return;
      }

      // attempt to decode error message
      try {
        final body = json.decode(response.body);
        if (body is Map && (body['error'] != null || body['message'] != null)) {
          throw Exception(body['error'] ?? body['message']);
        }
      } catch (_) {
        // ignore decode errors
      }

      throw Exception('Failed to activate account: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }
}
