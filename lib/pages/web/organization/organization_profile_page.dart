import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/firebase_account_service.dart'; // Add import
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/models/account.dart'; // Add import
import 'org_sidebar.dart';

class OrganizationProfilePage extends StatefulWidget {
  const OrganizationProfilePage({super.key});

  @override
  State<OrganizationProfilePage> createState() => _OrganizationProfilePageState();
}

class _OrganizationProfilePageState extends State<OrganizationProfilePage> {
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseAccountService _accountService = DatabaseAccountService(); // Add account service
  
  Organization? _organization;
  bool _isLoading = true;
  String _errorMessage = '';
  List<String> _photoUrls = [];
  String? _logoUrl;
  int _currentPhotoIndex = 0;
  
  // Account data
  String _username = '';
  String _email = '';
  
  // Form controllers for edit modal
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _missionController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();
  final TextEditingController _weekdayHoursController = TextEditingController();
  final TextEditingController _weekendHoursController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _landlineController = TextEditingController();
  final TextEditingController _contactNumbersController = TextEditingController();
  
  // Form controllers for account edit modal
  final TextEditingController _accountUsernameController = TextEditingController();
  final TextEditingController _accountEmailController = TextEditingController();
  final TextEditingController _accountCurrentPasswordController = TextEditingController();
  final TextEditingController _accountNewPasswordController = TextEditingController();
  final TextEditingController _accountConfirmPasswordController = TextEditingController();
  
  // Form submission states
  bool _isSubmitting = false;
  String? _submissionError;
  bool _isAccountSubmitting = false;
  String? _accountSubmissionError;
  
  // Password visibility
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  
  @override
  void initState() {
    super.initState();
    _loadOrganizationData();
    _loadAccountData();
  }
  
  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    _missionController.dispose();
    _servicesController.dispose();
    _weekdayHoursController.dispose();
    _weekendHoursController.dispose();
    _emailController.dispose();
    _landlineController.dispose();
    _contactNumbersController.dispose();
    
    // Account controllers
    _accountUsernameController.dispose();
    _accountEmailController.dispose();
    _accountCurrentPasswordController.dispose();
    _accountNewPasswordController.dispose();
    _accountConfirmPasswordController.dispose();
    
    super.dispose();
  }
  
  // Load account data from Firebase
  Future<void> _loadAccountData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return;
      }
      
      // Get current username
      String username = await _accountService.getCurrentUsername();
      
      // Get current email from Firebase Auth
      String email = _auth.currentUser?.email ?? '';
      
      setState(() {
        _username = username;
        _email = email;
      });
    } catch (e) {
      print('Error loading account data: $e');
    }
  }
  
  // Load organization data from Firebase
  Future<void> _loadOrganizationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get current user ID
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Fetch organization data
      final organization = await _organizationService.getOrganizationById(userId);
      if (organization == null) {
        throw Exception('Organization not found');
      }
      
      // Fetch organization photos if available
      List<String> photoUrls = [];
      if (organization.photo_ids != null && organization.photo_ids!.isNotEmpty) {
        photoUrls = await _photoService.getOrganizationPhotoUrls(organization.photo_ids);
      }
      
      // Fetch logo URL if available
      String? logoUrl;
      if (organization.logo_url != null && organization.logo_url!.isNotEmpty) {
        // Direct URL is available
        logoUrl = organization.logo_url;
      } 
      
      if (mounted) {
        setState(() {
          _organization = organization;
          _photoUrls = photoUrls;
          _logoUrl = logoUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  // Populate form controllers with current organization data
  void _populateFormControllers() {
    if (_organization != null) {
      _nameController.text = _organization!.org_name;
      _locationController.text = _organization!.location ?? '';
      _addressController.text = _organization!.address ?? '';
      _aboutController.text = _organization!.about ?? '';
      _missionController.text = _organization!.mission ?? '';
      _servicesController.text = _organization!.services?.join(', ') ?? '';
      _weekdayHoursController.text = _organization!.weekday_hours ?? '';
      _weekendHoursController.text = _organization!.weekend_hours ?? '';
      _emailController.text = _organization!.email ?? '';
      _landlineController.text = _organization!.landline ?? '';
      _contactNumbersController.text = _organization!.contact_numbers?.join(', ') ?? '';
    }
  }
  
  // Populate account form controllers with current account data
  void _populateAccountFormControllers() {
    _accountUsernameController.text = _username;
    _accountEmailController.text = _email;
    _accountCurrentPasswordController.text = '';
    _accountNewPasswordController.text = '';
    _accountConfirmPasswordController.text = '';
  }
  
  void _navigateToEditProfilePage() {
    // Populate form with current organization data
    _populateFormControllers();
    
    // Reset submission state
    setState(() {
      _isSubmitting = false;
      _submissionError = null;
    });
    
    // Show edit profile modal
    showDialog(
      context: context,
      builder: (context) => _buildEditProfileModal(),
    );
  }
  
  void _navigateToEditAccountPage() {
    // Populate form with current account data
    _populateAccountFormControllers();
    
    // Reset submission state
    setState(() {
      _isAccountSubmitting = false;
      _accountSubmissionError = null;
      _showCurrentPassword = false;
      _showNewPassword = false;
      _showConfirmPassword = false;
    });
    
    // Show edit account modal
    showDialog(
      context: context,
      builder: (context) => _buildEditAccountModal(),
    );
  }
  
  // Build the edit profile modal dialog
  Widget _buildEditProfileModal() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: const Color(0xFFFEF5F0),
      child: Container(
        width: min(MediaQuery.of(context).size.width * 0.8, 800),
        padding: EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Edit Organization Profile',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 24,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: const Color(0xFF545454)),
                    splashRadius: 20,
                  ),
                ],
              ),
              Divider(
                height: 30,
                color: const Color(0xFF8B8B8B),
                thickness: 1,
              ),
              
              // Form fields
              _buildFormField('Organization Name', _nameController, required: true),
              _buildFormField('Location', _locationController),
              _buildFormField('Address', _addressController),
              _buildFormField('About', _aboutController, maxLines: 3),
              _buildFormField('Mission', _missionController, maxLines: 3),
              _buildFormField('Services (comma separated)', _servicesController),
              _buildFormField('Weekday Hours', _weekdayHoursController),
              _buildFormField('Weekend Hours', _weekendHoursController),
              _buildFormField('Email', _emailController),
              _buildFormField('Landline', _landlineController),
              _buildFormField('Contact Numbers (comma separated)', _contactNumbersController),
              
              // Error message
              if (_submissionError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _submissionError!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 30),
              
              // Submit and cancel buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF545454),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                          borderRadius: BorderRadius.circular(250),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.25,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Save button - matching the edit profile button style
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitProfileChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFCECB),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                          borderRadius: BorderRadius.circular(250),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFFEFCECB).withOpacity(0.6),
                      ),
                      child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF1E2C2B)),
                            ),
                          )
                        : Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                              color: const Color(0xFF1E2C2B),
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.25,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build the edit account modal dialog
  Widget _buildEditAccountModal() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: const Color(0xFFFEF5F0),
      child: Container(
        width: min(MediaQuery.of(context).size.width * 0.8, 600),
        padding: EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Edit Account Details',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 24,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: const Color(0xFF545454)),
                    splashRadius: 20,
                  ),
                ],
              ),
              Divider(
                height: 30,
                color: const Color(0xFF8B8B8B),
                thickness: 1,
              ),
              
              // Form fields
              _buildFormField('Username', _accountUsernameController, required: true),
              _buildFormField('Email Address', _accountEmailController, required: true),
              
              SizedBox(height: 20),
              
              // Password change section
              Text(
                'Change Password (Optional)',
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 18,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 15),
              
              // Current Password field
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Password',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _accountCurrentPasswordController,
                      obscureText: !_showCurrentPassword,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: const Color(0xFF8B8B8B), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: const Color(0xFF8B8B8B), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: const Color(0xFFB6CBCA), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter current password to confirm changes',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showCurrentPassword = !_showCurrentPassword;
                            });
                          },
                        ),
                      ),
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 16,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ],
                ),
              ),
              
              // New Password field
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Password',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _accountNewPasswordController,
                      obscureText: !_showNewPassword,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: const Color(0xFF8B8B8B), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: const Color(0xFF8B8B8B), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: const Color(0xFFB6CBCA), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Leave blank to keep current password',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showNewPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showNewPassword = !_showNewPassword;
                            });
                          },
                        ),
                      ),
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 16,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Confirm Password field
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm New Password',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _accountConfirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: const Color(0xFF8B8B8B), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: const Color(0xFF8B8B8B), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: const Color(0xFFB6CBCA), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Confirm your new password',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 16,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Error message
              if (_accountSubmissionError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _accountSubmissionError!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 30),
              
              // Submit and cancel buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF545454),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                          borderRadius: BorderRadius.circular(250),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.25,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Save button - using B6CBCA color for account
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAccountSubmitting ? null : _submitAccountChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB6CBCA),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                          borderRadius: BorderRadius.circular(250),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFFB6CBCA).withOpacity(0.6),
                      ),
                      child: _isAccountSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF1E2B2B)),
                            ),
                          )
                        : Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                              color: const Color(0xFF1E2B2B),
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.25,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to build form fields with consistent styling
  Widget _buildFormField(String label, TextEditingController controller,
      {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'DM Sans',
                  ),
                ),
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: const Color(0xFF8B8B8B), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: const Color(0xFF8B8B8B), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: const Color(0xFFEFCECB), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            style: TextStyle(
              color: const Color(0xFF545454),
              fontSize: 16,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }
  
  // Submit form changes to backend
  Future<void> _submitProfileChanges() async {
    if (_organization == null) return;
    
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _submissionError = 'Organization name is required';
      });
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    
    try {
      // Process the services list
      List<String>? servicesList;
      if (_servicesController.text.isNotEmpty) {
        servicesList = _servicesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      
      // Process contact numbers
      List<String>? contactNumbersList;
      if (_contactNumbersController.text.isNotEmpty) {
        contactNumbersList = _contactNumbersController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      
      // Create updated organization object
      final updatedOrganization = _organization!.copyWith(
        org_name: _nameController.text.trim(),
        location: _locationController.text.isEmpty ? null : _locationController.text.trim(),
        address: _addressController.text.isEmpty ? null : _addressController.text.trim(),
        about: _aboutController.text.isEmpty ? null : _aboutController.text.trim(),
        mission: _missionController.text.isEmpty ? null : _missionController.text.trim(),
        services: servicesList,
        weekday_hours: _weekdayHoursController.text.isEmpty ? null : _weekdayHoursController.text.trim(),
        weekend_hours: _weekendHoursController.text.isEmpty ? null : _weekendHoursController.text.trim(),
        email: _emailController.text.isEmpty ? null : _emailController.text.trim(),
        landline: _landlineController.text.isEmpty ? null : _landlineController.text.trim(),
        contact_numbers: contactNumbersList,
      );
      
      // Get organization document ID from service
      final String? organizationDocId = await _organizationService.getOrganizationIDById(_auth.currentUser!.uid);
      
      if (organizationDocId == null) {
        throw Exception('Could not determine organization document ID');
      }
      
      // Update the organization in Firestore
      await _organizationService.updateOrganization(organizationDocId, updatedOrganization);
      
      // Update local state with the new organization data
      setState(() {
        _organization = updatedOrganization;
        _isSubmitting = false;
      });
      
      // Close the dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload organization data to ensure we have the latest
      await _loadOrganizationData();
      
    } catch (e) {
      print('Error updating profile: $e');
      setState(() {
        _isSubmitting = false;
        _submissionError = 'Failed to update profile: $e';
      });
    }
  }
  
  // Submit account changes to backend
  Future<void> _submitAccountChanges() async {
    // Validate required fields
    if (_accountUsernameController.text.trim().isEmpty || 
        _accountEmailController.text.trim().isEmpty) {
      setState(() {
        _accountSubmissionError = 'Username and email are required';
      });
      return;
    }
    
    // Validate email format
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(_accountEmailController.text.trim())) {
      setState(() {
        _accountSubmissionError = 'Please enter a valid email address';
      });
      return;
    }
    
    // Check if password change is requested
    bool changingPassword = _accountNewPasswordController.text.isNotEmpty;
    
    // If changing password, validate
    if (changingPassword) {
      // Current password is required
      if (_accountCurrentPasswordController.text.isEmpty) {
        setState(() {
          _accountSubmissionError = 'Current password is required to change password';
        });
        return;
      }
      
      // New and confirm password must match
      if (_accountNewPasswordController.text != _accountConfirmPasswordController.text) {
        setState(() {
          _accountSubmissionError = 'New passwords do not match';
        });
        return;
      }
      
      // Password must be at least 8 characters
      if (_accountNewPasswordController.text.length < 8) {
        setState(() {
          _accountSubmissionError = 'New password must be at least 8 characters';
        });
        return;
      }
    }
    
    setState(() {
      _isAccountSubmitting = true;
      _accountSubmissionError = null;
    });
    
    try {
      // 1. If changing username
      if (_accountUsernameController.text.trim() != _username) {
        await _accountService.updateUsername(_accountUsernameController.text.trim());
      }
      
      // 2. If changing email
      if (_accountEmailController.text.trim() != _email) {
        // Re-authenticate user before email change
        if (_accountCurrentPasswordController.text.isEmpty) {
          throw Exception('Current password is required to change email');
        }
        
        // Re-authenticate and update email
        await _accountService.updateEmail(
          _accountEmailController.text.trim(),
          _accountCurrentPasswordController.text
        );
      }
      
      // 3. If changing password
      if (changingPassword) {
        await _accountService.updatePassword(
          _accountCurrentPasswordController.text,
          _accountNewPasswordController.text
        );
      }
      
      // Update local state
      setState(() {
        _username = _accountUsernameController.text.trim();
        _email = _accountEmailController.text.trim();
        _isAccountSubmitting = false;
      });
      
      // Close the dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account details updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload account data to ensure we have the latest
      await _loadAccountData();
      
    } catch (e) {
      print('Error updating account: $e');
      setState(() {
        _isAccountSubmitting = false;
        _accountSubmissionError = 'Failed to update account: ${_getErrorMessage(e)}';
      });
    }
  }
  
  // Helper method to get user-friendly error messages
  String _getErrorMessage(dynamic error) {
    String message = error.toString();
    
    if (message.contains('wrong-password')) {
      return 'Incorrect current password';
    } else if (message.contains('email-already-in-use')) {
      return 'This email is already in use by another account';
    } else if (message.contains('requires-recent-login')) {
      return 'Please log out and log back in before making these changes';
    } else if (message.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection';
    }
    
    return message;
  }
  
  void _changePhotoIndex(int index) {
    setState(() {
      _currentPhotoIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: Center(
        child: Container(
          width: 1584,
          height: 1024,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: const Color(0xFFFEF5F0)),
          child: Stack(
            children: [
              // Top horizontal line
              Positioned(
                left: 16,
                top: 1,
                child: Container(
                  width: 503,
                  height: 0.50,
                  decoration: BoxDecoration(color: const Color(0xFF9E9E9E)),
                ),
              ),
              
              // Sidebar
              const Positioned(
                left: 0,
                top: 0,
                child: OrgSidebar(),
              ),
              
              // Main content area - Fix scrolling and alignment issues
              Positioned(
                left: 359,
                top: 0,
                right: 0,
                bottom: 0,
                child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                    ? _buildErrorView()
                    : SingleChildScrollView(
                        child: _organization != null
                          ? _buildOrganizationContent()
                          : Center(child: Text('No organization data available')),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            'Error Loading Organization Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrganizationData,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Color(0xFFC0D6B6),
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrganizationContent() {
    // Calculate available width for content area
    final double contentWidth = MediaQuery.of(context).size.width - 359;
    // Set appropriate paddings
    final double horizontalPadding = contentWidth * 0.05;
    
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization Header - Improved alignment
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Organization logo
              Container(
                width: 121,
                height: 118,
                decoration: ShapeDecoration(
                  image: _logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_logoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: const Color(0x8E725F63),
                    ),
                    borderRadius: BorderRadius.circular(92.50),
                  ),
                ),
                child: _logoUrl == null
                  ? Center(
                      child: Icon(
                        Icons.pets,
                        size: 50,
                        color: const Color(0xFF725F63),
                      ),
                    )
                  : null,
              ),
              
              SizedBox(width: 24),
              
              // Organization name and location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _organization!.org_name,
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 30,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      _organization!.address ?? 'No address provided',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 40),
          
          // New single-column layout
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              
              return Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    // First section: All text content
                    _buildTextSections(availableWidth),
                    
                    SizedBox(height: 40),
                    
                    // Second section: Photo gallery in landscape format
                    if (_photoUrls.isNotEmpty)
                      _buildPhotoGallerySection(availableWidth),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // New method to build all text sections together
  Widget _buildTextSections(double availableWidth) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Us section
          _buildSectionWithTitle(
            'About Us', 
            _organization!.about ?? 'No information provided',
            availableWidth
          ),
          
          SizedBox(height: 30),
          
          // Our Mission section (moved from right column)
          _buildSectionWithTitle(
            'Our Mission', 
            _organization!.mission ?? 'No mission statement provided',
            availableWidth
          ),
          
          SizedBox(height: 30),
          
          // Services Offered section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Services Offered',
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 24,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16),
              
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.start,
                children: _buildServiceTags(),
              ),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Operating Hours section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operating Hours',
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 24,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16),
              
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHoursRow('Weekdays', _organization!.weekday_hours ?? 'Not specified'),
                    SizedBox(height: 12),
                    _buildHoursRow('Weekends', _organization!.weekend_hours ?? 'Not specified'),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Contact Information section (moved from right column)
          if (_organization!.contact_numbers != null ||
              _organization!.email != null ||
              _organization!.social_media_links != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 24,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16),
                
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: _buildContactDetails(),
                ),
              ],
            ),
          
          SizedBox(height: 40),
          
          // Edit buttons
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Edit Profile button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _navigateToEditProfilePage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFCECB),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                          borderRadius: BorderRadius.circular(250),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'EDIT PROFILE DETAILS',
                        style: TextStyle(
                          color: const Color(0xFF1E2C2B),
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.25,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Edit Account button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _navigateToEditAccountPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB6CBCA),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                          borderRadius: BorderRadius.circular(250),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'EDIT ACCOUNT DETAILS',
                        style: TextStyle(
                          color: const Color(0xFF1E2B2B),
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.25,
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

  // Helper method for sections with title and text
  Widget _buildSectionWithTitle(String title, String content, double width) {
    final TextAlign textAlignment = width < 600 ? TextAlign.center : TextAlign.start;
    
    return Column(
      crossAxisAlignment: width < 600 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF545454),
            fontSize: 24,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        Text(
          content,
          textAlign: textAlignment,
          style: TextStyle(
            color: const Color(0xFF545454),
            fontSize: 16,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
  
  // New method to build photo gallery section at the bottom
  Widget _buildPhotoGallerySection(double availableWidth) {
    // Calculate photo gallery size with landscape aspect ratio (16:9)
    final double galleryHeight = min(350.0, availableWidth * 0.3);
    final double galleryWidth = min(availableWidth, 1200.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Photo Gallery',
          style: TextStyle(
            color: const Color(0xFF545454),
            fontSize: 24,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        
        // Landscape photo container
        Container(
          height: galleryHeight,
          width: galleryWidth,
          child: _photoUrls.isNotEmpty
            ? _buildLandscapePhotoGallery(galleryWidth, galleryHeight)
            : _buildEmptyPhotoPlaceholder(),
        ),
        
        SizedBox(height: 16),
        
        // Photo navigation dots centered below the gallery
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_photoUrls.length, (index) {
            return GestureDetector(
              onTap: () => _changePhotoIndex(index),
              child: Container(
                width: 12,
                height: 12,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentPhotoIndex == index
                    ? const Color(0xFF34C2BB)
                    : const Color(0xFFB6CBCA),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
  
  // Modified photo gallery with landscape orientation
  Widget _buildLandscapePhotoGallery(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _photoUrls.isNotEmpty && _currentPhotoIndex < _photoUrls.length
          ? Image.network(
              _photoUrls[_currentPhotoIndex],
              width: width,
              height: height,
              fit: BoxFit.cover, // Make sure the image covers the container
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 60,
                      color: Colors.grey[700],
                    ),
                  ),
                );
              },
            )
          : Container(color: Colors.grey[300]),
      ),
    );
  }
  
  // Helper for hours display
  Widget _buildHoursRow(String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$day:',
          style: TextStyle(
            color: const Color(0xFF545454),
            fontSize: 16,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          hours,
          style: TextStyle(
            color: const Color(0xFF545454),
            fontSize: 16,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
  
  // Better contact details formatting
  Widget _buildContactDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Email
        if (_organization!.email != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.email, size: 18, color: Colors.grey[700]),
                SizedBox(width: 8),
                Text(
                  _organization!.email!,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        
        // Phone numbers
        if (_organization!.contact_numbers != null && 
            _organization!.contact_numbers!.isNotEmpty)
          Column(
            children: _organization!.contact_numbers!.map((phone) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, size: 18, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Text(
                      phone,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        
        // Landline
        if (_organization!.landline != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_in_talk, size: 18, color: Colors.grey[700]),
                SizedBox(width: 8),
                Text(
                  'Landline: ${_organization!.landline}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
        // Social media links
        if (_organization!.social_media_links != null && 
            _organization!.social_media_links!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Text(
                  'Connect with us on social media',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var _ in _organization!.social_media_links!)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.link,
                          size: 24,
                          color: Color(0xFF725F63),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  // Empty photo placeholder with better styling
  Widget _buildEmptyPhotoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No photos available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build service tag widgets
  List<Widget> _buildServiceTags() {
    if (_organization?.services == null || _organization!.services!.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: const Color(0xFFEDEDED),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(250),
            ),
          ),
          child: Text(
            'NO SERVICES LISTED',
            style: TextStyle(
              color: const Color(0xFF545454),
              fontSize: 14,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w400,
              height: 1.14,
              letterSpacing: 1.25,
            ),
          ),
        ),
      ];
    }
    
    return _organization!.services!.map((service) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: const Color(0xFFEDEDED),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: const Color(0xFFEDEDED),
            ),
            borderRadius: BorderRadius.circular(250),
          ),
        ),
        child: Text(
          service.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFF545454),
            fontSize: 14,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
            height: 1.14,
            letterSpacing: 1.25,
          ),
        ),
      );
    }).toList();
  }
}
