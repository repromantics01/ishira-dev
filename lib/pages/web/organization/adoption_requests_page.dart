import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'org_sidebar.dart';
import 'package:pawsmatch/services/firebase_adopt_service.dart';
import 'package:pawsmatch/models/adopt.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';

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

  bool _isLoading = true;
  String _error = '';
  List<Adopt> _adoptionRequests = [];
  Map<String, Account> _userAccounts = {};
  Map<String, Map<String, dynamic>> _userProfiles = {};
  
  String _sortBy = 'Date';
  String _filterBy = 'All';

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
              
              // Page title - adjust positioning for consistent margin
              Positioned(
                left: 400,
                top: 100,
                child: SizedBox(
                  width: 646,
                  height: 50,
                  child: Text(
                    'Adoption Requests',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 48,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 0.33,
                    ),
                  ),
                ),
              ),
              
              // Apply consistent margins for sort and filter controls
              Positioned(
                left: 400,
                top: 170,
                child: Container(
                  width: 175,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 175,
                        child: Text(
                          'Sort',
                          style: TextStyle(
                            color: const Color(0xFF2E3036),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
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
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: SizedBox(),
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
                                  height: 1.43,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _sortBy = newValue!;
                            });
                          },
                          icon: Container(
                            width: 12,
                            height: 12,
                            child: Icon(
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
              ),
              
              // Filter dropdown - consistent left margin with sort
              Positioned(
                left: 590,
                top: 170,
                child: Container(
                  width: 171,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 171,
                        child: Text(
                          'Filter',
                          style: TextStyle(
                            color: const Color(0xFF2E3036),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
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
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: SizedBox(),
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
                                  height: 1.43,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _filterBy = newValue!;
                            });
                          },
                          icon: Container(
                            width: 12,
                            height: 12,
                            child: Icon(
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
              ),
              
              // Apply consistent margins to table background
              Positioned(
                left: 400,
                top: 280,
                child: Container(
                  width: 1115,
                  height: 576,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFEDEDED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              
              // Table header with consistent margins
              Positioned(
                left: 400,
                top: 260,
                child: Container(
                  width: 1115,
                  height: 65,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFB0CCCA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: [
                        // User column - 250 width
                        Expanded(
                          flex: 25,
                          child: Text(
                            'User',
                            style: TextStyle(
                              color: const Color(0xFF3B3B3B),
                              fontSize: 24,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Date column - 250 width
                        Expanded(
                          flex: 25,
                          child: Text(
                            'Date',
                            style: TextStyle(
                              color: const Color(0xFF3B3B3B),
                              fontSize: 24,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Status column - 200 width
                        Expanded(
                          flex: 20,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              color: const Color(0xFF3B3B3B),
                              fontSize: 24,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Action column - 150 width
                        Expanded(
                          flex: 30,
                          child: Text(
                            'Action',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF3B3B3B),
                              fontSize: 24,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Table content with consistent margins
              Positioned(
                left: 400,
                top: 325,
                child: Container(
                  width: 1115,
                  height: 531, // Adjusted to fit inside background properly
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
                      : _adoptionRequests.isEmpty // No adoption requests at all
                        ? _buildEmptyState(
                            'No adoption requests found',
                            'There are currently no adoption requests for your organization.',
                            Icons.pets,
                          )
                        : filteredRequests.isEmpty // No results for current filter
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
                                
                                return Column(
                                  children: [
                                    Container(
                                      height: 60,
                                      padding: const EdgeInsets.symmetric(horizontal: 40),
                                      child: Row(
                                        children: [
                                          // User column with first and last name
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
                                            ),
                                          ),
                                          // Date column - matches header
                                          Expanded(
                                            flex: 25,
                                            child: Text(
                                              _formatDate(adopt.date_submitted),
                                              style: TextStyle(
                                                color: const Color(0xFF3D3D3D),
                                                fontSize: 16,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          // Status column - matches header
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
                                            ),
                                          ),
                                          // Action column - matches header
                                          Expanded(
                                            flex: 30,
                                            child: Center(
                                              child: Container(
                                                height: 40,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                                  'View Details',
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
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1040,
                                      height: 1,
                                      decoration: BoxDecoration(color: const Color(0xFF9E9E9E)),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
              ),
              
              // Sidebar (unchanged)
              const Positioned(
                left: 0,
                top: 0,
                child: OrgSidebar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for empty states
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Color(0xFF725F63), size: 64),
          SizedBox(height: 24),
          Text(
            title,
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
    );
  }
}
