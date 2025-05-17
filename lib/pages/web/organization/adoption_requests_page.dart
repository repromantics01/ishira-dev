import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/models/pet.dart';
import 'org_sidebar.dart';
import 'package:pawsmatch/services/firebase_adopt_service.dart';
import 'package:pawsmatch/models/adopt.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/widgets/request_details_modal.dart';

class AdoptionRequestsPage extends StatefulWidget {
  const AdoptionRequestsPage({super.key});

  @override
  State<AdoptionRequestsPage> createState() => _AdoptionRequestsPageState();
}

class _AdoptionRequestsPageState extends State<AdoptionRequestsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAdoptService _adoptService = FirebaseAdoptService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseAccountService _accountService = DatabaseAccountService();
  final FirebaseProfileService _profileService = FirebaseProfileService();
  final FirebasePetService _petService = FirebasePetService();

  bool _isLoading = true;
  String _error = '';
  List<Adopt> _adoptionRequests = [];
  Map<String, Account> _userAccounts = {};
  Map<String, Map<String, dynamic>> _userProfiles = {};
  Map<String, Pet> _petMap = {};
  
  String _sortBy = 'Date';
  String _filterBy = 'All';
  String _organizationId = ''; // Add this to track organization ID for pet photos

  @override
  void initState() {
    super.initState();
    _loadAdoptionRequests();
  }

  Future<void> _loadAdoptionRequests() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      // Find the organization this admin belongs to
      String? orgId;
      
      // Try getting org by direct document ID (user.uid)
      final directOrgDoc = await _firestore.collection('organization').doc(user.uid).get();
      if (directOrgDoc.exists) {
        // Use the document ID as the org_id
        orgId = user.uid;
        print('Found organization by direct document ID: $orgId');
      } else {
        // Try finding organization where admin_ids array contains user.uid
        final orgSnapshot = await _firestore
            .collection('organization')
            .where('admin_ids', arrayContains: user.uid)
            .limit(1)
            .get();
        
        if (orgSnapshot.docs.isNotEmpty) {
          // Get org_id from document - use document ID as fallback
          orgId = orgSnapshot.docs.first.data()['org_id'] as String? ?? orgSnapshot.docs.first.id;
          print('Found organization by admin_ids: $orgId');
        } else {
          setState(() {
            _error = 'No organization found for current user';
            _isLoading = false;
          });
          return;
        }
      }
      
      // Store organization ID for later use
      _organizationId = orgId;

      // Get adoption requests where org_id matches found organization
      final adoptSnapshot = await _firestore
          .collection('adopt')
          .where('org_id', isEqualTo: orgId)
          .get();
      
      // Convert to adopt objects
      List<Adopt> adopts = [];
      for (var doc in adoptSnapshot.docs) {
        try {
          final data = doc.data();
          adopts.add(Adopt.fromJson(data));
        } catch (e) {
          print('Error parsing adoption document ${doc.id}: $e');
        }
      }
      
      print('Found ${adopts.length} adoption requests for organization $orgId');

      // Get account info for users
      Map<String, Account> accounts = {};
      Map<String, Map<String, dynamic>> profiles = {};
      
      for (var adopt in adopts) {
        try {
          // Get account info if not already fetched
          if (!accounts.containsKey(adopt.account_id)) {
            final account = await _accountService.getAccount(adopt.account_id);
            accounts[adopt.account_id] = account;
            
            // Also fetch profile information for each account
            try {
              final profileData = await _profileService.getUserProfile(adopt.account_id);
              profiles[adopt.account_id] = profileData!;
              print('Fetched profile for ${account.account_username}: ${profileData['first_name']} ${profileData['last_name']}');
            } catch (profileError) {
              print('Error fetching profile for account ${adopt.account_id}: $profileError');
            }
          }
        } catch (e) {
          print('Error fetching account info: $e');
        }
      }
      
      // Add pet fetching:
      for (var adopt in adopts) {
        try {
          // Get pet info if not already fetched
          if (!_petMap.containsKey(adopt.pet_id)) {
            try {
              final pet = await _petService.getPetById(adopt.pet_id);
              _petMap[adopt.pet_id] = pet;
              print('Fetched pet: ${pet.pet_name}');
            } catch (petError) {
              print('Error fetching pet ${adopt.pet_id}: $petError');
            }
          }
        } catch (e) {
          print('Error fetching pet data: $e');
        }
      }
      
      setState(() {
        _adoptionRequests = adopts;
        _userAccounts = accounts;
        _userProfiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load adoption requests: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMMM d, yyyy').format(date);
  }
  
  // Helper method to get user's full name
  String _getUserFullName(String accountId) {
    final profile = _userProfiles[accountId];
    if (profile != null) {
      final firstName = profile['first_name'] as String? ?? '';
      final lastName = profile['last_name'] as String? ?? '';
      
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }
    
    // Fallback to username if profile not found
    final account = _userAccounts[accountId];
    return account?.account_username ?? accountId;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 1200;
    
    // Create a filtered list based on the filter selection
    List<Adopt> filteredRequests = [];
    if (_adoptionRequests.isNotEmpty) {
      filteredRequests = _filterBy == 'All'
          ? _adoptionRequests
          : _adoptionRequests.where(
              (adopt) => adopt.application_status.toString().split('.').last == _filterBy).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: Row(
        children: [
          // Sidebar
          const OrgSidebar(),
          
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 40.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),
                    
                    // Page title
                    Text(
                      'Adoption Requests',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: isMobile ? 32 : 48,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Controls row (Sort and Filter)
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        // Sort dropdown
                        SizedBox(
                          width: 175,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sort',
                                style: TextStyle(
                                  color: const Color(0xFF2E3036),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFC5C6CC),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _sortBy,
                                    items: ['Date', 'Status', 'User'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            color: const Color(0xFF8F9098),
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _sortBy = newValue!;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: const Color(0xFF8F9098),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Filter dropdown
                        SizedBox(
                          width: 175,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter',
                                style: TextStyle(
                                  color: const Color(0xFF2E3036),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFC5C6CC),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _filterBy,
                                    items: ['All', 'Pending', 'Approved', 'Rejected'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            color: const Color(0xFF8F9098),
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _filterBy = newValue!;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: const Color(0xFF8F9098),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Table container with responsive width
                    Container(
                      width: double.infinity,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFEDEDED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Table header
                          Container(
                            width: double.infinity,
                            height: 65,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFB0CCCA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  // User column
                                  Expanded(
                                    flex: 25,
                                    child: Text(
                                      'User',
                                      style: TextStyle(
                                        color: const Color(0xFF3B3B3B),
                                        fontSize: isMobile ? 18 : 24,
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Pet column
                                  if (!isMobile)
                                    Expanded(
                                      flex: 20,
                                      child: Text(
                                        'Pet',
                                        style: TextStyle(
                                          color: const Color(0xFF3B3B3B),
                                          fontSize: 24,
                                          fontFamily: 'DM Sans',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  // Date column
                                  Expanded(
                                    flex: isMobile ? 30 : 25,
                                    child: Text(
                                      'Date',
                                      style: TextStyle(
                                        color: const Color(0xFF3B3B3B),
                                        fontSize: isMobile ? 18 : 24,
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Status column
                                  Expanded(
                                    flex: 20,
                                    child: Text(
                                      'Status',
                                      style: TextStyle(
                                        color: const Color(0xFF3B3B3B),
                                        fontSize: isMobile ? 18 : 24,
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Action column
                                  Expanded(
                                    flex: isMobile ? 25 : 30,
                                    child: Text(
                                      'Action',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFF3B3B3B),
                                        fontSize: isMobile ? 18 : 24,
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Table content
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight: 400,
                              maxHeight: 600,
                            ),
                            child: _isLoading
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(color: Color(0xFF725F63)),
                                      SizedBox(height: 20),
                                      Text(
                                        'Loading adoption requests...',
                                        style: TextStyle(
                                          color: Color(0xFF545454),
                                          fontSize: 16,
                                          fontFamily: 'DM Sans',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _error.isNotEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                                        SizedBox(height: 16),
                                        Text(
                                          'Error',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 20,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 40),
                                          child: Text(
                                            _error,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 16,
                                              fontFamily: 'DM Sans',
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        ElevatedButton(
                                          onPressed: _loadAdoptionRequests,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFFB0CCCA),
                                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Try Again',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _adoptionRequests.isEmpty
                                  ? _buildEmptyState(
                                      'No adoption requests found',
                                      'There are currently no adoption requests for your organization.',
                                      Icons.pets,
                                    )
                                  : filteredRequests.isEmpty
                                    ? _buildEmptyState(
                                        'No ${_filterBy} requests found',
                                        'Try changing your filter to see other adoption requests.',
                                        Icons.filter_alt,
                                      )
                                    : ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: filteredRequests.length,
                                        itemBuilder: (context, index) {
                                          final adopt = filteredRequests[index];
                                          final pet = _petMap[adopt.pet_id];
                                          
                                          return Column(
                                            children: [
                                              Container(
                                                height: isMobile ? 80 : 60,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isMobile ? 10 : 20,
                                                  vertical: isMobile ? 5 : 0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    // User column
                                                    Expanded(
                                                      flex: 25,
                                                      child: Text(
                                                        _getUserFullName(adopt.account_id),
                                                        style: TextStyle(
                                                          color: const Color(0xFF3D3D3D),
                                                          fontSize: 16,
                                                          fontFamily: 'Inter',
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    // Pet column (hidden on mobile)
                                                    if (!isMobile)
                                                      Expanded(
                                                        flex: 20,
                                                        child: Text(
                                                          pet?.pet_name ?? 'Unknown',
                                                          style: TextStyle(
                                                            color: const Color(0xFF3D3D3D),
                                                            fontSize: 16,
                                                            fontFamily: 'Inter',
                                                            fontWeight: FontWeight.w400,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    // Date column
                                                    Expanded(
                                                      flex: isMobile ? 30 : 25,
                                                      child: Text(
                                                        _formatDate(adopt.date_submitted),
                                                        style: TextStyle(
                                                          color: const Color(0xFF3D3D3D),
                                                          fontSize: 16,
                                                          fontFamily: 'Inter',
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    // Status column
                                                    Expanded(
                                                      flex: 20,
                                                      child: Text(
                                                        adopt.application_status.toString().split('.').last,
                                                        style: TextStyle(
                                                          color: const Color(0xFF3D3D3D),
                                                          fontSize: 16,
                                                          fontFamily: 'Inter',
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    // Action column
                                                    Expanded(
                                                      flex: isMobile ? 25 : 30,
                                                      child: Center(
                                                        child: InkWell(
                                                          onTap: () {
                                                            _showDetailsModal(context, adopt);
                                                          },
                                                          child: Container(
                                                            height: 40,
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal: isMobile ? 8 : 16, 
                                                              vertical: 12
                                                            ),
                                                            decoration: ShapeDecoration(
                                                              shape: RoundedRectangleBorder(
                                                                side: BorderSide(
                                                                  width: 1.50,
                                                                  color: const Color(0xFF545454),
                                                                ),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              isMobile ? 'View' : 'View Details',
                                                              style: TextStyle(
                                                                color: const Color(0xFF545454),
                                                                fontSize: 12,
                                                                fontFamily: 'Inter',
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Divider(
                                                height: 1,
                                                thickness: 1,
                                                color: Color(0xFF9E9E9E),
                                                indent: 20,
                                                endIndent: 20,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for empty states - modified to be responsive
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Color(0xFF725F63), size: 64),
            SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                color: Color(0xFF545454),
              ),
            ),
            SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'DM Sans',
                color: Color(0xFF545454).withOpacity(0.7),
              ),
            ),
            if (_filterBy != 'All') ...[
              SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _filterBy = 'All';
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF725F63)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Show All Requests',
                  style: TextStyle(
                    color: Color(0xFF725F63),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Improved modal to fix pet photo display
  void _showDetailsModal(BuildContext context, Adopt adopt) {
    final pet = _petMap[adopt.pet_id];
    final account = _userAccounts[adopt.account_id];
    final profile = _userProfiles[adopt.account_id];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RequestDetailsModal(
          request: adopt,
          pet: pet,
          userAccount: account,
          userProfile: profile,
          onClose: () {
            Navigator.of(context).pop();
            // Refresh the data
            _loadAdoptionRequests();
          },
          // Pass organization ID for photo display
          organizationId: _organizationId,
          onApprove: adopt.application_status == ApplicationStatus.Pending ? () async {
            try {
              // Update the adoption status in Firestore
              await _firestore.collection('adopt').doc(adopt.adopt_id).update({
                'application_status': ApplicationStatus.Approved.toString().split('.').last,
                'date_reviewed': DateTime.now().toIso8601String()
              });
              
              // Close the modal
              Navigator.of(context).pop();
              
              // Refresh the data
              _loadAdoptionRequests();
              
              // Show a success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Adoption request approved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              print('Error approving adoption: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to approve adoption: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } : null,
          onReject: adopt.application_status == ApplicationStatus.Pending ? () async {
            try {
              // Update the adoption status in Firestore
              await _firestore.collection('adopt').doc(adopt.adopt_id).update({
                'application_status': ApplicationStatus.Rejected.toString().split('.').last,
                'date_reviewed': DateTime.now().toIso8601String()
              });
              
              // Close the modal
              Navigator.of(context).pop();
              
              // Refresh the data
              _loadAdoptionRequests();
              
              // Show a success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Adoption request rejected'),
                  backgroundColor: Colors.orange,
                ),
              );
            } catch (e) {
              print('Error rejecting adoption: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to reject adoption: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } : null,
          onComplete: adopt.application_status == ApplicationStatus.Approved ? () async {
            try {
              // Update the adoption status to Completed
              await _firestore.collection('adopt').doc(adopt.adopt_id).update({
                'application_status': ApplicationStatus.Completed.toString().split('.').last,
                'date_completed': DateTime.now().toIso8601String()
              });
              
              // Also update the pet status to Adopted
              if (pet != null) {
                await _firestore.collection('pet').doc(pet.pet_id).update({
                  'pet_status': PetStatus.Adopted.toString().split('.').last
                });
              }
              
              // Close the modal
              Navigator.of(context).pop();
              
              // Refresh the data
              _loadAdoptionRequests();
              
              // Show a success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Adoption process completed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              print('Error completing adoption: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to complete adoption: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } : null,
          onMessage: () {
            // Implement message functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Messaging not implemented yet')),
            );
          },
        );
      },
    );
  }
}
