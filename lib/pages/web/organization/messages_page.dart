import 'package:flutter/material.dart';
import 'org_sidebar.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: Center(
        child: Container(
          width: 1584,
          height: 1024,
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                top: 0,
                child: OrgSidebar(),
              ),
              Center(
                child: Text(
                  'This is messages_page page!',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 32,
                    color: Color(0xFF545454),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
