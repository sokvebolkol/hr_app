import 'package:flutter/material.dart';
import '../../constants/constant.dart';

class LeaveRequestScreen extends StatelessWidget {
  const LeaveRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Request Leave"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 64, color: primary),
            const SizedBox(height: 16),
            const Text(
              "Leave Request",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Apply for your leave easily here.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            // Add your leave request form or list here
          ],
        ),
      ),
    );
  }
}