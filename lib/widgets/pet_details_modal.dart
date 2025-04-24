import 'package:flutter/material.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsmatch/widgets/user_profile_modal.dart'; // Add this import

class PetDetailsModal extends StatefulWidget {
  final Pet pet;
  final Function? onClose;
  final Function? onUpdatePet;
  final Function? onViewAdoptionRequests;

  const PetDetailsModal({
    Key? key,
    required this.pet,
    this.onClose,
    this.onUpdatePet,
    this.onViewAdoptionRequests,
  }) : super(key: key);

  @override
  State<PetDetailsModal> createState() => _PetDetailsModalState();
}

class _PetDetailsModalState extends State<PetDetailsModal> {
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoadingPhotos = true;
  List<String> _photoUrls = [];
  String? _surrendererName;
  String? _surrendererId; // Keep this field to store surrenderer account ID

  @override
  void initState() {
    super.initState();
    _loadPetPhotos();
    _loadSurrendererInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPetPhotos() async {
    if (widget.pet.photo_id.isEmpty) {
      setState(() {
        _isLoadingPhotos = false;
      });
      return;
    }

    try {
      List<String> photoUrls = [];
      
      // Process each photo ID in parallel for better performance
      final futures = widget.pet.photo_id.map((photoId) => _photoService.getPhotoUrl(photoId));
      final results = await Future.wait(futures);
      
      // Filter out null results
      photoUrls = results.whereType<String>().toList();
      
      if (mounted) {
        setState(() {
          _photoUrls = photoUrls;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      print('Error loading pet photos: $e');
      if (mounted) {
        setState(() {
          _isLoadingPhotos = false;
        });
      }
    }
  }

  Future<void> _loadSurrendererInfo() async {
    try {
      if (widget.pet.acquisition_type == AcquisitionType.Surrendered) {
        // Get the surrender record for this pet
        final surrenderDocs = await _firestore
            .collection('surrender')
            .where('pet_id', isEqualTo: widget.pet.pet_id)
            .get();
            
        if (surrenderDocs.docs.isNotEmpty) {
          final surrenderDoc = surrenderDocs.docs.first;
          final accountId = surrenderDoc.data()['account_id'] as String?;
          
          if (accountId != null) {
            // Store the account ID for later use
            _surrendererId = accountId;
            
            // Get the user profile for this account
            final profileDocs = await _firestore
                .collection('profile')
                .where('account_id', isEqualTo: accountId)
                .get();
                
            if (profileDocs.docs.isNotEmpty) {
              final profileDoc = profileDocs.docs.first;
              final firstName = profileDoc.data()['first_name'] as String? ?? '';
              final lastName = profileDoc.data()['last_name'] as String? ?? '';
              final address = profileDoc.data()['address'] as String? ?? 'Address not available';
              
              if (mounted) {
                setState(() {
                  _surrendererName = '$firstName $lastName'.trim();
                  if (_surrendererName!.isEmpty) {
                    _surrendererName = 'Unknown User';
                  }
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading surrenderer info: $e');
    }
  }
  
  // Update method to show user profile modal without email
  void _showSurrendererProfile(BuildContext context) {
    if (_surrendererId != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return UserProfileModal(
            userName: _surrendererName ?? 'Unknown User',
            userAddress: 'Address information not available',
            userId: _surrendererId!,
            onClose: () {
              Navigator.of(context).pop();
            },
            onBack: () {
              Navigator.of(context).pop();
            },
            onSendMessage: () {},
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot load surrenderer profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate pet age in years
    final petAge = DateTime.now().difference(widget.pet.birthdate).inDays ~/ 365;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 693,
          // Remove fixed height to allow scrolling to work properly
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(46, 40, 46, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet header section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pet image
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey[200],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _isLoadingPhotos
                              ? Center(child: CircularProgressIndicator())
                              : _photoUrls.isNotEmpty
                                  ? Image.network(
                                      _photoUrls.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(Icons.pets, size: 60, color: Colors.grey[600]),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Icon(Icons.pets, size: 60, color: Colors.grey[600]),
                                    ),
                        ),
                        SizedBox(width: 16),
                        
                        // Pet details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Pet name and age
                                  Text(
                                    '${widget.pet.pet_name.toUpperCase()}, $petAge',
                                    style: TextStyle(
                                      color: const Color(0xFF3F3F3F),
                                      fontSize: 32,
                                      fontFamily: 'Century Gothic',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    decoration: ShapeDecoration(
                                      color: _getStatusColor(widget.pet.pet_status),
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          width: 1,
                                          strokeAlign: BorderSide.strokeAlignCenter,
                                          color: const Color(0xFFBDBDBD),
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                    ),
                                    child: Text(
                                      _getStatusText(widget.pet.pet_status),
                                      style: TextStyle(
                                        color: const Color(0xFF1E2C2B),
                                        fontSize: 12,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              // Gender and Species
                              Text(
                                '${widget.pet.gender} ${widget.pet.species}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Century Gothic',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Breed
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Breed:',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${widget.pet.breed}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              
                              // Location
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Location:',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${widget.pet.address}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              
                              // Spayed/Neutered
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Is Spayed/Neutered:',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${widget.pet.is_neutered_or_spayed ? 'Yes' : 'No'}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              
                              // Vaccination Status
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Vaccination Status:',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${_getVaccinationStatusText(widget.pet.vaccination_status)}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Century Gothic',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Photo gallery - Add improved error handling for images
                    if (_photoUrls.isNotEmpty) ...[
                      Text(
                        'Photos',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontFamily: 'Century Gothic',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 170,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photoUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 180,
                              height: 170,
                              margin: EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey[200],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                _photoUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading image: $error');
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
                                        SizedBox(height: 8),
                                        Text(
                                          'Image failed to load',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
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
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / 
                                            loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    
                    // Description
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
                    Text(
                      widget.pet.description,
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 15,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.47,
                      ),
                    ),
                    SizedBox(height: 20), // Reduced from 24 to 20
                    
                    // Surrenderer info (if pet was surrendered) - Make it clickable
                    if (widget.pet.acquisition_type == AcquisitionType.Surrendered) ...[
                      Row(
                        children: [
                          Text(
                            'Surrendered by:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: 'Century Gothic',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          InkWell( // Make this text clickable
                            onTap: () {
                              _showSurrendererProfile(context);
                            },
                            child: Text(
                              _surrendererName ?? 'Loading...',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: 'Century Gothic',
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20), // Reduced from 24 to 20
                    ],
                    
                    SizedBox(height: 12), // Extra space before buttons
                    
                    // Action buttons
                    InkWell(
                      onTap: () {
                        widget.onViewAdoptionRequests?.call();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 40.50,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFEFCECB),
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
                            '${widget.pet.pet_name.toUpperCase()}\'S ADOPTION REQUESTS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF1E2C2B),
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Update Pet Details button
                    InkWell(
                      onTap: () {
                        widget.onUpdatePet?.call();
                      },
                      child: Container(
                        width: double.infinity,
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
                            'UPDATE PET DETAILS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF1E2C2B),
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Close button
                    InkWell(
                      onTap: () {
                        widget.onClose?.call();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 40.50,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFEDEDED),
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
                              letterSpacing: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10), // Add bottom padding for better scroll appearance
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get status text
  String _getStatusText(PetStatus status) {
    switch (status) {
      case PetStatus.Available:
        return 'FOR ADOPTION';
      case PetStatus.Adopted:
        return 'ADOPTED';
      case PetStatus.Pending:
        return 'PENDING';
      default:
        return 'UNKNOWN';
    }
  }

  // Helper method to get status color
  Color _getStatusColor(PetStatus status) {
    switch (status) {
      case PetStatus.Available:
        return const Color(0xFFE48C8A); // Pink/red color for adoption
      case PetStatus.Adopted:
        return Colors.blue.shade200; // Blue for adopted
      case PetStatus.Pending:
        return Colors.orange.shade200; // Orange for pending
      default:
        return Colors.grey.shade300;
    }
  }

  // Helper method to get vaccination status text
  String _getVaccinationStatusText(VaccinationStatus status) {
    switch (status) {
      case VaccinationStatus.Full:
        return 'Fully Vaccinated';
      case VaccinationStatus.Partial:
        return 'Partially Vaccinated';
      case VaccinationStatus.None:
        return 'Not Vaccinated';
      default:
        return 'Unknown';
    }
  }
}
