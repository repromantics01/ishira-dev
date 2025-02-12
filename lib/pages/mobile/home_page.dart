import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/s_dashboard.dart';
import 'package:pawsmatch/pages/mobile/adopter/a_dashboard.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/pages/mobile/user_registration_form.dart';

class MobileHomepage extends StatefulWidget {
  @override
  _MobileHomepageState createState() => _MobileHomepageState();
}

class _MobileHomepageState extends State<MobileHomepage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseAccountService _auth = DatabaseAccountService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                UserCredential userCredential =
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: _emailController.text,
                  password: _passwordController.text,
                );
                final uid = userCredential.user!.uid;
                final Account account = await _auth.getAccount(uid);
                final profileSnapshot = await FirebaseFirestore.instance
                    .collection('profile')
                    .where('account_id', isEqualTo: account.account_id)
                    .get();

                if (profileSnapshot.docs.isNotEmpty) {
                  final profileData = profileSnapshot.docs.first.data();
                  final userType = profileData['user_type'];

                  if (userType == 'Adopter') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdopterDashboard(),
                      ),
                    );
                  } else if (userType == 'Surrenderer') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurrendererDashboard(),
                      ),
                    );
                  }
                }
                            },
              child: Text('Login'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserRegistrationForm(),
                  ),
                );
              },
              child: Text('Don\'t have an account? Sign up'),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
