import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';

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
  bool _isLoading = false;
  bool _hasChanges = false;
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
        // Create updated pet object
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
        );

        // Update the pet in Firestore
        final success = await _petService.updatePet(updatedPet);
        if (success) {
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
