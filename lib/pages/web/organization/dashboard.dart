import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';

class OrganizationDashboard extends StatefulWidget {
  const OrganizationDashboard({super.key});

  @override
  _OrganizationDashboardState createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard> {
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Organization Dashboard'),
      ),
      body: Placeholder(),
      );
  }
}
