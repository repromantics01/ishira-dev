import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/s_dashboard.dart';
import 'package:pawsmatch/pages/mobile/adopter/a_dashboard.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/pages/mobile/user_registration_form.dart';

class UserLogin extends StatefulWidget {
  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseAccountService _auth = DatabaseAccountService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        final uid = userCredential.user!.uid;
        final Account account = await _auth.getAccount(uid);
        final profileSnapshot = await FirebaseFirestore.instance
            .collection('profile')
            .where('account_id', isEqualTo: account.account_id)
            .get();

        if (profileSnapshot.docs.isNotEmpty) {
          final profileData = profileSnapshot.docs.first.data();
          final userType = profileData['user_type'];

          if (userType == 'Adopter') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdopterDashboard()),
            );
          } else if (userType == 'Surrenderer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SurrendererDashboard()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = _getAuthErrorMessage(e.code);
        });
      } catch (e) {
        setState(() {
          _errorMessage = "An error occurred. Please try again.";
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      default:
        return 'Authentication failed: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    left: 16,
                    top: 16,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFF725F63)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Logo
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image(
                              image: AssetImage(
                                  'assets/photos/pawsmatch-text.png'),
                              height: 40),
                        ),
                      ],
                    ),
                  ),

                  // Subtitle
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 145,
                    child: Text(
                      'Sign up or login below to start using the app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFA99499),
                        fontSize: 15,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.57,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 32,
                    top: 200,
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 24,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // White container
                  Positioned(
                    left: 17,
                    right: 17,
                    top: 240,
                    child: Container(
                      padding: EdgeInsets.all(40),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: const Color.fromARGB(85, 126, 123, 124),
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email field
                          Text(
                            'Username/Email',
                            style: TextStyle(
                              color: Color(0xFF212121),
                              fontSize: 15,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Enter username or email...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 1,
                                  color: const Color(0xFFC5C6CC),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Password',
                            style: TextStyle(
                              color: Color(0xFF212121),
                              fontSize: 15,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Enter password...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
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
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12, right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Implement forgot password
                                },
                                child: Text(
                                  'Forgot Password?',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: const Color(0xFF545454),
                                    fontSize: 12,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w400,
                                    height: 1.33,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Error message if any
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          SizedBox(height: 10),

                          // Login button
                          _buildResponsiveButton(
                            context: context,
                            label: 'LOGIN',
                            onTap: _isLoading ? null : _handleLogin,
                            isLoading: _isLoading,
                          ),

                          SizedBox(height: 15), 

                          // Sign up section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF545454),
                                  fontSize: 12,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 1.33,
                                ),
                              ),
                            ],
                          ),

                          Divider(
                            color: const Color(0xFF9E9E9E),
                            thickness: 0.5,
                            height: 16, // Reduced from 32
                          ),

                          // Sign up button
                          _buildResponsiveButton(
                            context: context,
                            label: 'SIGN UP',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserRegistrationForm(),
                                ),
                              );
                            },
                            backgroundColor: Color(0xFF212121),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveButton({
    required BuildContext context,
    required String label,
    required VoidCallback? onTap,
    Color backgroundColor = const Color(0xFF212121),
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: ShapeDecoration(
          color: onTap == null
              ? backgroundColor.withOpacity(0.7)
              : backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onTap();
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Reduced vertical padding from 16 to 12
            child: isLoading
                ? Center(
                    child: SizedBox(
                        width: 20, // Slightly reduced size
                        height: 20, // Slightly reduced size
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )))
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: 1.25,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
