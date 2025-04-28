import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/widgets/logout_button.dart';

class ModeratorDashboard extends StatefulWidget {
  const ModeratorDashboard({super.key});

  @override
  _ModeratorDashboardState createState() => _ModeratorDashboardState();
}

class _ModeratorDashboardState extends State<ModeratorDashboard> {
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Organization> _unverifiedOrgs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedFilter = 'Verification Requests';

  @override
  void initState() {
    super.initState();
    _loadOrganizations(); // Renamed from _loadUnverifiedOrganizations
  }

  // Renamed and modified to handle different filters
  Future<void> _loadOrganizations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      List<Organization> organizations = [];
      
      // Load organizations based on selected filter
      if (_selectedFilter == 'Verification Requests') {
        // Get unverified and non-rejected organizations
        organizations = await _organizationService.getUnverifiedOrgs();
        print('Loaded ${organizations.length} verification requests');
      } else if (_selectedFilter == 'Verified Organizations') {
        // Get verified organizations
        organizations = await _organizationService.getOrganizationsByStatus(isVerified: true);
        print('Loaded ${organizations.length} verified organizations');
      }
      
      setState(() {
        _unverifiedOrgs = organizations; // Keep the variable name for now to avoid breaking other parts
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading organizations: $e');
      setState(() {
        _errorMessage = 'Error loading organizations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOrganization(Organization org) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Organization'),
        content: Text('Are you sure you want to verify ${org.org_name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C2BB),
            ),
            child: Text('Verify'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Update organization verification status
    try {
      final updatedOrg = org.copyWith(isVerified: true);
      await _organizationService.updateOrganization(org.org_id, updatedOrg);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${org.org_name} has been verified'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload organization list
      _loadOrganizations();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying organization: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add new method to reject organization verification
  Future<void> _rejectOrganization(Organization org) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Organization'),
        content: Text('Are you sure you want to reject ${org.org_name}\'s verification request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: Text('Reject'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Update organization rejection status
    try {
      // Add rejected field to organization
      final updatedOrg = org.copyWith(isRejected: true);
      await _organizationService.updateOrganization(org.org_id, updatedOrg);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${org.org_name}\'s verification request has been rejected'),
          backgroundColor: Colors.red[600],
        ),
      );
      
      // Reload organization list
      _loadOrganizations();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting organization: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              
              // Logo with refined styling
              Positioned(
                left: 79,
                top: 67, // Adjusted for better vertical positioning
                child: SizedBox(
                  width: 536,
                  height: 60, // Increased height for better appearance
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Paws',
                          style: TextStyle(
                            color: const Color(0xFF725F63),
                            fontSize: 96,
                            fontFamily: 'Cherry Bomb One',
                            fontWeight: FontWeight.w400,
                            height: 0.17,
                            letterSpacing: 1.2, // Add letter spacing
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'Match',
                          style: TextStyle(
                            color: const Color(0xFFE48C8A),
                            fontSize: 96,
                            fontFamily: 'Cherry Bomb One',
                            fontWeight: FontWeight.w400,
                            height: 0.17,
                            letterSpacing: 1.2, // Add letter spacing
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Moderator title with refined styling
              Positioned(
                left: 587,
                top: 99,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFCECB).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFE48C8A).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'MODERATOR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF725F63),
                      fontSize: 28,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5, // Add letter spacing
                    ),
                  ),
                ),
              ),
              
              // Page title with enhanced styling
              Positioned(
                left: 250,
                top: 186,
                child: Container(
                  width: 652,
                  height: 32,
                  child: Text(
                    _selectedFilter,
                    style: TextStyle(
                      color: const Color(0xFF636363),
                      fontSize: 36,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 0.44,
                      letterSpacing: 0.5, // Add slight letter spacing
                    ),
                  ),
                ),
              ),
              
              // Stylized subtitle text
              Positioned(
                left: 250,
                top: 215, // Position below the title
                child: Container(
                  width: 700,
                  child: Text(
                    _selectedFilter == 'Verification Requests' 
                      ? 'Review and approve organization verification requests' 
                      : 'Manage verified organizations',
                    style: TextStyle(
                      color: const Color(0xFF636363).withOpacity(0.7),
                      fontSize: 18,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              
              // Dropdown filter - Verification Requests
              Positioned(
                left: 250,
                top: 239,
                child: Container(
                  width: 202,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFFC5C6CC),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          underline: SizedBox(), // Remove underline
                          style: TextStyle(
                            color: const Color(0xFF8F9098),
                            fontSize: 14,
                            fontFamily: 'DM Sans', // Changed from 'Inter' to 'DM Sans'
                            fontWeight: FontWeight.w400,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedFilter = newValue;
                              });
                              _loadOrganizations(); // Reload with the new filter
                            }
                          },
                          items: ['Verification Requests', 'Verified Organizations']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Filter dropdown
              Positioned(
                left: 465,
                top: 239,
                child: Container(
                  width: 202,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFFC5C6CC),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: 'Filter',
                          isExpanded: true,
                          underline: SizedBox(), // Remove underline
                          style: TextStyle(
                            color: const Color(0xFF8F9098),
                            fontSize: 14,
                            fontFamily: 'DM Sans', // Changed from 'Inter' to 'DM Sans'
                            fontWeight: FontWeight.w400,
                          ),
                          onChanged: (String? newValue) {
                            // Implement filtering logic
                          },
                          items: ['Filter', 'Newest First', 'Oldest First', 'Organization Name']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Enhanced table background with shadow
              Positioned(
                left: 250,
                top: 339.07,
                child: Container(
                  width: 1115,
                  height: 577.93,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Enhanced table header with gradient
              Positioned(
                left: 250,
                top: 317,
                child: Container(
                  width: 1115,
                  height: 65.22,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFB0CCCA),
                        const Color(0xFFA5C1BF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  // Use a Row for better alignment of column headers
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 35),
                    child: Row(
                      children: [
                        // Organization Name
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Organization Name',
                            style: TextStyle(
                              color: const Color(0xFF3B3B3B),
                              fontSize: 20,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        // Date Requested
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'Date Requested',
                              style: TextStyle(
                                color: const Color(0xFF3B3B3B),
                                fontSize: 20,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        
                        // Status
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'Status',
                              style: TextStyle(
                                color: const Color(0xFF3B3B3B),
                                fontSize: 20,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        
                        // Action
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'Action',
                              style: TextStyle(
                                color: const Color(0xFF3B3B3B),
                                fontSize: 20,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Remove individual positioned column headers since we now have them in the container
              
              // Table content area with enhanced organization list - keep positioning
              Positioned(
                left: 250,
                top: 385,
                right: 219,
                bottom: 40,
                child: _isLoading
                  ? _buildLoadingIndicator()
                  : _errorMessage.isNotEmpty
                    ? _buildErrorMessage()
                    : _unverifiedOrgs.isEmpty
                      ? _buildEmptyState()
                      : _buildEnhancedOrganizationList(),
              ),
              
              // Modernized logout button
              Positioned(
                left: 1402,
                top: 79,
                child: Container(
                  width: 103,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFEF5F0),
                        const Color(0xFFF9EBE6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      width: 1,
                      color: const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            size: 20,
                            color: const Color(0xFF464646),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: const Color(0xFF464646),
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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
  
  // Enhanced loading indicator
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF34C2BB)),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            _selectedFilter == 'Verification Requests'
              ? 'Loading organization verification requests...'
              : 'Loading verified organizations...',
            style: TextStyle(
              color: const Color(0xFF545454),
              fontSize: 16,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Enhanced error message display
  Widget _buildErrorMessage() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Requests',
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 24,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(maxWidth: 500),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrganizations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C2BB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Enhanced empty state
  Widget _buildEmptyState() {
    String message = _selectedFilter == 'Verification Requests'
      ? 'There are no pending organization verification requests at this time.'
      : 'There are no verified organizations at this time.';
      
    return Center(
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedFilter == 'Verification Requests' 
                ? Icons.check_circle_outline
                : Icons.verified,
              size: 80,
              color: const Color(0xFF34C2BB),
            ),
            SizedBox(height: 24),
            Text(
              _selectedFilter == 'Verification Requests' 
                ? 'All Caught Up!'
                : 'No Verified Organizations',
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 28,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 24),
            OutlinedButton(
              onPressed: _loadOrganizations, // Updated from _loadUnverifiedOrganizations
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF34C2BB),
                side: BorderSide(color: const Color(0xFF34C2BB)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced organization list with formal, polished styling - improved alignment
  Widget _buildEnhancedOrganizationList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _unverifiedOrgs.length,
          itemBuilder: (context, index) {
            final org = _unverifiedOrgs[index];
            return Column(
              children: [
                // Organization row with consistent alignment to match headers
                Container(
                  height: 72,
                  padding: EdgeInsets.symmetric(horizontal: 35), // Match header padding
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : Color(0xFFFAFAFA),
                  ),
                  child: Row(
                    children: [
                      // Organization name with logo placeholder - align with header
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            // Small logo or placeholder
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E5E5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD5D5D5),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: org.logo_url != null && org.logo_url!.isNotEmpty
                                  ? Image.network(
                                      org.logo_url!,
                                      fit: BoxFit.cover,
                                      // Improved error handling for image loading
                                      errorBuilder: (context, error, stackTrace) {
                                        print("Error loading logo for ${org.org_name}: $error");
                                        return Icon(
                                          Icons.pets,
                                          size: 18,
                                          color: Colors.grey[600],
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / 
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.pets,
                                      size: 18,
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ),
                            SizedBox(width: 12),
                            // Organization name
                            Expanded(
                              child: Text(
                                org.org_name,
                                style: TextStyle(
                                  color: const Color(0xFF3D3D3D),
                                  fontSize: 15,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Date requested - Center aligned like header
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Container(
                            // Container to enforce alignment
                            alignment: Alignment.center,
                            width: double.infinity,
                            child: Text(
                              DateFormat('MMMM d, yyyy').format(org.date_created),
                              style: TextStyle(
                                color: const Color(0xFF3D3D3D),
                                fontSize: 15,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Status with colored badge - Center aligned like header
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: org.isVerified 
                                  ? const Color(0xFFEBF6E0) 
                                  : const Color(0xFFF6EFE0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: org.isVerified 
                                    ? const Color(0xFFC0D6B6) 
                                    : const Color(0xFFEFCECB),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              org.isVerified ? 'Verified' : 'Pending',
                              style: TextStyle(
                                color: org.isVerified 
                                    ? const Color(0xFF4A7C59) 
                                    : const Color(0xFF936262),
                                fontSize: 13,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Action button - Center aligned like header
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _viewOrganizationDetails(org),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1.50,
                                      color: const Color(0xFF545454),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  shadows: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _selectedFilter == 'Verified Organizations' 
                                        ? Icons.manage_accounts_outlined
                                        : Icons.visibility_outlined,
                                      size: 16,
                                      color: const Color(0xFF545454),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      _selectedFilter == 'Verified Organizations' 
                                        ? 'Manage'
                                        : 'View Details',
                                      style: TextStyle(
                                        color: const Color(0xFF545454),
                                        fontSize: 13,
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider with consistent margins
                if (index < _unverifiedOrgs.length - 1)
                  Container(
                    height: 1,
                    color: const Color(0xFFEEEEEE),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Enhanced organization details dialog
  void _viewOrganizationDetails(Organization org) {
    // ...keep existing functionality but enhance the dialog UI...
    showDialog(
      context: context,
      builder: (context) {
        // Get available screen size
        final screenSize = MediaQuery.of(context).size;
        final availableHeight = screenSize.height - 80; // Leave 80px padding (40px top and bottom)
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          // Use MediaQuery to ensure dialog fits within screen bounds
          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            width: 800,
            // Set maximum height based on available screen height
            constraints: BoxConstraints(
              maxHeight: availableHeight,
              maxWidth: screenSize.width - 48, // 24px padding on each side
            ),
            padding: EdgeInsets.all(0), // Remove default padding
            child: Column(
              mainAxisSize: MainAxisSize.min, // Important to prevent expansion
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced header with organization name and status badge
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0CCCA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  child: Row(
                    children: [
                      // Organization logo 
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: org.logo_url != null && org.logo_url!.isNotEmpty
                            ? Image.network(
                                org.logo_url!,
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                                errorBuilder: (context, error, stackTrace) {
                                  print("Error loading logo in dialog: $error");
                                  return Icon(
                                    Icons.business,
                                    size: 30,
                                    color: Colors.grey[600],
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF34C2BB)),
                                        value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Icon(
                                Icons.business,
                                size: 30,
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                      SizedBox(width: 20),
                      
                      // Organization name and status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              org.org_name,
                              style: TextStyle(
                                color: const Color(0xFF3B3B3B),
                                fontSize: 24,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: org.isVerified 
                                    ? const Color(0xFFEBF6E0) 
                                    : const Color(0xFFF6EFE0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: org.isVerified 
                                      ? const Color(0xFFC0D6B6) 
                                      : const Color(0xFFEFCECB),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                org.isVerified ? 'Verified' : 'Verification Pending',
                                style: TextStyle(
                                  color: org.isVerified 
                                      ? const Color(0xFF4A7C59) 
                                      : const Color(0xFF936262),
                                  fontSize: 14,
                                  fontFamily: 'DM Sans', // Changed from 'Inter' to 'DM Sans'
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Close button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: const Color(0xFF545454)),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                
                // Content area with scrolling - Fix height calculation
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rest of organization details with enhanced formatting
                          _buildDetailSection(
                            'Organization Information',
                            [
                              _buildEnhancedDetailRow('Date Created', DateFormat('MMMM d, yyyy').format(org.date_created)),
                              _buildEnhancedDetailRow('Location', org.location ?? 'Not provided'),
                              _buildEnhancedDetailRow('Address', org.address ?? 'Not provided'),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // About section
                          _buildDetailSection(
                            'About',
                            [
                              Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  org.about ?? 'No information provided',
                                  style: TextStyle(
                                    height: 1.5,
                                    color: Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Contact information
                          _buildDetailSection(
                            'Contact Information',
                            [
                              _buildEnhancedDetailRow('Email', org.email ?? 'Not provided'),
                              _buildEnhancedDetailRow('Phone', org.contact_numbers != null && org.contact_numbers!.isNotEmpty 
                                  ? org.contact_numbers!.join(', ') : 'Not provided'),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Verification information
                          _buildDetailSection(
                            'Verification Documents',
                            [
                              Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Proof of Validation',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      org.org_proof_of_validation,
                                      style: TextStyle(
                                        height: 1.5,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Footer with action buttons - Updated with reject button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Close button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Show action buttons only for unverified organizations
                      if (!org.isVerified) ...[
                        SizedBox(width: 12),
                        // Reject button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _rejectOrganization(org);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[100],
                            foregroundColor: Colors.red[800],
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cancel_outlined, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Reject Verification',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 12),
                        // Verify button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _verifyOrganization(org);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34C2BB),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Verify Organization',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper method for section titles in detail dialog
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF3B3B3B),
            fontSize: 18,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }
  
  // Enhanced detail row for organization details
  Widget _buildEnhancedDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            child: Text(
              label + ':',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
