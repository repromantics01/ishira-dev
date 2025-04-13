import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/firebase_surrender_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SurrenderForm extends StatefulWidget {
  final String? organizationId;
  
  const SurrenderForm({Key? key, this.organizationId}) : super(key: key);

  @override
  _SurrenderFormState createState() => _SurrenderFormState();
}

class _SurrenderFormState extends State<SurrenderForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _vaccinationStatusController =
      TextEditingController();
  bool _isNeuteredOrSpayed = false;
  List<File> _petImages = [];
  List<String> _photoIds = [];
  bool _isSubmitting = false;
  String _organizationName = "Organization";

  final FirebasePetService _firebasePetService = FirebasePetService();
  final FirebasePhotoService _firebasePhotoService = FirebasePhotoService();
  final FirebaseSurrenderService _surrenderService = FirebaseSurrenderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseOrganizationService _orgService = FirebaseOrganizationService();

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _speciesOptions = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Reptile', 'Fish', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.organizationId != null) {
      _loadOrganizationName();
    }
  }

  Future<void> _loadOrganizationName() async {
    if (widget.organizationId != null) {
      final organization = await _orgService.getOrganizationById(widget.organizationId!);
      if (organization != null && mounted) {
        setState(() {
          _organizationName = organization.org_name;
        });
      }
    }
  }

  Future pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _petImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future uploadImages(String petId) async {
    for (var image in _petImages) {
      // Generate a unique photo ID
      String photoId = _firebasePhotoService.generateNewPhotoId();
      final fileName = '${photoId}';
      final path = 'uploads/$fileName';

      // Upload to Supabase storage
      final response = await Supabase.instance.client.storage
          .from('pets')
          .upload(path, image);

      if (response.isNotEmpty) {
        final photoUrl = await Supabase.instance.client.storage
            .from('pets')
            .createSignedUrl(path,
                2838240000); // 2838240000 is the expiration time in seconds (90 years)

        // Add photo to Firestore and get the document ID
        await _firebasePhotoService.addPhotoToFirestore(photoUrl, photoId);
        _photoIds.add(photoId);
      } else {
        print('Error uploading image');
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _birthdateController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Container(
              width: 335,
              height: 620,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Dialog background
                  Container(
                    width: 335,
                    height: 620,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEDEDED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(38),
                      ),
                    ),
                  ),
                  // Dialog content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 25),
                      // Pet image at top
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: _petImages.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(_petImages[0]),
                                  fit: BoxFit.cover,
                                )
                              : DecorationImage(
                                  image: NetworkImage("https://placehold.co/150x150"),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Confirmation title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Are you sure you want to surrender ${_petNameController.text}?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 23,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                            height: 1.22,
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      // Supporting text
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 30),
                      //   child: Text(
                      //     'We understand that surrendering a pet is a difficult decision, and we appreciate the care you\'ve taken in making this choice.',
                      //     textAlign: TextAlign.center,
                      //     style: TextStyle(
                      //       color: const Color(0xFF646464),
                      //       fontSize: 13,
                      //       fontFamily: 'DM Sans',
                      //       fontWeight: FontWeight.w400,
                      //       height: 1.62,
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(height: 25),
                      // Notice text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'By submitting pet details, you are permitting and notifying ',
                                style: TextStyle(
                                  color: const Color(0xFF656565),
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.75,
                                ),
                              ),
                              TextSpan(
                                text: _organizationName + ' ',
                                style: TextStyle(
                                  color: const Color(0xFF656565),
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 1.75,
                                ),
                              ),
                              TextSpan(
                                text: 'about your surrender request.\n\n',
                                style: TextStyle(
                                  color: const Color(0xFF656565),
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.75,
                                ),
                              ),
                              TextSpan(
                                text: 'You cannot modify nor revert once submitted.\n\n',
                                style: TextStyle(
                                  color: const Color(0xFF656565),
                                  fontSize: 14,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 1.50,
                                ),
                              ),
                              TextSpan(
                                text: 'Proceed?',
                                style: TextStyle(
                                  color: const Color(0xFF656565),
                                  fontSize: 14,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 30),
                      // No button
                      Container(
                        width: 165,
                        margin: EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog without submitting
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0E0E0),
                            foregroundColor: const Color(0xFF1E2C2B),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                              borderRadius: BorderRadius.circular(250),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'NO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.25,
                            ),
                          ),
                        ),
                      ),
                      // Yes button
                      Container(
                        width: 165,
                        margin: EdgeInsets.only(bottom: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            submitPetDetails(); // Submit pet details
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC0D6B6),
                            foregroundColor: const Color(0xFF1E2C2B),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(width: 1, color: const Color(0xFF8B8B8B)),
                              borderRadius: BorderRadius.circular(250),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'YES',
                            style: TextStyle(
                              fontSize: 14,
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
      },
    );
  }

  void validateAndProceed() {
    if (_formKey.currentState?.validate() ?? false) {
      _showConfirmationDialog();
    }
  }

  Future<void> submitPetDetails() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      _formKey.currentState?.save();

      String petId = _firebasePetService.generateNewPetId();
      await uploadImages(petId);

      Pet pet = Pet(
        pet_id: petId,
        pet_name: _petNameController.text,
        gender: _genderController.text,
        photo_id: _photoIds, // List of photo document IDs
        pet_status: PetStatus.Available,
        birthdate: DateTime.parse(_birthdateController.text),
        address: _addressController.text,
        breed: _breedController.text,
        acquisition_type: AcquisitionType.Surrendered,
        description: _bioController.text,
        species: _speciesController.text,
        is_neutered_or_spayed: _isNeuteredOrSpayed,
        vaccination_status: VaccinationStatus.values.firstWhere(
          (e) =>
              e.toString() ==
              'VaccinationStatus.' + _vaccinationStatusController.text,
          orElse: () => VaccinationStatus.None,
        ),
      );

      // Add the pet to the Firestore collection
      await _firebasePetService.addPet(pet);

      // If the form was opened from an organization profile, create a surrender record
      if (widget.organizationId != null) {
        String? currentUserId = _auth.currentUser?.uid;
        if (currentUserId != null) {
          await _surrenderService.surrenderPetToOrganization(
            petId: petId,
            accountId: currentUserId,
            organizationId: widget.organizationId!,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pet successfully surrendered to organization')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: User not logged in')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pet details submitted successfully')),
        );
      }

      // Reset form or navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error submitting pet details: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 15,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: 'Enter $label...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.4),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                width: 1,
                color: const Color(0xFFC5C6CC),
              ),
            ),
          ),
          validator: validator,
        ),
        SizedBox(height: 15),
      ],
    );
  }

  Widget _buildResponsiveButton({
    required String label,
    required VoidCallback? onTap,
    Color backgroundColor = const Color(0xFF212121),
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: ShapeDecoration(
          color: onTap == null
              ? backgroundColor.withOpacity(0.7)
              : backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onTap();
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: 1.25,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'Surrender Pet',
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 24,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // White container with form
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: const Color.fromARGB(85, 126, 123, 124),
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField(
                          label: 'Pet Name',
                          controller: _petNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the pet name';
                            }
                            return null;
                          },
                        ),

                        _buildFormField(
                          label: 'Birthdate',
                          controller: _birthdateController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the birthdate';
                            }
                            return null;
                          },
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),

                        _buildFormField(
                          label: 'Address',
                          controller: _addressController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the address';
                            }
                            return null;
                          },
                        ),

                        _buildFormField(
                          label: 'Description',
                          controller: _bioController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your pet\'s description';
                            }
                            return null;
                          },
                        ),
                        
                        // Species dropdown (moved before breed)
                        Text(
                          'Species',
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 15,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _speciesController.text.isNotEmpty ? _speciesController.text : null,
                          decoration: InputDecoration(
                            hintText: 'Select species...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.4),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: 1,
                                color: const Color(0xFFC5C6CC),
                              ),
                            ),
                          ),
                          items: _speciesOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _speciesController.text = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a species';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),

                        _buildFormField(
                          label: 'Breed',
                          controller: _breedController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the breed';
                            }
                            return null;
                          },
                        ),

                        // Gender dropdown
                        Text(
                          'Gender',
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 15,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _genderController.text.isNotEmpty ? _genderController.text : null,
                          decoration: InputDecoration(
                            hintText: 'Select gender...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.4),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: 1,
                                color: const Color(0xFFC5C6CC),
                              ),
                            ),
                          ),
                          items: _genderOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _genderController.text = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a gender';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),

                        Text(
                          'Pet Images',
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 15,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 12),

                        _buildResponsiveButton(
                          label: 'PICK IMAGES',
                          onTap: pickImages,
                          backgroundColor: Color(0xFF9E7F85),
                        ),

                        SizedBox(height: 12),

                        _petImages.isNotEmpty
                            ? Container(
                                height: 120,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: _petImages.map((file) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(file,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                            : Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'No images selected',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),

                        SizedBox(height: 20),

                        // Styling the switch
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFC5C6CC)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              'Is Neutered or Spayed',
                              style: TextStyle(
                                color: Color(0xFF212121),
                                fontSize: 15,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: _isNeuteredOrSpayed,
                            onChanged: (value) {
                              setState(() {
                                _isNeuteredOrSpayed = value;
                              });
                            },
                            activeColor: Color(0xFF9E7F85),
                          ),
                        ),

                        SizedBox(height: 20),

                        Text(
                          'Vaccination Status',
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 15,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: 'Select vaccination status...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.4),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: 1,
                                color: const Color(0xFFC5C6CC),
                              ),
                            ),
                          ),
                          items: VaccinationStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status.toString().split('.').last,
                              child: Text(status.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _vaccinationStatusController.text = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select vaccination status';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 30),

                        _buildResponsiveButton(
                          label: 'SUBMIT',
                          onTap: _isSubmitting ? null : validateAndProceed,
                          isLoading: _isSubmitting,
                          backgroundColor: Color(0xFF212121),
                        ),
                      ],
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
