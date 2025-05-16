import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/pages/web/moderator/mod_dashboard.dart';
import 'package:pawsmatch/pages/web/organization/org_dashboard.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/pages/web/organization/sign_up.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawsmatch/widgets/web_background.dart';

class WebHomepage extends StatefulWidget {
  @override
  _WebHomepageState createState() => _WebHomepageState();
}

class _WebHomepageState extends State<WebHomepage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isFirebaseInitialized = false;
  bool _isLoading = true;
  bool _isAuthenticating = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  final DatabaseAccountService _accountService = DatabaseAccountService();
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  
  // Animation controller for the page transition
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    // Start the animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  _initializeFirebase() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      setState(() {
        _isFirebaseInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing Firebase: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to show pending verification modal
  Future<void> _showPendingVerificationModal() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Verification Pending',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A6572),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              Text(
                'Your organization is pending verification.',
                style: GoogleFonts.dmSans(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait for approval before accessing the dashboard.',
                style: GoogleFonts.dmSans(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You will receive an email notification when your verification is complete.',
                  style: GoogleFonts.dmSans(
                    fontStyle: FontStyle.italic,
                    color: Colors.amber.shade900,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF84A59D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('OK', style: GoogleFonts.dmSans(color: Colors.white)),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 10,
        );
      },
    );
  }

  // Helper method to show rejected verification modal
  Future<void> _showRejectedVerificationModal() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Verification Rejected',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              Text(
                'Your organization verification has been rejected.',
                style: GoogleFonts.dmSans(fontSize: 16),
              ),
              Text(
                'Thank you for your interest in PawsMatch.',
                style: GoogleFonts.dmSans(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Please check your email for detailed information about the rejection reason.',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade800,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'You may apply again in the future with additional documentation.',
                style: GoogleFonts.dmSans(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF84A59D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('OK', style: GoogleFonts.dmSans(color: Colors.white)),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 10,
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      print('Attempting login with email: $email');

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Email and password are required';
          _isAuthenticating = false;
        });
        return;
      }

      // Firebase Auth sign in
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      print('Firebase user: ${user?.uid}, email: ${user?.email}');
      if (user == null) {
        setState(() {
          _errorMessage = 'Login failed: No user found';
          _isAuthenticating = false;
        });
        return;
      }

      // Get account info
      final account = await _accountService.getAccount(user.uid);
      print('Account loaded: ${account.account_email}, type: ${account.account_type}');

      // Handle login based on account type
      if (account.account_type == AccountType.Moderator) {
        // Navigate to moderator dashboard if account type is moderator
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ModeratorDashboard(),
          ),
        );
        return;
      } else if (account.account_type == AccountType.OrgAdmin) {
        // Get organization info for organization admin
        final organization = await _organizationService.getOrganizationById(user.uid);
        //print('Organization loaded: ${organization?.org_name}');

        Organization? orgToPass = organization;
        if (orgToPass == null) {
          final orgSnapshot = await FirebaseFirestore.instance
              .collection('organization')
              .where('admin_ids', arrayContains: user.uid)
              .limit(1)
              .get();
          if (orgSnapshot.docs.isNotEmpty) {
            orgToPass = Organization.fromJson(orgSnapshot.docs.first.data());
          }
        }

        if (orgToPass == null) {
          setState(() {
            _errorMessage = 'No organization profile found for this account.';
            _isAuthenticating = false;
          });
          return;
        }
        
        // Check organization verification status
        if (orgToPass.isRejected) {
          // Organization was rejected - show rejection modal
          setState(() {
            _isAuthenticating = false;
          });
          await _showRejectedVerificationModal();
          return;
        } else if (!orgToPass.isVerified) {
          // Organization is still pending verification
          setState(() {
            _isAuthenticating = false;
          });
          await _showPendingVerificationModal();
          return;
        }

        // Organization is verified - proceed to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrganizationDashboard(org: orgToPass),
          ),
        );
        return;
      } else {
        // Other account types not supported for web login
        setState(() {
          _errorMessage = 'Only organization admin or moderator accounts can log in here.';
          _isAuthenticating = false;
        });
        return;
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} ${e.message}');
      String errorMsg = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Invalid email format';
      } else if (e.code == 'user-disabled') {
        errorMsg = 'This account has been disabled';
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } catch (e) {
      print('Login error: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  // Add this method to handle password reset
  Future<void> _handleForgotPassword() async {
    final _forgotPasswordEmailController = TextEditingController();
    
    // Show dialog to get email
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A6572),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text(
              'Enter your email address to receive a password reset link.',
              style: GoogleFonts.dmSans(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _forgotPasswordEmailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: GoogleFonts.dmSans(color: Color(0xFF84A59D)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF84A59D), width: 2),
                ),
                prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF84A59D)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_forgotPasswordEmailController.text.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: _forgotPasswordEmailController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent. Please check your inbox.'),
                      backgroundColor: Color(0xFF84A59D),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    )
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    )
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF84A59D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Send Reset Link', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'Loading PawsMatch...',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A6572),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isFirebaseInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
              SizedBox(height: 20),
              Text(
                'Failed to initialize Firebase',
                style: GoogleFonts.dmSans(
                  fontSize: 18, 
                  fontWeight: FontWeight.w500
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initializeFirebase,
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text('Retry', style: GoogleFonts.dmSans(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF84A59D),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Create the login form content
    Widget loginContent = WebContentContainer(
      child: WebCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Login Header
            Text(
              'Welcome Back',
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6572),
              ),
            ),
            Text(
              'Sign in to your organization account',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 30),
            
            // Error message if any
            if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.dmSans(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage.isNotEmpty) SizedBox(height: 20),
            
            // Email Field
            Text(
              'Email',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A6572),
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: GoogleFonts.dmSans(
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF84A59D)),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: 16
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Password Field
            Text(
              'Password',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A6572),
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: GoogleFonts.dmSans(
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF84A59D)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Color(0xFF84A59D),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: 16
                ),
              ),
            ),
            
            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.dmSans(
                    color: Color(0xFF84A59D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAuthenticating ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF84A59D),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isAuthenticating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Signing In...',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Log In',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
            
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'New to PawsMatch?',
                      style: GoogleFonts.dmSans(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
            ),
            
            // Sign Up Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignUpForm(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF84A59D), width: 2),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Create Organization Account',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF84A59D),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Use the WebBackground widget
    return WebBackground(
      contentWidget: loginContent,
    );
  }
}

// Web version of the app
class WebApp extends StatelessWidget {
  const WebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawsMatch Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF84A59D),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.dmSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF84A59D),
          primary: Color(0xFF84A59D),
          secondary: Color(0xFFF28482),
          tertiary: Color(0xFFF6BD60),
        ),
        useMaterial3: true,
      ),
      home: WebHomepage(),
    );
  }
}
