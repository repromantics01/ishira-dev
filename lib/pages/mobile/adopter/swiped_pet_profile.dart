import 'package:flutter/material.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/models/surrender.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/services/firebase_surrender_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class SwipedPetProfile extends StatefulWidget {
  final String petId;
  final Pet? pet; 

  const SwipedPetProfile({
    Key? key, 
    required this.petId,
    this.pet,
  }) : super(key: key);

  @override
  _SwipedPetProfileState createState() => _SwipedPetProfileState();
}

class _SwipedPetProfileState extends State<SwipedPetProfile> {
  final FirebasePetService _petService = FirebasePetService();
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  final FirebaseSurrenderService _surrenderService = FirebaseSurrenderService();
  
  String? _primaryPhotoUrl;
  List<String> _photoUrls = [];
  int _currentPhotoIndex = 0;
  Organization? _organization;
  
  Pet? _pet;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // If pet data is provided, use it directly
    if (widget.pet != null) {
      _pet = widget.pet;
      _loadData();
    } else {
      _loadPetData();
    }
  }
  
  // New method to load all data at once
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Load photos and organization in parallel for better performance
      await Future.wait([
        _loadPetPhotos(),
        _loadOrganizationFromSurrender(),
      ]);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pet data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadPetData() async {
    try {
      final petDoc = await _petService.getPetWithId(widget.petId);
      if (petDoc.exists) {
        setState(() {
          _pet = petDoc.data();
        });
        // Once pet is loaded, load other data
        await _loadData();
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
  
  // New method to find organization from surrender records
  Future<void> _loadOrganizationFromSurrender() async {
    if (_pet == null) return;
    
    try {
      // Find surrenders related to this pet
      final petId = _pet!.pet_id;
      
      // Query for surrender records with this pet_id
      final surrenders = await _surrenderService.getSurrendersByPetId(petId);
      
      if (surrenders.isNotEmpty) {
        // Get the first surrender record (typically there should only be one)
        final surrender = surrenders.first;
        
        // Use org_id from surrender to get organization details
        if (surrender.org_id.isNotEmpty) {
          final org = await _organizationService.getOrganizationById(surrender.org_id);
          if (mounted && org != null) {
            setState(() {
              _organization = org;
            });
            return;
          }
        }
      }
      
      // Fallback: Try to get organization directly from the pet (if implemented in the future)
      // or load a default organization
      await _loadDefaultOrganization();
      
    } catch (e) {
      print('Error loading organization from surrender: $e');
      // Fallback to default method
      await _loadDefaultOrganization();
    }
  }
  
  // Fallback method to load a default organization
  Future<void> _loadDefaultOrganization() async {
    try {
      final orgs = await _organizationService.fetchAllOrganizations();
      if (orgs.isNotEmpty && mounted) {
        setState(() {
          _organization = orgs.first;
        });
      }
    } catch (e) {
      print('Error loading default organization: $e');
    }
  }
  
  Future<void> _loadPetPhotos() async {
    // ...existing code...
    
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

  // Helper method to calculate age from birthdate
  String _calculateAge(DateTime birthdate) {
    // ...existing code...
    
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

  // ...existing helper methods...

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

  void _showAdoptionConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Color(0xFF725F63),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Adoption Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  children: [
                    // Pet icon
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFECC8C0),
                      child: Icon(
                        Icons.pets,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Description text
                    Text(
                      'You are about to submit an adoption request for:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF545454),
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Pet name
                    Text(
                      _pet!.pet_name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF725F63),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Important information
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFE0B2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Important:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF725F63),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The organization will review your request and get in touch with you soon to complete the adoption process.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF5D4037),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Checkbox for terms
                    StatefulBuilder(
                      builder: (context, setState) {
                        bool acceptTerms = false;
                        
                        return Column(
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: acceptTerms,
                                  activeColor: Color(0xFF725F63),
                                  onChanged: (value) {
                                    setState(() {
                                      acceptTerms = value!;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    'I understand and accept the adoption process terms',
                                    style: TextStyle(
                                      color: Color(0xFF545454),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    
                    // Buttons
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Color(0xFF725F63)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF725F63),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        
                        // Submit button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Show confirmation snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Adoption request sent for ${_pet!.pet_name}! The organization will contact you shortly.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              // Here you would implement the actual adoption request logic
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF725F63),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Submit Request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pet == null
              ? Center(child: Text('Pet not found'))
              : Stack(
                  children: [
                    _buildProfileContent(),
                    
                    // Adopt button at bottom
                    if (_pet != null && _pet!.pet_status == PetStatus.Available)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, -5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _showAdoptionConfirmation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF725F63),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              'Adopt ${_pet!.pet_name}!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
  
  Widget _buildProfileContent() {
    // Calculate consistent width for rectangles
    final screenWidth = MediaQuery.of(context).size.width;
    final rectangleWidth = screenWidth - 48; // 24px padding on each side
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 80), // Add padding for the Adopt button
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

          // The rest of the content is the same as PetProfile
          // ...existing structure...
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
                       Padding(
                                    padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                                    child: Row(
                                      children: [
                                        // Organization logo
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                            image: DecorationImage(
                                                image: _organization?.logo_url != null
                                                ? NetworkImage(_organization!.logo_url!)
                                                : NetworkImage('https://www.svgrepo.com/show/509477/shelter.svg') as ImageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 15),
                                        // Organization info
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Posted by',
                                              style: GoogleFonts.nunito(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              _organization?.org_name ?? 'Animal Shelter',
                                              style: GoogleFonts.nunito(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF5D4037),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // About Pet section
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

          // Pet details section
          Column(
            children: [
              Container(
                width: rectangleWidth - 48,
                child: Text(
                  'More About ${_pet!.pet_name}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
                    // Blue-green rectangle behind the details box
                    Positioned(
                      bottom: -25,
                      left: -15,
                      right: -15,
                      child: Container(
                        height: 150,
                        width: rectangleWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB6CBCA),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    // Details box
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

          // Health Information section
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
          
          SizedBox(height: 60), // Extra space at the bottom for the fixed adopt button
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