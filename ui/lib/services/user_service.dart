import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/pagination_metadata.dart';
import 'auth_service.dart';

class UserService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();

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

  /// Fetches all users with pagination and optional filters
  Future<Map<String, dynamic>> fetchUsers({
    int page = 1,
    int pageSize = 10,
    String? sort,
    int? regionId,
    int? formationId,
    int? rankId,
    bool? isActive,
    String? lastName,
    String? username,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();

      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (sort != null) 'sort': sort,
        if (regionId != null) 'region_id': regionId.toString(),
        if (formationId != null) 'formation_id': formationId.toString(),
        if (rankId != null) 'rank_id': rankId.toString(),
        if (isActive != null) 'is_active': isActive.toString(),
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        if (username != null && username.isNotEmpty) 'username': username,
      };

      final uri = Uri.parse(
        '$baseUrl/users',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> usersJson = data['users'] ?? [];
        final users = usersJson.map((json) => User.fromJson(json)).toList();

        final metadata = data['metadata'] != null
            ? PaginationMetadata.fromJson(data['metadata'])
            : null;

        return {'users': users, 'metadata': metadata};
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  /// Fetches a single user by ID
  Future<User> fetchUser(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  /// Updates an existing user
  Future<User> updateUser(int id, Map<String, dynamic> updates) async {
    try {
      final headers = await _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else if (response.statusCode == 409) {
        throw Exception('Edit conflict - user was modified by another request');
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception('Validation failed: ${error['error']}');
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  /// Deletes a user (soft delete - sets is_active to false)
  Future<void> deleteUser(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
}
