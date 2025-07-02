import 'dart:math';
import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'confirm-password-screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({Key? key}) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "OTP",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      body: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(screenWidth / 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight / 8),
            Container(
              alignment: Alignment.center,
              child: Text(
                "Enter the code",
                style: TextStyle(
                    fontSize: screenWidth / 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              alignment: Alignment.center,
              child: Text("from your phone number",
                  style: TextStyle(
                      fontSize: screenWidth / 24, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: screenHeight / 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _textFieldOTP(first: true, last: false),
                _textFieldOTP(first: false, last: false),
                _textFieldOTP(first: false, last: false),
                _textFieldOTP(first: false, last: true),
              ],
            ),
            const SizedBox(
              height: 50,
            ),
            GestureDetector(
              onTap: () async {
                // String username = userNameController.text.trim();
                // String password = passwordController.text.trim();
              },
              child: Container(
                width: 350,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: const BoxDecoration(
                    color: Color(0xFF007AFF),
                    borderRadius: BorderRadius.all(Radius.circular(30))),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfirmPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'SEND',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Khmer OS',
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textFieldOTP({required bool first, last}) {
    return SizedBox(
      height: 50,
      width: 42,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: TextFormField(
          autofocus: true,
          onChanged: (value) {
            if (value.length == 1 && last == false) {
              FocusScope.of(context).nextFocus();
            }
            if (value.length == 0 && first == false) {
              FocusScope.of(context).previousFocus();
            }
          },
          showCursor: false,
          readOnly: false,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            counter: const Offstage(),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(width: 2, color: Color(primary)),
              borderRadius: BorderRadius.circular(50),
            ),
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(width: 2, color: Color(primary)),
                borderRadius: BorderRadius.circular(50)),
          ),
        ),
      ),
    );
  }
}
