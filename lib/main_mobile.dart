import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/pages/mobile/mobile_homepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

// Called from main.dart
Future<void> initializeMobilePlatform() async {
  print("Mobile platform initialization");
  
  try {
    // Configure Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    
    // Initialize Supabase if credentials are available
    try {
      String? supabaseUrl = dotenv.env['SUPABASE_URL'];
      String? supabaseKey = dotenv.env['SUPABASE_KEY'];
      
      if (supabaseUrl != null && supabaseKey != null) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
        );
        print("Supabase initialized successfully");
      } else {
        print("Skipping Supabase initialization - missing credentials");
      }
    } catch (e) {
      print('Warning: Supabase initialization error: $e');
      // Continue without Supabase
    }
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