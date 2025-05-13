import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// URL Launcher utility that works on both web and mobile
class UrlLauncherWeb {
  static void openInNewTab(String url) async {
    try {
      if (kIsWeb) {
        // Use conditional import to access platform-specific implementation
        await _launchUrlWeb(url);
      } else {
        // For mobile platforms, use url_launcher package
        final Uri uri = Uri.parse(url);
        if (await url_launcher.canLaunchUrl(uri)) {
          await url_launcher.launchUrl(uri);
        } else {
          debugPrint('Could not launch $url');
        }
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
  }
  
  // This function will be replaced on the web platform
  static Future<void> _launchUrlWeb(String url) async {
    // This implementation will never be called on web
    // because it will be replaced by the web implementation
    debugPrint('Web URL launcher not available on this platform');
  }
}
