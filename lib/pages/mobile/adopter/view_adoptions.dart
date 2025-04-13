import 'package:flutter/material.dart';

class ViewAdoptionsPage extends StatefulWidget {
  const ViewAdoptionsPage({Key? key}) : super(key: key);

  @override
  _ViewAdoptionsPageState createState() => _ViewAdoptionsPageState();
}

class _ViewAdoptionsPageState extends State<ViewAdoptionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      appBar: AppBar(
        title: Text(
          'Your Adoptions',
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
            Icon(Icons.assignment, size: 100, color: Color(0xFF725F63)),
            SizedBox(height: 20),
            Text(
              'Your Adoptions',
              style: TextStyle(
                color: Color(0xFF545454),
                fontSize: 24,
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Pets you\'re in the process of adopting',
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
