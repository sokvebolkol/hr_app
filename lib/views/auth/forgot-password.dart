import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/constant.dart';
import 'otp-screen.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode(); // Add this line

  @override
  void dispose() {
    userIdController.dispose();
    emailController.dispose();
    emailFocusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  bool validateEmail(String email) {
    // Basic email validation regex
    final RegExp regex = RegExp(
      r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$',
    );
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: primary.withOpacity(0.1),
                  child: Icon(Icons.lock_reset, size: 48, color: primary),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  "Reset your password",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Enter your User ID and Email to receive an OTP.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: userIdController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: "User ID",
                  prefixIcon: Icon(Icons.person_outline, color: secondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  counterText: "", // Hide character counter
                ),
                onChanged: (value) {
                  if (value.length == 4) {
                    FocusScope.of(context).requestFocus(emailFocusNode);
                  }
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                focusNode: emailFocusNode, // Attach the focus node here
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined, color: secondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 2,
                ),
                icon: Icon(Icons.send, color: Colors.white),
                label: const Text("Get OTP"),
                onPressed: () {
                  if (userIdController.text.isEmpty ||
                      emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter both User ID and Email"),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  if (!validateEmail(emailController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a valid email address"),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => OtpScreen(
                            userId: userIdController.text,
                            email: emailController.text,
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Back to Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
