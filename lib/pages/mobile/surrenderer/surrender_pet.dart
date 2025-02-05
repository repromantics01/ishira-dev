import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SurrenderForm extends StatefulWidget {
  const SurrenderForm({Key? key}) : super(key: key);

  @override
  _SurrenderFormState createState() => _SurrenderFormState();
}

class _SurrenderFormState extends State<SurrenderForm> {
  final _formKey = GlobalKey<FormState>();
  String? _petName;
  DateTime? _birthdate;
  String? _address;
  String? _bio;
  String? _breed;
  String? _gender;
  String? _species;
  List<File> _petImages = [];
  bool? _isNeuteredOrSpayed;
  String? _vaccinationStatus;
  double? _weight;

  File? _petImage;

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _petImage = File(image.path);
        _petImages.add(File(image.path));
      });
    }
  }

  Future uploadImage() async {
    if (_petImage == null) return;

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = 'uploads/$fileName';

    //upload to supabase storage
    await Supabase.instance.client.storage
        .from('pets')
        .upload(path, _petImage!)
        .then((value) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Image Uploaded Successfully!"))
            );
          }
        });
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
                decoration: InputDecoration(
                  labelText: 'Pet Name',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _petName = value,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Birthdate',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _birthdate = DateTime.tryParse(value ?? ''),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _address = value,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _bio = value,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Breed',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _breed = value,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _gender = value,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Species',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _species = value,
              ),
              SizedBox(height: 20),
              Text(
                'Pet Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickImage,
                child: Text('Pick Image'),
              ),
              ElevatedButton(
                onPressed: uploadImage,
                child: Text('Upload'),
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
                value: _isNeuteredOrSpayed ?? false,
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
                items: [
                  'Not Vaccinated',
                  'Partially Vaccinated',
                  'Fully Vaccinated'
                ]
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  _vaccinationStatus = value;
                }),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Weight',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _weight = double.tryParse(value ?? ''),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    // Process the data
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
