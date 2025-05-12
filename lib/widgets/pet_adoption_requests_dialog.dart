import 'package:flutter/material.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/models/adopt.dart';
import 'package:pawsmatch/models/profile.dart';
import 'package:pawsmatch/services/firebase_adopt_service.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/widgets/user_profile_modal.dart'; // Add this import
import 'package:pawsmatch/widgets/user_profile_image.dart'; // Add this import

class PetAdoptionRequestsDialog extends StatefulWidget {
  final Pet pet;
  final Function? onClose;

  const PetAdoptionRequestsDialog({
    Key? key,
    required this.pet,
    this.onClose,
  }) : super(key: key);

  @override
  State<PetAdoptionRequestsDialog> createState() => _PetAdoptionRequestsDialogState();
}

class _PetAdoptionRequestsDialogState extends State<PetAdoptionRequestsDialog> {
  final FirebaseAdoptService _adoptService = FirebaseAdoptService();
  final FirebaseProfileService _profileService = FirebaseProfileService();
  final DatabaseAccountService _accountService = DatabaseAccountService();
  final ScrollController _scrollController = ScrollController();
  
  List<Adopt> _adoptionRequests = [];
  Map<String, Map<String, dynamic>> _userProfiles = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAdoptionRequests();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAdoptionRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Query for adoption requests for this specific pet
      final adoptionsSnapshot = await FirebaseFirestore.instance
          .collection('adopt')
          .where('pet_id', isEqualTo: widget.pet.pet_id)
          .get();
      
      // Convert to adopt objects
      List<Adopt> adopts = [];
      for (var doc in adoptionsSnapshot.docs) {
        try {
          final data = doc.data();
          adopts.add(Adopt.fromJson(data));
        } catch (e) {
          print('Error parsing adoption document ${doc.id}: $e');
        }
      }
      
      print('Found ${adopts.length} adoption requests for pet ${widget.pet.pet_name}');

      // Get user profiles for each adoption request
      Map<String, Map<String, dynamic>> profiles = {};
      for (var adopt in adopts) {
        try {
          // Get profile information for each account
          final profileData = await _profileService.getUserProfile(adopt.account_id);
          if (profileData != null) {
            profiles[adopt.account_id] = profileData;
          }
        } catch (e) {
          print('Error fetching profile for account ${adopt.account_id}: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _adoptionRequests = adopts;
          _userProfiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load adoption requests: $e';
          _isLoading = false;
        });
      }
      print('Error loading adoption requests: $e');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MM/dd/yy HH:mm').format(date);
  }

  String _getUserName(String accountId) {
    final profile = _userProfiles[accountId];
    if (profile != null) {
      final firstName = profile['first_name'] as String? ?? '';
      final lastName = profile['last_name'] as String? ?? '';
      
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }
    
    return 'Unknown User';
  }

  String _getUserAddress(String accountId) {
    final profile = _userProfiles[accountId];
    if (profile != null && profile['address'] != null) {
      return profile['address'] as String;
    }
    return 'No address provided';
  }

  String? _getUserProfilePicture(String accountId) {
    final profile = _userProfiles[accountId];
    if (profile != null && profile['profile_photo_url'] != null) {
      return profile['profile_photo_url'] as String;
    }
    return null;
  }

  // Add this new method to show the user profile modal
  void _showUserProfileModal(String accountId) {
    final profile = _userProfiles[accountId];
    if (profile != null) {
      final firstName = profile['first_name'] as String? ?? '';
      final lastName = profile['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();
      final address = profile['address'] as String? ?? 'No address provided';
      final profilePictureUrl = profile['profile_image_url'] as String?;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return UserProfileModal(
            userName: fullName.isEmpty ? 'Unknown User' : fullName,
            userAddress: address,
            profilePictureUrl: profilePictureUrl,
            userId: accountId, // Pass the account ID
            onClose: () {
              Navigator.of(context).pop();
            },
            onSendMessage: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Messaging functionality coming soon!')),
              );
            },
            onBack: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
    } else {
      // Show error if profile not loaded
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load user profile')),
      );
    }
  }

  Widget _buildAdopterAvatar(String accountId) {
    final profile = _userProfiles[accountId];
    final profileImageUrl = profile != null ? profile['profile_image_url'] as String? : null;
    final firstName = profile != null ? profile['first_name'] as String? ?? '' : '';
    final lastName = profile != null ? profile['last_name'] as String? ?? '' : '';
    final fullName = '$firstName $lastName'.trim();
    
    return UserProfileImage(
      imageUrl: profileImageUrl,
      fallbackText: fullName.isEmpty ? accountId.substring(0, 2) : fullName,
      size: 45,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 693,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Title section
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 49, 40, 20),
                child: Text(
                  '(${_adoptionRequests.length}) Adoption Requests',
                  style: const TextStyle(
                    color: Color(0xFF3F3F3F),
                    fontSize: 30,
                    fontFamily: 'Century Gothic',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              
              // List of adoption requests
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Error',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                          ],
                        ),
                      )
                    : _adoptionRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No Adoption Requests',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF545454),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'There are no adoption requests for ${widget.pet.pet_name} yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  color: Color(0xFF545454).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 45),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _adoptionRequests.length,
                            itemBuilder: (context, index) {
                              final adopt = _adoptionRequests[index];
                              final userName = _getUserName(adopt.account_id);
                              final userAddress = _getUserAddress(adopt.account_id);
                              final profilePicture = _getUserProfilePicture(adopt.account_id);
                              
                              return InkWell( // Wrap the container in InkWell to make it clickable
                                onTap: () {
                                  _showUserProfileModal(adopt.account_id);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 0),
                                  height: 120,
                                  child: Stack(
                                    children: [
                                      // Background
                                      Container(
                                        width: double.infinity,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      
                                      // User profile photo
                                      Positioned(
                                        left: 56,
                                        top: 20,
                                        child: Container(
                                          width: 79.26,
                                          height: 79.26,
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFFF5F5F5),
                                            image: profilePicture != null
                                              ? DecorationImage(
                                                  image: NetworkImage(profilePicture),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(
                                                width: 1,
                                                color: Colors.black.withOpacity(0.29),
                                              ),
                                              borderRadius: BorderRadius.circular(73),
                                            ),
                                          ),
                                          child: profilePicture == null
                                            ? Icon(
                                                Icons.person,
                                                size: 40,
                                                color: Colors.grey.shade600,
                                              )
                                            : null,
                                        ),
                                      ),
                                      
                                      // User name
                                      Positioned(
                                        left: 159,
                                        top: 34,
                                        child: SizedBox(
                                          width: 261,
                                          child: Text(
                                            userName,
                                            style: const TextStyle(
                                              color: Color(0xFF3F3F3F),
                                              fontSize: 20,
                                              fontFamily: 'Century Gothic',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Date submitted
                                      Positioned(
                                        right: 40,
                                        top: 46,
                                        child: Text(
                                          _formatDate(adopt.date_submitted),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: Color(0xFF3F3F3F),
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ),
                                      
                                      // User address
                                      Positioned(
                                        left: 159,
                                        top: 62,
                                        child: SizedBox(
                                          width: 300,
                                          child: Text(
                                            userAddress,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              fontFamily: 'Century Gothic',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Bottom separator
                                      Positioned(
                                        left: 14,
                                        bottom: 0,
                                        child: Container(
                                          width: 576,
                                          height: 1,
                                          decoration: const BoxDecoration(color: Color(0xFF9E9E9E)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
              
              // Close button at bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 30),
                child: InkWell(
                  onTap: () {
                    widget.onClose?.call();
                  },
                  child: Container(
                    width: 378,
                    height: 40.50,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFEDEDED),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFF8B8B8B),
                        ),
                        borderRadius: BorderRadius.circular(250),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'CLOSE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1E2C2B),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
