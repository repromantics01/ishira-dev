import 'package:flutter/foundation.dart';

/// Helper class for interacting with JavaScript safely across platforms
class JsInteropHelper {

  static bool hasProperty(dynamic jsObject, String property) {
    if (!kIsWeb) return false;
    
    try {
      // This is safe because on non-web platforms, kIsWeb is false
      // so this code doesn't execute
      return jsObject.hasProperty(property);
    } catch (e) {
      print('Error checking JS property $property: $e');
      return false;
    }
  }
  
  static dynamic getProperty(dynamic jsObject, String property) {
    if (!kIsWeb) return null;
    
    try {
      if (hasProperty(jsObject, property)) {
        return jsObject[property];
      }
    } catch (e) {
      print('Error getting JS property $property: $e');
    }
    return null;
  }
}
