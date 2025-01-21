import 'package:flutter/material.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/models/organization.dart';

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

  @override
  Widget build(BuildContext context) {
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

                      // Add account to database and get document ID
                      Account account = Account(
                        account_id: await _databaseService.getNextAccountId(),
                        account_type: AccountType.OrgAdmin,
                        account_username: widget.username,
                        account_email: widget.email,
                        account_password: widget.password,
                        date_created: DateTime.now(),
                      );
                      String accountId = await _databaseService.addAccount(account);

                      // Add organization details to database
                      Organization organization = Organization(
                        org_id: await _firebaseOrganizationService.getNextOrganizationId(),
                        org_name: _orgNameController.text,
                        org_proof_of_validation: _proofOfValidationFiles.map((file) => file.name).join(', '),
                        date_created: DateTime.now(),
                        admin_ids: [accountId],
                      );
                      await _firebaseOrganizationService.addOrganization(organization);
                        

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