import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../constants/constant.dart';
// import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../services/global_service.dart';
import '../dashboard/requester_dashboard.dart';
import '../dashboard/approver_dashboard_screen.dart';
import '../dashboard/ceo_dashboard_screen.dart';
import 'forgot-password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Language language = Language();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      }
    } catch (e) {
      return 'Unknown Device';
    }
    return 'Unknown Device';
  }

  Future<String?> _getFCMToken() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final String? token = await messaging.getToken();
        print('🔥 FCM Token obtained: ${token?.substring(0, 20)}...');
        return token;
      } else {
        print('❌ Notification permission denied');
        return null;
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final eCard = userNameController.text.trim();
    final password = passwordController.text.trim();

    if (eCard.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Please enter Staff ID and Password");
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final deviceName = await _getDeviceName();
      final deviceToken = await _getFCMToken();
      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      print('🔐 Logging in with device: $deviceName');
      print('📱 Device type: $deviceType');
      print('🔥 FCM Token: ${deviceToken != null ? "✅ Obtained" : "❌ Failed"}');

      final response = await http.post(
        Uri.parse('${ServerService().baseUrl}login'),
        body: {
          "ecard": eCard,
          "upassword": password,
          "device_name": deviceName,
          "device_type": deviceType,
          "device_token": deviceToken ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = convert.jsonDecode(response.body);
        final token = data['token'];
        final userId = data['userLoginInfo']['uid'];
        final isApprover = data['userProfile']['is_approver'] ?? false;
        final ceoUser = data['userProfile']['is_ceo'] ?? false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId);
        await prefs.setBool('isApprover', isApprover);
        await prefs.setBool('ceoUser', ceoUser);

        if (deviceToken != null) {
          await prefs.setString('fcm_token', deviceToken);
          await prefs.setString('device_type', deviceType);
          print('✅ FCM token and device type saved locally');
        }

        Widget targetScreen;

        if (ceoUser) {
          targetScreen = const CeoDashboardScreen();
        } else if (isApprover) {
          targetScreen = const ApproverDashboardScreen();
        } else {
          targetScreen = const DashboardScreen();
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      } else {
        _showErrorSnackBar("Login failed: ${response.body}");
      }
    } catch (e) {
      print('❌ Login error: $e');
      _showErrorSnackBar("Network error. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // language = context.watch<LanguageLogic>().language;

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                height:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        _buildHeader(),
                        const SizedBox(height: 60),
                        _buildLoginCard(),
                        const SizedBox(height: 20),
                        // _buildLanguageSelector(),
                        const Spacer(),
                        _buildFooter(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserIdField(),
            const SizedBox(height: 24),
            _buildPasswordField(),
            const SizedBox(height: 32),
            _buildLoginButton(),
            const SizedBox(height: 20),
            _buildForgotPasswordButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Staff ID',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: userNameController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            hintText: 'Enter your Staff ID',
            prefixIcon: Icon(Icons.person_outline, color: primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            counterText: "", // Hide character counter
          ),
          onChanged: (value) {
            if (value.length == 4) {
              FocusScope.of(context).nextFocus();
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your Staff ID';
            }
            if (value.length != 4) {
              return 'Staff ID must be 4 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _login(),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock_outlined, color: primary),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
                HapticFeedback.lightImpact();
              },
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade600,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 3) {
              return 'Password must be at least 3 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _login,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLoading ? "Logging in..." : "Login",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPassword()),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text(
        'Forgot Password?',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Widget _buildLanguageSelector() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(24),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.withOpacity(0.15),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         GestureDetector(
  //           onTap: () {
  //             if (language.code != 'KH') {
  //               context.read<LanguageLogic>().toggleLanguage();
  //             }
  //           },
  //           child: AnimatedContainer(
  //             duration: const Duration(milliseconds: 200),
  //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //             decoration: BoxDecoration(
  //               color:
  //                   language.code == 'KH'
  //                       ? primary.withOpacity(0.15)
  //                       : Colors.transparent,
  //               borderRadius: BorderRadius.circular(18),
  //             ),
  //             child: Row(
  //               children: [
  //                 const Text('🇰🇭', style: TextStyle(fontSize: 22)),
  //                 if (language.code == 'KH')
  //                   const Padding(
  //                     padding: EdgeInsets.only(left: 6),
  //                     child: Icon(
  //                       Icons.check_circle,
  //                       color: Colors.green,
  //                       size: 18,
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         GestureDetector(
  //           onTap: () {
  //             if (language.code != 'EN') {
  //               context.read<LanguageLogic>().toggleLanguage();
  //             }
  //           },
  //           child: AnimatedContainer(
  //             duration: const Duration(milliseconds: 200),
  //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //             decoration: BoxDecoration(
  //               color:
  //                   language.code == 'EN'
  //                       ? primary.withOpacity(0.15)
  //                       : Colors.transparent,
  //               borderRadius: BorderRadius.circular(18),
  //             ),
  //             child: Row(
  //               children: [
  //                 const Text('🇬🇧', style: TextStyle(fontSize: 22)),
  //                 if (language.code == 'EN')
  //                   const Padding(
  //                     padding: EdgeInsets.only(left: 6),
  //                     child: Icon(
  //                       Icons.check_circle,
  //                       color: Colors.green,
  //                       size: 18,
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Chokchey HR v1.0.0',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        Text(
          '© 2025 Chokchey. All rights reserved.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
