import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pawsmatch/main_mobile.dart' as mobile;
import 'package:pawsmatch/main_web.dart' as web;

void main() {
  if (kIsWeb) {
    // Run the web version
    web.main();
  } else {
    // Run the mobile version
    mobile.main();
  }
}
