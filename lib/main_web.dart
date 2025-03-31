import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/pages/web/web_login.dart';
import 'package:firebase_core/firebase_core.dart';

// This function is called from main.dart for web-specific initialization
Future<void> initializeApp() async {
  print('Web platform initialization');
  
  try {
    // Verify Firebase is initialized
    if (Firebase.apps.isEmpty) {
      throw Exception("Firebase should be initialized in main.dart before calling this method");
    }
    
    // Configure Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    
    // Any other web-specific initialization
    
  } catch (e) {
    print('Web initialization error: $e');
    throw Exception('Failed to initialize web platform: $e');
  }
}

// Define a MyApp class that will override the one in main.dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsMatch Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WebHomepage(),
    );
  }
}

// Error app for standalone mode
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('Failed to initialize: $error'),
        ),
      ),
    );
  }
}

// Keep the original main for direct testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeApp();
    runApp(const MyApp());
  } catch (e) {
    print('Error during initialization: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}