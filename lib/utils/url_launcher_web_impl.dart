import 'dart:js' as js;

// This file is only imported on web platforms
void _launchUrlWeb(String url) {
  js.context.callMethod('open', [url, '_blank']);
}
