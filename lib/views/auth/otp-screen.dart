import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../../constants/constant.dart';
import '../../services/global_service.dart';
import 'confirm-password-screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.userId, required this.email});
  final String userId;
  final String email;

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _timer;
  int _secondsLeft = 300; // 5 minutes
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
    _startTimer();
    _otpFocusNode.requestFocus();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _otpFocusNode.dispose();
    _otpController.dispose();
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (_secondsLeft == 0) {
      setState(() {
        _errorMessage = "OTP expired. Please request a new one.";
      });
      return;
    }
    final otp = _otpController.text;
    if (otp.length != 6) {
      setState(() {
        _errorMessage = "Please enter the 6-digit OTP.";
      });
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      final response = await http.post(
        Uri.parse('${ServerService().baseUrl}password/reset'),
        body: {"otp": otp},
      );
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmPasswordScreen(eCard: widget.userId),
          ),
        );
      } else {
        setState(() {
          _errorMessage = "Invalid OTP or expired. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error. Please try again.";
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "OTP Verification",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.07,
              vertical: 40,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: primary.withOpacity(0.1),
                    child: Icon(Icons.lock_outline, size: 38, color: primary),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Enter OTP",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We sent a code to your email\n${widget.email}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  if (_secondsLeft > 0)
                    Text(
                      "OTP expires in ${_formatTimer(_secondsLeft)}",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    )
                  else
                    const Text(
                      "OTP expired. Please request a new one.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: "6-digit OTP",
                      counterText: "",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (_) => _onSend(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 2,
                      ),
                      onPressed:
                          _isVerifying || _secondsLeft == 0 ? null : _onSend,
                      child:
                          _isVerifying
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text("Verify & Continue"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        _secondsLeft == 0
                            ? () {
                              _startTimer();
                              setState(() {
                                _otpController.clear();
                                _errorMessage = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("OTP resent!")),
                              );
                            }
                            : null,
                    child: Text(
                      "Resend OTP",
                      style: TextStyle(
                        color: _secondsLeft == 0 ? primary : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
