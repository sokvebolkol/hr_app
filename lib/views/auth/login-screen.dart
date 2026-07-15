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
import 'package:msal_auth/msal_auth.dart';
import '../../services/ms_auth_service.dart';
import '../../widgets/environment_switcher_bottom_sheet.dart';
import '../dashboard/manager_dashboard.dart';
import '../dashboard/requester_dashboard.dart';
import '../dashboard/ceo_dashboard_screen.dart';
import '../leaves/leave_request/leave_request_screen.dart';
import '../../viewmodels/profile_viewmodel.dart';
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
  bool _isMsLoading = false;
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
        return token;
      } else {
        return null;
      }
    } catch (e) {
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
              "password": password,
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
        final bcode = data['userLoginInfo']['bcode']?.toString() ?? '';
        final isApprover = data['userProfile']['is_approver'] ?? false;
        final ceoUser = data['userProfile']['is_ceo'] ?? false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId);
        await prefs.setString('bcode', bcode);
        await prefs.setBool('isApprover', isApprover);
        await prefs.setBool('ceoUser', ceoUser);

        if (deviceToken != null) {
          await prefs.setString('fcm_token', deviceToken);
          await prefs.setString('device_type', deviceType);
          print('✅ FCM Token saved: $deviceToken');
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

        // Capture the navigator before removing the login route so the
        // follow-up landing push doesn't rely on this removed context.
        final navigator = Navigator.of(context);
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => targetScreen),
          (route) => false,
        );

        _openLandingScreenIfNeeded(navigator, prefs);
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

  Future<void> _loginWithMicrosoft() async {
    setState(() => _isMsLoading = true);
    HapticFeedback.lightImpact();

    try {
      final accessToken = await MsAuthService.signIn();

      // null means the user explicitly cancelled — just stop the spinner.
      if (accessToken == null) {
        if (mounted) setState(() => _isMsLoading = false);
        return;
      }

      final deviceName = await _getDeviceName();
      final deviceToken = await _getFCMToken();
      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      final response = await http
          .post(
            Uri.parse('${ServerService().baseUrl}auth/microsoft'),
            headers: {'Content-Type': 'application/json'},
            body: convert.jsonEncode({
              'access_token': accessToken,
              'device_name': deviceName,
              'device_type': deviceType,
              'device_token': deviceToken ?? '',
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(language.connectionTimeout),
          );

      if (response.statusCode == 200) {
        final data = convert.jsonDecode(response.body);

        if (data['success'] == false || data['token'] == null) {
          final errorMessage = data['message'] ?? language.microsoftLoginFailed;
          _showErrorDialog(title: language.loginFailed, message: errorMessage);
          return;
        }

        final token = data['token'];
        final userId = data['userLoginInfo']['uid'];
        final bcode = data['userLoginInfo']['bcode']?.toString() ?? '';
        final isApprover = data['userProfile']['is_approver'] ?? false;
        final ceoUser = data['userProfile']['is_ceo'] ?? false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId);
        await prefs.setString('bcode', bcode);
        await prefs.setBool('isApprover', isApprover);
        await prefs.setBool('ceoUser', ceoUser);

        if (deviceToken != null) {
          await prefs.setString('fcm_token', deviceToken);
          await prefs.setString('device_type', deviceType);
        }

        if (!mounted) return;

        Widget targetScreen;
        if (ceoUser) {
          targetScreen = const CeoDashboardScreen();
        } else if (isApprover) {
          targetScreen = const ManagerDashboard();
        } else {
          targetScreen = const RequesterDashboardScreen();
        }

        // Capture the navigator before removing the login route so the
        // follow-up landing push doesn't rely on this removed context.
        final navigator = Navigator.of(context);
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => targetScreen),
          (route) => false,
        );

        _openLandingScreenIfNeeded(navigator, prefs);
      } else {
        String errorMessage = language.microsoftLoginFailed;
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
    } on MsalException catch (e) {
      _showErrorDialog(
        title: language.loginFailed,
        message:
            e.message.isNotEmpty ? e.message : language.microsoftLoginFailed,
      );
    } catch (_) {
      _showErrorDialog(
        title: language.loginFailed,
        message: language.microsoftLoginFailed,
      );
    } finally {
      if (mounted) setState(() => _isMsLoading = false);
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
                    onPressed: () {
                      // Close the dialog only. The awaiting login flow then
                      // pushes ConfirmPasswordScreen with the user's eCard.
                      Navigator.of(context).pop();
                    },
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

  // Honour the user's landing screen preference after login. If they chose
  // "Leave", open the Leave Request form on top of their dashboard so the back
  // button returns them to the dashboard. Defaults to Dashboard.
  void _openLandingScreenIfNeeded(
    NavigatorState navigator,
    SharedPreferences prefs,
  ) {
    final landingScreenIndex =
        prefs.getInt('landingScreenIndex') ?? kLandingScreenDashboard;
    if (landingScreenIndex == kLandingScreenLeave) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
      );
    }
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                const SizedBox(height: 60),
                                _buildHeader(),
                                const SizedBox(height: 32),
                                _buildLoginCard(),
                                const Spacer(),
                                _buildFooter(),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
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
            width: 100,
            height: 100,
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
        const SizedBox(height: 16),
        Text(
          "Chokchey HR",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Human Resource Portal",
          style: TextStyle(fontSize: 15, color: Colors.grey[700]),
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
      padding: const EdgeInsets.all(16),
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
            _buildOrDivider(),
            const SizedBox(height: 16),
            _buildMicrosoftLoginButton(),
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
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: userNameController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 4,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            hintText: language.enterStaffId,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: Colors.black87,
              size: 22,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 42,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.only(left: 4, top: 14, bottom: 14),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              language.password,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            _buildForgotPasswordButton(),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _login(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: language.enterPassword,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.black87,
              size: 22,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 42,
            ),
            suffixIcon: IconButton(
              splashRadius: 20,
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
                HapticFeedback.lightImpact();
              },
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.grey.shade500,
                size: 22,
              ),
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.only(left: 4, top: 14, bottom: 14),
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
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        language.forgotPassword,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            language.orDivider,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }

  Widget _buildMicrosoftLoginButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: (_isLoading || _isMsLoading) ? null : _loginWithMicrosoft,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        ),
        child:
            _isMsLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/microsoft_logo.png',
                      width: 20,
                      height: 20,
                      errorBuilder:
                          (_, __, ___) => const Icon(
                            Icons.window,
                            size: 20,
                            color: Color(0xFF00A4EF),
                          ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      language.loginWithMicrosoft,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
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
