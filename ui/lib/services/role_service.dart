import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/role.dart';
import 'auth_service.dart';

class RoleService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();

  /// Fetches all roles from the API
  Future<List<Role>> fetchRoles() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/roles'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> rolesJson = data['roles'] ?? [];
        return rolesJson.map((json) => Role.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching roles: $e');
    }
  }
}
