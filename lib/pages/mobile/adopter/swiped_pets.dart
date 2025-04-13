import 'package:flutter/material.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_swipe_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/pages/mobile/adopter/swiped_pet_profile.dart'; // Add this import

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
      // Get current user's liked pet IDs
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

  // Helper to format pet age
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      appBar: AppBar(
        title: Text(
          'Pets You Liked',
          style: TextStyle(
            color: Color(0xFF545454),
            fontFamily: 'Arial',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFFEF5F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF725F63)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF725F63)),
            onPressed: _loadLikedPets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: Color(0xFF725F63)))
          : user == null 
              ? _buildSignInPrompt()
              : _likedPets.isEmpty 
                  ? _buildEmptyState() 
                  : _buildPetGrid(),
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
