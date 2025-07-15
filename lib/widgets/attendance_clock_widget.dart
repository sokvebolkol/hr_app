import 'package:flutter/material.dart';

class ClockButtonWidget extends StatelessWidget {
  final IconData icon;
  final String textLabel;
  final Color color;
  final VoidCallback onPressed;

  const ClockButtonWidget({
    super.key,
    required this.icon,
    required this.color,
    required this.textLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        onPressed: onPressed,
        icon: Icon(
          icon, // Button icon
          color: Colors.white,
        ),
        label: Text(
          textLabel, // Button text
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
