import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadService {
  static final SupabaseClient _client = Supabase.instance.client;

  // DOUBLE CHECK: This must match your Supabase Dashboard bucket name exactly
  static const String bucketName = "alumni-files";

  /// Upload file to Supabase Storage
  static Future<String> uploadFile({
    required File file,
    required String folder,
  }) async {
    try {
      final fileExt = path.extension(file.path);
      final fileName = "${DateTime.now().millisecondsSinceEpoch}$fileExt";
      final filePath = "$folder/$fileName";

      // 1. Upload the file
      await _client.storage.from(bucketName).upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: null, // Let Supabase infer content type
            ),
          );

      // 2. Generate the Public URL
      // Note: This requires the bucket to be set to 'Public' in the Supabase Dashboard
      final String publicUrl = _client.storage.from(bucketName).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print("Supabase Upload Error: $e");
      rethrow;
    }
  }

  static Future<String> uploadImage(File file) async {
    return await uploadFile(file: file, folder: "images");
  }

  static Future<String> uploadDocument(File file) async {
    return await uploadFile(file: file, folder: "documents");
  }
}
