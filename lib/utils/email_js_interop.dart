import 'package:flutter/foundation.dart';

// Import implementation conditionally based on platform
import 'email_js_impl_stub.dart'
    if (dart.library.js) 'email_js_impl_web.dart';

/// Utility class to handle EmailJS operations in web environment
class EmailJsInterop {
  // EmailJS configuration constants
  static const String _SERVICE_ID = "service_17bu2ph";
  static const String _APPROVAL_TEMPLATE_ID = "template_pe0txyl";
  static const String _REJECTION_TEMPLATE_ID = "template_tn6g2ed";
  static const String _USER_ID = "dSAmVPjE9iRFgTq8z";

  /// Check if EmailJS is properly loaded and available
  static bool get isEmailJsAvailable {
    if (!kIsWeb) return false;
    return EmailJsImplementation.isAvailable();
  }
  
  /// Send an approval email using the predefined template
  static Future<bool> sendApprovalEmail({
    required Map<String, dynamic> templateParams,
  }) async {
    // Skip on mobile platforms
    if (!kIsWeb) {
      debugPrint('EmailJS is only available in web environment');
      return false;
    }
    
    return sendEmail(
      serviceId: _SERVICE_ID,
      templateId: _APPROVAL_TEMPLATE_ID,
      templateParams: templateParams,
      userId: _USER_ID,
    );
  }
  
  /// Send a rejection email using the predefined template
  static Future<bool> sendRejectionEmail({
    required Map<String, dynamic> templateParams,
  }) async {
    // Skip on mobile platforms
    if (!kIsWeb) {
      debugPrint('EmailJS is only available in web environment');
      return false;
    }
    
    return sendEmail(
      serviceId: _SERVICE_ID,
      templateId: _REJECTION_TEMPLATE_ID,
      templateParams: templateParams,
      userId: _USER_ID,
    );
  }
  
  /// Send an email using EmailJS
  static Future<bool> sendEmail({
    required String serviceId,
    required String templateId,
    required Map<String, dynamic> templateParams,
    String? userId,
  }) async {
    // Skip on mobile platforms
    if (!kIsWeb) {
      debugPrint('EmailJS is only available in web environment');
      return false;
    }
    
    try {
      return await EmailJsImplementation.sendEmail(
        serviceId: serviceId,
        templateId: templateId,
        templateParams: templateParams,
        userId: userId,
      );
    } catch (e) {
      debugPrint('Error sending email with EmailJS: $e');
      return false;
    }
  }
  
  /// Send a direct test email for debugging
  static Future<bool> sendTestEmail(String recipient) async {
    if (!kIsWeb) return false;
    return EmailJsImplementation.sendTestEmail(recipient);
  }
  
  /// Log the EmailJS status for debugging
  static void logStatus() {
    if (!kIsWeb) {
      debugPrint('EmailJS is only available on web platforms');
      return;
    }
    
    EmailJsImplementation.logStatus();
  }
}
