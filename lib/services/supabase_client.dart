import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseClientService {
  static SupabaseClient? _client;
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      String? supabaseUrl;
      String? supabaseKey;
      
      // Try environment variables first
      supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
      supabaseKey = const String.fromEnvironment('SUPABASE_KEY');
      
      // If not set, try .env file (typically for development)
      if ((supabaseUrl.isEmpty || supabaseKey.isEmpty) && !kIsWeb) {
        try {
          await dotenv.load(fileName: ".env");
          supabaseUrl = dotenv.env['SUPABASE_URL'];
          supabaseKey = dotenv.env['SUPABASE_KEY'];
        } catch (e) {
          print("Could not load .env file: $e");
        }
      }
      
      if (supabaseUrl != null && supabaseUrl.isNotEmpty && 
          supabaseKey != null && supabaseKey.isNotEmpty) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
        );
        _client = Supabase.instance.client;
        _initialized = true;
        print("Supabase client initialized successfully");
      } else {
        print("Skipping Supabase initialization - missing credentials");
      }
    } catch (e) {
      print("Error initializing Supabase client: $e");
      rethrow;
    }
  }
  
  static SupabaseClient? get client {
    if (!_initialized) {
      print("Warning: Trying to access Supabase client before initialization");
      return null;
    }
    return _client;
  }
}
