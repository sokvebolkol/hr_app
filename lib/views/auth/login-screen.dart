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
import 'package:package_info_plus/package_info_plus.dart';
import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../services/global_service.dart';
import '../../widgets/environment_switcher_bottom_sheet.dart';
import '../dashboard/manager_dashboard.dart';
import '../dashboard/requester_dashboard.dart';
import '../dashboard/ceo_dashboard_screen.dart';
import 'confirm-password-screen.dart';
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
  String _appVersion = '1.0.0';

  // For 7-tap gesture to open environment switcher
  int _logoTapCount = 0;
  DateTime? _lastTapTime;

  Language language = Language();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // print('Error loading app version');
    }
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
      _showErrorDialog(
        title: language.missingInformation,
        message: language.pleaseEnterBothStaffIdAndPassword,
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final deviceName = await _getDeviceName();
      final deviceToken = await _getFCMToken();
      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      final response = await http
          .post(
            Uri.parse('${ServerService().baseUrl}login'),
            body: {
              "ecard": eCard,
              "upassword": password,
              "device_name": deviceName,
              "device_type": deviceType,
              "device_token": deviceToken ?? '',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(language.connectionTimeout);
            },
          );

      if (response.statusCode == 200) {
        final data = convert.jsonDecode(response.body);
        // ✅ Check if login was successful
        if (data['success'] == false &&
            (data['token'] == null &&
                data['require_password_change'] == false)) {
          final errorMessage = data['message'] ?? language.invalidCredentials;
          _showErrorDialog(title: language.loginFailed, message: errorMessage);
          return;
        }
        // ✅ NEW: Check if password change is required
        if (data['require_password_change'] == true) {
          if (!mounted) return;
          // Show information dialog
          await _showPasswordChangeRequiredDialog();

          // Navigate to password change screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConfirmPasswordScreen(eCard: eCard),
            ),
          );
          return;
        }

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
          targetScreen = const ManagerDashboard();
        } else {
          targetScreen = const RequesterDashboardScreen();
        }

        if (!mounted) return;

        // ✅ Show success message

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      } else if (response.statusCode == 401) {
        // ✅ Unauthorized - wrong credentials
        _showErrorDialog(
          title: language.loginFailed,
          message: language.invalidCredentials,
        );
      } else if (response.statusCode == 422) {
        // ✅ Validation error
        try {
          final data = convert.jsonDecode(response.body);
          final errorMessage = data['message'] ?? language.invalidCredentials;
          _showErrorDialog(title: language.loginFailed, message: errorMessage);
        } catch (_) {
          _showErrorDialog(
            title: language.loginFailed,
            message: language.invalidCredentials,
          );
        }
      } else if (response.statusCode >= 500) {
        // ✅ Server error
        _showErrorDialog(
          title: language.loginFailed,
          message: language.serverExperiencingIssues,
        );
      } else {
        // ✅ Other errors
        String errorMessage = language.unknownError;
        try {
          final data = convert.jsonDecode(response.body);
          errorMessage = data['message'] ?? errorMessage;
        } catch (_) {}

        _showErrorDialog(title: language.loginFailed, message: errorMessage);
      }
    } on SocketException {
      _showErrorDialog(
        title: language.networkError,
        message: language.noInternetConnection,
      );
    } on FormatException {
      _showErrorDialog(
        title: language.dataError,
        message: language.invalidResponseFromServer,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ NEW: Password change required dialog
  Future<void> _showPasswordChangeRequiredDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false, // Prevent back button
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      language.passwordChangeRequired,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.pleaseCreateStrongPassword,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            language.pleaseCreateStrongPassword,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: Text(language.changePasswordNow),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // ✅ NEW: Formal error dialog
  void _showErrorDialog({
    required String title,
    required String message,
    String? technicalDetails,
  }) {
    if (!mounted) return;

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                // Error Title below the icon
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Error Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                if (technicalDetails != null) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      language.technicalDetails,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          technicalDetails,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    language.ok,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    language = context.watch<LanguageLogic>().language;

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: Stack(
            children: [
              SafeArea(
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
              Positioned(
                top: 48,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: primary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back to Welcome Screen',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _handleLogoTap,
          child: Container(
            width: 110,
            height: 110,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/logo_256x256.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogoTap() async {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds since last tap
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _logoTapCount = 0;
    }

    _lastTapTime = now;
    _logoTapCount++;

    if (_logoTapCount == 7) {
      _logoTapCount = 0;
      HapticFeedback.mediumImpact();
      await EnvironmentSwitcherBottomSheet.show(context);
    } else if (_logoTapCount >= 5) {
      // Visual feedback when getting close
      HapticFeedback.lightImpact();
    }
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
          language.staffId,
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
            hintText: language.enterStaffId,
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
              return language.enterStaffId;
            }
            if (value.length != 4) {
              return language.staffId4digits;
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
          language.password,
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
            hintText: language.enterPassword,
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
              return language.enterPassword;
            }
            if (value.length < 6) {
              return language.passwordTooShort;
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
                          _isLoading ? language.logging : language.login,
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
      child: Text(
        language.forgotPassword,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'CHOKCHEY v$_appVersion',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        Text(
          language.copyrightText,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
