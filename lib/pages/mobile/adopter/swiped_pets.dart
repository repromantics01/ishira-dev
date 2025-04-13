import 'package:flutter/material.dart';

class SwipedPetsPage extends StatefulWidget {
  const SwipedPetsPage({Key? key}) : super(key: key);

  @override
  _SwipedPetsPageState createState() => _SwipedPetsPageState();
}

class _SwipedPetsPageState extends State<SwipedPetsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      appBar: AppBar(
        title: Text(
          'Swiped Pets',
          style: TextStyle(
            color: Color(0xFF545454),
            fontFamily: 'Arial',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFFEF5F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF725F63)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 100, color: Color(0xFF725F63)),
            SizedBox(height: 20),
            Text(
              'Your Swiped Pets',
              style: TextStyle(
                color: Color(0xFF545454),
                fontSize: 24,
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Pets you\'ve liked will appear here',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 16,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
