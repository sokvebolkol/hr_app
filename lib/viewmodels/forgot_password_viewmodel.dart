import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/global_service.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();

  String? errorMessage;
  bool isLoading = false;

  bool validateInputs() {
    errorMessage = null;
    if (userIdController.text.length != 4) {
      errorMessage = "User ID must be 4 digits.";
      notifyListeners();
      return false;
    }
    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(emailController.text)) {
      errorMessage = "Please enter a valid email address.";
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> requestForgotPassword() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ServerService().baseUrl}password/email'),
        body: {
          'ecard': userIdController.text, 
          'email': emailController.text,
        },
      );

      isLoading = false;

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        errorMessage = "User ID or Email not found.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = "Network error. Please try again.";
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    userIdController.dispose();
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }
}
