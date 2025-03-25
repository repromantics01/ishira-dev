import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawsmatch/pages/mobile/user_login.dart';
import 'package:pawsmatch/pages/mobile/user_registration_form.dart';

class MobileHomepage extends StatelessWidget {
  const MobileHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                SizedBox(
                  width: 263,
                  child: Text(
                    'Welcome to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF725F63),
                      fontSize: 32,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w900,
                      height: 1.56,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Stack(
                  alignment: Alignment.center,
                    children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(image: AssetImage('assets/photos/pawsmatch-text.png')),
                    ),
                  ],
                  ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 230,
                  ),
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/photos/mobile-homepage.png'),
                        alignment: Alignment.centerRight,
                      fit: BoxFit.cover,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: 293,
                  child: Text(
                    'Where we connect pets to loving homes one match at a time...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.30,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildResponsiveButton(
                  context: context,
                  label: 'LOGIN',
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => UserLogin())
                    );
                  },
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 16),
                _buildResponsiveButton(
                  context: context,
                  label: 'SIGN UP',
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => UserRegistrationForm())
                    );
                  },
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildResponsiveButton({
    required BuildContext context, 
    required String label, 
    required VoidCallback onTap,
    required FontWeight fontWeight
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 0.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 - value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        onTapDown: (_) {
          HapticFeedback.lightImpact();
        },
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: ShapeDecoration(
              color: const Color(0xFF212121),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.1),
              onTap: onTap,
              child: Container(
                width: 277,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'DM Sans',
                    fontWeight: fontWeight,
                    height: 1,
                    letterSpacing: 1.25,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MobileApp extends StatelessWidget {
  const MobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsMatch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFFEF5F0),
      ),
      home: MobileHomepage(),
    );
  }
}