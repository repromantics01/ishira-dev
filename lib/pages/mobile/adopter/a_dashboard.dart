import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/pages/mobile/adopter/swiped_pets.dart';
import 'package:pawsmatch/pages/mobile/adopter/view_adoptions.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/pages/mobile/adopter/pet_swiper_page.dart';

class AdopterDashboard extends StatefulWidget {
  const AdopterDashboard({Key? key}) : super(key: key);

  @override
  _AdopterDashboardState createState() => _AdopterDashboardState();
}

class _AdopterDashboardState extends State<AdopterDashboard> {
  final FirebaseProfileService _profileService = FirebaseProfileService();
  final DatabaseAccountService _accountService = DatabaseAccountService();
  final FirebasePetService _petService = FirebasePetService();
  final FirebasePhotoService _photoService = FirebasePhotoService(); // Add this service
  int _selectedIndex = 1; // Default to home tab
  
  bool _isLoading = true;
  String _username = "User"; 
  String _userEmail = "";
  String _displayName = "User";

  Pet? _currentPet;
  bool _loadingPet = true;
  String? _petPhotoUrl; 
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRandomPet();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      
      await Future.delayed(const Duration(seconds: 2));
      String username = await _accountService.getCurrentUsername();
      String email = await _accountService.getCurrentEmail();
      print('Email loaded: $email');
      
      // Check if Firebase is properly initialized and user is logged in
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Loading data for uid: ${user.uid}');
      }
      
      // Get display name from user dashboard info
      Map<String, String> dashboardInfo = await _profileService.getUserDashboardInfo();
      print('Dashboard info loaded: $dashboardInfo');
      String displayName = dashboardInfo['displayName'] ?? 'User';
      
      print('Final values - Username: $username, Email: $email, DisplayName: $displayName');
      
      setState(() {
        _username = username;
        _userEmail = email;
        _displayName = displayName;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      // Show the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: $e'),
          duration: Duration(seconds: 5),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadRandomPet() async {
    setState(() {
      _loadingPet = true;
      _petPhotoUrl = null; // Reset photo URL
    });
    
    try {
      print('Starting to load random pet...');
      
      // Add timeout to prevent infinite loading
      final pet = await _petService.getRandomPet().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Pet loading timed out after 10 seconds');
          throw TimeoutException('Pet loading took too long');
        }
      );
      
      print('Pet loaded: ${pet?.pet_id ?? 'null'}');
      
      // Get photo URL if photo_id is available
      String? photoUrl;
      if (pet != null && pet.photo_id.isNotEmpty) {
        photoUrl = await _photoService.getPhotoUrl(pet.photo_id.first);
        print('Photo URL resolved: $photoUrl');
      }
      
      setState(() {
        _currentPet = pet;
        _petPhotoUrl = photoUrl;
        _loadingPet = false;
      });
    } catch (e) {
      print('Error loading random pet: $e');
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load pet: ${e.toString()}'),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _refreshPet,
          ),
        ),
      );
      
      setState(() {
        _currentPet = null; // Ensure null to show the no pets available card
        _loadingPet = false;
      });
    }
  }
  
  // Get a new random pet to display
  void _refreshPet() {
    _loadRandomPet();
  }
  
  // Record a like for the current pet
  void _likePet() async {
    if (_currentPet != null) {
      try {
        // Get the current user's ID
        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Record the swipe in Firestore
          await FirebaseFirestore.instance.collection('swipes').add({
            'account_id': user.uid,
            'pet_id': _currentPet!.pet_id,
            'liked': true,
            'timestamp': FieldValue.serverTimestamp(),
          });
          
          //For debug, might add modal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pet liked! Check your swiped pets.'))
          );
          
          _refreshPet();
        }
      } catch (e) {
        print('Error liking pet: $e');
      }
    }
  }
  
  // Record a dislike for the current pet
  void _dislikePet() async {
    if (_currentPet != null) {
      try {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Record the swipe in Firestore
          await FirebaseFirestore.instance.collection('swipes').add({
            'account_id': user.uid,
            'pet_id': _currentPet!.pet_id,
            'liked': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
          
          _refreshPet();
        }
      } catch (e) {
        print('Error disliking pet: $e');
      }
    }
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Navigation logic
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SwipedPetsPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ViewAdoptionsPage()),
      );
    }
    // index 1 is current page (home), no navigation needed
  }

  Widget _getBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFFEF5F0)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top profile section
            Padding(
              padding: const EdgeInsets.only(left: 39, top: 40),
              child: Text(
                'Hello, $_username',
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 32,
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.w700,
                  height: 0.75,
                ),
              ),
            ),
            
            // Profile card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 29, vertical: 20),
              width: MediaQuery.of(context).size.width - 58,
              padding: EdgeInsets.all(15),
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
              child: Row(
                children: [
                  // Profile image
                  Container(
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
                  SizedBox(width: 30),
                  // User info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 20,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w700,
                          height: 1.20,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _userEmail,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.56),
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 20),
              child: Text(
                'Start Matching',
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 30,
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.w700,
                  height: 0.80,
                ),
              ),
            ),          
            // Pet card container
            _loadingPet 
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _currentPet == null
                    ? _noPetsAvailableCard()
                    : _buildPetCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _noPetsAvailableCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 14.60,
            offset: Offset(0, 10),
            spreadRadius: 0,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.pets, size: 80, color: Color(0xFFDDCAC0)),
            SizedBox(height: 20),
            Text(
              'No pets available',
              style: TextStyle(
                color: Color(0xFF545454),
                fontSize: 24,
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Check back later for more pets',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 16,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPetCard() {
    // Debug info
    // print('Building pet card with pet: ${_currentPet?.pet_name ?? 'Unknown'}');
    // print('Pet photo URL: $_petPhotoUrl');
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            // This makes the route full-screen and hides system UI
            fullscreenDialog: true,
            // This prevents the route from having default animation
            opaque: true,
            // Custom page transitions
            pageBuilder: (context, animation, secondaryAnimation) => PetSwiperPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.1);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 26, vertical: 20),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 14.60,
              offset: Offset(0, 10),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          children: [
            // Pet image
            Container(
              height: 290,
              margin: EdgeInsets.all(15),
              decoration: ShapeDecoration(
                image: DecorationImage(
                  image: _petPhotoUrl != null
                    ? NetworkImage(_petPhotoUrl!)
                    : NetworkImage('https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png'),
                  fit: BoxFit.cover,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            
            // Pet info container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 3, 
                        child: Text(
                          '${_currentPet?.pet_name ?? "Unknown"}, ${_currentPet?.birthdate != null ? _calculateAge(_currentPet!.birthdate) : "?"}',
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 24,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8), 
                      Flexible(
                        flex: 2,
                        child: Text(
                          '${_currentPet?.species ?? "Unknown"} - ${_currentPet?.breed ?? "Mixed"}',
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 16,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _currentPet?.address ?? 'Unknown location',
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 15,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Dislike button
                      GestureDetector(
                        onTap: _dislikePet,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.8),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      // Like button
                      GestureDetector(
                        onTap: _likePet,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withOpacity(0.8),
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
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
          // Message icon
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF4EAEA),
              child: IconButton(
                icon: const Icon(Icons.message, color: Color(0xFF725F63)),
                onPressed: () {
                  // Add inbox navigation logic
                },
              ),
            ),
          ),
          // Profile icon
          Container(
            margin: const EdgeInsets.only(left: 6, right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF4EBEB),
              child: IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF725F63)),
                onPressed: () {
                  // Add profile navigation logic
                },
              ),
            ),
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: const Color(0xFF020202), width: 1),
          ),
        ),
        height: 84,
        child: Column(
          children: [
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Swiped pets
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.pets, size: 32),
                      onPressed: () => _onItemTapped(0),
                      color: _selectedIndex == 0 ? const Color(0xFF725F63) : Colors.grey,
                    ),
                    Text(
                      'Swiped Pets',
                      style: TextStyle(
                        color: const Color(0xFF212121),
                        fontSize: 10,
                        fontFamily: 'Actor',
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  ],
                ),
                
                // Home - with larger circular background
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.home, size: 24),
                        onPressed: () => _onItemTapped(1),
                        color: _selectedIndex == 1 ? const Color(0xFF725F63) : Colors.grey,
                      ),
                    ),
                    Text(
                      'Home',
                      style: TextStyle(
                        color: const Color(0xFF212121),
                        fontSize: 10,
                        fontFamily: 'Actor',
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  ],
                ),
                
                // Your Adoptions
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.assignment, size: 32),
                      onPressed: () => _onItemTapped(2),
                      color: _selectedIndex == 2 ? const Color(0xFF725F63) : Colors.grey,
                    ),
                    Text(
                      'Your Adoptions',
                      style: TextStyle(
                        color: const Color(0xFF212121),
                        fontSize: 10,
                        fontFamily: 'Actor',
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  ],
                ),
              ],
            ),
            // Bottom indicator line
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 134,
              height: 5,
              decoration: ShapeDecoration(
                color: const Color(0xFF020202),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_calculateAge(DateTime birthdate) {
  DateTime today = DateTime.now();
  int age = today.year - birthdate.year;
  if (today.month < birthdate.month || (today.month == birthdate.month && today.day < birthdate.day)) {
    age--;
  }
  return age;
}