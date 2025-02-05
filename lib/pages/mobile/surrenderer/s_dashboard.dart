import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/surrender_pet.dart';

class SurrendererDashboard extends StatefulWidget {
  const SurrendererDashboard({super.key});

  @override
  _SurrendererDashboardState createState() => _SurrendererDashboardState();
}

class _SurrendererDashboardState extends State<SurrendererDashboard> {
  final FirebaseProfileService _profileService = FirebaseProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Surrenderer Dashboard'),
      ),
      body: Column(
        children: [
          Placeholder(),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SurrenderForm()),
              );
            },
            child: Text('Surrender Pet'),
          ),
        ],
      ),
      );
  }
}