import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/web/organization/org_sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/pages/web/organization/organization_profile_page.dart'; // Add import
import 'package:pawsmatch/models/organization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrganizationDashboard extends StatefulWidget {
  final Organization? org;
  const OrganizationDashboard({super.key, this.org});

  @override
  _OrganizationDashboardState createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard> {
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Organization? _organization;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Data for adoption and surrender trends
  int _totalAdoptionRequests = 0;
  int _totalSurrenderRequests = 0;
  int _pendingAdoptionRequests = 0;
  int _pendingSurrenderRequests = 0;
  List<MapEntry<String, int>> _monthlySurrenderData = [];
  List<MapEntry<String, int>> _monthlyAdoptionData = [];

  @override
  void initState() {
    super.initState();
    if (widget.org != null) {
      _organization = widget.org;
      _isLoading = false;
      _loadRequestsData();
    } else {
      _loadOrganizationData();
    }
  }

  Future<void> _loadOrganizationData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get organization data for the logged in user
      final organization = await _organizationService.getOrganizationById(user.uid);
      
      setState(() {
        _organization = organization;
        _isLoading = false;
      });
      
      // After organization data is loaded, load requests data
      if (_organization != null) {
        _loadRequestsData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load organization data: $e';
        _isLoading = false;
      });
    }
  }
  
  // Load adoption and surrender request data
  Future<void> _loadRequestsData() async {
    if (_organization == null) return;
    
    try {
      final orgId = _organization!.org_id;
      print('Loading request data for organization ID: $orgId');
      
      // Get adoption requests with proper status field - no changes needed here
      final adoptionSnapshot = await _firestore
          .collection('adoption_requests')
          .where('organization_id', isEqualTo: orgId)
          .get();
          
      final adoptSnapshot = await _firestore
          .collection('adopt')
          .where('org_id', isEqualTo: orgId)
          .get();
          
      // Get surrender requests from both possible collections
      final surrenderRequestsSnapshot = await _firestore
          .collection('surrender_requests')
          .where('organization_id', isEqualTo: orgId)
          .get();
      print('Found ${surrenderRequestsSnapshot.docs.length} surrender requests');
          
      final surrenderSnapshot = await _firestore
          .collection('surrender')
          .where('org_id', isEqualTo: orgId)
          .get();
      print('Found ${surrenderSnapshot.docs.length} surrender records');
      
      // Process adoption data - combine both collections
      final adoptionRequestDocs = adoptionSnapshot.docs;
      final adoptDocs = adoptSnapshot.docs;
      final combinedAdoptionCount = adoptionRequestDocs.length + adoptDocs.length;
      
      // Count pending from both collections
      final pendingAdoptions = adoptionRequestDocs.where((doc) => 
          doc.data()['status'] == 'pending').length +
          adoptDocs.where((doc) => 
          doc.data()['application_status'] == 'Pending').length;
      
      // Process surrender data - combine both collections
      final surrenderRequestDocs = surrenderRequestsSnapshot.docs;
      final surrenderDocs = surrenderSnapshot.docs;
      final combinedSurrenderCount = surrenderRequestDocs.length + surrenderDocs.length;
      
      // Improved count of pending surrenders - check all possible status field names and values
      int pendingSurrenders = 0;
      
      // Check surrender_requests collection
      for (final doc in surrenderRequestDocs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Debug logging
        print('Surrender request document fields: ${data.keys.join(', ')}');
        if (data.containsKey('status')) {
          print('Status value: ${data['status']}');
        } else if (data.containsKey('application_status')) {
          print('Application status value: ${data['application_status']}');
        }
        
        // Case-insensitive check for 'pending' in various fields
        if ((data['status']?.toString().toLowerCase() == 'pending') ||
            (data['application_status']?.toString().toLowerCase() == 'pending') ||
            (data['surrender_status']?.toString().toLowerCase() == 'pending') ||
            (data['status'] == 'Pending') ||
            (data['application_status'] == 'Pending')) {
          pendingSurrenders++;
        }
      }
      
      // Check surrender collection
      for (final doc in surrenderDocs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Debug logging
        print('Surrender document fields: ${data.keys.join(', ')}');
        if (data.containsKey('status')) {
          print('Status value: ${data['status']}');
        } else if (data.containsKey('application_status')) {
          print('Application status value: ${data['application_status']}');
        }
        
        // Case-insensitive check for 'pending'
        if ((data['status']?.toString().toLowerCase() == 'pending') ||
            (data['application_status']?.toString().toLowerCase() == 'pending') ||
            (data['surrender_status']?.toString().toLowerCase() == 'pending') ||
            (data['status'] == 'Pending') ||
            (data['application_status'] == 'Pending')) {
          pendingSurrenders++;
        }
      }
      
      print('Counted pending surrender requests: $pendingSurrenders');
      
      // Group by month for trends - process all collections
      Map<String, int> adoptionByMonth = {};
      Map<String, int> surrenderByMonth = {};
      
      // Process both adoption collections for trends by month
      _processDocumentsForMonthlyData(adoptionRequestDocs, adoptionByMonth, 'created_at');
      _processDocumentsForMonthlyData(adoptDocs, adoptionByMonth, 'date_submitted');
      
      // Process both surrender collections for trends by month
      _processDocumentsForMonthlyData(surrenderRequestDocs, surrenderByMonth, 'created_at');
      _processDocumentsForMonthlyData(surrenderDocs, surrenderByMonth, 'date_surrendered');
      
      // Create date-ordered lists for display - Ensure proper chronological order
      final now = DateTime.now();
      List<String> last6Months = List.generate(6, (index) {
        final date = DateTime(now.year, now.month - index, 1);
        final monthStr = DateFormat('MMM yyyy').format(date);
        print('Generated month: $monthStr');
        return monthStr;
      }).reversed.toList();
      
      print('Displaying months: ${last6Months.join(", ")}');
      
      // Create processed data for UI with default 0 values
      List<MapEntry<String, int>> processedAdoption = [];
      List<MapEntry<String, int>> processedSurrender = [];
      
      for (final month in last6Months) {
        final adoptionValue = adoptionByMonth[month] ?? 0;
        final surrenderValue = surrenderByMonth[month] ?? 0;
        
        print('Month: $month - Adoptions: $adoptionValue, Surrenders: $surrenderValue');
        
        processedAdoption.add(MapEntry(month, adoptionValue));
        processedSurrender.add(MapEntry(month, surrenderValue));
      }
      
      setState(() {
        _totalAdoptionRequests = combinedAdoptionCount;
        _totalSurrenderRequests = combinedSurrenderCount;
        _pendingAdoptionRequests = pendingAdoptions;
        _pendingSurrenderRequests = pendingSurrenders;
        _monthlyAdoptionData = processedAdoption;
        _monthlySurrenderData = processedSurrender;
      });
      
    } catch (e) {
      print('Error loading request data: $e');
    }
  }
  
  // Helper method to process documents for monthly data
  void _processDocumentsForMonthlyData(
      List<QueryDocumentSnapshot> docs, 
      Map<String, int> monthData,
      String dateField) {
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Try all possible date field variations
      dynamic dateValue;
      String usedField = '';
      
      // Check primary field first
      if (data.containsKey(dateField)) {
        dateValue = data[dateField];
        usedField = dateField;
      } 
      // Check alternative fields
      else if (dateField == 'created_at' && data.containsKey('date_submitted')) {
        dateValue = data['date_submitted'];
        usedField = 'date_submitted';
      } 
      else if (dateField == 'date_submitted' && data.containsKey('created_at')) {
        dateValue = data['created_at'];
        usedField = 'created_at';
      }
      else if (data.containsKey('timestamp')) {
        dateValue = data['timestamp'];
        usedField = 'timestamp';
      }
      
      // If we found a date field, process it
      if (dateValue != null) {
        DateTime date;
        
        // Parse different types of date values
        if (dateValue is Timestamp) {
          date = dateValue.toDate();
        } else if (dateValue is DateTime) {
          date = dateValue;
        } else if (dateValue is String && dateValue.isNotEmpty) {
          try {
            date = DateTime.parse(dateValue);
          } catch (e) {
            print('Error parsing date string: $e');
            continue;
          }
        } else {
          continue; // Skip if the date format is unknown
        }
        
        // Format with consistent month name and year
        final String monthYear = DateFormat('MMM yyyy').format(date);
        
        // Add to month data map
        monthData[monthYear] = (monthData[monthYear] ?? 0) + 1;
        
        // Debug logging
        print('Document added to $monthYear from field $usedField with date $date');
      } else {
        // Debug which documents are missing date fields
        print('Document missing date fields. Available fields: ${data.keys.join(', ')}');
      }
    }
  }
  
  // Navigate to the organization profile page
  void _navigateToOrgProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrganizationProfilePage(),
      ),
    );
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
              // Sidebar
              const Positioned(
                left: 0,
                top: 0,
                child: OrgSidebar(),
              ),
              // Top horizontal line
              Positioned(
                left: 16,
                top: 1,
                child: Container(
                  width: 503,
                  height: 0.5,
                  decoration: BoxDecoration(color: const Color(0xFF9E9E9E)),
                ),
              ),
              // Dashboard title
              Positioned(
                left: 429,
                top: 90,
                child: SizedBox(
                  width: 448,
                  height: 19,
                  child: Text(
                    'Dashboard',
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
              // Dashboard subtitle
              Positioned(
                left: 429,
                top: 123,
                child: SizedBox(
                  width: 966,
                  height: 52,
                  child: Text(
                    'Welcome back! Here is a quick overview of the organization\'s trends.',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 24,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.88,
                    ),
                  ),
                ),
              ),
              // Highlighted stats box
              Positioned(
                left: 423,
                top: 171,
                child: Container(
                  width: 1050,
                  height: 130,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFBE8DD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  // Show loading indicator or error message
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
                      : null,
                ),
              ),
              // Org profile image - Organization Logo
              if (!_isLoading && _errorMessage.isEmpty && _organization != null)
                Positioned(
                  left: 494.33,
                  top: 196.28,
                  child: Container(
                    width: 87.29,
                    height: 85.45,
                    decoration: ShapeDecoration(
                      // Handle logo explicitly instead of relying on DecorationImage
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: const Color(0x8E725F63),
                        ),
                        borderRadius: BorderRadius.circular(92.50),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(90),
                      child: _organization?.logo_url != null && _organization!.logo_url!.isNotEmpty
                        ? Image.network(
                            _organization!.logo_url!,
                            fit: BoxFit.cover,
                            width: 87.29,
                            height: 85.45,
                            errorBuilder: (context, error, stackTrace) {
                              print("Error loading organization logo: $error");
                              return Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: const Color(0xFF725F63),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
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
                        : Center(
                            child: Icon(
                              Icons.pets,
                              size: 40,
                              color: const Color(0xFF725F63),
                            ),
                          ),
                    ),
                  ),
                ),
              // Edit Org Details button - Updated with navigation
              Positioned(
                left: 1293.84,
                top: 219,
                child: GestureDetector(
                  onTap: _navigateToOrgProfile,
                  child: Container(
                    width: 132.47,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.50,
                          color: const Color(0xFF545454),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Edit Org Details',
                          style: TextStyle(
                            color: const Color(0xFF545454),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Org name and email
              if (!_isLoading && _errorMessage.isEmpty && _organization != null)
                Positioned(
                  left: 636.91,
                  top: 208,
                  child: SizedBox(
                    width: 346.38,
                    height: 77,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${_organization!.org_name}\n',
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 28,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              height: 1.14,
                            ),
                          ),
                          TextSpan(
                            text: _organization!.email ?? 'No email provided',
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 24,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.33,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Trends section title
              Positioned(
                left: 434,
                top: 326,
                child: SizedBox(
                  width: 448,
                  height: 19,
                  child: Text(
                    'Overview',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 32,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 0.50,
                    ),
                  ),
                ),
              ),
              
              // Stats cards section
              Positioned(
                left: 423,
                top: 370,
                right: 112.09,
                child: Container(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        title: 'Total Adoption Requests',
                        value: _totalAdoptionRequests.toString(),
                        color: const Color(0xFF34C2BB),
                        icon: Icons.pets,
                      ),
                      _buildStatCard(
                        title: 'Total Surrender Requests',
                        value: _totalSurrenderRequests.toString(),
                        color: const Color(0xFFEFCECB),
                        icon: Icons.volunteer_activism,
                      ),
                      _buildStatCard(
                        title: 'Pending Adoptions',
                        value: _pendingAdoptionRequests.toString(),
                        color: const Color(0xFFC0D6B6),
                        icon: Icons.pending_actions,
                      ),
                      _buildStatCard(
                        title: 'Pending Surrenders',
                        value: _pendingSurrenderRequests.toString(),
                        color: const Color(0xFFFBE8DD),
                        icon: Icons.pending,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Monthly Data - Simple Table instead of chart
              Positioned(
                left: 423,
                top: 510,
                right: 112.09,
                bottom: 40,
                child: Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Adoption & Surrender Activity',
                          style: TextStyle(
                            color: const Color(0xFF545454),
                            fontSize: 24,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Last 6 months of activity',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Monthly data table or alternative visualization
                        Expanded(
                          child: _buildMonthlyDataTable(),
                        ),
                      ],
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
  
  // Helper method to build stat cards
  Widget _buildStatCard({required String title, required String value, required Color color, required IconData icon}) {
    return Container(
      width: 240,
      height: 120,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF545454),
              fontFamily: 'DM Sans',
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a simple table for monthly data instead of a chart
  Widget _buildMonthlyDataTable() {
    if (_monthlyAdoptionData.isEmpty && _monthlySurrenderData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No data available for the past 6 months',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      );
    }
    
    // Debug the monthly data we have
    print('Monthly adoption data: ${_monthlyAdoptionData.map((e) => '${e.key}: ${e.value}').join(', ')}');
    print('Monthly surrender data: ${_monthlySurrenderData.map((e) => '${e.key}: ${e.value}').join(', ')}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table header - enhance with color indicators
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              // Month header - same as before
              Expanded(
                flex: 2,
                child: Text(
                  'Month',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF545454),
                    fontSize: 16,
                  ),
                ),
              ),
              // Adoptions header - add color indicator
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF34C2BB),
                      ),
                      margin: EdgeInsets.only(right: 8),
                    ),
                    Text(
                      'Adoptions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF34C2BB),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Surrenders header - add color indicator
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEFCECB),
                      ),
                      margin: EdgeInsets.only(right: 8),
                    ),
                    Text(
                      'Surrenders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEFCECB),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Total Activity header - same as before
              Expanded(
                flex: 1,
                child: Text(
                  'Total Activity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF545454),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Table body with data rows
        Expanded(
          child: ListView.builder(
            itemCount: _monthlyAdoptionData.length,
            itemBuilder: (context, index) {
              final month = _monthlyAdoptionData[index].key;
              final adoptionCount = _monthlyAdoptionData[index].value;
              final surrenderCount = _monthlySurrenderData[index].value;
              final totalActivity = adoptionCount + surrenderCount;
              
              // Add month name highlight for better readability
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                  color: index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
                ),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        month,
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,  // Make month name bold
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF34C2BB),
                            ),
                            margin: EdgeInsets.only(right: 8),
                          ),
                          Text(
                            adoptionCount.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEFCECB),
                            ),
                            margin: EdgeInsets.only(right: 8),
                          ),
                          Text(
                            surrenderCount.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        totalActivity.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Summary row at bottom - Make it more prominent
        Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: Offset(0, -1),
            )],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'TOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF545454),
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  _totalAdoptionRequests.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF34C2BB),
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  _totalSurrenderRequests.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEFCECB),
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  (_totalAdoptionRequests + _totalSurrenderRequests).toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF545454),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
