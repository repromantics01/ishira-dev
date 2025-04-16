import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/organization_profile.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart'; // Add this import

class OrganizationsListing extends StatefulWidget {
  final bool showAppBar;

  const OrganizationsListing({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  _OrganizationsListingState createState() => _OrganizationsListingState();
}

class _OrganizationsListingState extends State<OrganizationsListing> {
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  final FirebasePhotoService _photoService = FirebasePhotoService(); // Add photo service
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Organization> _organizations = [];
  String _searchQuery = '';
  // Map to store organization photos for thumbnails
  final Map<String, String> _organizationThumbnails = {};

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrganizations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the new fetchAllOrganizations method
      final organizations = await _organizationService.fetchAllOrganizations();
      
      print("Fetched ${organizations.length} organizations"); // Debug output
      print("First organization: ${organizations.isNotEmpty ? organizations[0].org_name : 'none'}");
      
      if (mounted) {
        setState(() {
          _organizations = organizations;
          _isLoading = false;
        });
      }
      
      // After loading organizations, fetch their first photo for thumbnails
      _loadOrganizationThumbnails(organizations);

    } catch (e) {
      print('Error fetching organizations: $e');
      
      // Fallback to direct Firestore query if the service fails
      try {
        final querySnapshot = await FirebaseFirestore.instance.collection('organization').get();
        
        print("Fallback fetched ${querySnapshot.docs.length} organizations"); // Debug output
        
        final organizations = querySnapshot.docs.map((doc) {
          print("Raw data: ${doc.data()}"); // Debug output
          try {
            return Organization.fromJson(doc.data());
          } catch (jsonError) {
            print('Error parsing organization data: $jsonError for doc ${doc.id}');
            return null;
          }
        })
        .where((org) => org != null)
        .cast<Organization>()
        .toList();
        
        if (mounted) {
          setState(() {
            _organizations = organizations;
            _isLoading = false;
          });
        }
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        
        // Uncomment mock data as a last resort
        if (mounted) {
          setState(() {
            _organizations = _getMockOrganizations();
            _isLoading = false;
          });
        }
      }
    }
  }

  // New method to load organization thumbnails
  Future<void> _loadOrganizationThumbnails(List<Organization> organizations) async {
    for (var org in organizations) {
      String? thumbnailUrl;
      
      // First try to get a photo from photo_ids if available
      if (org.photo_ids != null && org.photo_ids!.isNotEmpty) {
        thumbnailUrl = await _photoService.getPhotoUrl(org.photo_ids![0]);
      }
      
      // If no photo found, fall back to the logo
      if (thumbnailUrl == null) {
        thumbnailUrl = org.logo_url;
      }
      
      if (thumbnailUrl != null && mounted) {
        setState(() {
          _organizationThumbnails[org.org_id] = thumbnailUrl!;
        });
      }
    }
  }

  List<Organization> _getMockOrganizations() {
    return [
      Organization(
        org_id: "1",
        org_name: "Happy Paws Rescue",
        org_proof_of_validation: "proof_url",
        date_created: DateTime.now(),
        admin_ids: ["admin1"],
        isVerified: true,
        location: "Manila, Philippines",
        address: "123 Main Street, Manila",
        about: "A shelter dedicated to rescuing and rehoming abandoned pets.",
        mission: "To find loving homes for all animals in need",
        services: ["Adoption", "Rescue", "Veterinary Care"],
        weekday_hours: "9:00 AM - 5:00 PM",
        weekend_hours: "10:00 AM - 3:00 PM",
        email: "contact@happypaws.org",
        landline: "(02) 8123-4567",
        logo_url: "https://placehold.co/70x70?text=HP",
      ),
      Organization(
        org_id: "2",
        org_name: "Second Chance Animal Shelter",
        org_proof_of_validation: "proof_url",
        date_created: DateTime.now(),
        admin_ids: ["admin2"],
        isVerified: true,
        location: "Quezon City, Philippines",
        address: "456 Animal Road, Quezon City",
        about: "Providing care and finding homes for abandoned and surrendered animals.",
        logo_url: "https://placehold.co/70x70?text=SC",
      ),
      Organization(
        org_id: "3",
        org_name: "Furever Homes",
        org_proof_of_validation: "proof_url",
        date_created: DateTime.now(),
        admin_ids: ["admin3"],
        isVerified: true,
        location: "Makati, Philippines",
        about: "Dedicated to finding loving homes for surrendered pets.",
        logo_url: "https://placehold.co/70x70?text=FH",
      ),
    ];
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Organization> _getFilteredOrganizations() {
    if (_searchQuery.isEmpty) {
      return _organizations;
    }

    final queryLower = _searchQuery.toLowerCase();
    return _organizations.where((org) {
      final nameLower = org.org_name.toLowerCase();
      final locationLower = (org.location ?? '').toLowerCase();
      
      return nameLower.contains(queryLower) || locationLower.contains(queryLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show app bar based on how we were navigated to
    bool isDirectNavigation = ModalRoute.of(context)?.settings.name != null;
    bool shouldShowAppBar = widget.showAppBar && isDirectNavigation;
    
    final filteredOrganizations = _getFilteredOrganizations();
    
    // Add debug print to check if we have organizations at build time
    print("Building UI with ${filteredOrganizations.length} filtered organizations");
    
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      // Only show app bar if directly navigated to (not in tab)
      appBar: shouldShowAppBar ? AppBar(
        title: Text(
          'Organizations',
          style: TextStyle(
            color: const Color(0xFF545454),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFEF5F0),
        elevation: 0,
        iconTheme: IconThemeData(
          color: Color(0xFF725F63),
        ),
      ) : null,
      body: _isLoading
          ? Container(
              color: const Color(0xFFFEF5F0),
              child: Center(child: CircularProgressIndicator()),
            )
          : Container(
              color: const Color(0xFFFEF5F0),
              child: CustomScrollView(
                slivers: [
                  // Title Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: Text(
                        'Discover',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 28,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  
                  // Search Bar Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                      child: Row(
                        children: [
                          // Search input with icon
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
                                  hintText: 'Search for organizations',
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
                                            _onSearch('');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, 
                                    horizontal: 12
                                  ),
                                ),
                                onChanged: _onSearch,
                              ),
                            ),
                          ),
                          
                          // Filter/Sort button
                          Container(
                            margin: EdgeInsets.only(left: 8),
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
                              onPressed: () {
                                _showFilterOptions();
                              },
                              tooltip: 'Filter & Sort',
                              constraints: BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Organization list
                  filteredOrganizations.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No organizations found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final org = filteredOrganizations[index];
                                return Card(
                                  elevation: 3,
                                  margin: EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 150,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFD8CBCB),
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                        ),
                                        child: Center(
                                          child: _organizationThumbnails.containsKey(org.org_id)
                                            ? Image.network(
                                                _organizationThumbnails[org.org_id]!,
                                                width: double.infinity,
                                                height: 150,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => 
                                                  Icon(Icons.pets, size: 60, color: Color(0xFF725F63)),
                                              )
                                            : org.logo_url != null 
                                              ? Image.network(
                                                  org.logo_url!,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) => 
                                                    Icon(Icons.pets, size: 60, color: Color(0xFF725F63)),
                                                )
                                              : Icon(
                                                  Icons.pets,
                                                  size: 60,
                                                  color: Color(0xFF725F63),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              org.org_name,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF545454),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: Color(0xFF725F63),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  org.location ?? 'Location not specified',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              org.about ?? 'No description available',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => OrganizationProfile(
                                                          organization: org,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    side: BorderSide(
                                                        color: Color(0xFF725F63)),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'View Details',
                                                    style: TextStyle(
                                                      color: Color(0xFF725F63),
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    // TODO: Implement contacting organization
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Color(0xFF725F63),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Contact',
                                                    style: TextStyle(
                                                      color: Colors.white,
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
                                );
                              },
                              childCount: filteredOrganizations.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
  
  void _showFilterOptions() {
    // Fix bottom overflow by using isScrollControlled: true and adding padding
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important to prevent overflow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) {
        return Padding(
          // Add bottom padding to account for the keyboard and bottom system UI
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20
          ),
          child: SingleChildScrollView( // Wrap in SingleChildScrollView to handle small screens
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
                        'Sort by:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF545454),
                        ),
                      ),
                      // Add close button for better UX
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                   //Sort options
                  SizedBox(height: 8),
                  _buildFilterOption('Name (A-Z)', Icons.sort_by_alpha),
                  _buildFilterOption('Location', Icons.location_on),
                  _buildFilterOption('Most Popular', Icons.trending_up),
                  
                  SizedBox(height: 16),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Apply filters
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
                  // Add padding at the bottom for iOS home indicator
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFilterOption(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          // TODO: Toggle filter option
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
                Icons.check_circle_outline,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
