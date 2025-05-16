import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/models/signup_form_data.dart';
import 'package:pawsmatch/pages/web/organization/sign_up2.dart';
import 'package:pawsmatch/pages/web/web_login.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawsmatch/widgets/web_background.dart';

class SignUpForm extends StatefulWidget {
  final SignUpFormData? formData;
  
  const SignUpForm({super.key, this.formData});

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> with SingleTickerProviderStateMixin {
  final DatabaseAccountService _databaseService = DatabaseAccountService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isFirebaseInitialized = false;
  bool _isLoading = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Animation controller
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
    
    // Initialize form fields with existing data if available
    if (widget.formData != null) {
      _usernameController.text = widget.formData!.username;
      _emailController.text = widget.formData!.email;
      _passwordController.text = widget.formData!.password;
      _confirmPasswordController.text = widget.formData!.password;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        backgroundColor: Color(0xFFFEF5F1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/paw_loading.gif', height: 100),
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
        backgroundColor: Color(0xFFFEF5F1),
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

    // Create form content
    Widget signUpContent = WebContentContainer(
      child: WebCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Row(
                children: [
                  _buildStepIndicator(1, true),
                  _buildStepConnector(true),
                  _buildStepIndicator(2, false),
                  _buildStepConnector(false),
                  _buildStepIndicator(3, false),
                ],
              ),
              SizedBox(height: 20),
              
              // Form title
              Text(
                'Account Information',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6572),
                ),
              ),
              Text(
                'Create your organization account credentials',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),
              
              // Form fields
              _buildFormField(
                label: 'Username',
                controller: _usernameController,
                icon: Icons.person_outline,
                hint: 'Enter your admin username',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your account username';
                  }
                  return null;
                },
              ),
              
              _buildFormField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email_outlined,
                hint: 'Enter your email address',
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
              
              _buildFormField(
                label: 'Password',
                controller: _passwordController,
                icon: Icons.lock_outline,
                hint: 'Create a strong password',
                obscureText: _obscurePassword,
                toggleObscureText: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
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
              
              _buildFormField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                hint: 'Confirm your password',
                obscureText: _obscureConfirmPassword,
                toggleObscureText: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
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
              
              SizedBox(height: 24),
              
              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Save current inputs
                      SignUpFormData formData = SignUpFormData(
                        username: _usernameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                        organizationName: widget.formData?.organizationName ?? '',
                        proofOfValidationFiles: widget.formData?.proofOfValidationFiles ?? [],
                        location: widget.formData?.location,
                        address: widget.formData?.address,
                        about: widget.formData?.about,
                        contactNumber: widget.formData?.contactNumber,
                        mission: widget.formData?.mission,
                        weekdayHours: widget.formData?.weekdayHours,
                        weekendHours: widget.formData?.weekendHours,
                        logoFile: widget.formData?.logoFile,
                      );
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignUpForm2(
                            formData: formData,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF84A59D),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
              
              // Already have an account - divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Already have an account?',
                        style: GoogleFonts.dmSans(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
              ),
              
              // Login button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WebHomepage(),
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
                    'Back to Login',
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
      ),
    );

    return WebBackground(
      contentWidget: signUpContent,
      subtitleText: 'Organization Sign Up',
    );
  }
  
  // Helper methods for the UI components
  Widget _buildStepIndicator(int step, bool isActive) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? Color(0xFF84A59D) : Colors.grey.shade200,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Color(0xFF84A59D) : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: GoogleFonts.dmSans(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Color(0xFF84A59D) : Colors.grey.shade300,
      ),
    );
  }
  
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? toggleObscureText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A6572),
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(icon, color: Color(0xFF84A59D)),
              suffixIcon: toggleObscureText != null
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Color(0xFF84A59D),
                    ),
                    onPressed: toggleObscureText,
                  )
                : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}