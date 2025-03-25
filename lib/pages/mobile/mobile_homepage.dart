import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/mobile/user_login.dart';
import 'package:pawsmatch/pages/mobile/user_registration_form.dart';

class MobileHomepage extends StatelessWidget {
  const MobileHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PawsMatch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => UserLogin())
                    );
                  },
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => UserRegistrationForm())
                    );
                  },
                  child: Text(
                    "Sign up",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome to",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Where we connect pets to loving homes one match at a time...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Image.asset(
                      "assets/homepage.png",
                      width: 400,
                      height: 292,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading homepage image: $error');
                        return Container(
                          width: 400,
                          height: 292,
                          color: Colors.grey[300],
                          child: Center(
                            child: Text('Image not found'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          "P   wsMatch",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Positioned(
                          left: 20,
                          child: Image.asset(
                            "assets/app-logo.png",
                            width: 36,
                            height: 46,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading logo image: $error');
                              return Container(
                                width: 36,
                                height: 46,
                                color: Colors.transparent,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}