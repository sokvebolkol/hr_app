import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:flutter/material.dart';

class InputFormField extends StatelessWidget {
  final String textString;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool number;
  final double height;
  final bool isIcon;
  final onlyRead;
  final isObscureText;
  final Color borderColor;
  final Color iconColor;
  final onTap;

  const InputFormField({
    super.key,
    this.textString = '',
    required this.controller,
    required this.hint,
    this.number = false,
    this.height = 60.0,
    this.isIcon = false,
    this.onlyRead = false,
    this.isObscureText = false,
    required this.icon,
    this.onTap,
    this.borderColor = const Color(primary),
    this.iconColor = const Color(secondary),
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = 0;
    double screenHeight = 0;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.all(screenWidth / 40),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 20),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 0.5, color: borderColor),
      ),
      child: TextFormField(
        onTap: onTap,
        controller: controller,
        readOnly: onlyRead,
        obscureText: isObscureText,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        keyboardType:
            number == false ? TextInputType.text : TextInputType.number,
        autocorrect: false,
        decoration:
            !isIcon
                ? InputDecoration(
                  icon: Icon(icon, color: iconColor, size: 20),
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                )
                : InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
      ),
    );
  }
}
