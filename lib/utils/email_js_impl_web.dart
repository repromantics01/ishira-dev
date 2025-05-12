import 'package:flutter/foundation.dart';
import 'dart:js' as js;

/// Web-specific implementation of EmailJS functionality
class EmailJsImplementation {
  /// Check if EmailJS is available
  static bool isAvailable() {
    try {
      return js.context.callMethod('eval', ['typeof emailjs !== "undefined"']);
    } catch (e) {
      debugPrint('EmailJS availability check error: $e');
      return false;
    }
  }
  
  /// Send email with EmailJS
  static Future<bool> sendEmail({
    required String serviceId,
    required String templateId,
    required Map<String, dynamic> templateParams,
    String? userId,
  }) async {
    try {
      // Double check required fields
      if (!templateParams.containsKey('to_email') || 
          templateParams['to_email'] == null || 
          templateParams['to_email'].toString().trim().isEmpty) {
        debugPrint('CRITICAL ERROR: to_email is missing or empty in templateParams');
        return false;
      }
      
      // Make sure we have minimal required fields
      var emailParams = Map<String, dynamic>.from(templateParams);
      if (!emailParams.containsKey('from_name')) {
        emailParams['from_name'] = 'PawsMatch Team';
      }
      
      // Convert template params to a JS object
      final jsTemplateParams = js.JsObject.jsify(emailParams);
      
      // Call emailjs.send directly
      js.context['emailjs'].callMethod('send', [
        serviceId,
        templateId,
        jsTemplateParams
      ]);
      
      debugPrint('EmailJS: Email sending initiated');
      return true;
    } catch (e) {
      debugPrint('Error sending email with EmailJS: $e');
      return false;
    }
  }
  
  /// Send test email
  static Future<bool> sendTestEmail(String recipient) async {
    try {
      final params = js.JsObject.jsify({
        'to_email': recipient.trim(),
        'to_name': 'Organization Admin',
        'organization_name': 'Test Organization',
        'organization_location': 'Test Location',
        'login_url': 'https://pawsmatch.app/login',
        'message': 'This is a test message',
        'approval_status': 'approved'
      });
      
      js.context['emailjs'].callMethod('send', [
        'service_sqa9kss',
        'template_pe0txyl',
        params,
        'dSAmVPjE9iRFgTq8z'
      ]);
      
      return true;
    } catch (e) {
      debugPrint('EmailJS test error: $e');
      return false;
    }
  }
  
  /// Log EmailJS status
  static void logStatus() {
    if (isAvailable()) {
      debugPrint('✓ EmailJS is available for use');
      final jsCode = '''
        try {
          console.log("EmailJS object:", emailjs);
          typeof emailjs;
        } catch(e) {
          console.error("Error accessing emailjs:", e);
          "error";
        }
      ''';
      final result = js.context.callMethod('eval', [jsCode]);
      debugPrint('EmailJS type: $result');
    } else {
      debugPrint('✗ EmailJS is not available - check your index.html setup');
    }
  }
}
