import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/models/surrender.dart';
import 'package:pawsmatch/pages/mobile/adopter/organization_profile.dart'; // Add this import
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/services/firebase_surrender_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawsmatch/services/firebase_adopt_service.dart';
import 'package:pawsmatch/services/firebase_swipe_service.dart'; // Add this import

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
  final FirebaseAdoptService _adoptService = FirebaseAdoptService();
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  final FirebaseSurrenderService _surrenderService = FirebaseSurrenderService();
  final FirebaseSwipeService _swipeService = FirebaseSwipeService(); 
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String account_id = FirebaseAuth.instance.currentUser!.uid;

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
          final org =
              await _organizationService.getOrganizationById(surrender.org_id);
          if (mounted && org != null) {
            setState(() {
              _organization = org as Organization?;
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

  Future<void> submitAdoptionDetails() async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if(currentUserId != null) {
        // Submit adoption request
        await _adoptService.adoptPetFromOrganization(
          petId: _pet!.pet_id,
          accountId: currentUserId,
          organizationId: _organization!.org_id,
        );
        
        // Mark the swipe as inactive
        await _swipeService.setSwipeInactive(_pet!.pet_id);
      }
    } catch (e) {
      print('Error submitting adoption details: $e');
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

  void _showAdoptionConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine available space and adapt accordingly
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            return Container(
              width: maxWidth,
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: maxHeight * 0.9, // Use 90% of available height max
              ),
              decoration: ShapeDecoration(
                color: const Color(0xFFEDEDED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pet image at the top with responsive size
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: maxWidth * 0.05, // Responsive padding
                        horizontal: 16,
                      ),
                      child: Container(
                        width: min(150, maxWidth * 0.4), // Responsive width
                        height: min(150, maxWidth * 0.4), // Responsive height
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                          image: DecorationImage(
                            image: _photoUrls.isNotEmpty
                                ? NetworkImage(_photoUrls.first)
                                : AssetImage(
                                        'assets/images/pet_placeholder.png')
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    // Confirmation question text with adaptive font size
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Are you sure you want to request ${_pet!.pet_name} for adoption?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize:
                              maxWidth < 300 ? 16 : 20, // Responsive font size
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Adoption commitment text with adaptive font size
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Adopting a pet is a big commitment and a life-changing decision— for both you and your future furry friend!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF646464),
                          fontSize:
                              maxWidth < 300 ? 11 : 13, // Responsive font size
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Confirmation details text
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'By confirming, you are notifying ',
                              style: TextStyle(
                                color: const Color(0xFF656565),
                                fontSize: maxWidth < 300
                                    ? 10
                                    : 12, // Responsive font size
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                height: 1.75,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${_organization?.org_name ?? "the organization"}',
                              style: TextStyle(
                                color: const Color(0xFF656565),
                                fontSize: maxWidth < 300
                                    ? 10
                                    : 12, // Responsive font size
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.75,
                              ),
                            ),
                            TextSpan(
                              text: ' about your adoption request.',
                              style: TextStyle(
                                color: const Color(0xFF656565),
                                fontSize: maxWidth < 300
                                    ? 10
                                    : 12, // Responsive font size
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                height: 1.75,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 16),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'You cannot revert request once confirmed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF656565),
                          fontSize:
                              maxWidth < 300 ? 12 : 14, // Responsive font size
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Proceed?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF656565),
                          fontSize:
                              maxWidth < 300 ? 12 : 14, // Responsive font size
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // NO button
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical:
                                maxWidth < 300 ? 8 : 12, // Responsive padding
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE0E0E0),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFF8B8B8B),
                              ),
                              borderRadius: BorderRadius.circular(250),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'NO',
                              style: TextStyle(
                                color: const Color(0xFF1E2C2B),
                                fontSize: maxWidth < 300
                                    ? 12
                                    : 14, // Responsive font size
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w500,
                                height: 1.14,
                                letterSpacing: 1.25,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // YES button
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          // Show success modal instead of SnackBar
                          _showAdoptionSuccessModal();
                          submitAdoptionDetails();

                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical:
                                maxWidth < 300 ? 8 : 12, // Responsive padding
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFC0D6B6),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFF8B8B8B),
                              ),
                              borderRadius: BorderRadius.circular(250),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'YES',
                              style: TextStyle(
                                color: const Color(0xFF1E2C2B),
                                fontSize: maxWidth < 300
                                    ? 12
                                    : 14, // Responsive font size
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w500,
                                height: 1.14,
                                letterSpacing: 1.25,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Updated method to show success modal after adoption confirmation
  void _showAdoptionSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get available width
            final maxWidth = min(335.0, constraints.maxWidth - 40);

            return Container(
              width: maxWidth,
              decoration: ShapeDecoration(
                color: const Color(0xFFEDEDED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hooray image
                  Padding(
                    padding: const EdgeInsets.only(top: 25, bottom: 10),
                    child: Image.asset(
                      'assets/photos/hooray.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback in case the image is missing
                        return Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCC80),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.celebration,
                            size: 70,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),

                  // Hooray text
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Text(
                      'Hooray!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 23,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Success message
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Your request has been sent to ',
                            style: TextStyle(
                              color: const Color(0xFF646464),
                              fontSize: 13,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          TextSpan(
                            text:
                                '${_organization?.org_name ?? "Organization Name"} ',
                            style: TextStyle(
                              color: const Color(0xFF646464),
                              fontSize: 13,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                          TextSpan(
                            text:
                                'for review. They will reach out to you soon with the next steps.',
                            style: TextStyle(
                              color: const Color(0xFF646464),
                              fontSize: 13,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE0E0E0),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFF8B8B8B),
                            ),
                            borderRadius: BorderRadius.circular(250),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'CLOSE',
                            style: TextStyle(
                              color: const Color(0xFF1E2C2B),
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                              height: 1.14,
                              letterSpacing: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modified layout: Name and status on same line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Pet name (left side)
                          Expanded(
                            child: Text(
                              _pet!.pet_name,
                              style: const TextStyle(
                                color: Color(0xFF545454),
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                height: 0.9,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Status badge (right side)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getPetStatusColor().withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getPetStatusColor(),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _pet!.pet_status == PetStatus.Available
                                      ? Icons.check_circle
                                      : _pet!.pet_status == PetStatus.Pending
                                          ? Icons.hourglass_empty
                                          : Icons.home,
                                  size: 16,
                                  color: _getPetStatusColor(),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _getPetStatusString(),
                                  style: TextStyle(
                                    color: _getPetStatusColor(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      // Remove the existing status badge since we've moved it to the top
                      
                      // Make the organization section clickable
                      InkWell(
                        onTap: () {
                          // Navigate to the AdopterOrganizationProfile when clicked
                          if (_organization != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdopterOrganizationProfile(
                                  organization: _organization!,
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 20, 16, 0),
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
                                        : NetworkImage(
                                                'https://www.svgrepo.com/show/509477/shelter.svg')
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              // Organization info
                              Expanded(
                                child: Column(
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
                                      _organization?.org_name ??
                                          'Animal Shelter',
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5D4037),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Add an arrow icon to indicate it's clickable
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color(0xFF5D4037),
                              ),
                            ],
                          ),
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
                          minHeight: 80, // Minimum height for the "About" box
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
                            maxLines: 1,
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
                          _buildDetailRow(
                              'Age', _calculateAge(_pet!.birthdate)),
                          _buildDetailRow(
                              'Origin',
                              _pet!.acquisition_type == AcquisitionType.Rescued
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

          SizedBox(height: 20),

          // Health Information section
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
                          minHeight: 80, // Minimum height
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEDED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.fromLTRB(16,35, 16, 20),
                        child: Column(
                          children: [
                            _buildHealthInfoChip(
                                'Spayed/Neutered', _pet!.is_neutered_or_spayed),
                            _buildHealthInfoChip(
                                'Vaccination', _getVaccinationStatusForChip()),
                          ],
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
                            'Medical Information',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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

          SizedBox(height: 10),

          // Adopt button - now part of scrollable content rather than fixed footer
          if (_pet != null && _pet!.pet_status == PetStatus.Available)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(  
                child: SizedBox(
                  width: screenWidth * 0.8,  
                  child: ElevatedButton(
                    onPressed: () {
                      _showAdoptionConfirmation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB6CBCA),
                      foregroundColor: const Color(0xFF1E2B2B),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: const Color.fromARGB(255, 145, 166, 165),
                        ),
                        borderRadius: BorderRadius.circular(250),
                      ),
                    ),
                    child: Text(
                      'Adopt ${_pet!.pet_name}!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.25,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
              height:
                  20), // Add a little padding at the bottom for better appearance
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
      String valueText;
      
      if (value is bool) {
        valueText = value ? 'Yes' : 'No';
      } else {
        valueText = value.toString();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color.fromARGB(179, 4, 4, 4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                color: Color.fromARGB(179, 4, 4, 4),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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


