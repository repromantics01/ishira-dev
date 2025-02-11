import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:pawsmatch/pages/web/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//TODO: Prohibit individual users login to website

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    // Load the .env file
    await dotenv.load(fileName: ".env");

    // Print debug statements to verify execution
    print('Loading environment variables...');
    print('Supabase URL: ${dotenv.env['SUPABASE_URL']}');
    print('Supabase Key: ${dotenv.env['SUPABASE_KEY']}');

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_KEY']!,
    );

    // Prohibit individual users login to website
    if (dotenv.env['USER_TYPE'] != 'organization') {
      throw Exception('Individual users are not allowed to log in to the website.');
    }

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
      home: WebHomepage(),
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