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

class WebHomepage extends StatefulWidget {
  @override
  _WebHomepageState createState() => _WebHomepageState();
}

class _WebHomepageState extends State<WebHomepage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isFirebaseInitialized = false;
  bool _isLoading = true;
  bool _isAuthenticating = false;
  String _errorMessage = '';

  final DatabaseAccountService _accountService = DatabaseAccountService();
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
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
          title: Text('Verification Pending'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pending, size: 50, color: Colors.amber),
              SizedBox(height: 16),
              Text('Your organization is pending verification.'),
              Text('Please wait for approval before accessing the dashboard.'),
              SizedBox(height: 8),
              Text(
                'You will receive an email notification when your verification is complete.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut(); // Sign out the user
              },
              child: Text('OK'),
            ),
          ],
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
          title: Text('Verification Rejected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, size: 50, color: Colors.red),
              SizedBox(height: 16),
              Text('Your organization verification has been rejected.'),
              Text('Thank you for your interest in PawsMatch.'),
              SizedBox(height: 8),
              Text(
                'Please check your email for detailed information about the rejection reason.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'You may apply again in the future with additional documentation.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut(); // Sign out the user
              },
              child: Text('OK'),
            ),
          ],
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
        title: Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email address to receive a password reset link.'),
            SizedBox(height: 16),
            TextField(
              controller: _forgotPasswordEmailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
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
                    SnackBar(content: Text('Password reset email sent. Please check your inbox.'))
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'))
                  );
                }
              }
            },
            child: Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isFirebaseInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to initialize Firebase'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeFirebase,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/photos/web-homepage.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 151,
              top: 266,
              child: SizedBox(
                width: 448,
                height: 19,
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 36,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    height: 0.44,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 151,
              top: 332,
              child: Container(
                width: 416,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Username/Email',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 14,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            width: 1,
                            color: const Color(0xFFC5C6CC),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            width: 1,
                            color: const Color(0xFFC5C6CC),
                          ),
                        ),
                        hintText: 'Enter your username or email',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 151,
              top: 422,
              child: Container(
                width: 416,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 14,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            width: 1,
                            color: const Color(0xFFC5C6CC),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            width: 1,
                            color: const Color(0xFFC5C6CC),
                          ),
                        ),
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 151,
              top: 512,
              child: Container(
                width: 416,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
            ),
            Positioned(
              left: 151,
              top: 562,
              child: Container(
                width: 416,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _isAuthenticating ? null : _handleLogin,
                      child: Container(
                        width: 416,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: ShapeDecoration(
                          color: _isAuthenticating 
                              ? const Color(0xFF212121).withOpacity(0.7)
                              : const Color(0xFF212121),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 368,
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
                                        'SIGNING IN...',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'DM Sans',
                                          fontWeight: FontWeight.w400,
                                          height: 1,
                                          letterSpacing: 1.25,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'LOGIN',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w400,
                                      height: 1,
                                      letterSpacing: 1.25,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 151,
              top: 661,
              child: Container(
                width: 416,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpForm(),
                          ),
                        );
                      },
                      child: Container(
                        width: 416,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF212121),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 368,
                              child: Text(
                                'SIGN UP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1,
                                  letterSpacing: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 434,
              top: 503,
              child: SizedBox(
                width: 133,
                height: 19,
                child: InkWell(
                  onTap: _handleForgotPassword,
                  child: Text(
                    'Forgot Password?',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 12,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 268,
              top: 626,
              child: SizedBox(
                width: 181,
                height: 19,
                child: Text(
                  'Don\'t have an account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFFEF5F0),
      ),
      home: WebHomepage(),
    );
  }
}
