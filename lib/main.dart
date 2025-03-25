import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// Make sure all imports come before any declarations
import 'main_stub.dart'
    if (dart.library.html) 'main_web.dart'
    if (dart.library.io) 'main_mobile.dart';

// Define a stub function that will be replaced by platform implementations
Future<void> initializeApp() async {
  if (kIsWeb) {
    // Web initialization is handled in main_web.dart
    // This function will be completely replaced when building for web
  } else {
    // Default mobile initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase and other services based on platform
  await initializeApp();
  
  runApp(const MyApp());
}

// Provide a default implementation that will be replaced
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(); // This will be replaced by platform-specific implementations
  }
}
