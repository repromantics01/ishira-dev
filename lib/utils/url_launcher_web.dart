import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

// Conditional import
import 'url_launcher_web_impl.dart'
    if (dart.library.html) 'url_launcher_web_impl_web.dart' as web_impl;

/// URL Launcher utility that works on both web and mobile
class UrlLauncherWeb {
  static void openInNewTab(String url) async {
    try {
      if (kIsWeb) {
        // Use web-specific implementation
        await web_impl.launchUrlWeb(url);
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
}