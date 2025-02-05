import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:pawsmatch/pages/mobile/home_page.dart';

const supabaseUrl = 'https://pouskfxetpaocvzkzwsg.supabase.co';
const supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvdXNrZnhldHBhb2N2emt6d3NnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg2NzQ4NzgsImV4cCI6MjA1NDI1MDg3OH0.aS8uwnumugUzd2CX4ZrEQTiU69nj6U_mP_sWc8GHvoQ');

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

    // Print the Supabase key to verify it
    print('Supabase Key: $supabaseKey');

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    runApp(MyApp());
  } catch (e) {
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