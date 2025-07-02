import 'package:flutter/material.dart';

class InputField extends StatefulWidget {
  final String textString;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final bool number;
  final isPasswordField;

  const InputField({
    Key? key,
    this.textString = '',
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.number = false,
    this.isPasswordField = false,
    required this.icon,
  }) : super(key: key);

  @override
  State<InputField> createState() => _InputFieldState();
}

bool hidePassword = true;

class _InputFieldState extends State<InputField> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = 0;
    double screenHeight = 0;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: screenWidth / 6,
            child: Icon(widget.icon, color: Colors.black, size: 20),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 25),
              child: TextFormField(
                controller: widget.controller,
                enableSuggestions: false,
                autocorrect: false,
                obscureText: widget.isPasswordField ? hidePassword : false,
                keyboardType:
                    widget.number ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 45,
                  ),
                  border: InputBorder.none,
                  hintText: widget.hint,
                  suffixIcon:
                      widget.obscureText
                          ? IconButton(
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            icon: Icon(
                              hidePassword == false
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFFB0B0B0),
                            ),
                          )
                          : null,
                  suffixIconConstraints: const BoxConstraints(
                    minHeight: 24,
                    minWidth: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
