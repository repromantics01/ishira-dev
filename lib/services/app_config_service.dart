import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Fix the import for JS interoperability that works across platforms
import 'package:universal_html/js.dart' if (dart.library.js) 'dart:js' as js;

/// A service that provides configuration values from various sources
/// with a consistent interface across platforms.
class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  
  // Singleton pattern
  factory AppConfigService() => _instance;
  
  AppConfigService._internal();
  
  bool _initialized = false;
  final Map<String, String> _configValues = {};
  
  /// Initialize the config service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Load environment variables from .env file for development
      if (!kIsWeb) {
        try {
          await dotenv.load(fileName: ".env");
          print("Loaded environment variables from .env file");
        } catch (e) {
          print("Could not load .env file: $e");
        }
      }
      
      // For web, try to get from JS window object
      if (kIsWeb) {
        _loadFromJsContext();
      }
      
      // Load from environment variables as fallback
      _loadFromEnvironment();
      
      // Load from .env file as last resort
      _loadFromDotEnv();
      
      _initialized = true;
      print("AppConfigService initialized successfully");
    } catch (e) {
      print("Error initializing AppConfigService: $e");
      rethrow;
    }
  }
  
  void _loadFromJsContext() {
    if (!kIsWeb) return;
    
    try {
      // Fix: Access the global context in a way compatible with our imports
      var jsGlobal;
      try {
        // Access global context - this will work with dart:js
        jsGlobal = js.context;
      } catch (e) {
        print("Could not access js.context, trying alternative approaches");
        return;
      }
      
      // Check for Supabase config in JS
      try {
        if (jsGlobal['supabaseConfig'] != null) {
          final supabaseConfig = jsGlobal['supabaseConfig'];
          
          try {
            final url = supabaseConfig['url'];
            if (url != null && url is String) {
              _configValues['SUPABASE_URL'] = url;
            }
            
            final key = supabaseConfig['key'];
            if (key != null && key is String) {
              _configValues['SUPABASE_KEY'] = key;
            }
          } catch (e) {
            print("Error accessing supabaseConfig properties: $e");
          }
        }
      } catch (e) {
        print("Error accessing supabaseConfig: $e");
      }
      
      // Check for Firebase config in JS
      try {
        if (jsGlobal['firebaseConfig'] != null) {
          final firebaseConfig = jsGlobal['firebaseConfig'];
          
          // Map Firebase config values
          final keyMappings = {
            'apiKey': 'FIREBASE_API_KEY',
            'appId': 'FIREBASE_APP_ID_WEB',
            'messagingSenderId': 'FIREBASE_MESSAGING_SENDER_ID',
            'projectId': 'FIREBASE_PROJECT_ID',
            'authDomain': 'FIREBASE_AUTH_DOMAIN',
            'databaseURL': 'FIREBASE_DATABASE_URL',
            'storageBucket': 'FIREBASE_STORAGE_BUCKET',
            'measurementId': 'FIREBASE_MEASUREMENT_ID'
          };
          
          keyMappings.forEach((jsKey, envKey) {
            try {
              final value = firebaseConfig[jsKey];
              if (value != null && value is String) {
                _configValues[envKey] = value;
              }
            } catch (e) {
              print("Error accessing firebaseConfig[$jsKey]: $e");
            }
          });
        }
      } catch (e) {
        print("Error accessing firebaseConfig: $e");
      }
    } catch (e) {
      print("Error loading config from JS: $e");
    }
  }
  
  void _loadFromEnvironment() {
    // Common config keys to load
    final keys = [
      'SUPABASE_URL',
      'SUPABASE_KEY',
      'FIREBASE_API_KEY',
      'FIREBASE_APP_ID_WEB',
      'FIREBASE_MESSAGING_SENDER_ID',
      'FIREBASE_PROJECT_ID',
      'FIREBASE_AUTH_DOMAIN',
      'FIREBASE_DATABASE_URL',
      'FIREBASE_STORAGE_BUCKET',
      'FIREBASE_MEASUREMENT_ID'
    ];
    
    // Use String.fromEnvironment for each key
    for (final key in keys) {
      try {
        // We can't use const in a loop, so we need to use a different approach
        // This is a workaround for the "Not a constant expression" error
        String value;
        if (key == 'SUPABASE_URL') {
          value = const String.fromEnvironment('SUPABASE_URL');
        } else if (key == 'SUPABASE_KEY') {
          value = const String.fromEnvironment('SUPABASE_KEY');
        } else if (key == 'FIREBASE_API_KEY') {
          value = const String.fromEnvironment('FIREBASE_API_KEY');
        } else if (key == 'FIREBASE_APP_ID_WEB') {
          value = const String.fromEnvironment('FIREBASE_APP_ID_WEB');
        } else if (key == 'FIREBASE_MESSAGING_SENDER_ID') {
          value = const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
        } else if (key == 'FIREBASE_PROJECT_ID') {
          value = const String.fromEnvironment('FIREBASE_PROJECT_ID');
        } else if (key == 'FIREBASE_AUTH_DOMAIN') {
          value = const String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
        } else if (key == 'FIREBASE_DATABASE_URL') {
          value = const String.fromEnvironment('FIREBASE_DATABASE_URL');
        } else if (key == 'FIREBASE_STORAGE_BUCKET') {
          value = const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'); 
        } else if (key == 'FIREBASE_MEASUREMENT_ID') {
          value = const String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
        } else {
          value = '';
        }
        
        if (value.isNotEmpty && !_configValues.containsKey(key)) {
          _configValues[key] = value;
        }
      } catch (e) {
        print("Error loading environment variable $key: $e");
      }
    }
  }
  
  void _loadFromDotEnv() {
    if (!dotenv.isInitialized) return;
    
    final keys = [
      'SUPABASE_URL',
      'SUPABASE_KEY',
      'FIREBASE_API_KEY',
      'FIREBASE_APP_ID_WEB',
      'FIREBASE_MESSAGING_SENDER_ID',
      'FIREBASE_PROJECT_ID',
      'FIREBASE_AUTH_DOMAIN',
      'FIREBASE_DATABASE_URL',
      'FIREBASE_STORAGE_BUCKET',
      'FIREBASE_MEASUREMENT_ID'
    ];
    
    for (final key in keys) {
      final value = dotenv.env[key];
      if (value != null && value.isNotEmpty && !_configValues.containsKey(key)) {
        _configValues[key] = value;
      }
    }
  }
  
  /// Get a configuration value by key
  String? getValue(String key) {
    if (!_initialized) {
      print("Warning: Trying to access config before initialization");
    }
    return _configValues[key];
  }
  
  /// Check if a configuration value exists
  bool hasValue(String key) {
    return _configValues.containsKey(key) && 
           _configValues[key]?.isNotEmpty == true;
  }
  
  /// Get Supabase URL
  String? get supabaseUrl => getValue('SUPABASE_URL');
  
  /// Get Supabase Key
  String? get supabaseKey => getValue('SUPABASE_KEY');
  
  /// Check if Supabase is properly configured
  bool get hasSupabaseConfig => 
      hasValue('SUPABASE_URL') && hasValue('SUPABASE_KEY');
}
