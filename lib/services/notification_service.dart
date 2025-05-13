import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/utils/email_js_interop.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // EmailJS configuration
  final String _emailJsServiceId = 'service_sqa9kss'; 
  final String _emailJsTemplateIdApproval = 'template_pe0txyl'; 
  final String _emailJsTemplateIdRejection = 'template_tn6g2ed'; 
  final String _emailJsUserId = 'dSAmVPjE9iRFgTq8z'; 
  final String _emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  
  final http.Client _httpClient;
  
  NotificationService({http.Client? httpClient}) : 
    _httpClient = httpClient ?? http.Client();
  
  /// Send an organization verification notification using EmailJS
  Future<bool> sendOrganizationVerificationEmail({
    required Organization organization,
    required List<String> recipientEmails,
    required bool isApproved,
    String? message,
  }) async {
    try {
      // Validate recipient emails
      if (recipientEmails.isEmpty) {
        debugPrint('Error: No recipient emails provided');
        return false;
      }
      
      // Filter out any empty emails
      final validEmails = recipientEmails.where((email) => email.trim().isNotEmpty).toList();
      if (validEmails.isEmpty) {
        debugPrint('Error: All provided emails were empty or invalid');
        return false;
      }
      
      // Store notification in Firestore for in-app notifications
      await _storeNotification(
        recipientIds: organization.admin_ids,
        title: isApproved 
            ? 'Organization Verification Approved' 
            : 'Organization Verification Rejected',
        body: isApproved
            ? 'Your organization "${organization.org_name}" has been verified successfully.'
            : 'Your organization "${organization.org_name}" verification request was rejected.',
        type: 'organization_verification',
        metadata: {
          'organization_id': organization.org_id,
          'is_approved': isApproved,
          'custom_message': message,
        }
      );
      
      // Create email parameters - use directly in template or send as parameters
      final emailParams = _getEmailParams(
        organization, 
        validEmails, 
        isApproved,
        message
      );
      
      // For debugging in development mode
      if (kDebugMode) {
        debugPrint('Sending email to: ${validEmails.join(", ")}');
        debugPrint('Primary recipient: ${validEmails.first}');
        debugPrint('Email subject: ${isApproved ? "Organization Approved" : "Organization Verification Update"}');
        debugPrint('Email parameters: $emailParams');
      }

      // Use direct browser EmailJS SDK if we're on web, otherwise use the REST API
      if (kIsWeb) {
        // Now use direct function calls for approval vs rejection emails
        if (isApproved) {
          // The HTML content is now set on the EmailJS template in their dashboard
          // We just need to send the parameters for the template to use
          return await EmailJsInterop.sendApprovalEmail(templateParams: emailParams);
        } else {
          return await EmailJsInterop.sendRejectionEmail(templateParams: emailParams);
        }
      } else {
        // Non-web platform fallback - use HTTP API
        final response = await _httpClient.post(
          Uri.parse(_emailJsUrl),
          headers: {
            'Content-Type': 'application/json',
            'origin': 'https://pawsmatch.app'
          },
          body: json.encode({
            'service_id': _emailJsServiceId,
            'template_id': isApproved ? _emailJsTemplateIdApproval : _emailJsTemplateIdRejection,
            'user_id': _emailJsUserId,
            'template_params': emailParams,
          }),
        );
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('Email sent successfully via EmailJS REST API');
          return true;
        } else {
          debugPrint('EmailJS error: ${response.body}');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      return false;
    }
  }
  
  // Helper method to create template parameters for EmailJS
  Map<String, dynamic> _getEmailParams(
    Organization organization, 
    List<String> recipientEmails,
    bool isApproved,
    String? message
  ) {
    // Ensure we have at least one valid email
    if (recipientEmails.isEmpty) {
      debugPrint("ERROR: No recipient emails provided!");
      throw Exception("No recipient emails provided");
    }
    
    final String toEmail = recipientEmails.first.trim();
    debugPrint('Using recipient email: $toEmail');
    
    // IMPORTANT: These parameters must match EXACTLY what your EmailJS template expects
    if (isApproved) {
      return {
        'from_name': 'PawsMatch Support', // Required by EmailJS
        'to_email': toEmail, // Required by EmailJS - the recipient's email address
        'subject': 'Organization Approved - PawsMatch',
        
        // Template-specific variables - make sure these match template placeholders
        'org_name': organization.org_name,
        'org_location': organization.location ?? 'Not specified',
        'login_url': 'https://pawsmatch.app/login',
        'message': 'Your organization has been approved!',
      };
    } else {
      return {
        'from_name': 'PawsMatch Support', // Required by EmailJS
        'to_email': toEmail, // Required by EmailJS - the recipient's email address
        'subject': 'Organization Verification Update - PawsMatch',
        
        // Template-specific variables - make sure these match template placeholders
        'org_name': organization.org_name, 
        'message': message ?? 'Your organization does not meet our current verification requirements.',
        'login_url': 'https://pawsmatch.app/login',
      };
    }
  }
  
  // Store notification in Firestore for in-app notification center
  Future<void> _storeNotification({
    required List<String> recipientIds,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Create the notification document
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'title': title,
        'body': body,
        'type': type,
        'created_at': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });
      
      // Add a recipient mapping for each user
      for (String userId in recipientIds) {
        final userNotificationRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationRef.id);
            
        batch.set(userNotificationRef, {
          'notification_id': notificationRef.id,
          'read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error storing notification: $e');
    }
  }
}
