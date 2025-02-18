import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:pawsmatch/pages/web/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );


    await dotenv.load(fileName: ".env");


    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_KEY']!,
    );
    print('Supabase initialized successfully.');

    runApp(MyApp());
  } catch (e) {
    print('Error during initialization: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
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
          child: Text('Failed to initialize Firebase: $error'),
        ),
      ),
    );
  }
}