import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/institution.dart';
import '../models/pagination_metadata.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class InstitutionService {
  final AuthService _authService = AuthService();

  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Fetches all institutions from the API
  Future<Map<String, dynamic>> fetchInstitutions() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/institutions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> institutionsJson = data['institutions'] ?? [];
        final institutions = institutionsJson
            .map((json) => Institution.fromJson(json))
            .toList();

        final metadata = data['metadata'] != null
            ? PaginationMetadata.fromJson(data['metadata'])
            : null;

        return {
          'institutions': institutions,
          'metadata': metadata,
        };
      } else {
        throw Exception('Failed to load institutions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching institutions: $e');
    }
  }

  /// Fetches a single institution by ID
  Future<Institution> fetchInstitution(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/institutions/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Institution.fromJson(data['institution']);
      } else {
        throw Exception('Failed to load institution: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching institution: $e');
    }
  }

  /// Creates a new institution
  Future<Institution> createInstitution({
    required String name,
    int? districtId,
    String? institutionType,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final body = {
        'name': name,
        if (districtId != null) 'district_id': districtId,
        if (institutionType != null && institutionType.isNotEmpty)
          'institution_type': institutionType,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/institutions'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Institution.fromJson(data['institution']);
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Failed to create institution: ${response.statusCode}';
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
      throw Exception('Error creating institution: $e');
    }
  }

  /// Deletes an institution
  Future<void> deleteInstitution(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/institutions/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        String errorMessage =
            'Failed to delete institution: ${response.statusCode}';
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
      throw Exception('Error deleting institution: $e');
    }
  }
}
