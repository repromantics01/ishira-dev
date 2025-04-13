import 'package:flutter/material.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SwipePetDetails extends StatefulWidget {
  final Pet pet;
  final Function() onSwipeLeft;
  final Function() onSwipeRight;
  final bool showInteractions; // Add this parameter to control button visibility

  const SwipePetDetails({
    Key? key, 
    required this.pet,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.showInteractions = true, // Default to showing interaction elements
  }) : super(key: key);

  @override
  _SwipePetDetailsState createState() => _SwipePetDetailsState();
}

class _SwipePetDetailsState extends State<SwipePetDetails> with SingleTickerProviderStateMixin {
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  String? _primaryPhotoUrl;
  List<String> _photoUrls = [];
  int _currentPhotoIndex = 0;
  Organization? _organization;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Initialize animation controller for heart beat effect
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
      .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _pulseHeart() {
    _animationController.forward();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Future.wait([
        _loadPetPhotos(),
        _loadOrganizationDetails(),
      ]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Calculate pet age from birthdate - fixed to properly display ages under 1 year
  String _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int years = now.year - birthdate.year;
    int months = now.month - birthdate.month;
    
    // Adjust for month/day differences
    if (now.day < birthdate.day) {
      months--;
    }
    
    // Adjust for negative months (birthdate is in future months of previous year)
    if (months < 0) {
      years--;
      months += 12;
    }
    
    if (years == 0) {
      // Show months for pets under a year old
      // Make sure we show at least 1 month for very young pets
      return '${months < 1 ? 1 : months} ${months == 1 ? 'month' : 'months'} old';
    } else {
      // Show years for older pets
      return '$years ${years == 1 ? 'year' : 'years'} old';
    }
  }

  // Convert enum to cute emoji and text
  String _getVaccinationStatusEmoji(VaccinationStatus status) {
    switch (status) {
      case VaccinationStatus.Full:
        return "✅ Fully Vaccinated";
      case VaccinationStatus.Partial:
        return "⚠️ Partially Vaccinated";
      case VaccinationStatus.None:
        return "❌ Not Vaccinated";
    }
  }

  // Get cute emoji based on gender
  String _getGenderEmoji(String gender) {
    return gender.toLowerCase() == 'male' ? "🧸 Boy" : "🌸 Girl";
  }

  // Get species emoji
  String _getSpeciesEmoji(String species) {
    String emoji = "🐾";
    if (species.toLowerCase().contains('dog')) emoji = "🐶";
    if (species.toLowerCase().contains('cat')) emoji = "🐱";
    if (species.toLowerCase().contains('bird')) emoji = "🐦";
    if (species.toLowerCase().contains('rabbit')) emoji = "🐰";
    if (species.toLowerCase().contains('hamster')) emoji = "🐹";
    if (species.toLowerCase().contains('fish')) emoji = "🐠";
    return emoji;
  }

  Future<void> _loadPetPhotos() async {
    try {
      if (widget.pet.photo_id.isNotEmpty) {
        List<String> photoUrls = [];
        
        // Load all photo URLs
        for (String photoId in widget.pet.photo_id) {
          final photoUrl = await _photoService.getPhotoUrl(photoId);
          if (photoUrl != null) {
            photoUrls.add(photoUrl);
          }
        }
        
        if (mounted) {
          setState(() {
            _photoUrls = photoUrls;
            _primaryPhotoUrl = photoUrls.isNotEmpty ? photoUrls.first : null;
          });
        }
      }
    } catch (e) {
      print('Error loading pet photos: $e');
    }
  }
  
  void _navigateToPhoto(int index) {
    if (index >= 0 && index < _photoUrls.length) {
      setState(() {
        _currentPhotoIndex = index;
        _primaryPhotoUrl = _photoUrls[index];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: _isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9E80)),
                      strokeWidth: 6.0,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Finding cute pets...",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF725F63),
                    ),
                  )
                ],
              ),
            )
          : SafeArea(
              child: Container(
                width: screenWidth,
                height: MediaQuery.of(context).size.height,
                clipBehavior: Clip.none, // Changed from antiAlias to none
                decoration: BoxDecoration(color: const Color(0xFFFEF5F0)),
                child: Stack(
                  clipBehavior: Clip.none, // Prevent clipping of stack children
                  children: [
                    // Main content container
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: NotificationListener<ScrollNotification>(
                        // Add a notification listener to handle scroll events
                        onNotification: (scrollNotification) {
                          // We can track scroll position here if needed
                          return false; // Return false to allow the notification to continue to bubble up
                        },
                        child: ClipRRect(
                          // Clip contents to prevent overflow issues
                          child: SingleChildScrollView(
                            // Use AlwaysScrollableScrollPhysics to ensure scroll works in all directions
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Container(
                              width: screenWidth,
                              decoration: BoxDecoration(color: const Color(0xFFFEF5F0)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pet image at the top - constrain width explicitly
                                  Container(
                                    height: 450,
                                    width: screenWidth,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(40),
                                        bottomRight: Radius.circular(40),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 15,
                                          offset: Offset(0, 10),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(40),
                                        bottomRight: Radius.circular(40),
                                      ),
                                      child: _primaryPhotoUrl != null
                                        ? Image.network(
                                            _primaryPhotoUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder: (context, error, stackTrace) => 
                                              Image.network(
                                                'https://via.placeholder.com/400x500?text=No+Image',
                                                fit: BoxFit.cover,
                                              ),
                                          )
                                        : Image.asset(
                                            'assets/photos/default_pet.png',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                    ),
                                  ),
                                  
                                  // Remove the thumbnail gallery and instead add a Photos section below
                                  
                                  // Pet name and info section
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(16, 30, 16, 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Name and age - add flexible to prevent overflow
                                        Flexible(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${widget.pet.pet_name}',
                                                style: GoogleFonts.catamaran(
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF473C38),
                                                  height: 1,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 5),
                                              // Fix the age display text in the UI
                                              Text(
                                                '${_calculateAge(widget.pet.birthdate)}',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF8E7A72),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                  
                                  // Address full - add overflow handling
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFE0B2),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Color(0xFFFF8A65),
                                            size: 16,
                                          ),
                                          SizedBox(width: 2),
                                          Flexible(
                                            child: Text(
                                              widget.pet.address.split(',').first,
                                              style: GoogleFonts.nunito(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFFF8A65),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Organization section
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
                                                : AssetImage('assets/photos/org_logo_default.png') as ImageProvider,
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
                                  
                                  // Divider
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                    child: Divider(height: 1, color: Colors.grey.shade300),
                                  ),
                                  
                                  // Description header
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        Icon(Icons.pets, color: Color(0xFFFF8A65)),
                                        SizedBox(width: 8),
                                        Text(
                                          'About ${widget.pet.pet_name}',
                                          style: GoogleFonts.catamaran(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF5D4037),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Description text
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(16, 15, 16, 20),
                                    child: Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        widget.pet.description,
                                        style: GoogleFonts.nunito(
                                          fontSize: 16,
                                          height: 1.5,
                                          color: Color(0xFF5D4037),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Quick info section
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Color(0xFFFF8A65)),
                                        SizedBox(width: 8),
                                        Text(
                                          'Quick Facts',
                                          style: GoogleFonts.catamaran(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF5D4037),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Basic info cards - make them more responsive
                                    // Breed row
                                    Padding(
                                    padding: EdgeInsets.fromLTRB(16, 15, 16, 8),
                                    child: Row(
                                      children: [
                                      _infoCard(
                                        "🐾 ${widget.pet.breed}",
                                        "Breed"
                                      ),
                                      ],
                                    ),
                                    ), 
                                    // Height and weight row
                                    Padding(
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 15),
                                    child: Row(
                                      children: [
                                      _infoCard(
                                        "${_getSpeciesEmoji(widget.pet.species)} ${widget.pet.species}",
                                          "Species"
                                      ),
                                      SizedBox(width: 8),
                                      _infoCard(
                                        _getGenderEmoji(widget.pet.gender),
                                          "Gender"
                                      ),
                                      ],
                                    ),
                                    ),
                                  // Add Photos Gallery section before Medical Details
                                  if (_photoUrls.length > 1) ...[
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(16, 15, 16, 15),
                                      child: Row(
                                        children: [
                                          Icon(Icons.photo_library, color: Color(0xFFFF8A65)),
                                          SizedBox(width: 8),
                                          Text(
                                            'More Photos',
                                            style: GoogleFonts.catamaran(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF5D4037),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Vertical photo gallery
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                                      child: Column(
                                        children: [
                                          for (int i = 1; i < _photoUrls.length; i++)
                                            Container(
                                              margin: EdgeInsets.only(bottom: 16),
                                              width: screenWidth - 32,
                                              height: 250,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 10,
                                                    offset: Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(20),
                                                child: Image.network(
                                                  _photoUrls[i],
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  errorBuilder: (context, error, stackTrace) => 
                                                    Container(
                                                      color: Colors.grey[200],
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey[400],
                                                          size: 60,
                                                        ),
                                                      ),
                                                    ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  // Medical info section
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(16, 15, 16, 15),
                                    child: Row(
                                      children: [
                                        Icon(Icons.medical_services_outlined, color: Color(0xFFFF8A65)),
                                        SizedBox(width: 8),
                                        Text(
                                          'Medical Details',
                                          style: GoogleFonts.catamaran(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF5D4037),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Medical info table - adjust padding
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 30),
                                    child: Container(
                                      padding: EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          _medicalInfoRow(
                                            "Vaccination Status",
                                            _getVaccinationStatusEmoji(widget.pet.vaccination_status)
                                          ),
                                          Divider(height: 20, color: Colors.grey.shade200),
                                          _medicalInfoRow(
                                            "Neutered/Spayed", 
                                            widget.pet.is_neutered_or_spayed ? "✅ Yes" : "❌ No"
                                          ),
                                          Divider(height: 20, color: Colors.grey.shade200),
                                          _medicalInfoRow(
                                            "Acquisition", 
                                            widget.pet.acquisition_type.toString().split('.').last
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Bottom space for buttons
                                  SizedBox(height: 100), // Increased to avoid bottom overflow
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    //Back button
                    // if (widget.showInteractions)
                    //   Positioned(
                    //     left: 20,
                    //     top: 40,
                    //     child: Container(
                    //       decoration: BoxDecoration(
                    //         color: Colors.white.withOpacity(0.7),
                    //         shape: BoxShape.circle,
                    //       ),
                    //       child: IconButton(
                    //         icon: Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
                    //         onPressed: () => Navigator.of(context).pop(),
                    //       ),
                    //     ),
                    //   ),
                    
                    // Action buttons (like/dislike)
                  //   if (widget.showInteractions)
                  //     Positioned(
                  //       left: 0,
                  //       right: 0,
                  //       bottom: 0,
                  //       child: Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           // Dislike button
                  //           Material(
                  //             color: Colors.white,
                  //             elevation: 8,
                  //             shadowColor: Colors.black.withOpacity(0.2),
                  //             borderRadius: BorderRadius.circular(50),
                  //             child: InkWell(
                  //               onTap: widget.onSwipeLeft,
                  //               borderRadius: BorderRadius.circular(50),
                  //               child: Container(
                  //                 width: 65,
                  //                 height: 0,
                  //                 decoration: BoxDecoration(
                  //                   shape: BoxShape.circle,
                  //                 ),
                  //                 child: Icon(
                  //                   Icons.close,
                  //                   color: Colors.red.shade400,
                  //                   size: 34,
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //           SizedBox(width: 20),
                  //           // Like button
                  //           ScaleTransition(
                  //             scale: _scaleAnimation,
                  //             child: Material(
                  //               color: Colors.white,
                  //               elevation: 8,
                  //               shadowColor: Colors.black.withOpacity(0.2),
                  //               borderRadius: BorderRadius.circular(50),
                  //               child: InkWell(
                  //                 onTap: () {
                  //                   _pulseHeart();
                  //                   widget.onSwipeRight();
                  //                 },
                  //                 borderRadius: BorderRadius.circular(50),
                  //                 child: Container(
                  //                   width: 65,
                  //                   height: 65,
                  //                   decoration: BoxDecoration(
                  //                     shape: BoxShape.circle,
                  //                   ),
                  //                   child: Icon(
                  //                     Icons.favorite,
                  //                     color: Colors.pink.shade400,
                  //                     size: 34,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  // 
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _infoCard(String value, String label) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 4), // Added margin for spacing
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 4), // Reduced horizontal padding
          child: Column(
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D4037),
                ),
                overflow: TextOverflow.ellipsis, // Add overflow handling
              ),
              SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12, // Reduced font size
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _medicalInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
        ),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Color(0xFF8D6E63),
            ),
            overflow: TextOverflow.ellipsis, // Add overflow handling
          ),
        ),
      ],
    );
  }

  // Helper methods
  Future<void> _loadOrganizationDetails() async {
    try {
      // For now, we'll just get the first organization as a placeholder
      final orgs = await _organizationService.fetchAllOrganizations();
      if (orgs.isNotEmpty && mounted) {
        setState(() {
          _organization = orgs.first;
        });
      }
    } catch (e) {
      print('Error loading organization: $e');
    }
  }
}
