import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/widgets/logout_button.dart';

class EditProfile extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfile({Key? key, required this.userData}) : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseProfileService _profileService = FirebaseProfileService();
  
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _suffixController;
  late final TextEditingController _addressController;
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.userData['firstName']);
    _middleNameController = TextEditingController(text: widget.userData['middleName']);
    _lastNameController = TextEditingController(text: widget.userData['lastName']);
    _suffixController = TextEditingController(text: widget.userData['suffix']);
    _addressController = TextEditingController(text: widget.userData['address']);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _addressController.dispose();
    super.dispose();
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

      // Get current profile
      final profileSnapshot = await _profileService.getUserProfile(user.uid);
      if (profileSnapshot == null) {
        throw Exception('Profile not found');
      }

      // Update profile data
      await _profileService.updateProfile(user.uid, {
        'first_name': _firstNameController.text,
        'middle_name': _middleNameController.text,
        'last_name': _lastNameController.text,
        'suffix': _suffixController.text,
        'address': _addressController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate successful update
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: ${e.toString()}';
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
                      // Profile avatar
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 113.82,
                              height: 113.82,
                              decoration: ShapeDecoration(
                                color: const Color(0xFFF5F5F5),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    color: Colors.black.withOpacity(0.29),
                                  ),
                                  borderRadius: BorderRadius.circular(73),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                            ),
                            // Edit icon (not functional in this version)
                            Positioned(
                              right: 0,
                              bottom: 10,
                              child: Container(
                                width: 21,
                                height: 21,
                                decoration: const ShapeDecoration(
                                  color: Color(0xFFD9D9D9),
                                  shape: OvalBorder(),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Color(0xFF545454),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Edit Profile Details text
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 20),
                        child: Text(
                          'Edit Profile Details',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.53),
                            fontSize: 16,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      
                      // First Name field
                      _buildFormField(
                        label: 'First Name',
                        controller: _firstNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'First name cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Middle Name field
                      _buildFormField(
                        label: 'Middle Name',
                        controller: _middleNameController,
                        validator: (value) {
                          // Middle name can be empty
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildFormField(
                              label: 'Last Name',
                              controller: _lastNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Last name cannot be empty';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Suffix field (narrower)
                          Expanded(
                            flex: 1,
                            child: _buildFormField(
                              label: 'Suffix',
                              controller: _suffixController,
                              validator: (value) {
                                // Suffix can be empty
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Address field
                      _buildFormField(
                        label: 'Address',
                        controller: _addressController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Address cannot be empty';
                          }
                          return null;
                        },
                      ),
                      
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      
                      // Buttons
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            // Cancel button
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 169,
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFEDEDED),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(250),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'CANCEL',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF1E2C2B),
                                      fontSize: 14,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w500,
                                      height: 1.14,
                                      letterSpacing: 1.25,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Confirm button
                            GestureDetector(
                              onTap: _isLoading ? null : _saveChanges,
                              child: Container(
                                width: 169,
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: ShapeDecoration(
                                  color: _isLoading 
                                      ? const Color(0xFFD9D9D9) 
                                      : const Color(0xFFC1BEBE),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(250),
                                  ),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF1E2C2B),
                                          ),
                                        )
                                      : const Text(
                                          'CONFIRM',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF1E2C2B),
                                            fontSize: 14,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w500,
                                            height: 1.14,
                                            letterSpacing: 1.25,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF787878),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1,
                color: Color(0xFFC5C6CC),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            style: const TextStyle(
              color: Color(0xFF8F9098),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
