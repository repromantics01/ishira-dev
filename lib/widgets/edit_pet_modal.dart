import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pawsmatch/utils/image_utils.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingPhotos = true; // Add this flag
  bool _hasChanges = false;
  bool _isUploadingPhotos = false;
  String? _errorMessage;

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
  List<String> _photoIds = [];
  List<XFile> _newPhotos = [];
  List<String> _photosToDelete = [];
  
  // Add map to store photo URLs
  Map<String, String> _photoUrlsMap = {};

  // Options for dropdowns
  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _speciesOptions = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current pet values
    _nameController = TextEditingController(text: widget.pet.pet_name);
    _selectedGender = widget.pet.gender;
    _selectedStatus = widget.pet.pet_status;
    _selectedBirthdate = widget.pet.birthdate;
    _addressController = TextEditingController(text: widget.pet.address);
    _breedController = TextEditingController(text: widget.pet.breed);
    _descriptionController = TextEditingController(text: widget.pet.description);
    _selectedSpecies = widget.pet.species;
    _isNeuteredOrSpayed = widget.pet.is_neutered_or_spayed;
    _vaccinationStatus = widget.pet.vaccination_status;
    _photoIds = List.from(widget.pet.photo_id); // Create a copy to avoid modifying the original

    // Load photo URLs
    _loadPhotoUrls();

    // Add listeners to detect changes
    _nameController.addListener(_onFormChanged);
    _addressController.addListener(_onFormChanged);
    _breedController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
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

  Future<void> _submitForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Process photos to delete
        if (_photosToDelete.isNotEmpty) {
          print('Deleting ${_photosToDelete.length} photos: $_photosToDelete');
          for (final photoId in _photosToDelete) {
            await _photoService.deletePhoto(photoId);
          }
        }
        
        // Create a new array for photo IDs that will contain existing + new photos
        List<String> updatedPhotoIds = List.from(_photoIds); // Start with current photos
        
        // Upload new photos and add their IDs to the pet's photo_id array
        if (_newPhotos.isNotEmpty) {
          setState(() {
            _isUploadingPhotos = true;
          });
          
          print('Uploading ${_newPhotos.length} new photos');
          // Upload the new photos and get their IDs
          final uploadedPhotoIds = await _photoService.uploadImages(_newPhotos);
          
          // Add the new photo IDs to our updated list
          if (uploadedPhotoIds.isNotEmpty) {
            updatedPhotoIds.addAll(uploadedPhotoIds);
            print('Added ${uploadedPhotoIds.length} new photo IDs: $uploadedPhotoIds');
            print('Updated photo ID array now contains ${updatedPhotoIds.length} photos');
          }
          
          setState(() {
            _isUploadingPhotos = false;
          });
        }

        // Create updated pet object with the combined photo IDs
        final updatedPet = widget.pet.copyWith(
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
          photo_id: updatedPhotoIds, // Update with combined photo IDs
        );

        // Update the pet in Firestore
        final success = await _petService.updatePet(updatedPet);
        if (success) {
          print('Successfully updated pet ${updatedPet.pet_name} with ${updatedPhotoIds.length} photos');
          if (mounted) {
            // Close modal and notify parent of success
            Navigator.of(context).pop();
            widget.onSuccess?.call();
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to update pet details';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
          _isUploadingPhotos = false;
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

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _newPhotos.addAll(images);
          _hasChanges = true;
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  // Camera option for taking a new photo
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _newPhotos.add(image);
          _hasChanges = true;
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImages();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add method to load photo URLs
  Future<void> _loadPhotoUrls() async {
    setState(() {
      _isLoadingPhotos = true;
    });

    try {
      // Load URLs for all photos in parallel
      for (String photoId in _photoIds) {
        final url = await _photoService.getPhotoUrl(photoId);
        if (url != null) {
          setState(() {
            _photoUrlsMap[photoId] = url;
          });
        }
      }
    } catch (e) {
      print('Error loading photo URLs: $e');
    } finally {
      setState(() {
        _isLoadingPhotos = false;
      });
    }
  }

  // Add this new method to reorder photos (useful for setting a main photo)
  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < _photoIds.length) {
        // Reordering existing photos
        final item = _photoIds.removeAt(oldIndex);
        _photoIds.insert(newIndex < _photoIds.length ? newIndex : _photoIds.length, item);
        _hasChanges = true;
      }
    });
  }

  // Make photo gallery reorderable
  Widget _buildPhotoGallery() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isLoadingPhotos
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Existing photos with reorder capability
                ..._photoIds.asMap().entries.map((entry) {
                  final index = entry.key;
                  final photoId = entry.value;
                  final photoUrl = _photoUrlsMap[photoId];
                  
                  return Stack(
                    children: [
                      Draggable<int>(
                        // Allow photos to be draggable for reordering
                        data: index,
                        feedback: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: photoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                              ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: Container(
                            margin: EdgeInsets.only(right: 12),
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        child: DragTarget<int>(
                          onAccept: (sourceIndex) {
                            _reorderPhotos(sourceIndex, index);
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              margin: EdgeInsets.only(right: 12),
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: candidateData.isNotEmpty
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                              ),
                              child: photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          photoUrl,
                                          fit: BoxFit.cover,
                                          width: 150,
                                          height: 150,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'Failed to load',
                                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        // Show main photo indicator if this is the first photo
                                        if (index == 0)
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Main',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                                  ),
                            );
                          },
                        ),
                      ),
                      
                      // Delete button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _photosToDelete.add(photoId);
                              _photoIds.removeAt(index);
                              _photoUrlsMap.remove(photoId);
                              _hasChanges = true;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade300,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(Icons.delete, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                
                // New photos to upload - using our cross-platform utility
                ..._newPhotos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final photo = entry.value;
                  return Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 12),
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ImageUtils.buildImageFromXFile(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Invalid image',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Delete button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _newPhotos.removeAt(index);
                              _hasChanges = true;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade300,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(Icons.delete, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                
                // Add photo button
                InkWell(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Color(0xFF725F63),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add Photos',
                          style: TextStyle(
                            color: Color(0xFF725F63),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to select',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

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
                      'Edit Pet Details',
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
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(46, 20, 46, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
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
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _genderOptions.contains(_selectedGender) ? _selectedGender : _genderOptions[0],
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
                                padding: EdgeInsets.symmetric(horizontal: 12),
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
                                        child: Text(status.toString().split('.').last),
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
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMMM d, yyyy').format(_selectedBirthdate),
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
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _speciesOptions.contains(_selectedSpecies) ? _selectedSpecies : _speciesOptions[0],
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
                                padding: EdgeInsets.symmetric(horizontal: 12),
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
                                        value: false,
                                        child: Text('No'),
                                      ),
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
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<VaccinationStatus>(
                                    isExpanded: true,
                                    value: _vaccinationStatus,
                                    items: VaccinationStatus.values.map((status) {
                                      String displayName;
                                      switch (status) {
                                        case VaccinationStatus.Full:
                                          displayName = 'Fully Vaccinated';
                                          break;
                                        case VaccinationStatus.Partial:
                                          displayName = 'Partially Vaccinated';
                                          break;
                                        case VaccinationStatus.None:
                                          displayName = 'Not Vaccinated';
                                          break;
                                      }
                                      return DropdownMenuItem<VaccinationStatus>(
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
                    
                    // Photo management section - Enhanced UI
                    Text(
                      'Pet Photos',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: 'Century Gothic',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add or remove photos of your pet. The first photo will be the main image shown in listings.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Photo gallery - Updated to handle loading state and errors
                    _buildPhotoGallery(),
                    // Upload progress indicator
                    if (_isUploadingPhotos)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Uploading photos...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24),
                    
                    // Save button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading || !_hasChanges ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFC0D6B6),
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFF8B8B8B),
                            ),
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
                                  'SAVE CHANGES',
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
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            side: BorderSide(color: const Color(0xFF8B8B8B)),
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: const Color(0xFF464646),
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
            ),
          ),
        ),
      ),
    );
  }
}
