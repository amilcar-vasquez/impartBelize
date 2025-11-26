import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/education.dart';
import '../models/qualification.dart';
import '../models/document.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class ApplicationService {
  final AuthService _authService = AuthService();

  static String get baseUrl => AppConfig.apiBaseUrl;

  // ==================== Education Endpoints ====================

  /// Creates a new education record
  Future<Education> createEducation(Map<String, dynamic> educationData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/education'),
        headers: headers,
        body: json.encode(educationData),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Education.fromJson(data['education']);
      } else {
        String errorMessage =
            'Failed to create education: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error creating education: $e');
    }
  }

  /// Gets education records for a teacher
  Future<List<Education>> getEducationByTeacher(int teacherId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$teacherId/education'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> educationJson = data['education'] ?? [];
        return educationJson.map((json) => Education.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load education: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching education: $e');
    }
  }

  /// Deletes an education record
  Future<void> deleteEducation(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/education/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete education: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting education: $e');
    }
  }

  // ==================== Qualification Endpoints ====================

  /// Creates a new qualification record
  Future<Qualification> createQualification(
    Map<String, dynamic> qualificationData,
  ) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/qualifications'),
        headers: headers,
        body: json.encode(qualificationData),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Qualification.fromJson(data['qualification']);
      } else {
        String errorMessage =
            'Failed to create qualification: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error creating qualification: $e');
    }
  }

  /// Gets qualification records for a teacher
  Future<List<Qualification>> getQualificationsByTeacher(int teacherId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$teacherId/qualifications'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> qualificationsJson = data['qualifications'] ?? [];
        return qualificationsJson
            .map((json) => Qualification.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load qualifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching qualifications: $e');
    }
  }

  /// Deletes a qualification record
  Future<void> deleteQualification(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/qualifications/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete qualification: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting qualification: $e');
    }
  }

  // ==================== Document Endpoints ====================

  /// Creates a new document record
  Future<Document> createDocument(Map<String, dynamic> documentData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/documents'),
        headers: headers,
        body: json.encode(documentData),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Document.fromJson(data['document']);
      } else {
        String errorMessage =
            'Failed to create document: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error creating document: $e');
    }
  }

  /// Gets documents for a teacher
  Future<List<Document>> getDocumentsByTeacher(int teacherId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$teacherId/documents'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> documentsJson = data['documents'] ?? [];
        return documentsJson.map((json) => Document.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load documents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching documents: $e');
    }
  }

  /// Deletes a document record
  Future<void> deleteDocument(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/documents/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete document: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }

  // ==================== Mock File Upload ====================

  /// Mock function to simulate uploading a file to Supabase
  /// In production, this would use the Supabase Storage API
  Future<String> uploadFileToSupabase(
    String filePath,
    String bucket,
    String fileName,
  ) async {
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 2));

    // Return a mock URL that would be returned by Supabase
    // In production, this would be:
    // final supabase = Supabase.instance.client;
    // final response = await supabase.storage.from(bucket).upload(fileName, File(filePath));
    // return supabase.storage.from(bucket).getPublicUrl(fileName);

    return 'https://mock-supabase-url.com/storage/v1/object/public/$bucket/$fileName';
  }
}
