import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pawsmatch/models/signup_form_data.dart';
import 'package:pawsmatch/pages/web/organization/sign_up.dart';
import 'package:pawsmatch/pages/web/organization/sign_up3.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/firebase_options.dart';
import 'package:pawsmatch/pages/web/web_login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawsmatch/services/supabase_client_service.dart';  // Add this import
import 'package:pawsmatch/utils/firebase_helper.dart';
import 'package:pawsmatch/pages/web/organization/success_dialog.dart';

class SignUpForm2 extends StatefulWidget {
  final SignUpFormData formData;

  SignUpForm2({
    required this.formData,
  });

  @override
  _SignUpForm2State createState() => _SignUpForm2State();
}

class _SignUpForm2State extends State<SignUpForm2> {
  final FirebaseOrganizationService _firebaseOrganizationService = FirebaseOrganizationService();
  final DatabaseAccountService _databaseService = DatabaseAccountService();
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _orgNameController = TextEditingController();
  List<PlatformFile> _proofOfValidationFiles = [];
  
  bool _isFirebaseInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFirebase();
    
    // Initialize with existing data
    _orgNameController.text = widget.formData.organizationName;
    if (widget.formData.proofOfValidationFiles.isNotEmpty) {
      _proofOfValidationFiles = widget.formData.proofOfValidationFiles;
    }
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
        SnackBar(content: Text('No files selected')),
      );
    }
  }

  void _navigateToNextStep() {
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
  
  // New method to navigate back with data
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
                // Fix: Change _initializeFirebase() to _checkFirebase
                onPressed: () => _checkFirebase(),
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
              
              // Organization Name field
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
                        'Organization Name',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _orgNameController,
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
                          hintText: 'Enter organization name',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
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
                ),
              ),
              
              // Proof of Validation title and description
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
                        'Proof of Validation',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 15,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'To ensure you are a legitimate organization, please upload a document that validates and verifies your organization\'s permission to run operations involving animal adoption and surrendering.',
                        style: TextStyle(
                          color: const Color(0xFF868686),
                          fontSize: 13,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          height: 1.70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Upload area
              Positioned(
                left: 151,
                top: 410,
                child: InkWell(
                  onTap: _pickFiles,
                  child: Container(
                    width: 416,
                    height: 165,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFEF5F0),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: const Color(0xFFC5C6CC),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _proofOfValidationFiles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file, size: 36, color: Color(0xFF868686)),
                                SizedBox(height: 8),
                                SizedBox(
                                  width: 181,
                                  height: 30,
                                  child: Text(
                                    'upload .pdf, .png, jpg, or .jpeg files of your proof of validation',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF868686),
                                      fontSize: 10,
                                      fontFamily: 'Arial',
                                      fontWeight: FontWeight.w400,
                                      height: 1.60,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Uploaded Files:',
                                  style: TextStyle(
                                    color: const Color(0xFF2E3036),
                                    fontSize: 12,
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _proofOfValidationFiles.length,
                                    itemBuilder: (context, index) {
                                      final file = _proofOfValidationFiles[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.description, color: Color(0xFF545454), size: 16),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                file.name,
                                                style: TextStyle(
                                                  color: Color(0xFF545454),
                                                  fontSize: 12,
                                                  fontFamily: 'DM Sans',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
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
              ),
              SizedBox(height: 15),
              
              // Add more spacing between upload area and submit button
              // Submit button - repositioned lower
              Positioned(
                left: 151,
                top: 595,  // Changed from 575 to 595 to add more space
                child: Container(
                  width: 416,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      InkWell(
                        onTap: _navigateToPreviousStep,
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE0E0E0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFF8B8B8B),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_back,
                                size: 16,
                                color: const Color(0xFF464646),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'BACK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF464646),
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1,
                                  letterSpacing: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Next button
                      InkWell(
                        onTap: () {
                          // Allow navigation without validation to keep inputs
                          _navigateToNextStep();
                        },
                        child: Container(
                          width: 200,
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
                              Text(
                                'NEXT',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFFEF5F0),
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1,
                                  letterSpacing: 1.25,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: const Color(0xFFFEF5F0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Reposition the elements below accordingly
              // Already have an account text
              Positioned(
                left: 272,
                top: 660,  // Changed from 640 to 660
                child: SizedBox(
                  width: 181,
                  height: 19,
                  child: Text(
                    'Already have an account?',
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
              
              // Divider
              Positioned(
                left: 168,
                top: 685,  // Changed from 665 to 685
                child: Container(
                  width: 375,
                  height: 0.5,
                  decoration: BoxDecoration(color: const Color(0xFF9E9E9E)),
                ),
              ),
              
              // Login button
              Positioned(
                left: 151,
                top: 700,  // Changed from 680 to 700
                child: Container(
                  width: 416,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _navigateToLogin,
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
                                  'LOGIN',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFFEF5F0),
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