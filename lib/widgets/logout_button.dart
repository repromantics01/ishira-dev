import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/pages/mobile/mobile_homepage.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: TextButton(
        onPressed: () async {
          final bool? confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
          
          // If confirmed, sign out and navigate to mobile homepage
          if (confirm == true) {
            await FirebaseAuth.instance.signOut();
            
            // Use Navigator to go to MobileHomepage instead of using named route
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const MobileHomepage(),
              ),
              (route) => false, // Remove all previous routes
            );
          }
        },
        child: Text(
          'Logout',
          style: TextStyle(
            color: Colors.black.withOpacity(0.56),
            fontSize: 16,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
