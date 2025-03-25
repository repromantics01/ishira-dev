import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

// Called from main.dart
Future<void> initializeApp() async {
  print("Mobile platform initialization");
  
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

// Error handling class
class FileNotFoundError implements Exception {
  final String message;
  FileNotFoundError(this.message);
  @override
  String toString() => 'FileNotFoundError: $message';
}