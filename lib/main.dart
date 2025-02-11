import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:pawsmatch/main_mobile.dart' as mobile;
import 'package:pawsmatch/main_web.dart' as web;

void main() {
  if (Platform.isAndroid || Platform.isIOS) {
    // Run the mobile version
    mobile.main();
  } else {
    // Run the web version
    web.main();
  }
}

