import 'package:firebase_core/firebase_core.dart';

/// Helper class for debugging Firebase initialization issues
class DebugHelper {
  /// Log Firebase initialization status
  static void logFirebaseStatus(String source) {
    final numApps = Firebase.apps.length;
    final appNames = Firebase.apps.map((app) => app.name).join(', ');
    
    print('===== FIREBASE STATUS [$source] =====');
    print('Number of Firebase apps: $numApps');
    print('Firebase app names: $appNames');
    print('=======================================');
  }
}
