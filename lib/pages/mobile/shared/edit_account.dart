import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/widgets/logout_button.dart';
import 'package:flutter/services.dart';

class EditAccount extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditAccount({Key? key, required this.userData}) : super(key: key);

  @override
  _EditAccountState createState() => _EditAccountState();
}

class _EditAccountState extends State<EditAccount> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseAccountService _accountService = DatabaseAccountService();

  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  String? _currentPassword; // Store the current password entered via modal

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userData['username']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Show modal to enter current password
  Future<void> _showCurrentPasswordModal() async {
    final TextEditingController _currentPasswordController = TextEditingController();
    String? error;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Current Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('For security, please enter your current password.'),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  errorText: error,
                ),
                autofocus: true,
                onSubmitted: (_) => Navigator.of(context).pop(_currentPasswordController.text),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_currentPasswordController.text.isEmpty) {
                  setState(() {
                    error = 'Password required';
                  });
                } else {
                  Navigator.of(context).pop(_currentPasswordController.text);
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _currentPassword = result;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update username if changed
      if (_usernameController.text != widget.userData['username']) {
        await _accountService.updateUsername(_usernameController.text);
      }

      // Update email if changed
      if (_emailController.text != widget.userData['email']) {
        if (_currentPassword == null) {
          await _showCurrentPasswordModal();
        }
        if (_currentPassword == null || _currentPassword!.isEmpty) {
          throw Exception('Current password required for email update');
        }
        try {
          await _accountService.updateEmail(_emailController.text, _currentPassword!);
        } on Exception catch (e) {
          // Show a more user-friendly error if operation-not-allowed
          final msg = e.toString().toLowerCase();
          if (msg.contains('operation-not-allowed')) {
            throw Exception('Email update is currently disabled. Please contact support.');
          }
          rethrow;
        }
      }

      // Update password if provided
      if (_passwordController.text.isNotEmpty) {
        if (_currentPassword == null) {
          await _showCurrentPasswordModal();
        }
        if (_currentPassword == null || _currentPassword!.isEmpty) {
          throw Exception('Current password required for password update');
        }
        await _accountService.updatePassword(_currentPassword!, _passwordController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account details updated successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate successful update
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating account: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? 'An error occurred')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF5F0),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          // Replace the logout button with the new widget
          LogoutButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section with title and back button
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF545454),
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 10),
                    // Title
                    const Text(
                      'User Settings',
                      style: TextStyle(
                        color: Color(0xFF545454),
                        fontSize: 24,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Top profile section with cream background
              Container(
                width: double.infinity,
                height: 20,
                color: const Color(0xFFFEF5F0),
              ),
              
              // Main content with white background and rounded top corners
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 160,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Edit Account Details text
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 20),
                        child: Text(
                          'Edit Account Details',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.53),
                            fontSize: 16,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      
                      // Username field
                      _buildFormField(
                        label: 'Username',
                        controller: _usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Email field
                      _buildFormField(
                        label: 'Email',
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // New Password field
                      _buildFormField(
                        label: 'New Password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        onTap: () async {
                          // Show modal for current password when focusing on new password
                          await _showCurrentPasswordModal();
                        },
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF725F63),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
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

  // Helper for building form fields
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
      onTap: onTap,
    );
  }
}
