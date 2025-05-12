import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:pawsmatch/services/app_config_service.dart';
import 'package:pawsmatch/services/supabase_client_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Direct imports for platform-specific code
import 'package:pawsmatch/main_mobile.dart' as mobile;
import 'package:pawsmatch/main_web.dart' as web;
import 'package:pawsmatch/pages/mobile/mobile_homepage.dart';
import 'package:pawsmatch/pages/web/web_login.dart';
import 'package:pawsmatch/utils/firebase_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Show loading screen first
  runApp(LoadingApp());
  
  try {
    // Load environment variables if needed
    if (!kIsWeb) {
      try {
        await dotenv.load(fileName: ".env");
        print("Loaded environment from .env file");
      } catch (e) {
        print("Environment loading error: $e");
        // Continue anyway
      }
    }
    
    // Initialize Firebase using our helper class
    // This centralizes Firebase initialization and prevents duplicates
    try {
      await FirebaseHelper.ensureInitialized();
      print("Firebase initialization handled by FirebaseHelper");
    } catch (e) {
      print("Firebase initialization error: $e");
      // Continue if possible - the app might still work with limited functionality
    }
    
    // Initialize AppConfigService
    final configService = AppConfigService();
    await configService.initialize();
    
    // Initialize Supabase once
    await SupabaseClientService.initialize();
    
    // Call platform-specific initialization
    if (kIsWeb) {
      print("Starting web app");
      await web.initializeApp(); // Other web-specific setup
      runApp(const WebApp());
    } else {
      print("Starting mobile platform initialization");
      await mobile.initializeMobilePlatform();
      print("Starting mobile app");
      runApp(const MobileApp());
    }
  } catch (e, stack) {
    print("Initialization error: $e");
    print("Stack trace: $stack");
    runApp(ErrorApp(error: e.toString()));
  }
}

// Loading screen while initializing
class LoadingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading PawsMatch...'),
            ],
          ),
        ),
      ),
    );
  }
}

// Error display screen
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Failed to initialize app:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(error, style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Mobile app class
class MobileApp extends StatelessWidget {
  const MobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MobileHomepage(),
    );
  }
}

// Web app class
class WebApp extends StatelessWidget {
  const WebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsMatch Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WebHomepage(),
      routes: {
        '/login': (context) => WebHomepage(),
        // ...add other web routes here if needed...
      },
    );
  }
}
