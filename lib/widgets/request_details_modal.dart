import 'package:flutter/material.dart';
import 'package:pawsmatch/models/adopt.dart';
import 'package:pawsmatch/models/surrender.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/widgets/user_profile_image.dart'; // Add this import

class RequestDetailsModal extends StatefulWidget {
  final dynamic request; // Can be Surrender or Adopt
  final Pet? pet;
  final Map<String, dynamic>? userProfile;
  final Account? userAccount;
  final Function()? onClose;
  final Function()? onApprove;
  final Function()? onReject;
  final Function()? onMessage;
  final Function()? onComplete; // New callback for completing adoptions
  final String? organizationId; // Add this parameter for pet photos

  const RequestDetailsModal({
    Key? key,
    required this.request,
    this.pet,
    this.userProfile,
    this.userAccount,
    this.onClose,
    this.onApprove,
    this.onReject,
    this.onMessage,
    this.onComplete, // Add this parameter
    this.organizationId,
  }) : super(key: key);

  @override
  State<RequestDetailsModal> createState() => _RequestDetailsModalState();
}

class _RequestDetailsModalState extends State<RequestDetailsModal> {
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoadingPhotos = false;
  bool _isProcessing = false; // Flag to show processing state during status updates
  List<String> _photoUrls = [];
  String _mainPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadPetPhotos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Get species-specific cute icon
  Widget _getPetSpeciesIcon(String species) {
    double iconSize = 60.0;
    Color iconColor = const Color(0xFF725F63);
    
    // Convert to lowercase for case-insensitive comparison
    String speciesLower = species.toLowerCase();
    
    if (speciesLower.contains('cat')) {
      return Icon(Icons.pets, size: iconSize, color: iconColor);
    } else if (speciesLower.contains('dog')) {
      return Transform.rotate(
        angle: 3.14159 / 4, // 45 degrees in radians
        child: Icon(Icons.pets, size: iconSize, color: iconColor),
      );
    } else if (speciesLower.contains('bird')) {
      return Icon(Icons.flutter_dash, size: iconSize, color: iconColor);
    } else if (speciesLower.contains('fish')) {
      return Icon(Icons.water, size: iconSize, color: iconColor);
    } else if (speciesLower.contains('rabbit')) {
      return Icon(Icons.cruelty_free, size: iconSize, color: iconColor);
    } else if (speciesLower.contains('hamster') || speciesLower.contains('guinea pig')) {
      return Icon(Icons.pets, size: iconSize, color: iconColor);
    } else {
      // Default pet icon
      return Icon(Icons.pets, size: iconSize, color: iconColor);
    }
  }

  Future<void> _loadPetPhotos() async {
    if (widget.pet == null || widget.pet!.photo_id.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingPhotos = true;
    });

    try {
      List<String> photoUrls = [];
      
      // Process each photo ID in parallel for better performance
      final futures = widget.pet!.photo_id.map((photoId) => _photoService.getPhotoUrl(photoId));
      final results = await Future.wait(futures);
      
      // Filter out null results
      photoUrls = results.whereType<String>().toList();
      
      setState(() {
        _photoUrls = photoUrls;
        _mainPhotoUrl = photoUrls.isNotEmpty ? photoUrls.first : '';
        _isLoadingPhotos = false;
      });

      print('Loaded ${photoUrls.length} pet photos');
    } catch (e) {
      print('Error loading pet photos: $e');
      setState(() {
        _isLoadingPhotos = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSurrenderRequest = widget.request is Surrender;
    final String requestType = isSurrenderRequest ? 'Surrender' : 'Adoption';
    final String requestStatus = isSurrenderRequest 
        ? (widget.request as Surrender).surrender_status.toString().split('.').last
        : (widget.request as Adopt).application_status.toString().split('.').last;
    
    // Determine if request is pending based on type
    final isPending = isSurrenderRequest 
        ? (widget.request as Surrender).surrender_status == SurrenderStatus.Pending
        : (widget.request as Adopt).application_status == ApplicationStatus.Pending;
    
    // For surrender requests, check if it's approved (reviewed)
    final isSurrenderApproved = isSurrenderRequest && 
        (widget.request as Surrender).surrender_status == SurrenderStatus.Approved;
    
    // User information
    final String userName = _getUserName();
    final String userAddress = _getUserAddress();
    
    // Pet information
    final String petName = widget.pet?.pet_name ?? 'Unknown';
    final int petAge = widget.pet != null 
        ? DateTime.now().difference(widget.pet!.birthdate).inDays ~/ 365 
        : 0;
    final String petGender = widget.pet?.gender ?? 'Unknown';
    final String petSpecies = widget.pet?.species ?? 'Unknown';
    final String petBreed = widget.pet?.breed ?? 'Unknown';
    final bool isSpayedOrNeutered = widget.pet?.is_neutered_or_spayed ?? false;
    final String vaccinationStatus = widget.pet != null 
        ? widget.pet!.vaccination_status.toString().split('.').last 
        : 'Unknown';
    final String petDescription = widget.pet?.description ?? 'No description available';
    
    // Dialog size constraints
    final double modalWidth = 693;
    final double modalHeight = 850;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: modalWidth,
        height: modalHeight,
        child: Stack(
          children: [
            // Background container with shadow
            Positioned(
              left: 15,
              top: 16,
              child: Container(
                width: 663,
                height: 834,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
            
            // Content container with scrolling
            Positioned(
              left: 63,
              top: 64,
              child: Container(
                width: 597,
                height: 740,
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: Radius.circular(10),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status indicator
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(requestStatus).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(requestStatus),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '$requestType Request - $requestStatus',
                              style: TextStyle(
                                color: _getStatusColor(requestStatus),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // User profile section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User profile image - updated
                              UserProfileImage(
                                imageUrl: widget.userProfile?['profile_image_url'] as String?,
                                fallbackText: _getUserFullName(),
                                size: 60,
                              ),
                              SizedBox(width: 15),
                              
                              // User information
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User name
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        color: const Color(0xFF3F3F3F),
                                        fontSize: 30,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    
                                    // User address
                                    Text(
                                      userAddress,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    
                                    // Message button
                                    InkWell(
                                      onTap: widget.onMessage,
                                      child: Container(
                                        height: 40.50,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFC0D6B6),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(0xFF8B8B8B),
                                            ),
                                            borderRadius: BorderRadius.circular(250),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'SEND A MESSAGE',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: const Color(0xFF1E2C2B),
                                              fontSize: 14,
                                              fontFamily: 'DM Sans',
                                              fontWeight: FontWeight.w500,
                                              height: 1.14,
                                              letterSpacing: 1.25,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Divider
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 24),
                            height: 1,
                            color: const Color(0xFF9E9E9E),
                          ),
                          
                          // Pet Details header
                          Center(
                            child: Text(
                              'Pet Details',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF3F3F3F),
                                fontSize: 30,
                                fontFamily: 'Century Gothic',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Pet details section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pet species icon (not from database)
                              Container(
                                width: 141,
                                height: 141,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: _getPetSpeciesIcon(petSpecies),
                                ),
                              ),
                              SizedBox(width: 24),
                              
                              // Pet information
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Pet name and age
                                    Text(
                                      '${petName.toUpperCase()}, $petAge',
                                      style: TextStyle(
                                        color: const Color(0xFF3F3F3F),
                                        fontSize: 30,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    
                                    // Pet gender and species
                                    Text(
                                      '$petGender $petSpecies',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    
                                    // Pet details in a card
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Column(
                                        children: [
                                          // Breed
                                          _buildDetailRow('Breed:', petBreed),
                                          SizedBox(height: 8),
                                          
                                          // Location
                                          _buildDetailRow('Location:', widget.pet?.address ?? "Unknown"),
                                          SizedBox(height: 8),
                                          
                                          // Spayed/Neutered
                                          _buildDetailRow('Spayed/Neutered:', isSpayedOrNeutered ? 'Yes' : 'No'),
                                          SizedBox(height: 8),
                                          
                                          // Vaccination Status
                                          _buildDetailRow('Vaccination:', vaccinationStatus),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          
                          // Pet Photos section
                          if (_photoUrls.isNotEmpty) ...[
                            Text(
                              'Pet Photos',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontFamily: 'Century Gothic',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            // Photo gallery
                            Container(
                              height: 172,
                              child: _isLoadingPhotos
                                ? Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _photoUrls.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: EdgeInsets.only(right: 12),
                                        width: 172,
                                        height: 172,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.grey[200],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(
                                            _photoUrls[index],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                            SizedBox(height: 24),
                          ],
                          
                          // Description section
                          Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontFamily: 'Century Gothic',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 12),
                          
                          // Description text
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              petDescription,
                              style: TextStyle(
                                color: const Color(0xFF545454),
                                fontSize: 15,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                height: 1.47,
                              ),
                            ),
                          ),
                          SizedBox(height: 32),
                          
                          // Action buttons section based on request type and status
                          Center(
                            child: Column(
                              children: [
                                // For Adoption Requests - standard approve/reject buttons
                                if (!isSurrenderRequest && isPending)
                                  Column(
                                    children: [
                                      // Approve button - full width like close button
                                      _buildFullWidthActionButton(
                                        'APPROVE',
                                        Colors.green.shade800,
                                        Colors.green.shade100,
                                        Colors.green.shade700,
                                        widget.onApprove,
                                      ),
                                      SizedBox(height: 12),
                                      // Reject button - full width like close button
                                      _buildFullWidthActionButton(
                                        'REJECT',
                                        Colors.red.shade800,
                                        Colors.red.shade100,
                                        Colors.red.shade700,
                                        widget.onReject,
                                      ),
                                    ],
                                  ),
                                
                                // For Surrender Requests - state-specific buttons
                                if (isSurrenderRequest) ...[
                                  if (isPending) 
                                    // Mark as Reviewed button for pending surrender
                                    _buildFullWidthActionButton(
                                      _isProcessing ? 'PROCESSING...' : 'MARK AS REVIEWED',
                                      Colors.blue.shade800,
                                      Colors.blue.shade100, 
                                      Colors.blue.shade700,
                                      _isProcessing ? null : () => _updateSurrenderStatus(SurrenderStatus.Approved),
                                    ),
                                  if (isSurrenderApproved)
                                    // Mark as Complete button for approved/reviewed surrender
                                    _buildFullWidthActionButton(
                                      _isProcessing ? 'PROCESSING...' : 'MARK AS COMPLETE',
                                      Colors.green.shade800,
                                      Colors.green.shade100,
                                      Colors.green.shade700,
                                      _isProcessing ? null : () => _updateSurrenderStatus(SurrenderStatus.Rejected),
                                    ),
                                  if (!isPending && !isSurrenderApproved)
                                    // Completed indicator (non-clickable)
                                    Container(
                                      width: 378,
                                      height: 40.50,
                                      decoration: ShapeDecoration(
                                        color: Colors.green.shade100,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            width: 1,
                                            color: Colors.green.shade700,
                                          ),
                                          borderRadius: BorderRadius.circular(250),
                                        ),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green.shade800, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'SURRENDER PROCESS COMPLETE',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontSize: 14,
                                                fontFamily: 'DM Sans',
                                                fontWeight: FontWeight.w500,
                                                height: 1.14,
                                                letterSpacing: 1.25,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                                
                                // Add consistent spacing before close button
                                SizedBox(height: 20),
                                
                                // Close button (for all cases) - unchanged
                                InkWell(
                                  onTap: widget.onClose,
                                  child: Container(
                                    width: 378,
                                    height: 40.50,
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          width: 1,
                                          color: const Color(0xFF8B8B8B),
                                        ),
                                        borderRadius: BorderRadius.circular(250),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'CLOSE',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: const Color(0xFF1E2C2B),
                                          fontSize: 14,
                                          fontFamily: 'DM Sans',
                                          fontWeight: FontWeight.w500,
                                          height: 1.14,
                                          letterSpacing: 1.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Add bottom space for scrolling
                          SizedBox(height: 20),
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
    );
  }

  // Modified method to update surrender status and pet status together
  Future<void> _updateSurrenderStatus(SurrenderStatus newStatus) async {
    // Only process if the request is a Surrender
    if (!(widget.request is Surrender) || widget.pet == null) return;
    
    final Surrender surrender = widget.request as Surrender;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // First query for the surrender document using unique fields
      final querySnapshot = await _firestore.collection('surrender')
          .where('pet_id', isEqualTo: surrender.pet_id)
          .where('account_id', isEqualTo: surrender.account_id)
          .get();
          
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No matching surrender document found');
      }
      
      // Get the actual document ID from the query result
      final String documentId = querySnapshot.docs.first.id;
      print('Found surrender document with ID: $documentId');
      
      // 1. Update the surrender status in Firestore using the retrieved document ID
      await _firestore.collection('surrender').doc(documentId).update({
        'surrender_status': newStatus.toString().split('.').last,
      });

      // 2. Update pet status based on surrender status
      PetStatus newPetStatus;
      
      if (newStatus == SurrenderStatus.Approved) {
        // When surrender is reviewed/approved, pet becomes available for adoption
        newPetStatus = PetStatus.Available;
      } else if (newStatus == SurrenderStatus.Rejected) {
        // In this context, "Rejected" marks the end of process
        // Pet is now fully under organization's care (or could be adopted)
        newPetStatus = PetStatus.Available;
      } else {
        // For any other status (like Pending), keep pet as is
        newPetStatus = widget.pet!.pet_status;
      }
      
      // Update the pet status in Firestore
      await _firestore.collection('pet').doc(widget.pet!.pet_id).update({
        'pet_status': newPetStatus.toString().split('.').last,
        'acquisition_type': AcquisitionType.Surrendered.toString().split('.').last,
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pet surrender status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Close the modal
      if (widget.onClose != null) {
        widget.onClose!();
      }
      
    } catch (e) {
      print('Error updating surrender status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Helper method to update adoption status
  Future<void> _updateAdoptionStatus(ApplicationStatus newStatus) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('adopt')
          .doc(widget.request.adopt_id)
          .update({
        'application_status': newStatus.toString().split('.').last,
        'date_completed': newStatus == ApplicationStatus.Completed 
            ? DateTime.now().toIso8601String() 
            : widget.request.date_completed?.toIso8601String(),
      });

      // Close the modal
      widget.onClose!();

    } catch (e) {
      print('Error updating adoption status: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontStyle: FontStyle.italic,
            fontFamily: 'Century Gothic',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontFamily: 'Century Gothic',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // New helper method to build full width action buttons (like close button)
  Widget _buildFullWidthActionButton(String text, Color textColor, Color bgColor, Color borderColor, Function()? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 378,  // Same width as close button
        height: 40.50,
        decoration: ShapeDecoration(
          color: bgColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: borderColor,
            ),
            borderRadius: BorderRadius.circular(250),  // Same border radius as close button
          ),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
              height: 1.14,
              letterSpacing: 1.25,
            ),
          ),
        ),
      ),
    );
  }
  
  // Remove or keep the original _buildActionButton method if needed for compatibility
  // Helper method to build action buttons
  Widget _buildActionButton(String text, Color textColor, Color bgColor, Color borderColor, Function()? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 178,
        height: 40.50,
        decoration: ShapeDecoration(
          color: bgColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: borderColor,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
              height: 1.14,
              letterSpacing: 1.25,
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to get status color - update to include Completed and Cancelled
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'completed':
        return Colors.blue.shade700;
      case 'cancelled':
        return Colors.grey.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Helper methods for user information
  String _getUserName() {
    if (widget.userProfile != null) {
      final String firstName = widget.userProfile!['first_name'] ?? '';
      final String lastName = widget.userProfile!['last_name'] ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName';
      }
    }
    
    if (widget.userAccount != null) {
      return widget.userAccount!.account_username;
    }
    
    return 'Unknown User';
  }

  String _getUserAddress() {
    if (widget.userProfile != null && widget.userProfile!['address'] != null) {
      return widget.userProfile!['address'];
    }
    return 'No address provided';
  }

  // Helper method to get user's full name
  String _getUserFullName() {
    if (widget.userProfile != null) {
      final firstName = widget.userProfile!['first_name'] as String? ?? '';
      final lastName = widget.userProfile!['last_name'] as String? ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }
    return widget.userAccount?.account_username ?? 'User';
  }
}
