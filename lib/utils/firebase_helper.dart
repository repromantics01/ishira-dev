import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pawsmatch/firebase_options.dart';

/// Helper class for safely accessing Firebase functionality
class FirebaseHelper {
  static bool _initialized = false;
  
  /// Initialize Firebase if it hasn't been initialized yet
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    
    if (Firebase.apps.isEmpty) {
      print("Initializing Firebase via FirebaseHelper");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully via FirebaseHelper");
    } else {
      print("Firebase already initialized, using existing instance");
    }
    
    _initialized = true;
  }
  
  /// Get a Firebase App instance safely
  static FirebaseApp get app {
    if (Firebase.apps.isEmpty) {
      throw Exception("Firebase not initialized. Call ensureInitialized() first.");
    }
    return Firebase.app();
  }
  
  /// Check if Firebase is initialized
  static bool get isInitialized => Firebase.apps.isNotEmpty;
}
