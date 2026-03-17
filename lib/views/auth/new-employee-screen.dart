import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../services/global_service.dart';
import 'login-screen.dart';
import 'confirm-password-screen.dart';

class EmployeeRegistrationScreen extends StatefulWidget {
  const EmployeeRegistrationScreen({super.key});

  @override
  State<EmployeeRegistrationScreen> createState() =>
      _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState extends State<EmployeeRegistrationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _staffIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFocused = false;
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
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
      });
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _staffIdController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ✅ Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unknown Device';
    String deviceType = 'unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        deviceType = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} (${iosInfo.model})';
        deviceType = 'ios';
      }
    } catch (e) {
      print('❌ Error getting device info: $e');
    }

    return {'device_name': deviceName, 'device_type': deviceType};
  }

  // ✅ Updated Login Function
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final staffId = _staffIdController.text.trim();

    if (staffId.isEmpty) {
      _showErrorDialog(
        title: language.missingInformation,
        message: language.enterStaffIdToContinue,
      );
      return;
    }

    if (staffId.length != 4) {
      _showErrorDialog(
        title: language.invalidStaffId,
        message: language.staffId4digits,
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Get device information
      final deviceInfo = await _getDeviceInfo();
      final response = await http
          .post(
            Uri.parse('${ServerService().baseUrl}new-employee-login'),
            body: {
              "ecard": staffId,
              "device_name": deviceInfo['device_name']!,
              "device_type": deviceInfo['device_type']!,
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your internet connection.',
              );
            },
          );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = convert.jsonDecode(response.body);

        // ✅ Check if password change is required
        if (data['require_password_change'] == true) {
          if (!mounted) return;

          // Navigate to Change Password Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConfirmPasswordScreen(eCard: staffId),
            ),
          );
          return;
        }

        // ✅ Success - Login complete
        if (data['success'] == true) {
          await _showSuccessDialog(
            title: language.loginSuccess,
            message: data['message'] ?? "Welcome! You're now logged in.",
          );

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else {
          // ✅ Login failed
          _showErrorDialog(
            title: language.loginFailed,
            message:
                data['message'] ??
                "User login information not found. Please contact your manager or HR department.",
          );
        }
      } else if (response.statusCode == 404) {
        _showErrorDialog(
          title: language.staffIdNotFound,
          message: language.staffIdNotFoundMsg,
        );
      } else if (response.statusCode == 401) {
        _showErrorDialog(
          title: language.unauthorized,
          message: language.invalidCredentialsContactHR,
        );
      } else if (response.statusCode == 422) {
        try {
          final data = convert.jsonDecode(response.body);
          final errorMessage =
              data['message'] ?? language.validationErrorOccurred;
          _showErrorDialog(
            title: language.validationError,
            message: errorMessage,
          );
        } catch (_) {
          _showErrorDialog(
            title: language.validationError,
            message: language.pleaseCheckStaffId,
          );
        }
      } else {
        String errorMessage =
            "User login information not found. Please contact your manager or HR department.";
        try {
          final data = convert.jsonDecode(response.body);
          errorMessage = data['message'] ?? errorMessage;
        } catch (_) {}

        _showErrorDialog(title: language.loginFailed, message: errorMessage);
      }
    } catch (e) {
      print('❌ Error: $e');
      _showErrorDialog(
        title: language.networkError,
        message: language.noInternetConnection,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
  }) async {
    HapticFeedback.heavyImpact();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade500, Colors.green.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text(language.continueToLogin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withOpacity(0.05),
              Colors.white,
              primary.withOpacity(0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      language.joinAsEmployee,
                      style: TextStyle(
                        color: primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withOpacity(0.3),
                          primary.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildDescriptionCard(),
                        const SizedBox(height: 24),
                        _buildGlassCard(
                          child: Column(
                            children: [
                              _buildStaffIdInput(),
                              const SizedBox(height: 24),
                              _buildRegisterButton(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.blue.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.enterCodeOrStaffId,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              language.followStepsToGetCode,
              style: TextStyle(fontSize: 13, color: secondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            // Steps
            _buildInfoItem(
              icon: Icons.supervisor_account_rounded,
              text: language.contactManagerToRegister,
            ),
            _buildInfoItem(
              icon: Icons.new_releases_outlined,
              text: language.registrationForNewEmployees,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: secondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildStaffIdInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary.withOpacity(0.2), primary.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.badge_rounded, color: primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              language.staffIdOrCode,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                _isFocused
                    ? [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [],
          ),
          child: TextFormField(
            controller: _staffIdController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 4,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            onTap: () {
              setState(() => _isFocused = true);
              HapticFeedback.lightImpact();
            },
            onFieldSubmitted: (_) {
              setState(() => _isFocused = false);
              _register();
            },
            decoration: InputDecoration(
              hintText: '●  ●  ●  ●',
              hintStyle: TextStyle(
                color: Colors.grey[300],
                fontSize: 24,
                letterSpacing: 10,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              counterText: '',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: _isFocused ? primary : Colors.grey[400],
                  size: 28,
                ),
              ),
              suffixIcon:
                  _staffIdController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          _staffIdController.clear();
                          setState(() {});
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '⚠️ ${language.pleaseEnterStaffIdOrCode}';
              }
              if (value.length != 4) {
                return '⚠️ ${language.staffIdOrCode4Digits}';
              }
              return null;
            },
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors:
              _isLoading
                  ? [Colors.grey[300]!, Colors.grey[400]!]
                  : [primary, primary.withOpacity(0.8)],
        ),
        boxShadow:
            _isLoading
                ? []
                : [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child:
            _isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      language.creatingAccount,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login_rounded, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      language.login,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
