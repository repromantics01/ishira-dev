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
      
      // First try to get config from AppConfigService
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
      
      
      if (supabaseUrl == null || supabaseUrl.isEmpty || supabaseUrl == "%SUPABASE_URL%" || 
          supabaseKey == null || supabaseKey.isEmpty || supabaseKey == "%SUPABASE_KEY%") {
         await dotenv.load(fileName: ".env");
        // Replace these with your actual Supabase URL and anon key for testing
        // supabaseUrl = 'https://pouskfxetpaocvzkzwsg.supabase.co';
        // supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvdXNrZnhldHBhb2N2emt6d3NnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg2NzQ4NzgsImV4cCI6MjA1NDI1MDg3OH0.aS8uwnumugUzd2CX4ZrEQTiU69nj6U_mP_sWc8GHvoQ';
        supabaseUrl = dotenv.env['SUPABASE_URL'];
        supabaseKey = dotenv.env['SUPABASE_KEY'];
      }
      
      // Log the URL and key being used (without revealing full key)
      print("Initializing Supabase with URL: $supabaseUrl");
      if (supabaseKey != null) {
        print("Key provided: ${supabaseKey.substring(0, 5)}...${supabaseKey.length > 10 ? supabaseKey.substring(supabaseKey.length - 5) : ''}");
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
        // Verify storage access
        // try {
        //   final buckets = await _client!.storage.listBuckets();
        //   print("Available storage buckets: ${buckets.map((b) => b.name).join(', ')}");
        //   print("Looking for 'pets' bucket...");
        //   if (buckets.any((b) => b.name == 'pets')) {
        //     print("'pets' bucket found!");
        //   } else {
        //     print("WARNING: 'pets' bucket not found! Uploads will fail.");
        //   }
        // } catch (e) {
        //   print("Error accessing storage: $e");
        // }
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
