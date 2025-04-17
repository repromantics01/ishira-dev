import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/mobile/shared/profile_and_account_settings.dart';

class NavigationHelper {
  // Navigate to profile and account settings
  static void navigateToProfileSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileAndAccountSettings()),
    );
  }
}
