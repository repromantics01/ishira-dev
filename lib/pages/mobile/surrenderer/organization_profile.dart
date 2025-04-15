import 'package:flutter/material.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/surrender_pet.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';

class OrganizationProfile extends StatefulWidget {
  final Organization organization;

  const OrganizationProfile({super.key, required this.organization});

  @override
  State<OrganizationProfile> createState() => _OrganizationProfileState();
}

class _OrganizationProfileState extends State<OrganizationProfile> {
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  
  final List<String> _photoUrls = [];
  bool _isLoading = true;
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    // Remove logo from hero section - only use photos from photo_ids
    if (widget.organization.photo_ids != null && widget.organization.photo_ids!.isNotEmpty) {
      final additionalPhotos = await _photoService.getOrganizationPhotoUrls(
        widget.organization.photo_ids
      );
      
      if (additionalPhotos.isNotEmpty) {
        if (mounted) {
          setState(() {
            _photoUrls.addAll(additionalPhotos);
          });
        }
      }
    }

    if (_photoUrls.isEmpty && widget.organization.logo_url != null) {
      // Fallback to logo only if no photos are available
      setState(() {
        _photoUrls.add(widget.organization.logo_url!);
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rectangleWidth = screenWidth - 48; 

    // Add debugging for the organization object
    print('Organization data: ${widget.organization.toJson()}');
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFFFEF5F0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero image carousel at the top
              Stack(
                children: [
                  Container(
                    height: 390,
                    decoration: BoxDecoration(
                      color: Color(0xFFD8CBCB), // Fallback color
                    ),
                    child: _isLoading 
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF725F63)),
                          ),
                        )
                      : _photoUrls.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pets,
                                  size: 100,
                                  color: Color(0xFF725F63),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No images available',
                                  style: TextStyle(
                                    color: Color(0xFF725F63),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
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
                                  print('Error loading image: $error');
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Color(0xFF725F63),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Image failed to load',
                                          style: TextStyle(
                                            color: Color(0xFF725F63),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF725F63)),
                                    ),
                                  );
                                },
                              );
                            },
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
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Image pagination dots - now reflecting actual number of photos
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _photoUrls.isEmpty
                        ? []
                        : List.generate(
                            _photoUrls.length,
                            (index) => GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 8,
                                height: 8,
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == _currentPhotoIndex
                                      ? Color(0xFF686868)
                                      : Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ],
              ),

              // Organization name and logo
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
                            widget.organization.org_name,
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              height: 0.9,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Color(0xFF725F63),
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Display location on first line
                                    Text(
                                      "${widget.organization.location ?? 'Location not specified'}",
                                      style: TextStyle(
                                        color: const Color(0xFF545454),
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    // Display address on second line if available
                                    if (widget.organization.address != null && 
                                        widget.organization.address!.isNotEmpty) 
                                      Text(
                                        widget.organization.address!,
                                        style: TextStyle(
                                          color: const Color(0xFF545454),
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Ratings (placeholder)
                          Row(
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    index < 4 ? Icons.star : Icons.star_border,
                                    color: Color(0xFFFFCD3C),
                                    size: 24,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                "(4.5)",
                                style: TextStyle(
                                  color: const Color(0xFF545454),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Organization logo circle with proper error handling
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x8E725F63),
                          width: 1,
                        ),
                        color: Color(0xFFD8CBCB), // Fallback color
                      ),
                      child: widget.organization.logo_url != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(35),
                              child: Image.network(
                                widget.organization.logo_url!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading logo in circle: $error');
                                  return Center(
                                    child: Icon(
                                      Icons.pets,
                                      size: 30,
                                      color: Color(0xFF725F63),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.pets,
                                size: 30,
                                color: Color(0xFF725F63),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // About Us section with minimum height and consistent width
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                              widget.organization.about ?? 'No information provided.',
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
                                'About Us',
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

              //SizedBox(height: 15),

              // Mission section with consistent width and non-wrapping title
              Column(
                children: [
                  Container(
                    width: rectangleWidth - 48, // Account for the existing padding
                    child: Text(
                      'Our Mission',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis, // Prevent wrapping
                      maxLines: 1, // Force single line
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
                        // Pink rectangle behind the mission box with consistent width
                        Positioned(
                          bottom: -25,
                          left: -15,
                          right: -15,
                          child: Container(
                            height: 150,
                            width: rectangleWidth,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECC8C0),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        // Mission description box with consistent width
                        Container(
                          width: rectangleWidth,
                          constraints: BoxConstraints(
                            minHeight: 100, // Minimum height for mission box
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 25, 16, 25),
                          child: Text(
                            widget.organization.mission ??
                              'No mission statement provided.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40),

              // Services section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Services Offered',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (widget.organization.services != null &&
                        widget.organization.services!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.organization.services!
                            .map((service) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFEDEDED),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(250),
                                    ),
                                  ),
                                  child: Text(
                                    service.toUpperCase(),
                                    style: TextStyle(
                                      color: const Color(0xFF545454),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 1.25,
                                    ),
                                  ),
                                ))
                            .toList(),
                      )
                    else
                      Text(
                        'No services specified.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Operating hours section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operating Hours',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Weekdays: ${widget.organization.weekday_hours ?? 'Not specified'}',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Weekends: ${widget.organization.weekend_hours ?? 'Not specified'}',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Contact section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact/Visit Us',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 20),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Teal rectangle behind the contact box (positioned to lower right)
                        Positioned(
                          bottom: -15,
                          right: -15,
                          child: Container(
                            height: 120,
                            width: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB6CBCA),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        // Contact information box
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.organization.email != null)
                                _buildContactItem(
                                  Icons.email_outlined,
                                  'Email',
                                  widget.organization.email!,
                                ),
                              if (widget.organization.landline != null)
                                _buildContactItem(
                                  Icons.phone,
                                  'Landline',
                                  widget.organization.landline!,
                                ),
                              // Contact numbers section - improved with icons and proper parsing
                              if (widget.organization.contact_numbers != null &&
                                  widget.organization.contact_numbers!.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contact Number/s:',
                                      style: TextStyle(
                                        color: const Color(0xFF545454),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ...widget.organization.contact_numbers!
                                      .map((contactEntry) {
                                        // Parse contact entry in format "label: number"
                                        final parts = contactEntry.split(':');
                                        if (parts.length < 2) return _buildContactItem(
                                          Icons.phone_android,
                                          'Contact',
                                          contactEntry.trim(),
                                        );
                                        
                                        return _buildContactItem(
                                          _getContactIcon(parts[0].trim().toLowerCase()),
                                          parts[0].trim(),
                                          parts.sublist(1).join(':').trim(),
                                        );
                                      })
                                      .toList(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30),

                    // Social Media section - with proper icons and styling
                    Builder(
                      builder: (context) {
                        // Debug print for social media links
                        print('Social media links: ${widget.organization.social_media_links}');
                        
                        if (widget.organization.social_media_links == null || 
                            widget.organization.social_media_links!.isEmpty) {
                          print('No social media links found or empty list');
                          return SizedBox.shrink(); // Don't show section
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect With Us',
                              style: TextStyle(
                                color: const Color(0xFF545454),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              height: 90,
                              child: Center(
                                child: ListView(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  children: _buildSocialMediaIcons(widget.organization),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Action buttons
              Center(
                child: Column(
                  children: [
                    Container(
                      width: screenWidth * 0.6,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement send message functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFCECB),
                          foregroundColor: const Color(0xFF1E2C2B),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFF8B8B8B),
                            ),
                            borderRadius: BorderRadius.circular(250),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'SEND MESSAGE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.25,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: screenWidth * 0.6,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to surrender pet page with organization ID
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => SurrenderForm(
                                organizationId: widget.organization.org_id,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB6CBCA),
                          foregroundColor: const Color(0xFF1E2B2B),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0xFF8B8B8B),
                            ),
                            borderRadius: BorderRadius.circular(250),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'SURRENDER HERE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSimpleSocialMediaIcons(Organization organization) {
    // Debugging
    if (organization.social_media_links == null) {
      print('Social media links are null');
      return [];
    }
    
    if (organization.social_media_links!.isEmpty) {
      print('Social media links list is empty');
      return [];
    }
    
    // Print all entries for debugging
    organization.social_media_links!.forEach((entry) {
      print('Social link: $entry');
    });

    final socialIcons = {
      'facebook': Icons.facebook,
      'instagram': Icons.camera_alt,
      'twitter': Icons.flutter_dash,
      'x': Icons.flutter_dash,
      'tiktok': Icons.music_note,
      'youtube': Icons.play_circle_filled,
      'linkedin': Icons.link,
      'pinterest': Icons.push_pin,
    };

    List<Widget> socialWidgets = [];

    for (String entry in organization.social_media_links!) {
      // Parse the platform and URL from the string (format: "platform: url")
      List<String> parts = entry.split(':');
      if (parts.length < 2) continue; // Skip malformed entries
      
      final platform = parts[0].trim().toLowerCase();
      final url = parts.sublist(1).join(':').trim(); // Join the rest in case URL contains colons
      
      // Skip empty URLs
      if (url.isEmpty) {
        print('Empty URL for platform: $platform');
        continue;
      }
      
      print('Adding icon for: $platform');
      
      socialWidgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: InkWell(
          onTap: () {
            // Future: Add URL launching functionality
            print('Would launch URL: $url');
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: Icon(
                  socialIcons[platform] ?? Icons.link,
                  color: Color(0xFF725F63),
                  size: 24,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _capitalizeFirstLetter(platform),
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ));
    }

    // If no valid social links were found
    if (socialWidgets.isEmpty) {
      return [
        Center(
          child: Text(
            'No social media links available',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        )
      ];
    }

    return socialWidgets;
  }
  
  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  // Helper method to build contact items with icons
  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF725F63),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to determine contact icon based on label
  IconData _getContactIcon(String labelLower) {
    if (labelLower.contains('mobile') || 
        labelLower.contains('phone') || 
        labelLower.contains('cell')) {
      return Icons.phone_android;
    } else if (labelLower.contains('emergency')) {
      return Icons.emergency;
    } else if (labelLower.contains('fax')) {
      return Icons.print;
    } else if (labelLower.contains('office')) {
      return Icons.business;
    } else if (labelLower.contains('main')) {
      return Icons.phone;
    }
    return Icons.contact_phone;
  }

  List<Widget> _buildSocialMediaIcons(Organization organization) {
    if (organization.social_media_links == null || 
        organization.social_media_links!.isEmpty) {
      return [];
    }
    
    // Map platform names to their corresponding icons and colors
    final socialIcons = {
      'facebook': Icons.facebook,
      'instagram': Icons.camera_alt,
      'twitter': Icons.flutter_dash,
      'x': Icons.flutter_dash,
    };
    
    // Map platform names to brand colors
    final socialColors = {
      'facebook': const Color(0xFF1877F2),
      'instagram': const Color(0xFFE4405F),
      'twitter': const Color(0xFF1DA1F2),
      'x': const Color(0xFF000000),
      'tiktok': const Color(0xFF000000),
      'youtube': const Color(0xFFFF0000),
      'linkedin': const Color(0xFF0A66C2),
      'pinterest': const Color(0xFFE60023),
      'web': const Color(0xFF34A853),
      'website': const Color(0xFF34A853),
    };

    List<Widget> socialWidgets = [];

    for (String entry in organization.social_media_links!) {
      List<String> parts = entry.split(':');
      if (parts.length < 2) continue; // Skip malformed entries
      
      final platform = parts[0].trim().toLowerCase();
      final url = parts.sublist(1).join(':').trim();
      
      if (url.isEmpty) continue;
      
      socialWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: socialColors[platform] ?? const Color(0xFF725F63),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    socialIcons[platform] ?? Icons.link,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    // TODO: Implement URL launching
                    print('Would launch URL: $url');
                  },
                ),
              ),
              SizedBox(height: 6),
              Text(
                _capitalizeFirstLetter(platform),
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (socialWidgets.isEmpty) {
      return [
        Center(
          child: Text(
            'No social media links available',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        )
      ];
    }

    return socialWidgets;
  }
}
