import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String btnText;
  final Function onBtnPressed;
  final Color color;
  final double btnWith;
  final double roundSize;

  const RoundedButton({
    super.key,
    required this.btnText,
    required this.onBtnPressed,
    required this.color,
    this.btnWith = 120,
    this.roundSize = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      color: color,
      borderRadius: BorderRadius.circular(roundSize),
      child: MaterialButton(
        onPressed: () {
          onBtnPressed();
        },
        minWidth: btnWith,
        height: 60,
        child: Text(
          btnText,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Kh Battambang',
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
