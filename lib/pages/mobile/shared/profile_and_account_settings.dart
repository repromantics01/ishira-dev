import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/pages/mobile/shared/edit_account.dart';
import 'package:pawsmatch/pages/mobile/shared/edit_profile.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/widgets/logout_button.dart';
import 'package:pawsmatch/widgets/user_profile_image.dart'; // Add this import

class ProfileAndAccountSettings extends StatefulWidget {
  const ProfileAndAccountSettings({Key? key}) : super(key: key);

  @override
  _ProfileAndAccountSettingsState createState() =>
      _ProfileAndAccountSettingsState();
}

class _ProfileAndAccountSettingsState extends State<ProfileAndAccountSettings> {
  final FirebaseProfileService _profileService = FirebaseProfileService();
  final DatabaseAccountService _accountService = DatabaseAccountService();

  bool _isLoading = true;
  UserType? _userType;
  Map<String, dynamic> _userData = {
    'username': 'User',
    'email': 'user@example.com',
    'password': '**********',
    'firstName': '',
    'middleName': '',
    'lastName': '',
    'suffix': '',
    'address': '',
  };

  // Add field for profile image URL
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get account info
      String username = await _accountService.getCurrentUsername();
      String email = await _accountService.getCurrentEmail();

      // Get dashboard info
      Map<String, String> dashboardInfo =
          await _profileService.getUserDashboardInfo();

      // Get profile data
      final profileSnapshot = await _profileService.getUserProfile(user.uid);

      setState(() {
        _userData = {
          'username': username,
          'email': email,
          'password': '**********',
          'firstName': profileSnapshot?['first_name'] ?? '',
          'middleName': profileSnapshot?['middle_name'] ?? '',
          'lastName': profileSnapshot?['last_name'] ?? '',
          'suffix': profileSnapshot?['suffix'] ?? '',
          'address': profileSnapshot?['address'] ?? '',
          'displayName': dashboardInfo['displayName'] ?? username,
        };
        
        _profileImageUrl = profileSnapshot?['profile_image_url'] as String?;

        _userType = profileSnapshot?['user_type'] == 'Adopter'
            ? UserType.Adopter
            : UserType.Surrenderer;

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.56),
              fontSize: 14,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.black.withOpacity(0.56),
              fontSize: 14,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w200,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF5F0),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          // Replace the logout button with the new widget
          LogoutButton(),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Top section with title and back button
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 0, top: 0, bottom: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Back button
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF545454),
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 10),
                        // Title
                        const Text(
                          'User Settings',
                          style: TextStyle(
                            color: Color(0xFF545454),
                            fontSize: 24,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Top profile section with cream background
                  Container(
                    width: double.infinity,
                    height: 20, 
                    color: const Color(0xFFFEF5F0),
                  ),

                  // Main content with white background and rounded top corners
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          160, // Ensure enough height
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 30,
                          bottom: 30), 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile avatar that overlaps the sections
                          Center(
                            child: UserProfileImage(
                              imageUrl: _profileImageUrl,
                              fallbackText: _userData['displayName'],
                              size: 100, // Larger size for the settings page
                              showBorder: true,
                              borderColor: Colors.grey.shade300,
                            ),
                          ),
                          // User name and email centered
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  _userData['displayName'] ?? 'User',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.56),
                                    fontSize: 16,
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  _userData['email'] ?? '',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.56),
                                    fontSize: 14,
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w400,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),

                          // Account Section
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: Text(
                              'Account',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.53),
                                fontSize: 14,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),

                          // Account Details
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40.0),
                            child: Column(
                              children: [
                                _buildDetailRow('Username', _userData['username'] ?? ''),
                                SizedBox(height: 16),
                                _buildDetailRow('Email', _userData['email'] ?? ''),
                                SizedBox(height: 16),
                                _buildDetailRow('Password', _userData['password'] ?? ''),
                              ],
                            ),
                          ),

                          // Edit Account Button
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              child: GestureDetector(
                                onTap: () async {
                                    final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditAccount(userData: _userData),
                                    ),
                                    );
                                    
                                    // If we got updated data back, refresh the UI
                                    if (result != null) {
                                    setState(() {
                                      _userData = result;
                                    });
                                    }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFEDEDED),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(250),
                                    ),
                                  ),
                                  child: const Text(
                                    'EDIT ACCOUNT DETAILS',
                                    style: TextStyle(
                                      color: Color(0xFF545454),
                                      fontSize: 14,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w400,
                                      height: 1.14,
                                      letterSpacing: 1.25,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 10),

                          // Profile Section
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.53),
                                fontSize: 14,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          

                          // Profile Details
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40.0),
                            child: Column(
                              children: [
                                _buildDetailRow('First Name', _userData['firstName'] ?? ''),
                                SizedBox(height: 16),
                                _buildDetailRow('Middle Name', _userData['middleName'] ?? ''),
                                SizedBox(height: 16),
                                _buildDetailRow('Last Name', _userData['lastName'] ?? ''),
                                SizedBox(height: 16),
                                _buildDetailRow('Suffix', _userData['suffix'] ?? ''),
                                SizedBox(height: 16),
                                _buildDetailRow('Address', _userData['address'] ?? ''),
                              ],
                            ),
                          ),

                          // Edit Profile Button
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15.0),
                              child: GestureDetector(
                                onTap: () async {
                                  // Navigate to edit profile page and wait for result
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfile(userData: _userData),
                                    ),
                                  );
                                  
                                  // If user made changes, reload the user data
                                  if (result == true) {
                                    _loadUserData();
                                  }
                                },
                                child: Container(
                                  width: 210,
                                  height: 40,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFEDEDED),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(250),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'EDIT PROFILE DETAILS',
                                      style: TextStyle(
                                        color: Color(0xFF545454),
                                        fontSize: 14,
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w400,
                                        height: 1.14,
                                        letterSpacing: 1.25,                  ),
                                    ),
                                  ),
                                ),
                                    ),
                             ),
                           ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
