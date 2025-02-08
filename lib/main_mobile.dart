import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:pawsmatch/pages/mobile/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

//TODO: Prohibit organization accounts to login to mobile app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    // Print the current working directory
    print('Current working directory: ${Directory.current.path}');

    // Check if the .env file exists
    if (File('.env').existsSync()) {
      print('.env file found');
    } else {
      print('.env file not found');
    }

    // Load the .env file
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print('Error loading .env file: $e');
      throw FileNotFoundError('.env file not found');
    }

    // Print debug statements to verify execution
    print('Loading environment variables...');
    print('Supabase URL: ${dotenv.env['SUPABASE_URL']}');
    print('Supabase Key: ${dotenv.env['SUPABASE_KEY']}');

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_KEY']!,
    );

    runApp(MyApp());
  } catch (e) {
    print('Error: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          child: Text('Failed to initialize Firebase: $error'),
        ),
      ),
    );
  }
}

class FileNotFoundError implements Exception {
  final String message;
  FileNotFoundError(this.message);
  @override
  String toString() => 'FileNotFoundError: $message';
}