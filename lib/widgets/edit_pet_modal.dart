import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
//import 'package:image_picker_web/image_picker_web.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/supabase_client_service.dart'; // Add this import
import 'package:pawsmatch/services/image_picker_service.dart';

class EditPetModal extends StatefulWidget {
  final Pet pet;
  final Function? onClose;
  final Function? onSuccess;

  const EditPetModal({
    Key? key,
    required this.pet,
    this.onClose,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<EditPetModal> createState() => _EditPetModalState();
}

class _EditPetModalState extends State<EditPetModal> {
  final _formKey = GlobalKey<FormState>();
  final FirebasePetService _petService = FirebasePetService();
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final Map<String, bool> _photosToRemove = {};
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _errorMessage;

  // Updated image related variables
  List<Map<String, dynamic>> _selectedImages =
      []; // Store image data with previews
  Map<String, dynamic> _existingPhotos = {}; // Store existing photo info
  bool _isUploadingImages = false;

  // Status variables for UI feedback
  bool _showSuccessMessage = false;
  String _statusMessage = '';

  // Form controllers
  late TextEditingController _nameController;
  late String _selectedGender;
  late PetStatus _selectedStatus;
  late DateTime _selectedBirthdate;
  late TextEditingController _addressController;
  late TextEditingController _breedController;
  late TextEditingController _descriptionController;
  late String _selectedSpecies;
  late bool _isNeuteredOrSpayed;
  late VaccinationStatus _vaccinationStatus;

  // Options for dropdowns
  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _speciesOptions = [
    'Dog',
    'Cat',
    'Bird',
    'Rabbit',
    'Other'
  ];

  // Add this field for the service
  final ImagePickerService _imagePickerService = ImagePickerService();

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current pet values
    _nameController = TextEditingController(text: widget.pet.pet_name);
    _selectedGender = widget.pet.gender.isEmpty ? 'Male' : widget.pet.gender;
    _selectedStatus = widget.pet.pet_status;
    _selectedBirthdate = widget.pet.birthdate;
    _addressController = TextEditingController(text: widget.pet.address);
    _breedController = TextEditingController(text: widget.pet.breed);
    _descriptionController =
        TextEditingController(text: widget.pet.description);
    _selectedSpecies = widget.pet.species.isEmpty ? 'Dog' : widget.pet.species;
    _isNeuteredOrSpayed = widget.pet.is_neutered_or_spayed;
    _vaccinationStatus = widget.pet.vaccination_status;

    // Add listeners to detect changes
    _nameController.addListener(_onFormChanged);
    _addressController.addListener(_onFormChanged);
    _breedController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);

    // Load existing photo URLs
    if (widget.pet.photo_id.isNotEmpty) {
      _loadExistingPhotos();
    }

    // Title dynamically set based on if we're adding or editing
    _modalTitle =
        widget.pet.pet_id == '' ? 'Add New Pet' : 'Edit Pet Details';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _breedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Track if form has changes
  void _onFormChanged() {
    setState(() {
      _hasChanges = true;
    });
  }
  

  Future<void> _pickMultipleImages() async {
    setState(() {
      _errorMessage = null;
      _statusMessage = 'Selecting images...';
    });
    
    try {
      final remainingSlots = 5 - (_existingPhotos.length - _photosToRemove.length + _selectedImages.length);
      
      if (remainingSlots <= 0) {
        setState(() {
          _statusMessage = 'Maximum number of photos (5) reached';
        });
        return;
      }
      
      // Use our platform-agnostic service
      final selectedImages = await _imagePickerService.pickImages(
        multiple: true,
        maxImages: remainingSlots,
      );
      
      if (selectedImages.isNotEmpty) {
        setState(() {
          for (var image in selectedImages) {
            _selectedImages.add({
              'bytes': image.bytes,
              'name': image.name,
              'preview': image.bytes,
            });
            _hasChanges = true;
          }
          _statusMessage = 'Selected ${selectedImages.length} images';
        });
      } else {
        setState(() {
          _statusMessage = 'No images selected';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting images: $e';
      });
      print('Error picking images: $e');
    }
  }

  Future<List<String>> uploadImages() async {
    List<String> newPhotoIds = [];
    
    if (_selectedImages.isEmpty) {
      return newPhotoIds;
    }
    
    setState(() {
      _isUploadingImages = true;
      _statusMessage = 'Uploading images...';
      _errorMessage = null;
    });
    
    try {
      // Fix the null pointer exception in the session check
      final client = Supabase.instance.client;
      final currentSession = client.auth.currentSession;
      
      // Debug session information
      print("Current session: ${currentSession != null ? 'exists' : 'is null'}");
      
      // For anonymous uploads, we don't need a valid session
      // So proceed with upload regardless of session status
      
      for (int i = 0; i < _selectedImages.length; i++) {
        // Generate a unique photo ID
        String photoId = _photoService.generateNewPhotoId();
        final Uint8List bytes = _selectedImages[i]['bytes'];
        
        // Use the same path format as in surrender_pet.dart
        final fileName = photoId;
        final path = 'uploads/$fileName';
        
        setState(() {
          _statusMessage = 'Uploading image ${i + 1} of ${_selectedImages.length}...';
        });
        
        try {
          print('Attempting upload to $path');
          
          // Simplify upload - don't check buckets which can cause errors
          await client.storage
              .from('pets')
              .uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );
          
          print('Upload successful');
          
          // Get URL - handle potential null values
          final photoUrl = await client.storage
              .from('pets')
              .createSignedUrl(path, 2838240000);
              
          if (photoUrl != null && photoUrl.isNotEmpty) {
            print('Got URL: $photoUrl');
            
            // Add to Firestore
            await _photoService.addPhotoToFirestore(photoUrl, photoId);
            newPhotoIds.add(photoId);
            
            setState(() {
              _statusMessage = 'Uploaded ${newPhotoIds.length} of ${_selectedImages.length} images';
            });
          } else {
            throw Exception('Generated URL was null or empty');
          }
        } catch (e) {
          print('Error uploading image: $e');
          
          // No need for fallback - just report the error
          setState(() {
            _errorMessage = 'Upload failed: $e';
          });
        }
      }
      
      return newPhotoIds;
    } catch (e) {
      print('Upload error: $e');
      setState(() {
        _errorMessage = 'Upload error: $e';
      });
      return [];
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _statusMessage = 'Processing your request...';
      });

      try {
        List<String> newPhotoIds = [];

        // Uncomment and execute image uploads if there are any selected
        if (_selectedImages.isNotEmpty) {
          setState(() {
            _statusMessage = 'Uploading images...';
          });
          newPhotoIds = await uploadImages();
        }

        // Create a list for the final photo IDs
        List<String> allPhotoIds = [];

        // Handle existing photos (if editing)
        if (widget.pet.pet_id.isNotEmpty && widget.pet.photo_id.isNotEmpty) {
          // Add existing photos that weren't marked for removal
          for (int i = 0; i < widget.pet.photo_id.length; i++) {
            String photoId = widget.pet.photo_id[i];
            if (!_photosToRemove.containsKey(photoId)) {
              allPhotoIds.add(photoId);
            }
          }
        }

        // Add newly uploaded photo IDs
        allPhotoIds.addAll(newPhotoIds);

        // Create updated pet object
        Pet updatedPet;
        if (widget.pet.pet_id.isEmpty) {
          // This is a new pet - generate a new ID
          String newPetId = _petService.generateNewPetId();
          updatedPet = Pet(
            pet_id: newPetId,
            pet_name: _nameController.text,
            gender: _selectedGender,
            pet_status: _selectedStatus,
            birthdate: _selectedBirthdate,
            address: _addressController.text,
            breed: _breedController.text,
            description: _descriptionController.text,
            species: _selectedSpecies,
            is_neutered_or_spayed: _isNeuteredOrSpayed,
            vaccination_status: _vaccinationStatus,
            photo_id: allPhotoIds,
            acquisition_type:
                AcquisitionType.Rescued, // Default for new pets added by org
          );

          setState(() {
            _statusMessage = 'Creating new pet profile...';
          });
        } else {
          // This is an existing pet
          updatedPet = widget.pet.copyWith(
            pet_name: _nameController.text,
            gender: _selectedGender,
            pet_status: _selectedStatus,
            birthdate: _selectedBirthdate,
            address: _addressController.text,
            breed: _breedController.text,
            description: _descriptionController.text,
            species: _selectedSpecies,
            is_neutered_or_spayed: _isNeuteredOrSpayed,
            vaccination_status: _vaccinationStatus,
            photo_id: allPhotoIds,
          );

          setState(() {
            _statusMessage = 'Updating pet profile...';
          });
        }

        // Update or create the pet in Firestore
        bool success = false;
        if (widget.pet.pet_id.isEmpty) {
          // This is a new pet
          await _petService.addPet(updatedPet);
          success = true; // Assume success if no exception was thrown
        } else {
          // This is an existing pet
          success = await _petService.updatePet(updatedPet);
        }

        if (success) {
          setState(() {
            _showSuccessMessage = true;
            _statusMessage = widget.pet.pet_id.isEmpty
                ? 'Pet added successfully!'
                : 'Pet updated successfully!';
          });

          // Short delay to show success message before closing
          await Future.delayed(const Duration(milliseconds: 1500));

          if (mounted) {
            // Close modal and notify parent of success
            Navigator.of(context).pop();
            widget.onSuccess?.call();
          }
        } else {
          setState(() {
            _errorMessage = widget.pet.pet_id.isEmpty
                ? 'Failed to add new pet'
                : 'Failed to update pet details';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF725F63), // Header background
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
        _hasChanges = true;
      });
    }
  }

  // Updated method for picking multiple images - simplified for web
  // Updated method to remove a selected image
  void _removeSelectedImage(int index) {
    if (index < _selectedImages.length) {
      setState(() {
        _selectedImages.removeAt(index);
        _hasChanges = true;
      });
    }
  }

  // Updated method to toggle removal of existing photo
  void _togglePhotoRemoval(String photoId) {
    setState(() {
      if (_photosToRemove.containsKey(photoId)) {
        _photosToRemove.remove(photoId);
      } else {
        _photosToRemove[photoId] = true;
      }
      _hasChanges = true;
    });
  }

  // Load existing photos
  Future<void> _loadExistingPhotos() async {
    try {
      for (String photoId in widget.pet.photo_id) {
        final photoUrl = await _photoService.getPhotoUrl(photoId);
        if (photoUrl != null && mounted) {
          setState(() {
            _existingPhotos[photoId] = {
              'url': photoUrl,
              'id': photoId,
            };
          });
        }
      }
    } catch (e) {
      print('Error loading existing photos: $e');
    }
  }

  // Improved method to display selected images
  Widget _buildImagePreview(Map<String, dynamic> imageData, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              imageData['bytes'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: InkWell(
            onTap: () => _removeSelectedImage(index),
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // Title for modal header
  late String _modalTitle;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 693,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(70),
              child: Container(
                padding: EdgeInsets.fromLTRB(46, 20, 46, 10),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_back_ios_new,
                                size: 16,
                                color: Colors.black,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Back',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: 'Century Gothic',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _modalTitle,
                      style: TextStyle(
                        color: const Color(0xFF3F3F3F),
                        fontSize: 24,
                        fontFamily: 'Century Gothic',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 60), // Balance the layout
                  ],
                ),
              ),
            ),
            body: Form(
              key: _formKey,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(46, 20, 46, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error message
                        if (_errorMessage != null)
                          Container(
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style:
                                        TextStyle(color: Colors.red.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Success message
                        if (_showSuccessMessage)
                          Container(
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Colors.green),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _statusMessage,
                                    style:
                                        TextStyle(color: Colors.green.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Status message during operations
                        if (_statusMessage.isNotEmpty &&
                            !_showSuccessMessage &&
                            _errorMessage == null)
                          Container(
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _statusMessage,
                                    style:
                                        TextStyle(color: Colors.blue.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Continue with the existing form UI...
                        // ...existing code for Basic Information section...

                        // Basic Information Section
                        Text(
                          'Basic Information',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Century Gothic',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Pet Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Pet Name*',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a pet name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Gender and Status in a row
                        Row(
                          children: [
                            // Gender Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Gender*'),
                                  SizedBox(height: 8),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _genderOptions
                                                .contains(_selectedGender)
                                            ? _selectedGender
                                            : _genderOptions[0],
                                        items: _genderOptions.map((gender) {
                                          return DropdownMenuItem<String>(
                                            value: gender,
                                            child: Text(gender),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedGender = newValue;
                                              _hasChanges = true;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Status Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pet Status*'),
                                  SizedBox(height: 8),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<PetStatus>(
                                        isExpanded: true,
                                        value: _selectedStatus,
                                        items: PetStatus.values.map((status) {
                                          return DropdownMenuItem<PetStatus>(
                                            value: status,
                                            child: Text(status
                                                .toString()
                                                .split('.')
                                                .last),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedStatus = newValue;
                                              _hasChanges = true;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Birthdate
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Birthdate*'),
                            SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 15),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('MMMM d, yyyy')
                                          .format(_selectedBirthdate),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Detailed Information Section
                        Text(
                          'Detailed Information',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Century Gothic',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Species and Breed in a row
                        Row(
                          children: [
                            // Species Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Species*'),
                                  SizedBox(height: 8),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: _speciesOptions
                                                .contains(_selectedSpecies)
                                            ? _selectedSpecies
                                            : _speciesOptions[0],
                                        items: _speciesOptions.map((species) {
                                          return DropdownMenuItem<String>(
                                            value: species,
                                            child: Text(species),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedSpecies = newValue;
                                              _hasChanges = true;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Breed
                            Expanded(
                              child: TextFormField(
                                controller: _breedController,
                                decoration: InputDecoration(
                                  labelText: 'Breed*',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a breed';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Address*',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an address';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Health Information Section
                        Text(
                          'Health Information',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Century Gothic',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Neutered/Spayed and Vaccination Status in a row
                        Row(
                          children: [
                            // Neutered/Spayed
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Neutered/Spayed*'),
                                  SizedBox(height: 8),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<bool>(
                                        isExpanded: true,
                                        value: _isNeuteredOrSpayed,
                                        items: [
                                          DropdownMenuItem<bool>(
                                            value: true,
                                            child: Text('Yes'),
                                          ),
                                          DropdownMenuItem<bool>(
                                              value: false, child: Text('No')),
                                        ],
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _isNeuteredOrSpayed = newValue;
                                              _hasChanges = true;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Vaccination Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vaccination Status*'),
                                  SizedBox(height: 8),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<VaccinationStatus>(
                                        isExpanded: true,
                                        value: _vaccinationStatus,
                                        items: VaccinationStatus.values
                                            .map((status) {
                                          String displayName;
                                          switch (status) {
                                            case VaccinationStatus.Full:
                                              displayName = 'Fully Vaccinated';
                                              break;
                                            case VaccinationStatus.Partial:
                                              displayName =
                                                  'Partially Vaccinated';
                                              break;
                                            case VaccinationStatus.None:
                                              displayName = 'Not Vaccinated';
                                              break;
                                          }
                                          return DropdownMenuItem<
                                              VaccinationStatus>(
                                            value: status,
                                            child: Text(displayName),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _vaccinationStatus = newValue;
                                              _hasChanges = true;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Description*',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 32),

                        // Pet Photos Section
                        Text(
                          'Pet Photos',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Century Gothic',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Updated photo upload container
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Upload pet photos (max 5)',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  // Add photo button - only show if less than 5 total photos
                                  if (_existingPhotos.length -
                                          _photosToRemove.length +
                                          _selectedImages.length <
                                      5)
                                    InkWell(
                                      onTap: (_isLoading || _isUploadingImages)
                                          ? null
                                          : () async {
                                              await _pickMultipleImages();
                                            },
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey.shade400),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color:
                                              (_isLoading || _isUploadingImages)
                                                  ? Colors.grey.shade200
                                                  : Colors.white,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              size: 32,
                                              color: (_isLoading ||
                                                      _isUploadingImages)
                                                  ? Colors.grey.shade400
                                                  : Colors.grey,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Add Photo',
                                              style: TextStyle(
                                                color: (_isLoading ||
                                                        _isUploadingImages)
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Display existing photos
                                  ...(_existingPhotos.entries.map((entry) {
                                    final String photoId = entry.key;
                                    final String url = entry.value['url'];
                                    final bool markedForRemoval =
                                        _photosToRemove.containsKey(photoId);

                                    return Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: NetworkImage(url),
                                              fit: BoxFit.cover,
                                              colorFilter: markedForRemoval
                                                  ? ColorFilter.mode(
                                                      Colors.grey
                                                          .withOpacity(0.7),
                                                      BlendMode.saturation)
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: InkWell(
                                            onTap: () =>
                                                _togglePhotoRemoval(photoId),
                                            child: Container(
                                              padding: EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: markedForRemoval
                                                    ? Colors.blue
                                                    : Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                markedForRemoval
                                                    ? Icons.refresh
                                                    : Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList()),

                                  // Display newly selected images
                                  ..._selectedImages
                                      .asMap()
                                      .entries
                                      .map((entry) => _buildImagePreview(
                                          entry.value, entry.key))
                                      .toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),

                        // Save button row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: (_isLoading ||
                                      _isUploadingImages ||
                                      !_hasChanges)
                                  ? null
                                  : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFC0D6B6),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFF8B8B8B),
                                ),
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      widget.pet.pet_id.isEmpty
                                          ? 'ADD PET'
                                          : 'SAVE CHANGES',
                                      style: TextStyle(
                                        color: const Color(0xFF464646),
                                        fontSize: 14,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            SizedBox(width: 16),
                            OutlinedButton(
                              onPressed: (_isLoading || _isUploadingImages)
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                side:
                                    BorderSide(color: const Color(0xFF8B8B8B)),
                                foregroundColor: const Color(0xFF464646),
                                disabledForegroundColor: Colors.grey.shade400,
                              ),
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Overlay for blocking interactions during loading
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
