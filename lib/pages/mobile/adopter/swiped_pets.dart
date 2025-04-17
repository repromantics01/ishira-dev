import 'package:flutter/material.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_swipe_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/pages/mobile/adopter/swiped_pet_profile.dart';
import 'package:pawsmatch/pages/mobile/adopter/view_adoptions.dart';
import 'package:pawsmatch/pages/mobile/adopter/a_dashboard.dart';
import 'package:flutter/services.dart';
import 'package:pawsmatch/utils/navigation_helper.dart';

class SwipedPetsPage extends StatefulWidget {
  const SwipedPetsPage({Key? key}) : super(key: key);

  @override
  _SwipedPetsPageState createState() => _SwipedPetsPageState();
}

class _SwipedPetsPageState extends State<SwipedPetsPage> {
  final FirebaseSwipeService _swipeService = FirebaseSwipeService();
  final FirebasePetService _petService = FirebasePetService();
  final FirebasePhotoService _photoService = FirebasePhotoService();
  
  bool _isLoading = true;
  List<Pet> _likedPets = [];
  Map<String, String> _petPhotos = {};
  int _selectedIndex = 0; // This page is index 0
  
  @override
  void initState() {
    super.initState();
    _loadLikedPets();
  }

  Future<void> _loadLikedPets() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final likedPetIds = await _swipeService.getCurrentUserLikedPetIds();
      
      if (likedPetIds.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Remove duplicates
      final uniquePetIds = likedPetIds.toSet().toList();
      
      // Fetch details for each pet
      List<Pet> pets = [];
      for (final petId in uniquePetIds) {
        try {
          final pet = await _petService.getPetById(petId);
          if (pet != null) {
            pets.add(pet);
            
            // Load the pet's primary photo for display
            if (pet.photo_id.isNotEmpty) {
              final photoUrl = await _photoService.getPhotoUrl(pet.photo_id[0]);
              if (photoUrl != null) {
                _petPhotos[pet.pet_id] = photoUrl;
              }
            }
          }
        } catch (e) {
          print('Error fetching pet $petId: $e');
        }
      }
      
      setState(() {
        _likedPets = pets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading liked pets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPetAge(DateTime birthdate) {
    final now = DateTime.now();
    int years = now.year - birthdate.year;
    int months = now.month - birthdate.month;
    
    if (now.day < birthdate.day) {
      months--;
    }
    
    if (months < 0) {
      years--;
      months += 12;
    }
    
    if (years == 0) {
      return '${months < 1 ? 1 : months} ${months == 1 ? 'month' : 'months'} old';
    } else {
      return '$years ${years == 1 ? 'year' : 'years'} old';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on the selected tab
    if (index == 0) {
      // Already on swiped pets page, do nothing
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdopterDashboard()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ViewAdoptionsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF5F0),
        automaticallyImplyLeading: false, 
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF4EAEA),
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
              backgroundColor: const Color(0xFFF4EBEB),
              child: IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF725F63)),
                onPressed: () {
                  NavigationHelper.navigateToProfileSettings(context);
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Title positioned at top
          Positioned(
            left: 18,
            top: 18,
            child: SizedBox(
              width: 301,
              height: 36,
              child: Text(
                'Swiped Pets',
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 32,
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          
          // Content positioned below title
          Padding(
            padding: const EdgeInsets.only(top: 70), // Make space for the title
            child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: Color(0xFF725F63)))
                : user == null 
                    ? _buildSignInPrompt()
                    : _likedPets.isEmpty 
                        ? _buildEmptyState() 
                        : _buildPetGrid(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF5F0).withOpacity(0.5), // Semi-transparent background
          // Remove the border here
        ),
        height: 85, 
        child: Column(
          children: [
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Swiped pets button
                _buildNavButton(
                  icon: Icons.pets,
                  label: 'Swiped Pets',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                  isHomeButton: false,
                ),
                
                // Home button - special design
                _buildNavButton(
                  icon: Icons.home,
                  label: 'Home',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                  isHomeButton: true,
                ),
                
                // Your Adoptions button
                _buildNavButton(
                  icon: Icons.assignment,
                  label: 'Your Adoptions',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                  isHomeButton: false,
                ),
              ],
            ),
            // Bottom indicator line
            Container(
              margin: const EdgeInsets.only(top: 5), // Adjusted from 10
              width: 134,
              height: 2,
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

  // Simplified nav button with no animations
  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isHomeButton,
  }) {
    // Colors and sizes
    final activeColor = const Color(0xFF725F63);
    final inactiveColor = Colors.grey;
    final double iconSize = isHomeButton ? 26 : 32;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Button without animation
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: EdgeInsets.all(isHomeButton ? 8 : 6),
            decoration: BoxDecoration(
              color: isHomeButton 
                ? isSelected 
                  ? Color(0xFFECC8C0).withOpacity(0.7)  // Semi-transparent
                  : const Color(0xFFF6F6F6).withOpacity(0.5)  // Semi-transparent
                : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected && isHomeButton
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ),
        
        SizedBox(height: 5),
        
        // Label
        Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : const Color(0xFF212121),
            fontSize: 10,
            fontFamily: 'Actor',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        
        // Indicator dot for selected item
        Container(
          margin: EdgeInsets.only(top: 4),
          width: isSelected && !isHomeButton ? 4 : 0,
          height: 4,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle_outlined, size: 80, color: Color(0xFF725F63)),
          SizedBox(height: 24),
          Text(
            'Sign In Required',
            style: TextStyle(
              color: Color(0xFF545454),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Please sign in to see your liked pets',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to sign in page
              // Navigator.pushNamed(context, '/signin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF725F63),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Color(0xFF725F63)),
          SizedBox(height: 24),
          Text(
            'No Liked Pets Yet',
            style: TextStyle(
              color: Color(0xFF545454),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start swiping to find pets you love and they\'ll appear here',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF725F63),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Find Pets'),
          ),
        ],
      ),
    );
  }

  Widget _buildPetGrid() {
    return RefreshIndicator(
      onRefresh: _loadLikedPets,
      color: Color(0xFF725F63),
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _likedPets.length,
        itemBuilder: (context, index) {
          final pet = _likedPets[index];
          final photoUrl = _petPhotos[pet.pet_id];
          final gender = pet.gender.toLowerCase();
          final cardColor = gender == 'male' 
              ? const Color(0xFFB0CCCA) 
              : const Color(0xFFD8CBCB);
          
          return Card(
            elevation: 4,
            margin: EdgeInsets.zero, // No margin to prevent overflow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias, // Clip any overflowing content
            child: InkWell(
              onTap: () {
                // Navigate to the SwipedPetProfile page when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SwipedPetProfile(
                      petId: pet.pet_id,
                      pet: pet,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet image
                  Expanded(
                    flex: 5, // Allocate 5/8 of space to image
                    child: Stack(
                      children: [
                        // ...existing image code...
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: cardColor,
                          child: photoUrl != null
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  Center(
                                    child: Icon(
                                      Icons.pets,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.pets,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                        ),
                          
                        // ...existing gender indicator code...
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: gender == 'male' 
                                  ? Colors.blue.withOpacity(0.8) 
                                  : Colors.pink.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(
                              gender == 'male' ? Icons.male : Icons.female,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Pet details
                  Expanded(
                    flex: 3, // Allocate 3/8 of space to details
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Use minimum space needed
                        children: [
                          // ...existing text details...
                          Text(
                            pet.pet_name,
                            style: TextStyle(
                              color: Color(0xFF545454),
                              fontSize: 14, // Smaller font size
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2), // Reduced spacing
                          
                          Text(
                            pet.breed,
                            style: TextStyle(
                              color: Color(0xFF8E7A72),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2), // Reduced spacing
                          
                          Text(
                            _getPetAge(pet.birthdate),
                            style: TextStyle(
                              color: Color(0xFF8E7A72),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
