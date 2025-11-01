import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/teacher.dart';
import '../config/app_config.dart';

class ApiService {
  // Get base URL from configuration
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Fetches all teachers from the API
  Future<List<Teacher>> fetchTeachers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teachers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> teachersJson = data['teachers'] ?? [];
        return teachersJson.map((json) => Teacher.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load teachers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching teachers: $e');
    }
  }

  /// Fetches a single teacher by ID
  Future<Teacher> fetchTeacher(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Teacher.fromJson(data['teacher']);
      } else {
        throw Exception('Failed to load teacher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching teacher: $e');
    }
  }

  /// Creates a new teacher
  Future<Teacher> createTeacher(Map<String, dynamic> teacherData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teachers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(teacherData),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Teacher.fromJson(data['teacher']);
      } else {
        throw Exception('Failed to create teacher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating teacher: $e');
    }
  }

  /// Updates an existing teacher
  Future<Teacher> updateTeacher(int id, Map<String, dynamic> teacherData) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/teachers/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(teacherData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Teacher.fromJson(data['teacher']);
      } else {
        throw Exception('Failed to update teacher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating teacher: $e');
    }
  }

  /// Deletes a teacher
  Future<void> deleteTeacher(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/teachers/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete teacher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting teacher: $e');
    }
  }
}
