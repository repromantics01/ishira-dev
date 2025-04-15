import 'package:flutter/material.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:pawsmatch/services/firebase_photo_service.dart';

class AdopterOrganizationProfile extends StatefulWidget {
  final Organization organization;

  const AdopterOrganizationProfile({Key? key, required this.organization})
      : super(key: key);

  @override
  _AdopterOrganizationProfileState createState() =>
      _AdopterOrganizationProfileState();
}

class _AdopterOrganizationProfileState
    extends State<AdopterOrganizationProfile> {
  final FirebasePhotoService _photoService = FirebasePhotoService();

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

    if (widget.organization.photo_ids != null &&
        widget.organization.photo_ids!.isNotEmpty) {
      final additionalPhotos = await _photoService
          .getOrganizationPhotoUrls(widget.organization.photo_ids);

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

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;

    try {
      final Uri url = Uri.parse(urlString);
      await url_launcher.launchUrl(url);
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rectangleWidth = screenWidth - 48; // 24px padding on each side

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFFFEF5F0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero image carousel
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF725F63)),
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
              // // About Us section with minimum height and consistent width
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
                              minHeight:
                                  150, // Minimum height for the "About" box
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEDED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 40, 16, 25),
                            child: Text(
                              widget.organization.about ??
                                  'No information provided.',
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
                                overflow:
                                    TextOverflow.ellipsis, // Prevent wrapping
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

              // Mission section with consistent width and non-wrapping title
              Column(
                children: [
                  Container(
                    width:
                        rectangleWidth - 48, // Account for the existing padding
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
                                  onTap: () => _launchURL(
                                      'mailto:${widget.organization.email}'),
                                ),
                              if (widget.organization.landline != null)
                                _buildContactItem(
                                  Icons.phone,
                                  'Landline',
                                  widget.organization.landline!,
                                  onTap: () => _launchURL(
                                      'tel:${widget.organization.landline}'),
                                ),
                              // Contact numbers section
                              if (widget.organization.contact_numbers != null &&
                                  widget
                                      .organization.contact_numbers!.isNotEmpty)
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
                                      if (parts.length < 2)
                                        return _buildContactItem(
                                          Icons.phone_android,
                                          'Contact',
                                          contactEntry.trim(),
                                          onTap: () => _launchURL(
                                              'tel:${contactEntry.trim()}'),
                                        );

                                      final label = parts[0].trim();
                                      final number =
                                          parts.sublist(1).join(':').trim();

                                      return _buildContactItem(
                                        _getContactIcon(label.toLowerCase()),
                                        label,
                                        number,
                                        onTap: () => _launchURL('tel:$number'),
                                      );
                                    }).toList(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30),

                    // Social Media section
                    Builder(
                      builder: (context) {
                        if (widget.organization.social_media_links == null ||
                            widget.organization.social_media_links!.isEmpty) {
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
                                  children: _buildSocialMediaIcons(
                                      widget.organization),
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

              // Send Message button for adopters
              Center(
                child: Container(
                  width: screenWidth * 0.6,
                  margin: EdgeInsets.only(bottom: 60),
                  child: ElevatedButton(
                    onPressed: () {
                      // Show message dialog
                      _showMessageDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF725F63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(250),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'SEND MESSAGE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.25,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageDialog(BuildContext context) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Message to ${widget.organization.org_name}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF725F63),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF725F63)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF725F63), width: 2),
                  ),
                ),
                maxLines: 6,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Process message sending here
                      Navigator.of(context).pop();
                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Message sent to ${widget.organization.org_name}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF725F63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Send Message'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build contact items with icons - added onTap parameter
  Widget _buildContactItem(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
                  onPressed: () => _launchURL(url),
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

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}
