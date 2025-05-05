import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/widgets/pet_details_modal.dart';
import 'package:pawsmatch/widgets/pet_adoption_requests_dialog.dart'; // Add this import
import 'package:pawsmatch/widgets/edit_pet_modal.dart'; // Add this import
import 'org_sidebar.dart';
//import 'package:image_picker_web/image_picker_web.dart';

class ManagePetsPage extends StatefulWidget {
  const ManagePetsPage({super.key});

  @override
  State<ManagePetsPage> createState() => _ManagePetsPageState();
}

class _ManagePetsPageState extends State<ManagePetsPage> {
  final FirebasePetService _petService = FirebasePetService();
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController(); // New search controller

  List<Pet> _pets = [];
  Map<String, String> _petMainPhotoUrls = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchTerm = ''; // Add search term state
  
  // Sorting and filtering options
  String _sortBy = 'Name (A-Z)';
  String _filterBy = 'All';

  @override
  void initState() {
    super.initState();
    _loadPets();
    // Add listener to search controller
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current user for organization ID
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get all pets
      final petsSnapshot = await _petService.getAllPets().first;
      final List<Pet> allPets = petsSnapshot.docs.map((doc) => doc.data()).toList();

      // For demo, we'll show all pets. In a real app, you might filter by organization ID
      setState(() {
        _pets = allPets;
      });

      // Fetch main photo URL for each pet
      for (var pet in _pets) {
        if (pet.photo_id.isNotEmpty) {
          try {
            final photoUrl = await _photoService.getPhotoUrl(pet.photo_id.first);
            if (photoUrl != null) {
              setState(() {
                _petMainPhotoUrls[pet.pet_id] = photoUrl;
              });
            }
          } catch (e) {
            print('Error fetching photo for pet ${pet.pet_id}: $e');
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load pets: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sort pets based on the selected sort option
  List<Pet> _getSortedPets() {
    List<Pet> sortedPets = List.from(_pets);
    switch (_sortBy) {
      case 'Name (A-Z)':
        sortedPets.sort((a, b) => a.pet_name.compareTo(b.pet_name));
        break;
      case 'Name (Z-A)':
        sortedPets.sort((a, b) => b.pet_name.compareTo(a.pet_name));
        break;
      case 'Age (Youngest)':
        sortedPets.sort((a, b) => b.birthdate.compareTo(a.birthdate));
        break;
      case 'Age (Oldest)':
        sortedPets.sort((a, b) => a.birthdate.compareTo(b.birthdate));
        break;
      case 'Recently Added':
        // Assuming newer pets have higher IDs or there's a date_added field
        sortedPets = sortedPets.reversed.toList();
        break;
    }
    return sortedPets;
  }

  // Filter pets based on the selected filter option
  List<Pet> _getFilteredPets() {
    List<Pet> sortedPets = _getSortedPets();
    
    // First filter by search term if not empty
    if (_searchTerm.isNotEmpty) {
      sortedPets = sortedPets.where((pet) => 
        pet.pet_name.toLowerCase().contains(_searchTerm.toLowerCase())).toList();
    }
    
    // Then apply category filter
    if (_filterBy == 'All') {
      return sortedPets;
    }
    
    // Filter by status
    if (_filterBy == 'Available') {
      return sortedPets.where((pet) => pet.pet_status == PetStatus.Available).toList();
    } else if (_filterBy == 'Adopted') {
      return sortedPets.where((pet) => pet.pet_status == PetStatus.Adopted).toList();
    } else if (_filterBy == 'Pending') {
      return sortedPets.where((pet) => pet.pet_status == PetStatus.Pending).toList();
    } else if (_filterBy == 'Rescued') {
      return sortedPets.where((pet) => pet.acquisition_type == AcquisitionType.Rescued).toList();
    } else if (_filterBy == 'Surrendered') {
      return sortedPets.where((pet) => pet.acquisition_type == AcquisitionType.Surrendered).toList();
    }
    
    return sortedPets;
  }

  // Calculate pet age in years from birthdate
  int _calculatePetAge(DateTime birthdate) {
    return DateTime.now().difference(birthdate).inDays ~/ 365;
  }

  @override
  Widget build(BuildContext context) {
    // Get filtered pets
    final filteredPets = _isLoading ? [] : _getFilteredPets();
    
    // Calculate available width for content area (total width minus sidebar width)
    final double contentAreaWidth = 1584 - 359;
    // Standard left margin for all content
    final double leftMargin = 400;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: Center(
        child: Container(
          width: 1584,
          height: 1024,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: const Color(0xFFFEF5F0)),
          child: Stack(
            children: [
              // Top horizontal line
              Positioned(
                left: 16,
                top: 1,
                child: Container(
                  width: 503,
                  height: 0.50,
                  decoration: BoxDecoration(color: const Color(0xFF9E9E9E)),
                ),
              ),
              
              // Page title - consistent positioning
              Positioned(
                left: leftMargin,
                top: 80,
                child: Text(
                  'Manage Pets',
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 48,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              
              // Control row with consistent alignment
              Positioned(
                left: leftMargin,
                top: 160,
                child: Row(
                  children: [
                    // New Search Field
                    Container(
                      width: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search Pets',
                            style: TextStyle(
                              color: const Color(0xFF2E3036),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFFC5C6CC),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search pet name...',
                                border: InputBorder.none,
                                suffixIcon: _searchTerm.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : Icon(Icons.search, color: const Color(0xFF8F9098)),
                                hintStyle: TextStyle(
                                  color: const Color(0xFF8F9098),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Spacing between controls
                    SizedBox(width: 20),
                    
                    // Sort dropdown
                    Container(
                      width: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sort',
                            style: TextStyle(
                              color: const Color(0xFF2E3036),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFFC5C6CC),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _sortBy,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _sortBy = newValue;
                                    });
                                  }
                                },
                                items: <String>[
                                  'Name (A-Z)', 
                                  'Name (Z-A)', 
                                  'Age (Youngest)', 
                                  'Age (Oldest)',
                                  'Recently Added'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        color: const Color(0xFF8F9098),
                                        fontSize: 14,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: const Color(0xFF8F9098),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Spacing between controls
                    SizedBox(width: 20),
                    
                    // Filter dropdown
                    Container(
                      width: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter',
                            style: TextStyle(
                              color: const Color(0xFF2E3036),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: const Color(0xFFC5C6CC),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _filterBy,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _filterBy = newValue;
                                    });
                                  }
                                },
                                items: <String>[
                                  'All', 
                                  'Available', 
                                  'Adopted', 
                                  'Pending',
                                  'Rescued',
                                  'Surrendered',
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        color: const Color(0xFF8F9098),
                                        fontSize: 14,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: const Color(0xFF8F9098),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Spacing between controls
                    SizedBox(width: 20),
                    
                    // Add New Pet Button - aligned with dropdowns
                    Container(
                      height: 68, // Match the height of dropdowns + label
                      padding: EdgeInsets.only(top: 20), // Align with dropdown fields
                      child: InkWell(
                        onTap: () {
                          _showAddPetModal();
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFC0D6B6),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFF8B8B8B),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: const Color(0xFF464646), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add New Pet',
                                style: TextStyle(
                                  color: const Color(0xFF464646),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Pets grid area with proper padding
              Positioned(
                left: leftMargin,
                top: 260,
                right: 40,
                bottom: 20,
                child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF725F63),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 64),
                            SizedBox(height: 16),
                            Text(
                              'Error',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadPets,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                backgroundColor: Color(0xFFC0D6B6),
                              ),
                              child: Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : filteredPets.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 25,
                            mainAxisSpacing: 25,
                          ),
                          itemCount: filteredPets.length,
                          itemBuilder: (context, index) {
                            final pet = filteredPets[index];
                            final photoUrl = _petMainPhotoUrls[pet.pet_id];
                            final petAge = _calculatePetAge(pet.birthdate);
                            
                            return _buildPetCard(pet, photoUrl, petAge);
                          },
                        ),
              ),
              
              // Sidebar
              const Positioned(
                left: 0,
                top: 0,
                child: OrgSidebar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pet card widget with improved padding
  Widget _buildPetCard(Pet pet, String? photoUrl, int age) {
    // Status indicator color
    Color statusColor;
    switch (pet.pet_status) {
      case PetStatus.Available:
        statusColor = Colors.green;
        break;
      case PetStatus.Adopted:
        statusColor = Colors.red;
        break;
      case PetStatus.Pending:
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 14.60,
            offset: Offset(0, 10),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet photo
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 175,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.pets,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.pets,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                      ),
                  
                  // Status indicator
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        pet.pet_status.toString().split('.').last,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Gradient overlay for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Pet info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet name and age
                Text(
                  '${pet.pet_name}, $age',
                  style: TextStyle(
                    color: const Color(0xFF3F3F3F),
                    fontSize: 18,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 4),
                
                // Gender and Species
                Text(
                  '${pet.gender} ${pet.species}',
                  style: TextStyle(
                    color: const Color(0xFF7A7A7A),
                    fontSize: 14,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Edit button
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () {
                      // Show pet details modal instead of SnackBar
                      _showPetDetailsModal(pet);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF545454),
                      side: BorderSide(color: const Color(0xFF545454)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'VIEW DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
  }

  // New method to show pet details modal
  void _showPetDetailsModal(Pet pet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PetDetailsModal(
          pet: pet,
          onClose: () {
            Navigator.of(context).pop();
          },
          onUpdatePet: () {
            Navigator.of(context).pop();
            _showUpdatePetDialog(pet);
          },
          onViewAdoptionRequests: () {
            Navigator.of(context).pop();
            _viewAdoptionRequests(pet);
          },
        );
      },
    );
  }

  // Method to show update pet dialog
  void _showUpdatePetDialog(Pet pet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditPetModal(
          pet: pet,
          onClose: () {
            Navigator.of(context).pop();
          },
          onSuccess: () {
            // Refresh pet list after update
            _loadPets();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pet details updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  // Method to view adoption requests for a pet
  void _viewAdoptionRequests(Pet pet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PetAdoptionRequestsDialog(
          pet: pet,
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // Method to show add pet modal
  void _showAddPetModal() {
    // Create a default empty Pet object for new pet
    final newPet = Pet(
      pet_id: '',
      pet_name: '',
      species: '',
      breed: '',
      gender: '',
      description: '',
      birthdate: DateTime.now(),
      vaccination_status: VaccinationStatus.None,
      pet_status: PetStatus.Available,
      address: '',
      is_neutered_or_spayed: false,
      acquisition_type: AcquisitionType.Rescued,
      photo_id: [],
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditPetModal(
          pet: newPet, 
          onClose: () {
            Navigator.of(context).pop();
          },
          onSuccess: () {
            // Refresh pet list after adding
            _loadPets();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('New pet added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Color(0xFF725F63).withOpacity(0.5)),
          SizedBox(height: 24),
          Text(
            _filterBy == 'All' 
                ? 'No pets available' 
                : 'No $_filterBy pets available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF545454),
            ),
          ),
          SizedBox(height: 16),
          Text(
            _filterBy == 'All'
                ? 'You haven\'t added any pets yet.'
                : 'Try changing your filter to see more pets.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF545454).withOpacity(0.7),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Open add pet modal
              _showAddPetModal();
            },
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add New Pet',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Color(0xFF725F63),
            ),
          ),
        ],
      ),
    );
  }
}
