import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawsmatch/pages/web/web_login.dart';
import 'package:pawsmatch/widgets/web_background.dart';

class SuccessDialog extends StatelessWidget {
  final String email;
  
  const SuccessDialog({
    Key? key, 
    required this.email,
  }) : super(key: key);

  void _navigateToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => WebHomepage())
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create success content
    Widget successContent = WebContentContainer(
      child: WebCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFF84A59D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 60,
                color: Color(0xFF84A59D),
              ),
            ),
            SizedBox(height: 20),
            
            // Success title
            Text(
              'Registration Complete!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6572),
              ),
            ),
            SizedBox(height: 16),
            
            // Success message
            Text(
              'Please allow us 8-12 hours to review and process your registration.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                color: Color(0xFF4A6572),
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            
            // Email confirmation
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF6BD60).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFF6BD60).withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: Color(0xFFF6BD60),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'An email confirmation will be sent to:',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4A6572),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 36.0),
                    child: Text(
                      email,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF84A59D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Verification steps notice
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Next Steps',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A6572),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildStepItem(
                    1,
                    'The system moderator will review your documents and verify your organization.',
                  ),
                  SizedBox(height: 12),
                  _buildStepItem(
                    2,
                    'You will receive an email notifying you of your verification status.',
                  ),
                  SizedBox(height: 12),
                  _buildStepItem(
                    3,
                    'Once approved, you can log in to access your organization dashboard.',
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            
            // Return to login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToLogin(context),
                icon: Icon(Icons.login_rounded, color: Colors.white),
                label: Text(
                  'Return to Login',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF84A59D),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return WebBackground(
      contentWidget: successContent,
      subtitleText: 'Registration Success',
    );
  }
  
  // Helper method to build a step item
  Widget _buildStepItem(int step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Color(0xFF84A59D),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: Color(0xFF4A6572),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
