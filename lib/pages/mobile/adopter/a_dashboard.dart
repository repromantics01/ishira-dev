import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';

class AdopterDashboard extends StatefulWidget {
  const AdopterDashboard({Key? key});

  @override
  _AdopterDashboardState createState() => _AdopterDashboardState();
}

class _AdopterDashboardState extends State<AdopterDashboard> {
  final FirebaseProfileService _profileService = FirebaseProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adopter Dashboard'),
      ),
      body: Placeholder(),
      );
  }
}