import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:pawsmatch/pages/web/home_page.dart';
import 'dart:js_util' as js_util;

// Override the initializeApp function from main.dart
Future<void> initializeApp() async {
  print('Loading environment variables...');
  
  final firebaseConfig = js_util.getProperty(js_util.globalThis, 'firebaseConfig');
  final supabaseConfig = js_util.getProperty(js_util.globalThis, 'supabaseConfig');

  print('Initializing Firebase...');
  
  // Create a FirebaseOptions object manually instead of using fromMap
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: js_util.getProperty(firebaseConfig, 'apiKey'),
      authDomain: js_util.getProperty(firebaseConfig, 'authDomain'),
      projectId: js_util.getProperty(firebaseConfig, 'projectId'),
      storageBucket: js_util.getProperty(firebaseConfig, 'storageBucket'),
      messagingSenderId: js_util.getProperty(firebaseConfig, 'messagingSenderId'),
      appId: js_util.getProperty(firebaseConfig, 'appId'),
      measurementId: js_util.getProperty(firebaseConfig, 'measurementId'),
    ),
  );
  
  print('Firebase initialized successfully.');

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Get values from supabaseConfig directly
  final supabaseUrl = js_util.getProperty(supabaseConfig, 'url');
  final supabaseKey = js_util.getProperty(supabaseConfig, 'key');
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );
  print('Supabase initialized successfully.');
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

// No longer using this function
// Map<String, dynamic> _convertToMap(dynamic jsObject) {
//   return Map<String, dynamic>.from(js_util.dartify(jsObject));
// }

// Custom error handling function for the main() in this file
void handleInitError(dynamic error) {
  print('Error during initialization: $error');
  runApp(ErrorApp(error: error.toString()));
}

// Keep the original main for direct testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeApp();
    runApp(const MyApp());
  } catch (e) {
    handleInitError(e);
  }
}