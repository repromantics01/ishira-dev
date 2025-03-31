import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';

class ModeratorDashboard extends StatefulWidget {
  const ModeratorDashboard({super.key});

  @override
  _ModeratorDashboardState createState() => _ModeratorDashboardState();
}

class _ModeratorDashboardState extends State<ModeratorDashboard> {
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    VerificationRequests(),
    VerifiedAccounts(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moderator Dashboard'),
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.selected,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.pending_actions),
                selectedIcon: Icon(Icons.pending),
                label: Text('Verification Requests'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.verified_user),
                selectedIcon: Icon(Icons.verified),
                label: Text('Verified Accounts'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
    );
  }
}

class VerificationRequests extends StatelessWidget {
  const VerificationRequests({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Requests',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Organization>>(
              future: _organizationService.getUnverifiedOrgs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No verification requests found.'));
                }

                final organizations = snapshot.data!;

                return ListView.builder(
                  itemCount: organizations.length,
                  itemBuilder: (context, index) {
                    final organization = organizations[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        title: Text(organization.org_name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Proof of Validation: ${organization.org_proof_of_validation}'),
                            Text('Date Created: ${organization.date_created.toLocal()}'),
                            Text('Verified: ${organization.isVerified ? "Yes" : "No"}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            // Verify the organization
                            final updatedOrg = organization.copyWith(isVerified: true);
                            await _organizationService.updateOrganization(organization.org_id, updatedOrg);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${organization.org_name} has been verified')),
                            );
                          },
                          child: Text('Verify'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VerifiedAccounts extends StatelessWidget {
  const VerifiedAccounts({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verified Accounts',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: 0, // Assume the list is empty
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        title: Text('Organization Name'),
                        subtitle: Text('Verified'),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
