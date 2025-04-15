import 'dart:io';
import 'dart:math';

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine available space and adapt accordingly
              final maxWidth = constraints.maxWidth;
              final maxHeight = constraints.maxHeight;
              
              return Container(
                width: maxWidth,
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: maxHeight * 0.9, // Use 90% of available height max
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFFEDEDED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pet image at the top with responsive size
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: maxWidth * 0.05, // Responsive padding
                          horizontal: 16,
                        ),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                            image: _petImages.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(_petImages[0]),
                                    fit: BoxFit.cover,
                                  )
                                : DecorationImage(
                                    image: AssetImage('assets/images/pet_placeholder.png') as ImageProvider,
                                    fit: BoxFit.cover,
                                    onError: (exception, stackTrace) => Icon(
                                      Icons.pets,
                                      size: 60,
                                      color: Color(0xFF725F63),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      
                      // Confirmation question text with adaptive font size
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Are you sure you want to surrender ${_petNameController.text}?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: maxWidth < 300 ? 16 : 20, // Responsive font size
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Surrender commitment text with adaptive font size
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'We understand that surrendering a pet is a difficult decision, and we appreciate the care you\'ve taken in making this choice.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF646464),
                            fontSize: maxWidth < 300 ? 11 : 13, // Responsive font size
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Confirmation details text
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'By submitting pet details, you are permitting and notifying ',
                                style: TextStyle(
                                  color: const Color(0xFF656565),
                                  fontSize: maxWidth < 300 ? 10 : 12, // Responsive font size
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.75,
                                ),
                              ),
                              TextSpan(
                                text: '${_organizationName} ',
                                style: TextStyle(
                                  color: const Color(0xFF656565),
                                  fontSize: maxWidth < 300 ? 10 : 12, // Responsive font size
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 1.75,
                                ),
                              ),
                              TextSpan(
                                text: 'about your surrender request.',
                                style: TextStyle(
                                  color: const Color(0xFF656565),
                                  fontSize: maxWidth < 300 ? 10 : 12, // Responsive font size
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.75,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'You cannot modify nor revert once submitted.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF656565),
                            fontSize: maxWidth < 300 ? 12 : 14, // Responsive font size
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Proceed?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF656565),
                            fontSize: maxWidth < 300 ? 12 : 14, // Responsive font size
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // NO button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: maxWidth < 300 ? 8 : 12, // Responsive padding
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE0E0E0),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFF8B8B8B),
                                ),
                                borderRadius: BorderRadius.circular(250),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'NO',
                                style: TextStyle(
                                  color: const Color(0xFF1E2C2B),
                                  fontSize: maxWidth < 300 ? 12 : 14, // Responsive font size
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w500,
                                  height: 1.14,
                                  letterSpacing: 1.25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // YES button
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            submitPetDetails();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: maxWidth < 300 ? 8 : 12, // Responsive padding
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFC0D6B6),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFF8B8B8B),
                                ),
                                borderRadius: BorderRadius.circular(250),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'YES',
                                style: TextStyle(
                                  color: const Color(0xFF1E2C2B),
                                  fontSize: maxWidth < 300 ? 12 : 14, // Responsive font size
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w500,
                                  height: 1.14,
                                  letterSpacing: 1.25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // New method to show success modal after surrender is complete
  void _showSurrenderSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get available width
            final maxWidth = min(335.0, constraints.maxWidth - 40);
            
            return Container(
              width: maxWidth,
              decoration: ShapeDecoration(
                color: const Color(0xFFEDEDED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thank you image
                  Padding(
                    padding: const EdgeInsets.only(top: 25, bottom: 10),
                    child: Image.asset(
                      'assets/photos/thank_you.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback in case the image is missing
                        return Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECC8C0),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volunteer_activism,
                            size: 70,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Thank you text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Thank You!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 23,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  
                  // Success message
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Your pet surrender information has been sent to ',
                            style: TextStyle(
                              color: const Color(0xFF646464),
                              fontSize: 13,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          TextSpan(
                            text: '${_organizationName}. ',
                            style: TextStyle(
                              color: const Color(0xFF646464),
                              fontSize: 13,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                          TextSpan(
                            text: 'They will reach out to you about the next steps.',
                            style: TextStyle(
                              color: const Color(0xFF646464),
                              fontSize: 13,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        // Also navigate back to the previous screen after closing the dialog
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE0E0E0),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFF8B8B8B),
                            ),
                            borderRadius: BorderRadius.circular(250),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'CLOSE',
                            style: TextStyle(
                              color: const Color(0xFF1E2C2B),
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
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

     
        String? currentUserId = _auth.currentUser?.uid;
        if (currentUserId != null) {
          await _surrenderService.surrenderPetToOrganization(
            petId: petId,
            accountId: currentUserId,
            organizationId: widget.organizationId!,
          );
          
          // Show success modal instead of SnackBar
          _showSurrenderSuccessModal();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: User not logged in')),
          );
        }
       

      // Don't navigate back immediately - let the user close the success modal
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
