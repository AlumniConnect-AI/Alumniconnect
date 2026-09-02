import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static SupabaseClient get _client {
    if (!Supabase.instance.isInitialized) {
      throw Exception(
          "Supabase not initialized. Call bootstrap() before using StorageService."
      );
    }
    return Supabase.instance.client;
  }

  static Future<String> uploadFile(File file, String path) async {
    await _client.storage.from('chat').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _client.storage.from('chat').getPublicUrl(path);
  }
}