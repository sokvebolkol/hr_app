import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/constant.dart';
import 'otp-screen.dart';
import '../../viewmodels/forgot_password_viewmodel.dart';
import 'package:provider/provider.dart';

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordViewModel(),
      child: const ForgotPasswordViewBody(),
    );
  }
}

class ForgotPasswordViewBody extends StatelessWidget {
  const ForgotPasswordViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ForgotPasswordViewModel>(context);

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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Enter your E-Card and Email to receive an OTP",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: vm.userIdController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: "E-Card",
                  prefixIcon: Icon(Icons.credit_card, color: secondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  counterText: "",
                ),
                onChanged: (value) {
                  if (value.length == 4) {
                    FocusScope.of(context).requestFocus(vm.emailFocusNode);
                  }
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: vm.emailController,
                focusNode: vm.emailFocusNode,
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
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
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
                icon:
                    vm.isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.send, color: Colors.white),
                label: Text(vm.isLoading ? "Sending..." : "Get OTP"),
                onPressed:
                    vm.isLoading
                        ? null
                        : () async {
                          if (vm.validateInputs()) {
                            final success = await vm.requestForgotPassword();
                            if (success) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => OtpScreen(
                                        userId: vm.userIdController.text,
                                        email: vm.emailController.text,
                                      ),
                                ),
                              );
                            } else if (vm.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(vm.errorMessage!)),
                              );
                            }
                          }
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
