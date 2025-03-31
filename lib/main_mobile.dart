import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/pages/mobile/mobile_homepage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Called from main.dart
Future<void> initializeMobilePlatform() async {
  print("Mobile platform initialization");
  
  try {
    // Verify Firebase is initialized
    if (Firebase.apps.isEmpty) {
      throw Exception("Firebase should be initialized in main.dart before calling this method");
    }
    
    // Configure Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 10485760, // 10MB
    );
    
    // Any other mobile-specific initialization
    // Note: Supabase is now initialized in the main.dart file
    
  } catch (e) {
    print('Mobile initialization error: $e');
    throw Exception('Failed to initialize mobile platform: $e');
  }
}

// For backward compatibility
Future<void> initializeApp() async {
  await initializeMobilePlatform();
}

class MyMobileApp extends StatelessWidget {
  const MyMobileApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsMatch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MobileHomepage(),
    );
  }
}

// Error screen for when things go wrong
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('Failed to initialize app: $error'),
        ),
      ),
    );
  }
}

void handleInitError(dynamic error) {
  print('Error during initialization: $error');
  runApp(ErrorApp(error: error.toString()));
}