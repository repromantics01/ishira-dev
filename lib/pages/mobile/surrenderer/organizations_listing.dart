import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationsListing extends StatefulWidget {
  final bool showAppBar;
  
  // Add showAppBar parameter with default value true
  const OrganizationsListing({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  _OrganizationsListingState createState() => _OrganizationsListingState();
}

class _OrganizationsListingState extends State<OrganizationsListing> {
  final List<Map<String, dynamic>> _organizations = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // This is a placeholder for actual data fetching
      // In a real app, you would fetch this data from Firestore
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay

      setState(() {
        _organizations.addAll([
          {
            'name': 'Happy Paws Rescue',
            'location': 'Manila, Philippines',
            'description':
                'A shelter dedicated to rescuing and rehoming abandoned pets.',
            'image': 'assets/photos/org1.jpg',
          },
          {
            'name': 'Second Chance Animal Shelter',
            'location': 'Quezon City, Philippines',
            'description':
                'Providing care and finding homes for abandoned and surrendered animals.',
            'image': 'assets/photos/org2.jpg',
          },
          {
            'name': 'Furever Homes',
            'location': 'Makati, Philippines',
            'description':
                'Dedicated to finding loving homes for surrendered pets.',
            'image': 'assets/photos/org3.jpg',
          },
        ]);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading organizations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show app bar based on how we were navigated to
    bool isDirectNavigation = ModalRoute.of(context)?.settings.name != null;
    bool shouldShowAppBar = widget.showAppBar && isDirectNavigation;
    
    return Scaffold(
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
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Color(0xFF725F63),
        ),
      ) : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _organizations.isEmpty
              ? Center(child: Text('No organizations found'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
                      child: SizedBox(
                        width: 300,
                        height: 35,
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
                    const SizedBox(height: 1),
                    
                    // Improved search bar with icons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                                            // TODO: Implement search clear logic
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, 
                                    horizontal: 12
                                  ),
                                ),
                                onChanged: (value) {
                                  // TODO: Implement search functionality
                                  setState(() {});
                                },
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
                                // TODO: Show filter/sort options
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
                    
                    const SizedBox(height: 16),
                    
                    // Organization list
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _organizations.length,
                        itemBuilder: (context, index) {
                          final org = _organizations[index];
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
                                    child: Icon(
                                      Icons.pets,
                                      size: 60,
                                      color: Color(0xFF725F63),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        org['name'],
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
                                            org['location'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        org['description'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () {
                                              // TODO: Implement viewing organization details
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: Color(0xFF725F63)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                              backgroundColor:
                                                  Color(0xFF725F63),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                      ),
                    ),
                  ],
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
