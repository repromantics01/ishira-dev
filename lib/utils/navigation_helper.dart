import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/mobile/shared/profile_and_account_settings.dart';
import 'package:pawsmatch/pages/mobile/shared/inbox.dart';
import 'package:pawsmatch/pages/mobile/shared/conversation_page.dart';

class NavigationHelper {
  // Navigate to profile and account settings
  static void navigateToProfileSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileAndAccountSettings()),
    );
  }
  
  static void navigateToInbox(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InboxPage()),
    );
  }

  static Widget profileSettingsPage(BuildContext context) {
    return ProfileAndAccountSettings();
  }
}
