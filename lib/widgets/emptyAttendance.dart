import 'package:flutter/material.dart';

class EmptyAttendance extends StatelessWidget {
  const EmptyAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_busy, size: 100.0, color: Colors.grey),
        SizedBox(height: 20.0),
        Text(
          'No attendance clocks found.',
          style: TextStyle(fontSize: 18.0, color: Colors.grey),
        ),
      ],
    );
  }
}
