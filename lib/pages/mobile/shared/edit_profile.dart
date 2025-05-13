import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
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
  final FirebasePhotoService _photoService = FirebasePhotoService();
  
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _suffixController;
  late final TextEditingController _addressController;
  
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  
  // Profile image state variables
  String? _currentProfileImageUrl;
  PlatformFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.userData['firstName']);
    _middleNameController = TextEditingController(text: widget.userData['middleName']);
    _lastNameController = TextEditingController(text: widget.userData['lastName']);
    _suffixController = TextEditingController(text: widget.userData['suffix']);
    _addressController = TextEditingController(text: widget.userData['address']);
    
    // Initialize profile image URL if available
    _currentProfileImageUrl = widget.userData['profileImageUrl'];
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

  // Method to pick an image
  Future<void> _pickImage() async {
    try {
      print('Starting image picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImageFile = result.files.first;
        });
        
        print('File selected: ${_selectedImageFile!.name}');
        
        // Handle web platform (uses bytes)
        if (kIsWeb && _selectedImageFile?.bytes != null) {
          setState(() {
            _selectedImageBytes = _selectedImageFile!.bytes;
            print('Web platform: Image bytes loaded, size: ${_selectedImageBytes!.length}');
          });
        } 
        // Handle mobile platform (uses path)
        else if (!kIsWeb && _selectedImageFile?.path != null) {
          try {
            File file = File(_selectedImageFile!.path!);
            print('Reading file from path: ${_selectedImageFile!.path}');
            
            if (file.existsSync()) {
              final bytes = await file.readAsBytes();
              setState(() {
                _selectedImageBytes = bytes;
                print('Mobile platform: Read ${_selectedImageBytes!.length} bytes from file');
              });
            } else {
              print('File does not exist at path: ${_selectedImageFile!.path}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected file not found'))
              );
            }
          } catch (e) {
            print('Error reading file: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error reading file: $e'))
            );
          }
        }
      } else {
        print('No file selected or picker was canceled');
      }
    } catch (e) {
      print('Error in file picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e'))
      );
    }
  }

  // Method to upload the selected image
  Future<String?> _uploadProfileImage() async {
    if (_selectedImageBytes == null) {
      print('No image bytes to upload');
      return _currentProfileImageUrl;
    }
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      print('Uploading image bytes, size: ${_selectedImageBytes!.length}');
      
      // Upload image to Supabase
      final imageUrl = await _photoService.uploadProfileImage(
        _selectedImageBytes!, 
        user.uid
      );
      
      if (imageUrl == null) {
        throw Exception('Failed to get URL after upload');
      }
      
      print('Successfully uploaded image, URL: $imageUrl');
      
      setState(() {
        _isUploading = false;
        _currentProfileImageUrl = imageUrl;
      });
      
      return imageUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error uploading profile image: $e';
      });
      print('Upload error: $e');
      return null;
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

      // Upload profile image if a new one was selected
      String? profileImageUrl = _currentProfileImageUrl;
      if (_selectedImageBytes != null) {
        profileImageUrl = await _uploadProfileImage();
        if (profileImageUrl == null && _errorMessage == null) {
          _errorMessage = 'Failed to upload profile image';
        }
      }

      // Update profile data
      await _profileService.updateProfile(user.uid, {
        'first_name': _firstNameController.text,
        'middle_name': _middleNameController.text,
        'last_name': _lastNameController.text,
        'suffix': _suffixController.text,
        'address': _addressController.text,
        'profile_image_url': profileImageUrl,
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
                      // Profile avatar with upload functionality
                      Center(
                        child: Stack(
                          children: [
                            // Profile image container
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
                              // Show selected image, current image, or default icon
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(73),
                                child: _selectedImageBytes != null
                                  ? Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : _currentProfileImageUrl != null
                                    ? Image.network(
                                        _currentProfileImageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading profile image: $error');
                                          return Center(
                                            child: Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.black.withOpacity(0.5),
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                      ),
                              ),
                            ),
                            // Edit icon that triggers image picker
                            Positioned(
                              right: 0,
                              bottom: 10,
                              child: GestureDetector(
                                onTap: _isUploading ? null : _pickImage,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _isUploading ? Colors.grey : const Color(0xFFD9D9D9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _isUploading 
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Color(0xFF545454),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Selected image filename display
                      if (_selectedImageFile != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _selectedImageFile!.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
