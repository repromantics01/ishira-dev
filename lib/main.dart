import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// Replace any direct import of main_web.dart with this conditional import approach
import 'main_stub.dart'
    if (dart.library.html) 'main_web.dart'
    if (dart.library.io) 'main_mobile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase and other services based on platform
  await initializeApp(); // This function will be defined in platform-specific files
  
  runApp(MyApp());
}
