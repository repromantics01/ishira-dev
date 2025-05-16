import 'dart:html' as html;

Future<void> launchUrlWeb(String url) async {
  html.window.open(url, '_blank');
}