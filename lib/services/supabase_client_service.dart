import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pawsmatch/services/app_config_service.dart';

class SupabaseClientService {
  static SupabaseClient? _client;
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      String? supabaseUrl;
      String? supabaseKey;
      
      // Use AppConfigService to get configuration
      final configService = AppConfigService();
      await configService.initialize();
      
      if (configService.hasSupabaseConfig) {
        supabaseUrl = configService.supabaseUrl;
        supabaseKey = configService.supabaseKey;
        print("Using Supabase config from AppConfigService");
      } else {
        // Fallback to direct environment or dotenv access
        supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
        supabaseKey = const String.fromEnvironment('SUPABASE_KEY');
        
        if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
          try {
            if (!dotenv.isInitialized && !kIsWeb) {
              await dotenv.load(fileName: ".env");
            }
            supabaseUrl = dotenv.env['SUPABASE_URL'];
            supabaseKey = dotenv.env['SUPABASE_KEY'];
          } catch (e) {
            print("Error loading .env file: $e");
          }
        }
      }
      
      // Initialize Supabase with the found credentials
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
