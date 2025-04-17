import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/surrender_pet.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/organizations_listing.dart'; // Add this import
import 'package:pawsmatch/pages/mobile/surrenderer/surrender_history.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/utils/navigation_helper.dart'; 

class SurrendererDashboard extends StatefulWidget {
  const SurrendererDashboard({super.key});

  @override
  _SurrendererDashboardState createState() => _SurrendererDashboardState();
}

class _SurrendererDashboardState extends State<SurrendererDashboard> {
  final FirebaseProfileService _profileService = FirebaseProfileService();
  final DatabaseAccountService _accountService = DatabaseAccountService();
  int _selectedIndex = 1; // Default to home tab
  
  // User data state
  bool _isLoading = true;
  String _username = "User"; 
  String _userEmail = "";
  String _displayName = "User";
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  // Fixed function to load user data properly
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Debug: Print before loading data
      //print('Loading user data...');
      
      String username = await _accountService.getCurrentUsername();
      String email = await _accountService.getCurrentEmail();
      Map<String, String> dashboardInfo = await _profileService.getUserDashboardInfo();
      String displayName = dashboardInfo['displayName'] ?? 'User';
      
      setState(() {
        _username = username;
        _userEmail = email;
        _displayName = displayName;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    switch (_selectedIndex) {
      case 0: // Organizations
        return const OrganizationsListing();
      case 1: // Home
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
                  child: SizedBox(
                    width: 300,
                    height: 35,
                    child: Text(
                      'Hello, $_username',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 28,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
              
                // Profile container with display name (User if no profile name)
                Container(
                  width: MediaQuery.of(context).size.width - 24,
                  height: 130,
                  margin: const EdgeInsets.only(bottom: 5),
                  child: Stack(
                    clipBehavior: Clip.none, 
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                          height: 115,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFDEAE0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            shadows: [
                              BoxShadow(
                                color: Color(0x3F000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                        ),
                      ),
                      
                      Positioned(
                        left: 33,
                        top: 20, // Adjusted to center vertically
                        child: Container(
                          width: 83,
                          height: 83,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFDDCAC0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(55),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: const Color(0xFF725F63),
                            ),
                          ),
                        ),
                      ),
                      
                      Positioned(
                        left: 146,
                        top: 28, // Adjusted to align with profile image
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName, // Show display name (profile name or "User")
                              style: TextStyle(
                                color: const Color.fromARGB(255, 67, 63, 63),
                                fontSize: 20,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              _userEmail, // Show user email
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.56),
                                fontSize: 14,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 140,
                        bottom: 20,
                        child: Container(
                          height: 35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () {
                              NavigationHelper.navigateToProfileSettings(context);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: Size(30, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                            child: Text(
                              'Edit Profile Details',
                              style: TextStyle(
                                color: const Color(0xFF725F63),
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // First container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                  width: MediaQuery.of(context).size.width - 24,
                  height: 180,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        child: Container(
                          height: 180,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFD8CBCB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadows: [
                              BoxShadow(
                                color: Color(0x3F000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        top: 20,
                        child: SizedBox(
                          width: 170,
                          height: 95,
                          child: Text(
                            'FIND THE PERFECT NEW HOME FOR YOUR PET',
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 18,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w900,
                              height: 1.10,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 10,
                        child: Container(
                          width: 160,
                          height: 170,
                          decoration: ShapeDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/photos/s-dashboard-img1.png'),
                              fit: BoxFit.cover,
                              alignment: Alignment.centerLeft),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        top: 120,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF212121),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              // Update this to set the Organizations tab as selected
                              setState(() {
                                _selectedIndex = 0; // Switch to Organizations tab instead of pushing new route
                              });
                            },
                            child: Text(
                              'BROWSE SHELTERS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.14,
                                letterSpacing: 1.25,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Second container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                  width: MediaQuery.of(context).size.width - 24,
                  height: 180,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        child: Container(
                          height: 180,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF8EBEB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadows: [
                              BoxShadow(
                                color: Color(0x3F000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        top: 20,
                        child: SizedBox(
                          width: 170,
                          height: 95,
                          child: Text(
                            'SEE HOW YOUR PETS ARE THRIVING IN THEIR NEW HOMES',
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 18,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w800,
                              height: 1.10,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 160,
                          height: 180,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/photos/s-dashboard-img2.png'),
                              fit: BoxFit.cover,
                              alignment: Alignment.centerLeft),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        top: 120,
                        child: GestureDetector(
                          onTap: () {
                            // Navigate to History tab when this button is clicked
                            setState(() {
                              _selectedIndex = 2; // Switch to History tab
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: ShapeDecoration(
                              color: const Color(0xFF212121),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            ),
                            child: Text(
                              'VIEW SURRENDER HISTORY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.14,
                                letterSpacing: 1.25,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),                
              ],
            ),
          ),
        );
      case 2: // Surrender History
        return const SurrenderHistory(showAppBar: false); // Use SurrenderHistory with showAppBar set to false
      default:
        return const Center(child: Text('Home'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF5F0),
        automaticallyImplyLeading: false,
        actions: [
          // Inbox icon
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: IconButton(
                icon: const Icon(Icons.message, color: Color(0xFF725F63)),
                onPressed: () {
                  NavigationHelper.navigateToInbox(context);
                },
              ),
            ),
          ),
          // Profile icon
          Container(
            margin: const EdgeInsets.only(left: 6, right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF725F63)),
                onPressed: () {
                  // Use the navigation helper
                  NavigationHelper.navigateToProfileSettings(context);
                },
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFEF5F0),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFEF5F0),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Organizations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF725F63),
        onTap: _onItemTapped,
      ),
    );
  }
}
