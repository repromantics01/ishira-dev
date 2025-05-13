import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/pages/mobile/user_login.dart';
import 'package:pawsmatch/pages/mobile/mobile_homepage.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/pages/mobile/success_dialog.dart';  // Add this import

class UserRegistrationForm extends StatefulWidget {
  const UserRegistrationForm({super.key});

  @override
  _UserRegistrationFormState createState() => _UserRegistrationFormState();
}

class _UserRegistrationFormState extends State<UserRegistrationForm> {
  final DatabaseAccountService _databaseAccountService =
      DatabaseAccountService();
  final FirebaseProfileService _firebaseProfileService =
      FirebaseProfileService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _userType = 'Adopter';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleRegistration() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Passwords do not match';
        });
        return;
      }
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Add account to database using user UID as document ID
        Account account = Account(
          account_id: userCredential.user!.uid,
          account_type: AccountType.User,
          account_username: _usernameController.text,
          account_email: _emailController.text,
          account_password: _passwordController.text,
          date_created: DateTime.now(),
        );
        String uid = userCredential.user!.uid;
        await _databaseAccountService.addAccount(account, uid);

        Profile profile = Profile(
          account_id: userCredential.user!.uid,
          profile_id: userCredential.user!.uid,
          user_type: _userType == 'Adopter'
              ? UserType.Adopter
              : UserType.Surrenderer,
          first_name: '',
          middle_name: '',
          last_name: '',
          suffix: '',
          bio: '',
          address: '',
          date_created: DateTime.now(),
        );
        await _firebaseProfileService.addProfile(profile);

        // Send email verification
        await userCredential.user!.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification email sent. Please check your inbox.')),
        );
        
        // Navigate to success dialog after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessDialog(needsVerification: true)),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = _getAuthErrorMessage(e.code);
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Error creating user: $e';
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
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'Error creating account: $code';
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
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).padding.top,
                ),
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFF725F63)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                        image: AssetImage('assets/photos/pawsmatch-text.png'),
                        height: 40
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25),

                // Sign Up Title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 24,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Main form container
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: EdgeInsets.all(30),
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
                        // Username field
                        _buildFormField(
                          label: 'Username',
                          hintText: 'Enter your username...',
                          controller: _usernameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),

                        // Email field
                        _buildFormField(
                          label: 'Email',
                          hintText: 'Enter your email address...',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
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
                        SizedBox(height: 15),

                        // Password field
                        _buildFormField(
                          label: 'Password',
                          hintText: 'Enter your password...',
                          controller: _passwordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),

                        // Confirm Password field
                        _buildFormField(
                          label: 'Confirm Password',
                          hintText: 'Confirm your password...',
                          controller: _confirmPasswordController,
                          obscureText: true,
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
                        SizedBox(height: 15),

                        // User Type dropdown
                        Text(
                          'User Type',
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 15,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFC5C6CC),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _userType,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              border: InputBorder.none,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            items: <String>['Adopter', 'Surrenderer'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _userType = newValue!;
                              });
                            },
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

                        SizedBox(height: 20),

                        // Register button
                        _buildResponsiveButton(
                          context: context,
                          label: 'SIGN UP',
                          onTap: _isLoading ? null : _handleRegistration,
                          isLoading: _isLoading,
                        ),

                        SizedBox(height: 15),

                        // Login section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
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
                          height: 16,
                        ),

                        // Login button
                        _buildResponsiveButton(
                          context: context,
                          label: 'LOGIN',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserLogin(),
                              ),
                            );
                          },
                          backgroundColor: Color(0xFF212121),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 15,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enableSuggestions: !obscureText,
          autocorrect: !obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.4),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          validator: validator,
        ),
      ],
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: isLoading
                ? Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
