import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../services/global_service.dart';
import '../../utils/password_rules.dart';
import 'login-screen.dart';

/// Set New Password screen used by the Forgot Password / first-login reset
/// flows (user is not authenticated). Logged-in users change their password
/// via [ChangePasswordScreen] instead.
///
/// On success, `set-new-password` revokes every token issued for this user
/// (all devices), so any locally stored session must be cleared and the
/// user sent back to Login.
class ConfirmPasswordScreen extends StatefulWidget {
  const ConfirmPasswordScreen({super.key, this.eCard});
  final String? eCard; // Pass eCard from previous screen

  @override
  // ignore: library_private_types_in_public_api
  _ConfirmPasswordScreenState createState() => _ConfirmPasswordScreenState();
}

class _ConfirmPasswordScreenState extends State<ConfirmPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Rebuild live for the requirements checklist.
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _matchesConfirm =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;

  bool get _canSubmit =>
      !_isLoading &&
      PasswordRules.isValid(_newPasswordController.text) &&
      _matchesConfirm;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submit() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError("Please fill in both fields");
      return;
    }

    final ruleError = PasswordRules.firstError(newPassword);
    if (ruleError != null) {
      _showError(ruleError);
      return;
    }

    if (newPassword != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    if (widget.eCard == null || widget.eCard!.isEmpty) {
      _showError("E-Card is missing.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ServerService().baseUrl}set-new-password'),
        body: {"ecard": widget.eCard!, "password": newPassword},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        // The backend revokes every token on success, so any locally stored
        // session is now invalid. Clear it (keeping device-level settings
        // like landing screen / environment) before returning to Login.
        await ServerService().clearUserSession();

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        _showError("Failed to reset password: ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      _showError("Network error. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRequirement(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: met ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: met ? Colors.green[700] : Colors.grey[600],
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final newPassword = _newPasswordController.text;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Set New Password",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: primary.withOpacity(0.1),
                child: Icon(Icons.lock, size: 48, color: primary),
              ),
              const SizedBox(height: 24),
              Text(
                "Create a new password",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your new password must be different from previous passwords.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: "New Password",
                  prefixIcon: Icon(Icons.lock_outline, color: secondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                      color: secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: Icon(Icons.lock_outline, color: secondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),

              // Password requirements checklist
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequirement(
                      "At least ${PasswordRules.minLength} characters",
                      PasswordRules.hasMinLength(newPassword),
                    ),
                    _buildRequirement(
                      "Contains an uppercase letter",
                      PasswordRules.hasUppercase(newPassword),
                    ),
                    _buildRequirement(
                      "Contains a lowercase letter",
                      PasswordRules.hasLowercase(newPassword),
                    ),
                    _buildRequirement(
                      "Contains a number",
                      PasswordRules.hasNumber(newPassword),
                    ),
                    _buildRequirement(
                      "Contains a symbol (e.g. ! @ # \$)",
                      PasswordRules.hasSymbol(newPassword),
                    ),
                    _buildRequirement(
                      "Not a common password",
                      PasswordRules.isNotDisallowed(newPassword),
                    ),
                    _buildRequirement("Passwords match", _matchesConfirm),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _canSubmit ? 1 : 0.55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary,
                      disabledForegroundColor: Colors.white70,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 2,
                    ),
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: SpinKitCircle(
                                color: Colors.white,
                                size: 20,
                              ),
                            )
                            : const Icon(Icons.check_circle_outline),
                    label: Text(_isLoading ? "Resetting..." : "Reset Password"),
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
