import 'dart:html' as html;

/// Utility class for launching URLs in web environment
class UrlLauncherWeb {
  static void openInNewTab(String url) {
    html.window.open(url, '_blank');
  }
}
