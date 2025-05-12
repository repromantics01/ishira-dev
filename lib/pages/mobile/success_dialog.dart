import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/mobile/user_login.dart';

class SuccessDialog extends StatefulWidget {
  final bool needsVerification;

  const SuccessDialog({super.key, this.needsVerification = false});

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Logo bounce animation
    _logoAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    // Text scale animation
    _textScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));
    
    // Button slide up animation
    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
    ));
    
    // Overall fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    
    // Start animations after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with fade in animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/photos/success-background.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          
          // Content with animations
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Logo with scale animation
                  ScaleTransition(
                    scale: _logoAnimation,
                    child: Image.asset(
                      'assets/photos/pawsmatch-text2.png',
                      width: 200,
                      height: 80,
                    ),
                  ),
                  
                  const SizedBox(height: 1),
                  
                  // Success text with scale animation
                  ScaleTransition(
                    scale: _textScaleAnimation,
                    child: const Text(
                      'SUCCESS!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xBA725F63),
                        fontSize: 32,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Subtitle with fade-in animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: 293,
                      child: Text(
                        widget.needsVerification
                            ? 'Please check your email to verify your account before logging in.'
                            : 'You can now proceed logging in your account credentials.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xBA725F63),
                          fontSize: 15,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          height: 1.47,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Button with slide-up animation
                  SlideTransition(
                    position: _buttonSlideAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        // Add button press animation
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => UserLogin(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 500),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF725F63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
