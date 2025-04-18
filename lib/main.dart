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
  
  runApp(LoadingApp());
  
  try {
    if (!kIsWeb) {
      try {
        await dotenv.load(fileName: ".env");
        print("Loaded environment from .env file");
      } catch (e) {
        print("Environment loading error: $e");
        // Continue anyway
      }
    }
    
    try {
      await FirebaseHelper.ensureInitialized();
      print("Firebase initialization handled by FirebaseHelper");
    } catch (e) {
      print("Firebase initialization error: $e");
    }
    
    final configService = AppConfigService();
    await configService.initialize();

    await SupabaseClientService.initialize();

    if (kIsWeb) {
      print("Starting web app");
      
      if (kDebugMode) {
        try {
          print("Debug mode: using full initialization path");
          await web.initializeApp();
          print("Web initialization completed successfully");
          runApp(const WebApp());
        } catch (e, stack) {
          print("Debug web initialization error: $e");
          print("Stack trace: $stack");

          runApp(WebApp(
            useSimplifiedMode: true, 
            errorMessage: "Debug mode initialization failed"
          ));
        }
      } else {
        print("Production mode: bypassing web.initializeApp() completely");

        runApp(WebApp(
          useSimplifiedMode: true,
          errorMessage: "Welcome to PawsMatch! We're launching soon."
        ));
      }
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
  final bool useSimplifiedMode;
  final String errorMessage;
  
  const WebApp({Key? key, this.useSimplifiedMode = false, this.errorMessage = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsMatch Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: useSimplifiedMode 
          ? Scaffold(
              appBar: AppBar(title: Text('PawsMatch Web')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to PawsMatch',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      errorMessage.isNotEmpty ? errorMessage : 'We\'re experiencing technical difficulties.\nPlease check back later.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : WebHomepage(),
    );
  }
}
