import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/web/organization/messages_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileModal extends StatelessWidget {
  final String? userName;
  final String? userAddress;
  final String? profilePictureUrl;
  final String userId; // Added user ID parameter
  final Function? onClose;
  final Function? onBack;

  const UserProfileModal({
    Key? key,
    this.userName = 'User Full Name',
    this.userAddress = 'User\'s Full Address, Baybay City',
    this.profilePictureUrl,
    required this.userId, // Required param for identifying the user
    this.onClose,
    this.onBack, required Null Function() onSendMessage,
  }) : super(key: key);

  // Helper method to generate or get thread ID between organization and user
  String _getThreadId(String organizationId, String userId) {
    // Sort the IDs to ensure consistency regardless of who initiates
    final sortedIds = [organizationId, userId]..sort();
    return "${sortedIds[0]}_${sortedIds[1]}";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: 693,
        height: 515,
        child: Stack(
          children: [
            // White background container
            Positioned(
              left: 85,
              top: 16,
              child: Container(
                width: 568,
                height: 483,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
              ),
            ),
            
            // Content container
            Positioned(
              left: 57,
              top: 32,
              child: Container(
                width: 579,
                height: 483,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(),
                child: Stack(
                  children: [
                    // Profile picture
                    Positioned(
                      left: 242,
                      top: 29,
                      child: Container(
                        width: 139.03,
                        height: 139.03,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF5F5F5),
                          image: profilePictureUrl != null
                            ? DecorationImage(
                                image: NetworkImage(profilePictureUrl!),
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
                        child: profilePictureUrl == null
                          ? Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey.shade600,
                            )
                          : null,
                      ),
                    ),
                    
                    // User full name
                    Positioned(
                      left: 184,
                      top: 180,
                      child: SizedBox(
                        width: 261,
                        child: Text(
                          userName ?? 'User Full Name',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF3F3F3F),
                            fontSize: 30,
                            fontFamily: 'Century Gothic',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    
                    // User address
                    Positioned(
                      left: 159,
                      top: 221,
                      child: SizedBox(
                        width: 310,
                        child: Text(
                          userAddress ?? 'User\'s Full Address, Baybay City',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Century Gothic',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    
                    // Send message button - Updated with navigation
                    Positioned(
                      left: 132,
                      top: 287, // Moved up since email is removed
                      child: InkWell(
                        onTap: () {
                          // Get the current organization ID
                          final currentOrgId = FirebaseAuth.instance.currentUser?.uid;
                          if (currentOrgId != null) {
                            // Generate thread ID using org ID and user ID
                            final threadId = _getThreadId(currentOrgId, userId);
                            
                            // Close the modal
                            Navigator.of(context).pop();
                            
                            // Navigate to the messages page with the thread ID
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MessagesPage(
                                  initialThreadId: threadId,
                                  recipientId: userId,
                                  recipientName: userName ?? 'User',
                                ),
                              ),
                            );
                          } else {
                            // Show error if no org ID found
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not identify organization account')),
                            );
                          }
                        },
                        child: Container(
                          width: 378,
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
                    ),
                    
                    // Close button
                    Positioned(
                      left: 132,
                      top: 347, // Moved up since email is removed
                      child: InkWell(
                        onTap: () {
                          onClose?.call();
                        },
                        child: Container(
                          width: 378,
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
            
            // Back button
            Positioned(
              left: 125,
              top: 41,
              child: InkWell(
                onTap: () {
                  onBack?.call();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Colors.black,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Century Gothic',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
