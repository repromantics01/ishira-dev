import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpForm2 extends StatefulWidget {
  final String username;
  final String email;
  final String password;

  SignUpForm2({
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  _SignUpForm2State createState() => _SignUpForm2State();
}

class _SignUpForm2State extends State<SignUpForm2> {
  
  final FirebaseOrganizationService _firebaseOrganizationService = FirebaseOrganizationService();
  final DatabaseAccountService _databaseService = DatabaseAccountService();
  
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _orgNameController = TextEditingController();
  List<PlatformFile> _proofOfValidationFiles = [];

  Future uploadDocuments() async {
    if (_proofOfValidationFiles.isEmpty) return;

    for (var file in _proofOfValidationFiles) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
      final path = 'uploads/$fileName';

      // Upload to Supabase storage
      await Supabase.instance.client.storage
          .from('organization_documents')
          .upload(path, File(file.path!), fileOptions: FileOptions(cacheControl: '3600', upsert: false))
          .then((value) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Document ${file.name} Uploaded Successfully!"))
              );
            }
          });
    }
  }

  @override
  Widget build(BuildContextxcontext) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Organization Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text(
                'Organization Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _orgNameController,
                decoration: InputDecoration(
                  labelText: 'Organization Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the organization name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                'Proof of Validation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );

                  if (result != null) {
                    setState(() {
                      _proofOfValidationFiles = result.files;
                    });
                  } else {
                    // User canceled the picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No files selected')),
                    );
                  }
                },
                child: Text('Upload Documents'),
              ),
              SizedBox(height: 10),
              _proofOfValidationFiles.isNotEmpty
                  ? Column(
                      children: _proofOfValidationFiles.map((file) {
                        return ListTile(
                          title: Text(file.name),
                        );
                      }).toList(),
                    )
                  : Text('No documents uploaded'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Process data
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Processing Data')),
                    );

                    try {
                      // Create user account
                      final userCredential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: widget.email,
                        password: widget.password,
                      );

                      // Add account to database using user UID as document ID
                      Account account = Account(
                        account_id: userCredential.user!.uid,
                        account_type: AccountType.OrgAdmin,
                        account_username: widget.username,
                        account_email: widget.email,
                        account_password: widget.password,
                        date_created: DateTime.now(),
                      );
                      String uid = userCredential.user!.uid;
                      await _databaseService.addAccount(account, uid);

                      // Generate a new document ID for the organization
                      String orgId = _firebaseOrganizationService.generateNewOrganizationId();

                      // Add organization details to database
                      Organization organization = Organization(
                        org_id: orgId,
                        org_name: _orgNameController.text,
                        org_proof_of_validation: _proofOfValidationFiles.map((file) => file.name).join(', '),
                        date_created: DateTime.now(),
                        admin_ids: [uid],
                        isVerified: false,
                      );
                      await _firebaseOrganizationService.addOrganizationWithId(organization, orgId);

                      // Upload documents to Supabase storage
                      await uploadDocuments();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User created successfully')),
                      );
                      print(userCredential);

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating user: $e')),
                      );
                      print('Error: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}