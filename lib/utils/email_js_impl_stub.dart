import 'package:flutter/foundation.dart';

/// Stub implementation for non-web platforms
class EmailJsImplementation {
  /// Check if EmailJS is available (always false on mobile)
  static bool isAvailable() => false;
  
  /// Send email with EmailJS (stub implementation)
  static Future<bool> sendEmail({
    required String serviceId,
    required String templateId,
    required Map<String, dynamic> templateParams,
    String? userId,
  }) async {
    debugPrint('EmailJS is not available on mobile platforms');
    return false;
  }
  
  /// Send test email (stub implementation)
  static Future<bool> sendTestEmail(String recipient) async {
    debugPrint('EmailJS test email not available on mobile platforms');
    return false;
  }
  
  /// Log EmailJS status (stub implementation)
  static void logStatus() {
    debugPrint('EmailJS is not available on mobile platforms');
  }
}
