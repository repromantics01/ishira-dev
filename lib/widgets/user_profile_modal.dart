import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/web/organization/messages_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/widgets/user_profile_image.dart';

class UserProfileModal extends StatelessWidget {
  final String userName;
  final String userAddress;
  final String userId;
  final String? profilePictureUrl;
  final VoidCallback onClose;

  const UserProfileModal({
    Key? key,
    required this.userName,
    required this.userAddress,
    required this.userId,
    this.profilePictureUrl,
    required this.onClose, required Null Function() onSendMessage, required Null Function() onBack, String? profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User profile image
            UserProfileImage(
              imageUrl: profilePictureUrl,
              fallbackText: userName,
              size: 100,
              showBorder: true,
              borderColor: Colors.grey.shade300,
              backgroundColor: Colors.grey.shade100,
            ),
            SizedBox(height: 16),
            
            // User name
            Text(
              userName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'DM Sans',
              ),
            ),
            
            // Address if available
            if (userAddress.isNotEmpty && userAddress != 'Address information not available')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      userAddress,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 24),
            
            // Close button
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C2BB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
