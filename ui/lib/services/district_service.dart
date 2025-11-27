import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/district.dart';
import '../models/pagination_metadata.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class DistrictService {
  final AuthService _authService = AuthService();

  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Fetches all districts from the API
  Future<Map<String, dynamic>> fetchDistricts() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/districts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> districtsJson = data['districts'] ?? [];
        final districts = districtsJson
            .map((json) => District.fromJson(json))
            .toList();

        final metadata = data['metadata'] != null
            ? PaginationMetadata.fromJson(data['metadata'])
            : null;

        return {
          'districts': districts,
          'metadata': metadata,
        };
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching districts: $e');
    }
  }

  /// Fetches a single district by ID
  Future<District> fetchDistrict(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/districts/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return District.fromJson(data['district']);
      } else {
        throw Exception('Failed to load district: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching district: $e');
    }
  }

  /// Creates a new district
  Future<District> createDistrict(String name) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/districts'),
        headers: headers,
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return District.fromJson(data['district']);
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Failed to create district: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        } catch (_) {
          // Use default error message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error creating district: $e');
    }
  }

  /// Deletes a district
  Future<void> deleteDistrict(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/districts/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        String errorMessage =
            'Failed to delete district: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        } catch (_) {
          // Use default error message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error deleting district: $e');
    }
  }
}
