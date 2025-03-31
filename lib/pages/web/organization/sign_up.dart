import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/pages/web/organization/sign_up2.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:firebase_core/firebase_core.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final DatabaseAccountService _databaseService = DatabaseAccountService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  
  bool _isFirebaseInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  _initializeFirebase() async {
    try {
      // Don't initialize Firebase again, just check if it's already initialized
      _isFirebaseInitialized = Firebase.apps.isNotEmpty;
      
      if (!_isFirebaseInitialized) {
        print('Firebase is not initialized, this is unexpected');
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking Firebase initialization: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              // Title
              Positioned(
                left: 151,
                top: 150,
                child: SizedBox(
                  width: 448,
                  height: 40,
                  child: Text(
                    'Organization Sign Up',
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

              // Username field
              Positioned(
                left: 151,
                top: 220,
                child: Container(
                  width: 416,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Username',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameController,
                        enableSuggestions: false,
                        autocorrect: false,
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
                          hintText: 'Enter your username',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your account username';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Email field
              Positioned(
                left: 151,
                top: 310,
                child: Container(
                  width: 416,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
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
                        enableSuggestions: false,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
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
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Password field
              Positioned(
                left: 151,
                top: 400,
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
                        enableSuggestions: false,
                        autocorrect: false,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Confirm Password field
              Positioned(
                left: 151,
                top: 490,
                child: Container(
                  width: 416,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Password',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
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
                          hintText: 'Confirm your password',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Next button
              Positioned(
                left: 151,
                top: 580,
                child: Container(
                  width: 416,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUpForm2(
                                  username: _usernameController.text,
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                ),
                              ),
                            );
                          }
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
                                  'NEXT',
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
            ],
          ),
        ),
      ),
    );
  }
}