import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable background widget for web pages in PawsMatch.
/// 
/// This widget creates a split layout with a decorative left side featuring the PawsMatch logo
/// and cat illustration, and a content area on the right side for forms or other content.
class WebBackground extends StatelessWidget {
  /// The widget to display in the content area (right side).
  final Widget contentWidget;
  
  /// Optional text to display below the main PawsMatch title.
  final String? subtitleText;
  
  /// Creates a WebBackground.
  /// 
  /// The [contentWidget] parameter is required and will be displayed on the right side.
  /// The [subtitleText] parameter is optional and defaults to "Connect • Adopt • Love".
  const WebBackground({
    Key? key,
    required this.contentWidget,
    this.subtitleText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Color(0xFFFEF5F1), // Updated background color to #fef5f1
      body: Row(
        children: [
          // Left side - Logo and illustration
          Expanded(
            child: Container(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo image instead of text
                  Image.asset(
                    'assets/photos/pawsmatch-text.png',
                    width: 550,
                  ),
                  SizedBox(height: 5),
                  Text(
                    subtitleText ?? 'Connect • Adopt • Love',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF84A59D),
                      letterSpacing: 1.2,
                    ),
                  ),
                  //SizedBox(height: 5),
                  // Cat illustration - now 70% of screen height
                  Image.asset(
                    'assets/photos/cat_illustration.png',
                    height: screenHeight * 0.72,
                    fit: BoxFit.contain,
                  ),
                  Spacer(),
                  // Footer text
                  Text(
                    '© ${DateTime.now().year} PawsMatch • Connecting Pets & People with Love',
                    style: GoogleFonts.dmSans(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right side - Content area
          Expanded(
            child: contentWidget,
          ),
        ],
      ),
    );
  }
}

/// A wrapper widget for content to be displayed in the right side of WebBackground.
///
/// This widget applies consistent padding and layout for form contents.
class WebContentContainer extends StatelessWidget {
  /// The widget to display inside the container.
  final Widget child;
  
  /// Creates a WebContentContainer.
  ///
  /// The [child] parameter is required and will be displayed inside the container.
  const WebContentContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
          ],
        ),
      ),
    );
  }
}

/// A reusable card widget for forms and content in PawsMatch web pages.
///
/// This widget creates a styled card with consistent appearance.
class WebCard extends StatelessWidget {
  /// The widget to display inside the card.
  final Widget child;
  
  /// Creates a WebCard.
  ///
  /// The [child] parameter is required and will be displayed inside the card.
  const WebCard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: child,
      ),
    );
  }
}
