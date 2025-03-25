import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Import platform-specific implementations
import 'dart:core';

// Platform-specific implementations
import 'package:pawsmatch/pages/mobile/mobile_homepage.dart';
import 'package:pawsmatch/pages/web/web_homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Show loading screen first
  runApp(LoadingApp());
  
  try {
    // Initialize Firebase with the correct options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
    
    // Load environment variables if needed
    if (!kIsWeb) {
      try {
        await dotenv.load(fileName: ".env");
        print("Loaded environment from .env file");
      } catch (e) {
        print("Environment loading error: $e");
        // Continue anyway
      }
    }
    
    // Call platform-specific initialization
    await initPlatformSpecific();
    
    // Run the appropriate app based on platform
    if (kIsWeb) {
      print("Starting web app");
      runApp(const WebApp());
    } else {
      print("Starting mobile app");
      runApp(const MobileApp());
    }
  } catch (e, stack) {
    print("Initialization error: $e");
    print("Stack trace: $stack");
    runApp(ErrorApp(error: e.toString()));
  }
}

// Call platform-specific initialization from either main_web.dart or main_mobile.dart
Future<void> initPlatformSpecific() async {
  if (kIsWeb) {
    // Import web-specific initialization
    await import('package:pawsmatch/main_web.dart');
  } else {
    // Import mobile-specific initialization
    await import('package:pawsmatch/main_mobile.dart');
  }
}

// Loading screen while initializing
class LoadingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading PawsMatch...'),
            ],
          ),
        ),
      ),
    );
  }
}

// Error display screen
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Failed to initialize app:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(error, style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

dynamic import(String path) async {
  // This is a stub for the dynamic import functionality
  print("Importing: $path");
  return null;
}

// Mobile app class
class MobileApp extends StatelessWidget {
  const MobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MobileHomepage(),
    );
  }
}

// Web app class
class WebApp extends StatelessWidget {
  const WebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsMatch Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WebHomepage(),
    );
  }
}
