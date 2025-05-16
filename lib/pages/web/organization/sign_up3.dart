import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:pawsmatch/widgets/web_background.dart';
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

class _SignUpForm3State extends State<SignUpForm3> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final DatabaseAccountService _databaseService = DatabaseAccountService();
  final FirebaseOrganizationService _orgService = FirebaseOrganizationService();
  final FirebasePhotoService _photoService = FirebasePhotoService();

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
    _animationController.dispose();
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
              .from('organization_documents')
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
        
        // Use createSignedUrl instead of getPublicUrl
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
    if (!_formKey.currentState!.validate()) {
      // Show error toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

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
      
      // 4. Create account in Firestore
      final Account account = Account(
        account_id: userCredential.user!.uid,
        account_username: widget.formData.username,
        account_email: widget.formData.email,
        account_password: widget.formData.password,
        account_type: AccountType.OrgAdmin,
        date_created: DateTime.now(),
      );
      
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
        logo_url: logoUrl,
        weekday_hours: _weekdayHoursController.text.isNotEmpty ? _weekdayHoursController.text : null,
        weekend_hours: _weekendHoursController.text.isNotEmpty ? _weekendHoursController.text : null,
      );
      
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !mounted) {
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

    // Create form content for step 3
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
                  _buildStepConnector(true),
                  _buildStepIndicator(3, true),
                ],
              ),
              SizedBox(height: 20),
              
              // Form title
              Text(
                'Contact Information',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6572),
                ),
              ),
              Text(
                'Add details for adopters to reach you',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),
              
              // Error message display if any
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.dmSans(
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Logo upload section
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organization Logo',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A6572),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload your organization\'s logo',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  InkWell(
                    onTap: _pickLogo,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300, 
                          width: 1
                        ),
                      ),
                      child: _logoFile != null && _logoFile!.bytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _logoFile!.bytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Color(0xFF84A59D),
                                  size: 32,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add Logo',
                                  style: GoogleFonts.dmSans(
                                    color: Color(0xFF84A59D),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Form fields in two columns
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField(
                          label: 'Location',
                          controller: _locationController,
                          hint: 'City, Country',
                          icon: Icons.location_on_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter location';
                            }
                            return null;
                          },
                        ),
                        
                        _buildFormField(
                          label: 'Contact Numbers',
                          controller: _contactNumberController,
                          hint: 'Comma separated phone numbers',
                          icon: Icons.phone_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter contact number(s)';
                            }
                            return null;
                          },
                        ),
                        
                        _buildFormField(
                          label: 'Weekday Hours',
                          controller: _weekdayHoursController,
                          hint: 'e.g. 9:00 AM - 5:00 PM',
                          icon: Icons.access_time,
                          required: false,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Right column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField(
                          label: 'Address',
                          controller: _addressController,
                          hint: 'Full address',
                          icon: Icons.home_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter address';
                            }
                            return null;
                          },
                        ),
                        
                        _buildFormField(
                          label: 'Email',
                          controller: _emailController,
                          hint: 'Contact email',
                          icon: Icons.email_outlined,
                          enabled: false, // Email is from previous step
                        ),
                        
                        _buildFormField(
                          label: 'Weekend Hours',
                          controller: _weekendHoursController,
                          hint: 'e.g. 10:00 AM - 3:00 PM',
                          icon: Icons.weekend_outlined,
                          required: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // About and Mission (full width)
              _buildFormField(
                label: 'About Your Organization',
                controller: _aboutController,
                hint: 'Describe your organization',
                icon: Icons.info_outline,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide information about your organization';
                  }
                  return null;
                },
              ),
              
              _buildFormField(
                label: 'Mission Statement',
                controller: _missionController,
                hint: 'Your organization\'s mission (optional)',
                icon: Icons.stars_outlined,
                maxLines: 2,
                required: false,
              ),
              
              SizedBox(height: 30),
              
              // Navigation Buttons
              Row(
                mainAxisAlignment: _isLoading 
                    ? MainAxisAlignment.center 
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isLoading)
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
                  
                  // Submit button / Loading indicator
                  _isLoading
                    ? Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF84A59D)),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Creating your account...',
                              style: GoogleFonts.dmSans(
                                color: Color(0xFF4A6572),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _submitRegistration,
                        label: Text(
                          'Submit Registration',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        icon: Icon(Icons.check_circle, color: Colors.white),
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
  
  // Helper UI components
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
    required String hint,
    required IconData icon,
    bool required = true,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required ? '$label*' : label,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A6572),
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(icon, color: Color(0xFF84A59D)),
              filled: true,
              fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
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
            validator: validator ?? (required 
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null
            ),
          ),
        ],
      ),
    );
  }
}
