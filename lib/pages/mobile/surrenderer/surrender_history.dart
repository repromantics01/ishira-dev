import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/pet_profile.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/firebase_surrender_service.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/models/photo.dart';
import 'package:pawsmatch/models/surrender.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SurrenderHistory extends StatefulWidget {
  final bool showAppBar;
  
  const SurrenderHistory({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  _SurrenderHistoryState createState() => _SurrenderHistoryState();
}

class _SurrenderHistoryState extends State<SurrenderHistory> {
  final FirebasePetService _petService = FirebasePetService();
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final FirebaseSurrenderService _surrenderService = FirebaseSurrenderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';
  List<String> _userSurrenderPetIds = [];
  
  // Cache for photo URLs to avoid repeated lookups
  final Map<String, String> _photoUrlCache = {};

  @override
  void initState() {
    super.initState();
    _fetchUserSurrenders();
  }
  
  // Fetch surrender records for the current user
  Future<void> _fetchUserSurrenders() async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        // Get surrender records where account_id matches current user
        final surrenders = await _surrenderService.getSurrendersByAccountId(userId);
        
        setState(() {
          // Extract just the pet IDs from the surrender records
          _userSurrenderPetIds = surrenders.map((surrender) => surrender.pet_id).toList();
          _isLoading = false;
        });
      } catch (e) {
        print('Error fetching user surrenders: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getPetAge(DateTime birthdate) {
    final now = DateTime.now();
    final difference = now.difference(birthdate);
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();
    
    if (years > 0) {
      return years == 1 ? '1 year old' : '$years years old';
    } else if (months > 0) {
      return months == 1 ? '1 month old' : '$months months old';
    } else {
      return '${difference.inDays} days old';
    }
  }

  String _getStatusText(PetStatus status) {
    switch(status) {
      case PetStatus.Adopted:
        return 'Adopted';
      case PetStatus.Available:
        return 'Available';
      case PetStatus.Pending:
        return 'Pending Adoption';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(PetStatus status) {
    switch(status) {
      case PetStatus.Adopted:
        return Colors.green;
      case PetStatus.Available:
        return Color(0xFF725F63);
      case PetStatus.Pending:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Add method to get gender-specific color
  Color _getPetCardColor(String gender) {
    // Return B0CCCA for male and D8CBCB for female
    return gender.toLowerCase() == 'male' 
        ? const Color(0xFFB0CCCA) 
        : const Color(0xFFD8CBCB);
  }

  // Add method to get photo URL with improved error handling
  Future<String?> _getPhotoUrl(String photoId) async {
    // Check if URL is already in cache
    if (_photoUrlCache.containsKey(photoId)) {
      return _photoUrlCache[photoId];
    }
    
    try {
      var photoDoc = await _photoService.getPhotoWithId(photoId);
      
      if (photoDoc.exists) {
        final data = photoDoc.data();
        if (data == null) {
          print('Photo data is null for $photoId');
          return null;
        }
        
        final photoUrl = data.photo_url;
        
        // Store URL in cache before returning
        _photoUrlCache[photoId] = photoUrl;
        return photoUrl;
      } else {
        print('No photo document found for ID: $photoId');
        return null;
      }
    } catch (e) {
      print('Error fetching photo $photoId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show app bar based on how we were navigated to
    bool isDirectNavigation = ModalRoute.of(context)?.settings.name != null;
    bool shouldShowAppBar = widget.showAppBar && isDirectNavigation;
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    return Scaffold(
      appBar: shouldShowAppBar
          ? AppBar(
              title: Text(
                'My Surrendered Pets',
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(
                color: Color(0xFF725F63),
              ),
            )
          : null,
      backgroundColor: const Color(0xFFFEF5F0),
      body: userId == null
          ? Center(
              child: Text(
                'Please sign in to view your surrendered pets',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            )
          : _isLoading
              ? Center(child: CircularProgressIndicator())
              : _userSurrenderPetIds.isEmpty
                  ? Center(
                      child: Text(
                        'You have not surrendered any pets yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot<Pet>>(
                      stream: _petService.getAllPets(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading pets: ${snapshot.error}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No surrendered pets found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }

                        // Filter to only show pets surrendered by the current user
                        var pets = snapshot.data!.docs
                            .map((doc) => doc.data())
                            .where((pet) => _userSurrenderPetIds.contains(pet.pet_id))
                            .where((pet) {
                              if (_searchController.text.isEmpty) return true;
                              return pet.pet_name
                                      .toLowerCase()
                                      .contains(_searchController.text.toLowerCase()) ||
                                  pet.breed
                                      .toLowerCase()
                                      .contains(_searchController.text.toLowerCase());
                            })
                            .where((pet) {
                              if (_filter == 'All') return true;
                              return _getStatusText(pet.pet_status) == _filter;
                            })
                            .toList();

                        if (pets.isEmpty) {
                          return Center(
                            child: Text(
                              'No pets match your filters',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }

                        // Use CustomScrollView to have everything scroll together
                        return CustomScrollView(
                          slivers: [
                            // Title Section now in scrollable area
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                                child: Text(
                                  'My Pets',
                                  style: TextStyle(
                                    color: const Color(0xFF545454),
                                    fontSize: 28,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Search Bar Section now in scrollable area
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7F8FD),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: Colors.grey.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            // ...existing TextField decoration...
                                            hintText: 'Search for pets',
                                            hintStyle: TextStyle(
                                              color: const Color(0xFF8F9098),
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: const Color(0xFF725F63),
                                              size: 22,
                                            ),
                                            suffixIcon: _searchController.text.isNotEmpty
                                                ? IconButton(
                                                    icon: Icon(
                                                      Icons.clear,
                                                      color: Colors.grey,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      setState(() {});
                                                    },
                                                  )
                                                : null,
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 12,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF725F63),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.filter_list,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        onPressed: _showFilterOptions,
                                        tooltip: 'Filter & Sort',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Pet List
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final pet = pets[index];
                                    final cardColor = _getPetCardColor(pet.gender);
                                    
                                    return Card(
                                      // ...existing card code...
                                      elevation: 4,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Pet Image Section
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                            child: pet.photo_id.isNotEmpty
                                                ? FutureBuilder<String?>(
                                                    future: _getPhotoUrl(pet.photo_id[0]),
                                                    builder: (context, photoSnapshot) {
                                                      if (photoSnapshot.connectionState == 
                                                          ConnectionState.waiting) {
                                                        return Container(
                                                          height: 150,
                                                          color: cardColor,
                                                          child: Center(
                                                            child: CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      }
                                                      
                                                      final photoUrl = photoSnapshot.data;
                                                      if (photoUrl == null || photoUrl.isEmpty) {
                                                        return Container(
                                                          height: 150,
                                                          color: cardColor,
                                                          child: Center(
                                                            child: Icon(
                                                              Icons.pets,
                                                              size: 60,
                                                              color: const Color(0xFF725F63),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      
                                                      // Show actual photo with error handling
                                                      return Container(
                                                        height: 150,
                                                        width: double.infinity,
                                                        child: Image.network(
                                                          photoUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              height: 150,
                                                              color: cardColor,
                                                              child: Center(
                                                                child: Icon(
                                                                  Icons.broken_image,
                                                                  size: 60,
                                                                  color: const Color(0xFF725F63),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Container(
                                                              height: 150,
                                                              color: cardColor,
                                                              child: Center(
                                                                child: CircularProgressIndicator(
                                                                  value: loadingProgress.expectedTotalBytes != null
                                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                                          loadingProgress.expectedTotalBytes!
                                                                      : null,
                                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                                      const Color(0xFF725F63)),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    height: 150,
                                                    color: cardColor, // Use gender-specific color
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.pets,
                                                        size: 60,
                                                        color: const Color(0xFF725F63),
                                                      ),
                                                    ),
                                                  ),
                                          ),

                                          // Pet Details Section
                                          Container(
                                            decoration: BoxDecoration(
                                              color: cardColor.withOpacity(0.3), // Lighter version of gender color
                                              borderRadius: const BorderRadius.vertical(
                                                bottom: Radius.circular(12),
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Header row with name and status
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        pet.pet_name,
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(pet.pet_status),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        _getStatusText(pet.pet_status),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                
                                                // Combined row for gender and species/breed
                                                Row(
                                                  children: [
                                                    // Gender
                                                    Icon(
                                                      pet.gender.toLowerCase() == 'male' ? Icons.male : Icons.female,
                                                      size: 16,
                                                      color: const Color(0xFF725F63),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      pet.gender,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                    
                                                    // Divider
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      child: Text(
                                                        '•',
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ),
                                                    
                                                    // Species and breed
                                                    Icon(
                                                      Icons.pets,
                                                      size: 16,
                                                      color: const Color(0xFF725F63),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        '${pet.species} - ${pet.breed}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[800],
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                
                                                // Age info
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.cake,
                                                      size: 16,
                                                      color: const Color(0xFF725F63),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _getPetAge(pet.birthdate),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                
                                                // Description with limited lines
                                                Text(
                                                  pet.description,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[800],
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 10),
                                                
                                                // View Details button
                                                Center(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => PetProfile(petId: pet.pet_id),
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF725F63),
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 24, 
                                                        vertical: 8,
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'View Details',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  childCount: pets.length,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
    );
  }
  
  void _showFilterOptions() {
    // ...existing code...
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF545454),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  
                  // Status filter options
                  Text(
                    'Status:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF545454),
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildFilterOption('All', Icons.pets, _filter == 'All'),
                  _buildFilterOption('Available', Icons.check_circle_outline, _filter == 'Available'),
                  _buildFilterOption('Pending Adoption', Icons.hourglass_empty, _filter == 'Pending Adoption'),
                  _buildFilterOption('Adopted', Icons.home, _filter == 'Adopted'),
                  
                  SizedBox(height: 16),
                  
                  // Sort options
                  Text(
                    'Sort by:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF545454),
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildFilterOption('Name (A-Z)', Icons.sort_by_alpha, false),
                  _buildFilterOption('Date Posted (Latest)', Icons.calendar_today, false),
                  _buildFilterOption('Age (Youngest)', Icons.cake, false),
                  
                  SizedBox(height: 16),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Apply selected filters
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF725F63),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFilterOption(String title, IconData icon, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _filter = title;
            Navigator.pop(context);
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Color(0xFF725F63),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF545454),
                ),
              ),
              Spacer(),
              Icon(
                isSelected ? Icons.check_circle : Icons.check_circle_outline,
                size: 20,
                color: isSelected ? Color(0xFF725F63) : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
