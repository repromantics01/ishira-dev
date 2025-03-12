import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:pawsmatch/pages/web/home_page.dart';
import 'dart:js' as js;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Loading environment variables...');
    
    final firebaseConfig = js.context['firebaseConfig'];
    final supabaseConfig = js.context['supabaseConfig'];

    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: firebaseConfig['apiKey'],
        appId: firebaseConfig['appId'],
        messagingSenderId: firebaseConfig['messagingSenderId'],
        projectId: firebaseConfig['projectId'],
        authDomain: firebaseConfig['authDomain'],
        databaseURL: firebaseConfig['databaseURL'],
        storageBucket: firebaseConfig['storageBucket'],
        measurementId: firebaseConfig['measurementId'],
      ),
    );
    print('Firebase initialized successfully.');

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    await Supabase.initialize(
      url: supabaseConfig['url'],
      anonKey: supabaseConfig['key'],
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