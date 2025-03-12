import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';

class SurrenderForm extends StatefulWidget {
  const SurrenderForm({Key? key}) : super(key: key);

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
  final TextEditingController _vaccinationStatusController = TextEditingController();
  bool _isNeuteredOrSpayed = false;
  List<File> _petImages = [];
  List<String> _photoIds = [];

  final FirebasePetService _firebasePetService = FirebasePetService();
  final FirebasePhotoService _firebasePhotoService = FirebasePhotoService();

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
            .createSignedUrl(path, 2838240000); // 2838240000 is the expiration time in seconds (90 years)

        // Add photo to Firestore and get the document ID
        await _firebasePhotoService.addPhotoToFirestore(photoUrl, photoId);
        _photoIds.add(photoId);
      } else {
        print('Error uploading image');
      }
    }
  }

  Future<void> submitPetDetails() async {
    if (_formKey.currentState?.validate() ?? false) {
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
          (e) => e.toString() == 'VaccinationStatus.' + _vaccinationStatusController.text,
          orElse: () => VaccinationStatus.None,
        ),
      );

      // Add the pet to the Firestore collection
      await _firebasePetService.addPet(pet);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pet details submitted successfully')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Surrender Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text(
                'Surrender Pet Form',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _petNameController,
                decoration: InputDecoration(
                  labelText: 'Pet Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the pet name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _birthdateController,
                decoration: InputDecoration(
                  labelText: 'Birthdate',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the birthdate';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pet\'s description.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: 'Breed',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the breed';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _genderController,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the gender';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _speciesController,
                decoration: InputDecoration(
                  labelText: 'Species',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the species';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                'Pet Images',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickImages,
                child: Text('Pick Images'),
              ),
              SizedBox(height: 10),
              _petImages.isNotEmpty
                  ? Column(
                      children: _petImages.map((file) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.file(file, height: 200),
                        );
                      }).toList(),
                    )
                  : Text('No images uploaded'),
              SizedBox(height: 20),
              SwitchListTile(
                title: Text('Is Neutered or Spayed'),
                value: _isNeuteredOrSpayed,
                onChanged: (value) {
                  setState(() {
                    _isNeuteredOrSpayed = value;
                  });
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Vaccination Status',
                  border: OutlineInputBorder(),
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
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitPetDetails,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
