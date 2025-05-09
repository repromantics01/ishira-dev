import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/models/signup_form_data.dart';
import 'package:pawsmatch/pages/web/organization/sign_up2.dart';
import 'package:pawsmatch/pages/web/organization/success_dialog.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/supabase_client_service.dart';
import 'package:pawsmatch/utils/firebase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpForm3 extends StatefulWidget {
  final SignUpFormData formData;

  const SignUpForm3({
    Key? key,
    required this.formData,
  }) : super(key: key);

  @override
  _SignUpForm3State createState() => _SignUpForm3State();
}

class _SignUpForm3State extends State<SignUpForm3> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseAccountService _databaseService = DatabaseAccountService();
  final FirebaseOrganizationService _orgService = FirebaseOrganizationService();
  final FirebasePhotoService _photoService = FirebasePhotoService(); // Add FirebasePhotoService

  // Form controllers
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _missionController = TextEditingController();
  final TextEditingController _weekdayHoursController = TextEditingController();
  final TextEditingController _weekendHoursController = TextEditingController();

  bool _isLoading = false;
  bool _isFirebaseInitialized = false;
  String? _errorMessage;
  PlatformFile? _logoFile;

  @override
  void initState() {
    super.initState();
    _checkFirebase();
    
    // Initialize fields with data from previous steps
    _locationController.text = widget.formData.location ?? '';
    _addressController.text = widget.formData.address ?? '';
    _aboutController.text = widget.formData.about ?? '';
    _contactNumberController.text = widget.formData.contactNumber ?? '';
    _emailController.text = widget.formData.email;
    _missionController.text = widget.formData.mission ?? '';
    _weekdayHoursController.text = widget.formData.weekdayHours ?? '';
    _weekendHoursController.text = widget.formData.weekendHours ?? '';
    
    if (widget.formData.logoFile != null) {
      _logoFile = widget.formData.logoFile;
    }
  }

  void dispose() {
    _locationController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _missionController.dispose();
    _weekdayHoursController.dispose();
    _weekendHoursController.dispose();
    super.dispose();
  }

  _checkFirebase() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
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

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _logoFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadLogo() async {
    if (_logoFile == null) return null;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Generate a unique filename for the logo
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final filename = '${timestamp}_${_logoFile!.name.replaceAll(' ', '_')}';
      
      //print('Starting logo upload with filename: $filename');
      
      // For web (Uint8List)
      if (_logoFile!.bytes != null) {
        print('Uploading web file bytes, size: ${_logoFile!.bytes!.length} bytes');
        return await _photoService.uploadLogo(_logoFile!.bytes!, filename);
      } 
      // For mobile (File path)
      else if (_logoFile!.path != null) {
        print('Reading file from path: ${_logoFile!.path}');
        try {
          final bytes = await File(_logoFile!.path!).readAsBytes();
          print('File read successfully, size: ${bytes.length} bytes');
          return await _photoService.uploadLogo(bytes, filename);
        } catch (e) {
          print('Error reading file: $e');
          setState(() {
            _errorMessage = "Error reading logo file: $e";
          });
          return null;
        }
      } else {
        print('No valid file content (no bytes or path)');
        setState(() {
          _errorMessage = "Invalid logo file format";
        });
        return null;
      }
    } catch (e) {
      print('Exception during logo upload process: $e');
      setState(() {
        _errorMessage = "Error uploading logo: $e";
      });
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _uploadProofDocuments() async {
    if (widget.formData.proofOfValidationFiles.isEmpty) return null;
    
    final supabase = SupabaseClientService.client;
    if (supabase == null) {
      setState(() {
        _errorMessage = "Supabase connection not initialized";
      });
      return null;
    }
    
    final List<String> documentUrls = [];
    
    for (var file in widget.formData.proofOfValidationFiles) {
      try {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
        final path = 'documents/$fileName';  // Consistent path format
        
        // For web (Uint8List)
        if (file.bytes != null) {
          await supabase.storage
              .from('organization_documents')  // Consistent bucket name
              .uploadBinary(path, file.bytes!, fileOptions: const FileOptions(
                contentType: 'application/octet-stream',
                upsert: true
              ));
        } 
        // For mobile (File path)
        else {
          print('Skipping file with no bytes or path: ${file.name}');
          continue;
        }
        
        // FIXED: Use createSignedUrl instead of getPublicUrl
        final documentUrl = await supabase.storage
            .from('organization_documents')
            .createSignedUrl(path, FirebasePhotoService.SIGNED_URL_EXPIRY);
            
        documentUrls.add(documentUrl);
        print('Uploaded document: $fileName, URL: $documentUrl');
      } catch (e) {
        print('Error uploading document ${file.name}: $e');
        // Continue with other documents
      }
    }
    
    // Join all document URLs
    return documentUrls.isEmpty ? null : documentUrls.join(",");
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      // 1. Upload logo if provided
      String? logoUrl;
      if (_logoFile != null) {
        print('Starting logo upload process');
        logoUrl = await _uploadLogo();
        
        // Debug logging
        if (logoUrl != null) {
          print('Logo successfully uploaded, URL: $logoUrl');
        } else {
          print('Logo upload failed or returned null URL');
        }
      }
      
      // 2. Upload validation documents
      final String? documentUrls = await _uploadProofDocuments();
      
      // 3. Create Firebase Auth account
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.formData.email,
        password: widget.formData.password,
      );
      
      // 4. Create account in Firestore - Fix Account constructor to match model
      final Account account = Account(
        account_id: userCredential.user!.uid,
        account_username: widget.formData.username, // Changed from username to account_username
        account_email: widget.formData.email,    // Changed from email to account_email
        account_password: widget.formData.password, // Added password field
        account_type: AccountType.OrgAdmin, // Changed from role string to enum
        date_created: DateTime.now(),   // Added date_created field
      );
      
      // Fix method name to match service implementation
      await _databaseService.addAccount(account, userCredential.user!.uid);
      
      // Parse contact numbers from comma-separated string
      List<String> contactNumbers = _contactNumberController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      // 5. Create organization in Firestore with logo URL
      final Organization organization = Organization(
        org_id: userCredential.user!.uid,
        org_name: widget.formData.organizationName,
        org_proof_of_validation: documentUrls ?? "No documents provided",
        date_created: DateTime.now(),
        admin_ids: [userCredential.user!.uid],
        isVerified: false,
        isRejected: false,
        location: _locationController.text,
        address: _addressController.text,
        about: _aboutController.text,
        mission: _missionController.text.isNotEmpty ? _missionController.text : null,
        email: _emailController.text,
        contact_numbers: contactNumbers,
        logo_url: logoUrl, // This will be the URL retrieved from Supabase
        weekday_hours: _weekdayHoursController.text.isNotEmpty ? _weekdayHoursController.text : null,
        weekend_hours: _weekendHoursController.text.isNotEmpty ? _weekendHoursController.text : null,
      );
      
      //print('Creating organization with logo_url: $logoUrl');
      
      // Use correct method from service
      await _orgService.addOrganizationWithId(organization, userCredential.user!.uid);
      
      // 6. Show success dialog
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SuccessDialog(
              email: widget.formData.email,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Registration error: $e');
    }
  }

  // Add method to navigate back without validation
  void _navigateToPreviousStep() {
    // Save current state before going back
    SignUpFormData updatedFormData = SignUpFormData(
      username: widget.formData.username,
      email: widget.formData.email,
      password: widget.formData.password,
      organizationName: widget.formData.organizationName,
      proofOfValidationFiles: widget.formData.proofOfValidationFiles,
      location: _locationController.text,
      address: _addressController.text,
      about: _aboutController.text,
      contactNumber: _contactNumberController.text,
      mission: _missionController.text,
      weekdayHours: _weekdayHoursController.text,
      weekendHours: _weekendHoursController.text,
      logoFile: _logoFile,
    );
    
    // Replace current page with previous page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpForm2(
          formData: updatedFormData,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label, 
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label*' : label,
          style: TextStyle(
            color: const Color(0xFF545454),
            fontSize: 14,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
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
            hintText: hint ?? 'Enter $label',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
            ),
          ),
          validator: required ? (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          } : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !mounted) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
                top: 90,
                child: SizedBox(
                  width: 448,
                  height: 40,
                  child: Text(
                    'Organization Details',
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

              // Form content in a scrollable area
              Positioned(
                left: 151,
                top: 150,
                width: 416,
                bottom: 100,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message if any
                      if (_errorMessage != null)
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),

                      // Logo upload section
                      Text(
                        'Organization Logo',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Logo selection area
                      InkWell(
                        onTap: _pickLogo,
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFC5C6CC)),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: _logoFile != null && _logoFile!.bytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.memory(
                                    _logoFile!.bytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: Colors.grey.shade400,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add Logo',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Required information fields                      
                      _buildFormField(
                        label: 'Location',
                        controller: _locationController,
                        hint: 'Enter city and country (e.g. Manila, Philippines)',
                      ),
                      
                      _buildFormField(
                        label: 'Address',
                        controller: _addressController,
                        hint: 'Enter full address',
                      ),

                      _buildFormField(
                        label: 'About Your Organization',
                        controller: _aboutController,
                        hint: 'Provide a description of your organization',
                        maxLines: 4,
                      ),

                      _buildFormField(
                        label: 'Contact Email',
                        controller: _emailController,
                      ),

                      _buildFormField(
                        label: 'Contact Numbers',
                        controller: _contactNumberController,
                        hint: 'Enter phone numbers (comma separated)',
                      ),

                      // Optional information fields
                      _buildFormField(
                        label: 'Mission Statement',
                        controller: _missionController,
                        hint: 'Your organization\'s mission (optional)',
                        maxLines: 2,
                        required: false,
                      ),
                      
                      _buildFormField(
                        label: 'Weekday Hours',
                        controller: _weekdayHoursController,
                        hint: 'e.g. 9:00 AM - 5:00 PM (optional)',
                        required: false,
                      ),
                      
                      _buildFormField(
                        label: 'Weekend Hours',
                        controller: _weekendHoursController,
                        hint: 'e.g. 10:00 AM - 3:00 PM (optional)',
                        required: false,
                      ),

                      // Submit button area with Back and Submit buttons
                      Container(
                        width: 416,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
                            InkWell(
                              onTap: _isLoading ? null : _navigateToPreviousStep,
                              child: Container(
                                width: 180,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: ShapeDecoration(
                                  color: _isLoading ? Colors.grey.shade300 : Color(0xFFE0E0E0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFF8B8B8B),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                        color: Colors.black87,
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
                            
                            // Submit button
                            InkWell(
                              onTap: _isLoading ? null : _submitRegistration,
                              child: Container(
                                width: 180,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: ShapeDecoration(
                                  color: _isLoading ? Colors.grey : const Color(0xFF212121),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading 
                                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'SUBMIT',
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
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),
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
