import 'package:flutter/material.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/surrender_pet.dart';

class OrganizationProfile extends StatelessWidget {
  final Organization organization;

  const OrganizationProfile({Key? key, required this.organization})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Debug: Print logo URL to verify it's not null or empty
    print('Organization logo URL: ${organization.logo_url}');

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFFFEF5F0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero image at the top with better error handling
              Stack(
                children: [
                  Container(
                    height: 390,
                    decoration: BoxDecoration(
                      color: Color(0xFFD8CBCB), // Fallback color
                    ),
                    child: organization.logo_url != null
                        ? Image.network(
                            organization.logo_url!,
                            width: double.infinity,
                            height: 390,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Log error and show placeholder
                              print('Error loading organization logo: $error');
                              return Center(
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
                                      'Image not available',
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
                          )
                        : Center(
                            child: Icon(
                              Icons.pets,
                              size: 100,
                              color: Color(0xFF725F63),
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
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Image pagination dots
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 1
                                ? Color(0xFF686868)
                                : Colors.black.withOpacity(0.1),
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
                            organization.org_name,
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
                                child: Text(
                                  "${organization.location ?? 'Location not specified'}${organization.address != null ? ', ${organization.address}' : ''}",
                                  style: TextStyle(
                                    color: const Color(0xFF545454),
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                      child: organization.logo_url != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(35),
                              child: Image.network(
                                organization.logo_url!,
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
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEDED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 40, 16, 25),
                            child: Text(
                              organization.about ?? 'No information provided.',
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

              // Mission section
              Column(
                children: [
                  Text(
                  'Our Mission',
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Pink rectangle behind the mission box
                        Positioned(
                          bottom: -25,
                          left: -15,
                          right: -15,
                          child: Container(
                            height: 150,
                            width: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECC8C0),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        // Mission description box
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 25, 16, 25),
                          child: Text(
                            organization.mission ??
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
                    if (organization.services != null &&
                        organization.services!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: organization.services!
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
                        'Weekdays: ${organization.weekday_hours ?? 'Not specified'}',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Weekends: ${organization.weekend_hours ?? 'Not specified'}',
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
                        // Teal rectangle behind the contact box (positioned to lower left)
                        Positioned(
                          bottom: -15,
                          left: -15,
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
                              if (organization.email != null)
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Email: ',
                                        style: TextStyle(
                                          color: const Color(0xFF545454),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: organization.email,
                                        style: TextStyle(
                                          color: const Color(0xFF545454),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 8),
                              if (organization.landline != null)
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Landline: ',
                                        style: TextStyle(
                                          color: const Color(0xFF545454),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: organization.landline,
                                        style: TextStyle(
                                          color: const Color(0xFF545454),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 8),
                              // Contact numbers
                              if (organization.contact_numbers != null &&
                                  organization.contact_numbers!.isNotEmpty)
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
                                    ...organization.contact_numbers!.entries
                                        .map((entry) => Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16, top: 4),
                                              child: Text(
                                                "${entry.key}: ${entry.value}",
                                                style: TextStyle(
                                                  color: const Color(0xFF545454),
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30),

                    // Social Media section
                    if (organization.social_media_links != null &&
                        organization.social_media_links!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              'Social Media',
                              style: TextStyle(
                                color: const Color(0xFF545454),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildSocialMediaIcons(organization),
                          ),
                        ],
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
                                organizationId: organization.org_id,
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

  List<Widget> _buildSocialMediaIcons(Organization organization) {
    if (organization.social_media_links == null) {
      return [];
    }

    final socialIcons = {
      'facebook': Icons.facebook,
      'instagram': Icons.camera_alt,
      'twitter': Icons.flutter_dash, // Using flutter_dash as Twitter/X
      'x': Icons.flutter_dash,
      'tiktok': Icons.music_note,
      'youtube': Icons.play_arrow,
    };

    final socialLabels = {
      'facebook': 'Facebook',
      'instagram': 'Instagram',
      'twitter': 'Twitter',
      'x': 'X',
      'tiktok': 'TikTok',
      'youtube': 'YouTube',
    };

    List<Widget> socialWidgets = [];

    organization.social_media_links!.forEach((platform, url) {
      final lowercasePlatform = platform.toLowerCase();

      socialWidgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: Icon(
                socialIcons[lowercasePlatform] ?? Icons.link,
                color: Color(0xFF725F63),
              ),
            ),
            SizedBox(height: 8),
            Text(
              socialLabels[lowercasePlatform] ?? platform,
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ));
    });

    return socialWidgets;
  }
}
