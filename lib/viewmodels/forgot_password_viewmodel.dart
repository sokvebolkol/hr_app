import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/global_service.dart';
import '../localization/language.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();

  String? errorMessage;
  bool isLoading = false;

  bool validateInputs(Language language) {
    errorMessage = null;
    if (userIdController.text.length != 4) {
      errorMessage = language.userIdMust4Digits;
      notifyListeners();
      return false;
    }
    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(emailController.text)) {
      errorMessage = language.pleaseEnterValidEmail;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> requestForgotPassword(Language language) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ServerService().baseUrl}password/email'),
        body: {'ecard': userIdController.text, 'email': emailController.text},
      );

      isLoading = false;

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        errorMessage = language.userIdOrEmailNotFound;
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = language.networkErrorTryAgain;
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
