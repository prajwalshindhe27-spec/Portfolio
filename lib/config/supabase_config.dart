import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://cqkxqnzngsxsqducrxag.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxa3hxbnpuZ3N4c3FkdWNyeGFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUwMzMzMDUsImV4cCI6MjEwMDYwOTMwNX0.C71JvERDPD4boNAgk5VtCK59peMu7LYYYvo638NVcEs';

  static Future<void> initialize() async {
    if (url.isEmpty || anonKey.isEmpty) {
      return;
    }

    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}
