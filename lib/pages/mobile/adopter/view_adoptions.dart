import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/models/adopt.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_adopt_service.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/pages/mobile/adopter/swiped_pets.dart';
import 'package:pawsmatch/pages/mobile/adopter/a_dashboard.dart';
import 'package:flutter/services.dart';

class ViewAdoptionsPage extends StatefulWidget {
  const ViewAdoptionsPage({Key? key}) : super(key: key);

  @override
  _ViewAdoptionsPageState createState() => _ViewAdoptionsPageState();
}

class _ViewAdoptionsPageState extends State<ViewAdoptionsPage> {
  final FirebaseAdoptService _adoptService = FirebaseAdoptService();
  final FirebasePetService _petService = FirebasePetService();
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _allAdoptedPets = [];
  List<Map<String, dynamic>> _filteredAdoptedPets = [];
  bool _isLoading = true;
  int _selectedIndex = 2; // This page is index 2
  
  // Filter options
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Rejected', 'Complete', 'Cancelled'];
  
  @override
  void initState() {
    super.initState();
    _loadAdoptions();
  }

  // Apply filter based on selected option
  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      
      if (filter == 'All') {
        _filteredAdoptedPets = List.from(_allAdoptedPets);
      } else {
        _filteredAdoptedPets = _allAdoptedPets
            .where((item) => item['adoptionStatus'] == filter)
            .toList();
      
      print("Applied filter: $filter, now showing ${_filteredAdoptedPets.length} items");
    }
  });
  }
  
  Future<void> _loadAdoptions() async {
    setState(() {
      _isLoading = true;
      _allAdoptedPets = [];
      _filteredAdoptedPets = [];
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print("No authenticated user found");
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print("Fetching adoptions for user: ${user.uid}");
      
      final adoptions = await _adoptService.getCurrentUserAdopts();
      print("Found ${adoptions.length} adoption records");
      
      if (adoptions.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      List<Map<String, dynamic>> adoptedPetsData = [];
      // Map to track unique pets by ID, to avoid duplicates
      Map<String, Map<String, dynamic>> uniquePetsMap = {};
      
      // Process each adoption record (now a Map instead of an Adopt object)
      for (var adoptionData in adoptions) {
        try {
          // Extract adoption details from the Map
          final String adoptId = adoptionData['adopt_id'] as String? ?? '';
          final String petId = adoptionData['pet_id'] as String? ?? '';
          
          print("Processing adoption record: $adoptId for pet: $petId");
          
          if (petId.isEmpty) {
            print("Invalid pet ID");
            continue;
          }
          
          // Get pet details
          final petDoc = await _petService.getPetWithId(petId);
          if (!petDoc.exists) {
            print("Pet with ID $petId not found");
            continue;
          }
          
          final pet = petDoc.data();
          print("Found pet: ${pet.pet_name}");
          
          // Get first pet photo
          String? photoUrl;
          if (pet.photo_id.isNotEmpty) {
            photoUrl = await _photoService.getPhotoUrl(pet.photo_id[0]);
          }
          
          // Get application status from adoption data
          final String applicationStatusString = adoptionData['application_status'] as String? ?? 'Pending';
          
          // Determine status color based on status string
          String status;
          Color statusColor;
          switch (applicationStatusString) {
            case 'Approved':
              status = 'Approved';
              statusColor = Colors.green;
              break;
            case 'Pending':
              status = 'Pending';
              statusColor = Colors.orange;
              break;
            case 'Rejected':
              status = 'Rejected';
              statusColor = Colors.red;
              break;
            case 'Completed':
              status = 'Completed';
              statusColor = Colors.blue;
              break;
            case 'Cancelled':
              status = 'Cancelled';
              statusColor = Colors.grey;
              break;
            default:
              status = 'Pending';
              statusColor = Colors.orange;
          }
          
          // Get date information with fallbacks
          DateTime dateSubmitted;
          try {
            var dateData = adoptionData['date_submitted'];
            if (dateData is Timestamp) {
              dateSubmitted = dateData.toDate();
            } else if (dateData is String) {
              dateSubmitted = DateTime.parse(dateData);
            } else {
              dateSubmitted = DateTime.now();
            }
          } catch (e) {
            dateSubmitted = DateTime.now();
            print("Error parsing date: $e");
          }
          
          // Create data record for this adoption
          final petAdoptionData = {
            'pet': pet,
            'photoUrl': photoUrl,
            'adoptionStatus': status,
            'statusColor': statusColor,
            'adoptionDate': dateSubmitted,
            'adoptId': adoptId,
            'orgId': adoptionData['org_id'] as String? ?? '',
            'adopterComment': adoptionData['adopter_comment'] as String? ?? '',
          };
          
          // Check if we already have an adoption for this pet
          if (uniquePetsMap.containsKey(petId)) {
            // If we already have this pet, compare dates and keep the most recent application
            final existing = uniquePetsMap[petId]!;
            final existingDate = existing['adoptionDate'] as DateTime;
            
            // Replace only if new application is more recent
            if (dateSubmitted.isAfter(existingDate)) {
              uniquePetsMap[petId] = petAdoptionData;
              print("Updated to more recent adoption for pet: ${pet.pet_name}");
            } else {
              print("Kept existing adoption record for pet: ${pet.pet_name} (newer one exists)");
            }
          } else {
            // First time seeing this pet, add it
            uniquePetsMap[petId] = petAdoptionData;
            print("Added first adoption record for pet: ${pet.pet_name}");
          }
        } catch (e) {
          print("Error processing adoption: $e");
        }
      }
      
      // Convert the map values to a list
      adoptedPetsData = uniquePetsMap.values.toList();
      
      // Sort by adoption date (newest first)
      if (adoptedPetsData.isNotEmpty) {
        adoptedPetsData.sort((a, b) => 
          (b['adoptionDate'] as DateTime).compareTo(a['adoptionDate'] as DateTime)
        );
      }
      
      print("Processed total of ${adoptedPetsData.length} unique adoption records");
      
      setState(() {
        _allAdoptedPets = adoptedPetsData;
        _filteredAdoptedPets = List.from(adoptedPetsData);
        _isLoading = false;
      });
      
    } catch (e) {
      print("Error loading adoptions: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _checkStatus(String adoptId) {
    // Find the adoption details by adoptId
    final adoptionDetails = _filteredAdoptedPets.firstWhere(
      (item) => item['adoptId'] == adoptId,
      orElse: () => <String, dynamic>{},
    );
    
    if (adoptionDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adoption details not found')),
      );
      return;
    }
    
    // Show detailed modal with adoption information
    _showAdoptionDetailsModal(context, adoptionDetails);
  }

  void _showAdoptionDetailsModal(BuildContext context, Map<String, dynamic> adoptionDetails) {
    final Pet pet = adoptionDetails['pet'];
    final String status = adoptionDetails['adoptionStatus'];
    final Color statusColor = adoptionDetails['statusColor'];
    final DateTime adoptionDate = adoptionDetails['adoptionDate'];
    final String photoUrl = adoptionDetails['photoUrl'];
    final String adoptId = adoptionDetails['adoptId'];
    final String adopterComment = adoptionDetails['adopterComment'];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with pet image
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                  color: const Color(0xFFD8CBCB),
                ),
                child: Stack(
                  children: [
                    // Dark overlay for better text visibility
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    
                    // Close button in top right
                    Positioned(
                      right: 10,
                      top: 10,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close, 
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    
                    // Title at bottom of image
                    Positioned(
                      bottom: 10,
                      left: 15,
                      right: 15,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Adoption Request",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          // Status badge in header
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content - scrollable part
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pet information section
                        Text(
                          "Pet Information",
                          style: TextStyle(
                            color: Color(0xFF545454),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        
                        // Pet details
                        _buildInfoRow("Name", pet.pet_name),
                        _buildInfoRow("Species", pet.species),
                        _buildInfoRow("Breed", pet.breed),
                        _buildInfoRow("Gender", pet.gender),
                        _buildInfoRow("Age", _calculateAge(pet.birthdate)),
                        _buildInfoRow("Location", pet.address),
                        
                        Divider(height: 30),
                        
                        // Adoption details section
                        Text(
                          "Application Details",
                          style: TextStyle(
                            color: Color(0xFF545454),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        
                        // Application info
                        _buildInfoRow(
                          "Date Submitted", 
                          DateFormat('MMMM d, yyyy').format(adoptionDate),
                        ),
                        _buildInfoRow("Status", status),
                        _buildInfoRow("Application ID", adoptId),
                        
                        if (adopterComment.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Text(
                            "Your Notes:",
                            style: TextStyle(
                              color: Color(0xFF545454),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFEDEDED),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              adopterComment.isEmpty ? "No comment provided." : adopterComment,
                              style: TextStyle(
                                color: Color(0xFF545454),
                                fontSize: 14,
                                fontStyle: adopterComment.isEmpty ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                          ),
                        ],
                        
                        SizedBox(height: 15),
                        
                        // Next steps/status information
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statusColor.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusTitle(status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                _getStatusMessage(status),
                                style: TextStyle(
                                  color: Color(0xFF545454),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer with action button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFECC8C0),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFF545454),
                      fontWeight: FontWeight.bold,
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
  
  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                color: Color(0xFF545454),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Color(0xFF545454),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Get status-specific title
  String _getStatusTitle(String status) {
    switch (status) {
      case 'Pending':
        return 'Your application is under review';
      case 'Approved':
        return 'Your application has been approved!';
      case 'Rejected':
        return 'Your application was not accepted';
      case 'Completed':
        return 'Adoption completed successfully!';
      case 'Cancelled':
        return 'Application cancelled';
      default:
        return 'Application status';
    }
  }
  
  // Get status-specific helper message
  String _getStatusMessage(String status) {
    switch (status) {
      case 'Pending':
        return 'The shelter is reviewing your application. This process typically takes 3-5 business days. You\'ll be messaged by the organization when there\'s an update.';
      case 'Approved':
        return 'Congratulations! The shelter has approved your application. They will contact you soon to arrange a meeting with the pet and discuss next steps.';
      case 'Rejected':
        return 'Unfortunately, your application was not accepted at this time. This could be due to various reasons. Please contact the shelter directly for more information.';
      case 'Completed':
        return 'The adoption process has been completed. We hope you and your new pet have a wonderful life together!';
      case 'Cancelled':
        return 'This application has been cancelled. If you believe this is a mistake, please contact the shelter.';
      default:
        return 'Please wait for updates on your application status.';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on the selected tab
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SwipedPetsPage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdopterDashboard()),
      );
    } else if (index == 2) {
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF5F0),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF4EAEA),
              child: IconButton(
                icon: const Icon(Icons.message, color: Color(0xFF725F63)),
                onPressed: () {
                  // TODO: Add message navigation logic
                },
              ),
            ),
          ),
          // Profile icon
          Container(
            margin: const EdgeInsets.only(left: 6, right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF4EBEB),
              child: IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF725F63)),
                onPressed: () {
                  // Add profile navigation logic
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAdoptions,
          child: Stack(
            children: [
              // Main title
              Positioned(
                left: 18,
                top: 18,
                child: SizedBox(
                  width: 301,
                  height: 36,
                  child: Text(
                    'Adoptions',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 32,
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
              
              // Subtitle and filter row
              Positioned(
                left: 20,
                top: 74,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5, // Fixed width (50% of screen)
                      child: Text(
                        'Your Adoption Requests',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 16,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w700,
                          height: 1.50,
                        ),
                        maxLines: 1, // Prevent wrapping to multiple lines
                        overflow: TextOverflow.ellipsis, // Use ellipsis if text is too long
                      ),
                    ),
                    
                    // Filter button
                    GestureDetector(
                      onTap: () {
                        _showFilterOptions(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECC8C0),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
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
                            Text(
                              'Filter: $_selectedFilter',
                              style: TextStyle(
                                color: const Color(0xFF545454),
                                fontSize: 12,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.filter_list,
                              size: 16,
                              color: const Color(0xFF545454),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // List of adoption requests
              Positioned(
                left: 20,
                top: 120,
                right: 20,
                bottom: 0,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredAdoptedPets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pets, size: 70, color: Color(0xFF725F63)),
                                SizedBox(height: 20),
                                Text(
                                  _selectedFilter == 'All' 
                                      ? 'No adoption requests yet'
                                      : 'No $_selectedFilter adoption requests',
                                  style: TextStyle(
                                    color: Color(0xFF545454),
                                    fontSize: 18,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  _selectedFilter == 'All'
                                      ? 'When you request to adopt a pet, it will show up here'
                                      : 'Try changing the filter to see other adoption requests',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF757575),
                                    fontSize: 14,
                                    fontFamily: 'Arial',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            itemCount: _filteredAdoptedPets.length,
                            itemBuilder: (context, index) {
                              final item = _filteredAdoptedPets[index];
                              final Pet pet = item['pet'];
                              final photoUrl = item['photoUrl'];
                              final status = item['adoptionStatus'];
                              final DateTime adoptionDate = item['adoptionDate'];
                              final String adoptId = item['adoptId'];
                              
                              return GestureDetector(
                                onTap: () => _checkStatus(adoptId),
                                child: Container(
                                  width: double.infinity,
                                  height: 127,
                                  margin: EdgeInsets.only(bottom: 10), // Reduced from 20 to 10
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Background container
                                      Positioned(
                                        left: 0,
                                        top: 3,
                                        right: 0,
                                        child: Container(
                                          height: 114,
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFFF7EBEB),
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(
                                                width: 1,
                                                color: const Color(0xFFD8CBCB),
                                              ),
                                              borderRadius: BorderRadius.circular(9),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Pet image
                                      Positioned(
                                        left: 15,
                                        top: 30,
                                        child: Container(
                                          width: 62,
                                          height: 62,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: photoUrl != null
                                                  ? NetworkImage(photoUrl)
                                                  : AssetImage('assets/images/pet_placeholder.png') as ImageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Pet name
                                      Positioned(
                                        left: 92,
                                        top: 19,
                                        child: Text(
                                          pet.pet_name,
                                          style: TextStyle(
                                            color: const Color(0xFF545454),
                                            fontSize: 14,
                                            fontFamily: 'Arial',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      
                                      // Pet breed
                                      Positioned(
                                        left: 92,
                                        top: 42,
                                        child: Text(
                                          pet.breed,
                                          style: TextStyle(
                                            color: const Color(0xFF545454),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            fontFamily: 'Arial',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      
                                      // Pet gender and age
                                      Positioned(
                                        left: 92,
                                        top: 61,
                                        child: Text(
                                          '${pet.gender}, ${_calculateAge(pet.birthdate)}',
                                          style: TextStyle(
                                            color: const Color(0xFF545454),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            fontFamily: 'Arial',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      
                                      // Date requested text
                                      Positioned(
                                        left: 92,
                                        top: 80,
                                        child: Text(
                                          'Requested: ${DateFormat('MMM d, yyyy').format(adoptionDate)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 10,
                                            fontFamily: 'Arial',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      
                                      // Adoption status badge
                                      Positioned(
                                        right: 15,
                                        top: 19,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item['statusColor'].withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: item['statusColor'],
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: item['statusColor'],
                                              fontSize: 10,
                                              fontFamily: 'Arial',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Positioned(
                                      //   right: 15,
                                      //   bottom: 15,
                                      //   child: Row(
                                      //     mainAxisSize: MainAxisSize.min,
                                      //     children: [
                                      //       Text(
                                      //         'View Details',
                                      //         style: TextStyle(
                                      //           color: const Color(0xFF725F63),
                                      //           fontSize: 12,
                                      //           fontStyle: FontStyle.italic,
                                      //           fontFamily: 'Arial',
                                      //         ),
                                      //       ),
                                      //       SizedBox(width: 4),
                                      //       Icon(
                                      //         Icons.arrow_forward_ios,
                                      //         size: 12,
                                      //         color: const Color(0xFF725F63),
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF5F0).withOpacity(0.5), // Semi-transparent background
        ),
        height: 85, 
        child: Column(
          children: [
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Swiped pets button
                _buildNavButton(
                  icon: Icons.pets,
                  label: 'Swiped Pets',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                  isHomeButton: false,
                ),
                
                // Home button - special design
                _buildNavButton(
                  icon: Icons.home,
                  label: 'Home',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                  isHomeButton: true,
                ),
                
                // Your Adoptions button
                _buildNavButton(
                  icon: Icons.assignment,
                  label: 'Your Adoptions',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                  isHomeButton: false,
                ),
              ],
            ),
            // Bottom indicator line
            Container(
              margin: const EdgeInsets.only(top: 5), // Adjusted from 10
              width: 134,
              height: 2,
              decoration: ShapeDecoration(
                color: const Color(0xFF020202),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simplified nav button with no animations
  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isHomeButton,
  }) {
    // Colors and sizes
    final activeColor = const Color(0xFF725F63);
    final inactiveColor = Colors.grey;
    final double iconSize = isHomeButton ? 26 : 32;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Button without animation
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: EdgeInsets.all(isHomeButton ? 8 : 6),
            decoration: BoxDecoration(
              color: isHomeButton 
                ? isSelected 
                  ? Color(0xFFECC8C0).withOpacity(0.7)  // Semi-transparent
                  : const Color(0xFFF6F6F6).withOpacity(0.5)  // Semi-transparent
                : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected && isHomeButton
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ),
        
        SizedBox(height: 5),
        
        // Label
        Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : const Color(0xFF212121),
            fontSize: 10,
            fontFamily: 'Actor',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        
        // Indicator dot for selected item
        Container(
          margin: EdgeInsets.only(top: 4),
          width: isSelected && !isHomeButton ? 4 : 0,
          height: 4,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
  
  // Show filter options in a bottom sheet
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow more control over the sheet height
      backgroundColor: const Color(0xFFFEF5F0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          // Add safe area padding at bottom to avoid overflow
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView( // Make content scrollable
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Adoptions',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 20,
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Filter options
                  ...List.generate(_filters.length, (index) {
                    final filter = _filters[index];
                    Color chipColor;
                    
                    // Set colors based on filter
                    switch (filter) {
                      case 'Approved':
                        chipColor = Colors.green.withOpacity(0.2);
                        break;
                      case 'Pending':
                        chipColor = Colors.orange.withOpacity(0.2);
                        break;
                      case 'Rejected':
                        chipColor = Colors.red.withOpacity(0.2);
                        break;
                      default:
                        chipColor = const Color(0xFFECC8C0);
                    }
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          _applyFilter(filter);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedFilter == filter ? chipColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedFilter == filter ? Colors.transparent : const Color(0xFFD8CBCB),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 16),
                              if (_selectedFilter == filter)
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: const Color(0xFF545454),
                                ),
                              if (_selectedFilter != filter)
                                Icon(
                                  Icons.circle_outlined,
                                  size: 20,
                                  color: const Color(0xFF545454),
                                ),
                              SizedBox(width: 12),
                              Text(
                                filter,
                                style: TextStyle(
                                  color: const Color(0xFF545454),
                                  fontSize: 16,
                                  fontFamily: 'Arial',
                                  fontWeight: _selectedFilter == filter ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              
                              // Count badge for each filter
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD8CBCB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  filter == 'All' 
                                    ? '${_allAdoptedPets.length}' 
                                    : '${_allAdoptedPets.where((item) => item['adoptionStatus'] == filter).length}',
                                  style: TextStyle(
                                    color: const Color(0xFF545454),
                                    fontSize: 12,
                                    fontFamily: 'Arial',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  // Add extra padding at the bottom
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Helper method to calculate age from birthdate
  String _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    final difference = now.difference(birthdate);
    
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();
    
    if (years > 0) {
      return '$years yrs';
    } else if (months > 0) {
      return '$months mo';
    } else {
      final days = difference.inDays;
      return '$days days';
    }
  }
}
