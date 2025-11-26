import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../config/supabase_config.dart';

class SupabaseStorageService {
  static SupabaseClient? _client;

  /// Initialize Supabase (call this once in main.dart)
  /// Uses service_role key to bypass RLS policies for file uploads
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey, // Use service_role to bypass RLS
    );
    _client = Supabase.instance.client;
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseStorageService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Upload a file to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required File file,
    required String bucket,
    required String fileName,
    String? folder,
  }) async {
    try {
      // Construct the storage path
      final String filePath = folder != null ? '$folder/$fileName' : fileName;

      // Read file as bytes
      final bytes = await file.readAsBytes();

      // Get file extension for MIME type
      final extension = path.extension(fileName).toLowerCase();
      String? contentType;

      // Set content type based on file extension
      switch (extension) {
        case '.pdf':
          contentType = 'application/pdf';
          break;
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.doc':
          contentType = 'application/msword';
          break;
        case '.docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      // Upload to Supabase Storage
      await client.storage
          .from(bucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false, // Don't overwrite if file exists
            ),
          );

      // Get public URL
      final String publicUrl = client.storage
          .from(bucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload teacher document
  /// Returns the public URL
  Future<String> uploadTeacherDocument({
    required File file,
    required int teacherId,
    required String documentType,
  }) async {
    // Generate unique filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(file.path);
    final sanitizedDocType = documentType.replaceAll(' ', '_').toLowerCase();
    final fileName = '${teacherId}_${sanitizedDocType}_$timestamp$extension';

    return await uploadFile(
      file: file,
      bucket: SupabaseConfig.teacherDocumentsBucket,
      fileName: fileName,
      folder: 'teacher_$teacherId',
    );
  }

  /// Delete a file from Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      await client.storage.from(bucket).remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Delete teacher document by URL
  Future<void> deleteTeacherDocument(String fileUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // Find bucket and file path
      final bucketIndex = pathSegments.indexOf('object');
      if (bucketIndex == -1 || bucketIndex + 2 >= pathSegments.length) {
        throw Exception('Invalid file URL format');
      }

      final bucket = pathSegments[bucketIndex + 2];
      final filePath = pathSegments.sublist(bucketIndex + 3).join('/');

      await deleteFile(bucket: bucket, filePath: filePath);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  /// List files in a folder
  Future<List<FileObject>> listFiles({
    required String bucket,
    String? folder,
  }) async {
    try {
      final files = await client.storage.from(bucket).list(path: folder);

      return files;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }
}
