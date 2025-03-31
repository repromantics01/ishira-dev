import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/web/web_login.dart';

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
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/photos/success-image.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Main message
            Positioned(
              left: 329,
              top: 222,
              child: SizedBox(
                width: 818, 
                height: 109,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'DONE!\n',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 40  ,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.17,
                        ),
                      ),
                      TextSpan(
                        text: 'Please allow us 8-12 hours to review and process your registration.\n',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 36,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.50,
                        ),
                      ),
                      TextSpan(
                        text: 'An email should be sent to you confirming your verification.',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 24,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w400,
                          height: 2,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Email info
            Positioned(
              left: 329,
              top: 370,
              child: SizedBox(
                width: 818,
                child: Text(
                  'We will send confirmation to: $email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF868686),
                    fontSize: 18,
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            
            // Back to login button
            Positioned(
              left: 479,
              top: 450,
              child: Container(
                width: 518,
                child: InkWell(
                  onTap: () => _navigateToLogin(context),
                  child: Container(
                    width: 518,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF212121),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 470,
                          child: Text(
                            'RETURN TO LOGIN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFFEF5F0),
                              fontSize: 16,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1,
                              letterSpacing: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
