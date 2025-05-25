import 'package:flutter/material.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/supabase_client_service.dart';
import 'package:intl/intl.dart';

class PetProfile extends StatefulWidget {
  final String petId;
  final Pet? pet; // Optional pet data, if already available

  const PetProfile({
    Key? key, 
    required this.petId,
    this.pet,
  }) : super(key: key);

  @override
  _PetProfileState createState() => _PetProfileState();
}

class _PetProfileState extends State<PetProfile> {
  final FirebasePetService _petService = FirebasePetService();
  final FirebasePhotoService _photoService = FirebasePhotoService();
  
  Pet? _pet;
  bool _isLoading = true;
  List<String> _photoUrls = [];
  int _currentPhotoIndex = 0;
  Organization? _organization; // Add this field
  
  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _pet = widget.pet;
      _loadPetPhotos();
      _loadOrganizationForPet(); // Load org for provided pet
    } else {
      _loadPetData();
    }
  }
  
  Future<void> _loadPetData() async {
    try {
      final petDoc = await _petService.getPetWithId(widget.petId);
      if (petDoc.exists) {
        setState(() {
          _pet = petDoc.data();
        });
        await _loadPetPhotos();
        await _loadOrganizationForPet(); // Load org after loading pet
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Pet document not found');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading pet data: $e');
    }
  }
  
  Future<void> _loadPetPhotos() async {
    if (_pet == null || _pet!.photo_id.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      final urls = <String>[];
      for (final photoId in _pet!.photo_id) {
        final url = await _photoService.getPhotoUrl(photoId);
        if (url != null) {
          urls.add(url);
        }
      }
      setState(() {
        _photoUrls = urls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading pet photos: $e');
    }
  }

  // --- FIX: Always use pet.org_id if available ---
  Future<void> _loadOrganizationForPet() async {
    if (_pet == null) return;
    try {
      String? orgId;
      if (_pet!.toJson().containsKey('org_id')) {
        orgId = _pet!.toJson()['org_id'];
      } else if (_pet!.toJson().containsKey('organization_id')) {
        orgId = _pet!.toJson()['organization_id'];
      } else if ((_pet as dynamic).org_id != null) {
        orgId = (_pet as dynamic).org_id;
      }
      if (orgId != null && orgId.isNotEmpty) {
        final org = await FirebaseOrganizationService().getOrganizationById(orgId);
        if (mounted && org != null) {
          setState(() {
            _organization = org;
          });
        }
      }
    } catch (e) {
      print('Error loading organization for pet: $e');
    }
  }

  // Helper method to calculate age from birthdate
  String _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    final difference = now.difference(birthdate);
    
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();
    
    if (years > 0) {
      return years == 1 ? '1 year old' : '$years years old';
    } else if (months > 0) {
      return months == 1 ? '1 month old' : '$months months old';
    } else {
      final days = difference.inDays;
      return days == 1 ? '1 day old' : '$days days old';
    }
  }

  String _getVaccinationStatus() {
    if (_pet == null) return 'Unknown';
    
    switch (_pet!.vaccination_status) {
      case VaccinationStatus.Full:
        return 'Fully vaccinated';
      case VaccinationStatus.Partial:
        return 'Partially vaccinated';
      case VaccinationStatus.None:
        return 'Not vaccinated';
      default:
        return 'Unknown';
    }
  }
  
  String _getPetStatusString() {
    if (_pet == null) return 'Unknown';
    
    switch (_pet!.pet_status) {
      case PetStatus.Available:
        return 'Available for adoption';
      case PetStatus.Adopted:
        return 'Adopted';
      case PetStatus.Pending:
        return 'Adoption pending';
      default:
        return 'Unknown';
    }
  }
  
  Color _getPetStatusColor() {
    if (_pet == null) return Colors.grey;
    
    switch (_pet!.pet_status) {
      case PetStatus.Available:
        return Colors.green;
      case PetStatus.Adopted:
        return Colors.blue;
      case PetStatus.Pending:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0), // Matching background color
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pet == null
              ? Center(child: Text('Pet not found'))
              : _buildProfileContent(),
    );
  }
  
  Widget _buildProfileContent() {
    // Calculate consistent width for rectangles
    final screenWidth = MediaQuery.of(context).size.width;
    final rectangleWidth = screenWidth - 48; // 24px padding on each side
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero image section with back button, similar to organization profile
          Stack(
            children: [
              // Main pet image
              Container(
                height: 390,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8CBCB), // Fallback color
                ),
                child: _photoUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: _photoUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPhotoIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          _photoUrls[index],
                          width: double.infinity,
                          height: 390,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.pets,
                                    size: 100,
                                    color: const Color(0xFF725F63),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Image not available',
                                    style: TextStyle(
                                      color: const Color(0xFF725F63),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.pets,
                        size: 100,
                        color: const Color(0xFF725F63),
                      ),
                    ),
              ),
              
              // Back button with transparent background
              Positioned(
                top: 40,
                left: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              
              // Image pagination dots
              if (_photoUrls.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _photoUrls.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPhotoIndex
                              ? const Color(0xFF686868)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Pet name and basic info, similar to organization header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pet!.pet_name,
                        style: const TextStyle(
                          color: Color(0xFF545454),
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 0.9,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            _pet!.gender.toLowerCase() == 'male' 
                                ? Icons.male 
                                : Icons.female,
                            size: 18,
                            color: _pet!.gender.toLowerCase() == 'male'
                                ? Colors.blue
                                : Colors.pink,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "${_pet!.gender} • ${_calculateAge(_pet!.birthdate)}",
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Location info
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: const Color(0xFF725F63),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _pet!.address,
                              style: TextStyle(
                                color: const Color(0xFF545454),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Status badge
                      SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getPetStatusColor(),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getPetStatusString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // About Pet section with styled background, ensure minimum height
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Container(
                        width: rectangleWidth,
                        constraints: BoxConstraints(
                          minHeight: 150, // Minimum height for the "About" box
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEDED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 40, 16, 25),
                        child: Text(
                          _pet!.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF545454),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECC8C0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'About ${_pet!.pet_name}',
                            overflow: TextOverflow.ellipsis, // Prevent wrapping
                            maxLines: 1, // Force single line
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pet details section with styled background, similar to "Mission" in organization
          Column(
            children: [
              Container(
                width: rectangleWidth - 48, // Account for the existing padding
                child: Text(
                  'More About ${_pet!.pet_name}',
                  overflow: TextOverflow.ellipsis, // Prevent wrapping
                  maxLines: 1, // Force single line
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Blue-green rectangle behind the details box - match width with "About" section
                    Positioned(
                      bottom: -25,
                      left: -15,
                      right: -15,
                      child: Container(
                        height: 150,
                        width: rectangleWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB6CBCA), // Teal color from org profile
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    // Details box with consistent width
                    Container(
                      width: rectangleWidth,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Species', _pet!.species),
                          _buildDetailRow('Breed', _pet!.breed),
                          _buildDetailRow('Gender', _pet!.gender),
                          _buildDetailRow('Age', _calculateAge(_pet!.birthdate)),
                          _buildDetailRow('Origin', _pet!.acquisition_type == AcquisitionType.Rescued 
                              ? 'Rescued' 
                              : 'Surrendered'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 40),

          // Health Information section, similar to Services in org profile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Information',
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16),
                // Health info items as chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHealthInfoChip(
                      'Spayed/Neutered',
                      _pet!.is_neutered_or_spayed
                    ),
                    _buildHealthInfoChip(
                      'Vaccination',
                      _getVaccinationStatusForChip()
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 60),
        ],
      ),
    );
  }
  
  // Build white text on black background for pet details
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build chips for health information
  Widget _buildHealthInfoChip(String label, dynamic value) {
    String displayText;
    Color bgColor;
    
    if (value is bool) {
      displayText = value ? '$label: Yes' : '$label: No';
      bgColor = value ? const Color(0xFFB6CBCA) : const Color(0xFFEDEDED);
    } else {
      displayText = '$label: $value';
      if (value == 'Full') {
        bgColor = const Color(0xFFB6CBCA);
      } else if (value == 'Partial') {
        bgColor = const Color(0xFFECC8C0);
      } else {
        bgColor = const Color(0xFFEDEDED);
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(250),
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: const Color(0xFF545454),
          fontSize: 14,
        ),
      ),
    );
  }
  
  // Helper for vaccination status chip
  String _getVaccinationStatusForChip() {
    switch (_pet!.vaccination_status) {
      case VaccinationStatus.Full:
        return 'Full';
      case VaccinationStatus.Partial:
        return 'Partial';
      case VaccinationStatus.None:
        return 'None';
      default:
        return 'Unknown';
    }
  }
}
