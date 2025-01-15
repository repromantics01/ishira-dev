import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Pager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _isConnected = false;
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    _logCounterEvent();
  }

  void _logCounterEvent() async {
    await analytics.logEvent(
      name: 'increment_counter',
      parameters: <String, Object>{
        'counter': _counter,
      },
    );
  }

  void _checkFirebaseConnection() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _isConnected = true;
      });
      print('Connected to Firebase');
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
      print('Failed to connect to Firebase: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              _isConnected ? 'Connected to Firebase' : 'Not connected to Firebase',
              style: TextStyle(color: _isConnected ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}