import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawsmatch/models/signup_form_data.dart';
import 'package:pawsmatch/pages/web/organization/sign_up.dart';
import 'package:pawsmatch/pages/web/organization/sign_up3.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/pages/web/web_login.dart';
import 'package:pawsmatch/services/supabase_client_service.dart';
import 'package:pawsmatch/utils/firebase_helper.dart';
import 'package:pawsmatch/widgets/web_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpForm2 extends StatefulWidget {
  final SignUpFormData formData;

  SignUpForm2({
    required this.formData,
  });

  @override
  _SignUpForm2State createState() => _SignUpForm2State();
}

class _SignUpForm2State extends State<SignUpForm2> with SingleTickerProviderStateMixin {
  final FirebaseOrganizationService _firebaseOrganizationService = FirebaseOrganizationService();
  final DatabaseAccountService _databaseService = DatabaseAccountService();
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _orgNameController = TextEditingController();
  List<PlatformFile> _proofOfValidationFiles = [];
  
  bool _isFirebaseInitialized = false;
  bool _isLoading = true;
  bool _isDragging = false;
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkFirebase();
    
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
    
    // Initialize with existing data
    _orgNameController.text = widget.formData.organizationName;
    if (widget.formData.proofOfValidationFiles.isNotEmpty) {
      _proofOfValidationFiles = widget.formData.proofOfValidationFiles;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  _checkFirebase() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simply check if Firebase is initialized, don't try to initialize it
      _isFirebaseInitialized = FirebaseHelper.isInitialized;
      
      if (!_isFirebaseInitialized) {
        print('Firebase is not initialized, this is unexpected');
      }
    } catch (e) {
      print('Error checking Firebase initialization: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Update the uploadDocuments function to use our SupabaseClientService
  Future uploadDocuments() async {
    if (_proofOfValidationFiles.isEmpty) return;

    final supabase = SupabaseClientService.client;
    if (supabase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Supabase connection not initialized"))
      );
      return;
    }

    for (var file in _proofOfValidationFiles) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
      final path = 'documents/$fileName';  // Consistent path format

      // Upload to Supabase storage
      try {
        await supabase.storage
            .from('organizations')  // Consistent bucket name
            .upload(path, File(file.path!), fileOptions: FileOptions(cacheControl: '3600', upsert: false))
            .then((value) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Document ${file.name} Uploaded Successfully!"))
                );
              }
            });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error uploading document: $e"))
          );
        }
      }
    }
  }
  
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => WebHomepage())
    );
  }

  void _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _proofOfValidationFiles = result.files;
      });
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No files selected'),
          backgroundColor: Color(0xFF84A59D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _navigateToNextStep() {
    if (_formKey.currentState!.validate()) {
      // Save all current form data
      SignUpFormData updatedFormData = SignUpFormData(
        username: widget.formData.username,
        email: widget.formData.email,
        password: widget.formData.password,
        organizationName: _orgNameController.text,
        proofOfValidationFiles: _proofOfValidationFiles,
        location: widget.formData.location,
        address: widget.formData.address,
        about: widget.formData.about,
        contactNumber: widget.formData.contactNumber,
        mission: widget.formData.mission,
        weekdayHours: widget.formData.weekdayHours,
        weekendHours: widget.formData.weekendHours,
        logoFile: widget.formData.logoFile,
      );
      
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => SignUpForm3(
            formData: updatedFormData,
          ),
        ),
      );
    }
  }
  
  // Navigate back with data
  void _navigateToPreviousStep() {
    // Save current data before going back
    SignUpFormData updatedFormData = SignUpFormData(
      username: widget.formData.username,
      email: widget.formData.email,
      password: widget.formData.password,
      organizationName: _orgNameController.text,
      proofOfValidationFiles: _proofOfValidationFiles,
      location: widget.formData.location,
      address: widget.formData.address,
      about: widget.formData.about,
      contactNumber: widget.formData.contactNumber,
      mission: widget.formData.mission,
      weekdayHours: widget.formData.weekdayHours,
      weekendHours: widget.formData.weekendHours,
      logoFile: widget.formData.logoFile,
    );
    
    // Replace the current page with the previous page, passing updated data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpForm(
          formData: updatedFormData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFFEF5F1), // Updated background color
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
        backgroundColor: Color(0xFFFEF5F1), // Updated background color
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
                onPressed: _checkFirebase,
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
                  _buildStepIndicator(2, true),
                  _buildStepConnector(false),
                  _buildStepIndicator(3, false),
                ],
              ),
              SizedBox(height: 20),
              
              // Form title
              Text(
                'Organization Details',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6572),
                ),
              ),
              Text(
                'Tell us about your organization',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),
              
              // Organization Name field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organization Name',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A6572),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _orgNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter organization name',
                      hintStyle: GoogleFonts.dmSans(
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(Icons.business, color: Color(0xFF84A59D)),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the organization name';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Proof of Validation
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proof of Validation',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A6572),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6BD60).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFF6BD60).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFFF6BD60),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'To ensure you are a legitimate organization, please upload a document that validates and verifies your organization\'s permission to run operations involving animal adoption and surrendering.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: Color(0xFF4A6572),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // File Upload Area
                  GestureDetector(
                    onTap: _pickFiles,
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? Color(0xFF84A59D).withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isDragging
                              ? Color(0xFF84A59D)
                              : Colors.grey.shade300,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _proofOfValidationFiles.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload,
                                  size: 48,
                                  color: Color(0xFF84A59D),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Click to upload files',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4A6572),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Supported formats: PDF, PNG, JPG, JPEG',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Uploaded Files (${_proofOfValidationFiles.length})',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4A6572),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _pickFiles,
                                        icon: Icon(Icons.add, size: 18, color: Color(0xFF84A59D)),
                                        label: Text(
                                          'Add More',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            color: Color(0xFF84A59D),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Divider(color: Colors.grey.shade200),
                                  SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _proofOfValidationFiles.length,
                                      itemBuilder: (context, index) {
                                        final file = _proofOfValidationFiles[index];
                                        
                                        // Determine icon based on file type
                                        IconData fileIcon;
                                        Color iconColor;
                                        
                                        if (file.extension == 'pdf') {
                                          fileIcon = Icons.picture_as_pdf;
                                          iconColor = Colors.red.shade400;
                                        } else if (['jpg', 'jpeg', 'png'].contains(file.extension)) {
                                          fileIcon = Icons.image;
                                          iconColor = Color(0xFF84A59D);
                                        } else {
                                          fileIcon = Icons.insert_drive_file;
                                          iconColor = Colors.grey.shade700;
                                        }
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Icon(fileIcon, color: iconColor, size: 20),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  file.name,
                                                  style: GoogleFonts.dmSans(
                                                    color: Color(0xFF545454),
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
                                                onPressed: () {
                                                  setState(() {
                                                    _proofOfValidationFiles.removeAt(index);
                                                  });
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                                splashRadius: 20,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              
              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  OutlinedButton.icon(
                    onPressed: _navigateToPreviousStep,
                    icon: Icon(Icons.arrow_back, color: Color(0xFF84A59D)),
                    label: Text(
                      'Back',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF84A59D),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF84A59D), width: 2),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  // Next button
                  ElevatedButton.icon(
                    onPressed: _navigateToNextStep,
                    label: Text(
                      'Continue',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    icon: Icon(Icons.arrow_forward, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF84A59D),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              
              // Have an account section - divider and login button
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
                child: OutlinedButton.icon(
                  onPressed: _navigateToLogin,
                  icon: Icon(Icons.login, color: Color(0xFF4A6572)),
                  label: Text(
                    'Sign In Instead',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A6572),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF4A6572), width: 1),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}