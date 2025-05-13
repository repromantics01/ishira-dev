import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import 'dart:html' as html;

/// Direct email testing utility using inline JavaScript
class DirectEmailTest {
  /// Send a test email using direct JavaScript injection
  static bool sendTestEmail(String recipientEmail) {
    if (!kIsWeb) {
      debugPrint('Direct email test only works on web platforms');
      return false;
    }
    
    try {
      debugPrint('Attempting to send direct test email to: $recipientEmail');
      
      // Create a script element with pure JavaScript
      final scriptElement = html.ScriptElement();
      
      // Set the JavaScript content to execute EmailJS directly
      scriptElement.text = '''
        console.log("Starting direct EmailJS test with raw JavaScript");
        
        // Log EmailJS presence
        console.log("EmailJS object exists:", typeof emailjs !== "undefined");
        
        // Only proceed if EmailJS is loaded
        if (typeof emailjs !== "undefined") {
          emailjs.send(
            "service_sqa9kss", 
            "template_pe0txyl",
            {
              to_email: "$recipientEmail",
              org_name: "Test Organization",
              org_location: "Test Location",
              login_url: "https://pawsmatch.app/login"
            },
            "dSAmVPjE9iRFgTq8z"
          ).then(
            function(response) {
              console.log("SUCCESS:", response.status, response.text);
            },
            function(error) {
              console.log("FAILED:", error);
            }
          );
        } else {
          console.error("EmailJS not loaded!");
        }
      ''';
      
      // Add script to document body
      html.document.body?.append(scriptElement);
      
      // Remove script after execution
      scriptElement.remove();
      
      debugPrint('Email test script injected and executed');
      return true;
    } catch (e) {
      debugPrint('Error in direct email test: $e');
      return false;
    }
  }

  /// Inject EmailJS SDK and initialize it if not already loaded
  static void ensureEmailJSLoaded() {
    if (!kIsWeb) return;
    
    try {
      // Create a script element
      final scriptElement = html.ScriptElement();
      scriptElement.src = "https://cdn.jsdelivr.net/npm/@emailjs/browser@3/dist/email.min.js";
      
      // After script loads, initialize EmailJS
      scriptElement.onLoad.listen((_) {
        final initScript = html.ScriptElement();
        initScript.text = '''
          console.log("Initializing EmailJS programmatically");
          emailjs.init("dSAmVPjE9iRFgTq8z");
          console.log("EmailJS initialization complete");
        ''';
        html.document.body?.append(initScript);
        initScript.remove();
      });
      
      // Add script to document head
      html.document.head?.append(scriptElement);
      
      debugPrint('EmailJS script loading requested');
    } catch (e) {
      debugPrint('Error ensuring EmailJS is loaded: $e');
    }
  }
}
