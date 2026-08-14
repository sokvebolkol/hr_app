import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constant.dart';
import '../../services/global_service.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../auth/welcome.dart';
import '../auth/change_password_screen.dart';
import '../../services/app_update_service.dart';
import '../../widgets/app_update_bottom_sheet.dart';
import '../profile/profile_screen.dart';
import '../settings/environment_selector_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late ProfileViewModel _viewModel;
  bool isCeoUser = false;
  String _appVersion = '1.0.0';
  Color get themeColor => isCeoUser ? secondary : primary;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _checkUserRole();
    _loadAppVersion();
    // Initialize and fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initialize();
    });
  }

  Future<void> _checkUserRole() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final ceoUserValue = pref.getBool("ceoUser") ?? false;
    if (mounted) {
      setState(() {
        isCeoUser = ceoUserValue;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      print('Error loading app version');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: themeColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildBlueHeader(),
                    Positioned(
                      top: 200,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildItem(),
                    ),
                    Positioned(
                      top: 90,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(child: _buildProfileAvatar()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlueHeader() {
    final serverService = ServerService();
    final isProduction =
        serverService.currentEnvironment == Environment.production;

    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          height: 200,
          decoration: BoxDecoration(color: themeColor),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${viewModel.languageLogic.language.version} $_appVersion',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Show environment label only if not production
                      if (!isProduction) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getEnvironmentColor(
                              serverService.currentEnvironment,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getEnvironmentIcon(
                                  serverService.currentEnvironment,
                                ),
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                serverService.baseUrlName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  InkWell(
                    onTap: () => _handleLogout(viewModel),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.exit_to_app,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem() {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 120),
                _buildMenuItem(
                  viewModel: viewModel,
                  icon: Icons.person_outline,
                  title: viewModel.languageLogic.language.myProfile,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  viewModel: viewModel,
                  icon: Icons.lock_outline,
                  title: viewModel.languageLogic.language.changePassword,
                  onTap: () async {
                    await _navigateToChangePassword(viewModel);
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  viewModel: viewModel,
                  icon: Icons.system_update_outlined,
                  title: viewModel.languageLogic.language.checkForUpdate,
                  onTap: () async {
                    await _checkForUpdate(viewModel);
                  },
                ),
                _buildDivider(),
                isCeoUser ? SizedBox() : _buildLandingScreenSelector(),
                _buildDivider(),
                _buildLanguageSelector(),

                // Show Environment Settings only if not production
                if (ServerService().currentEnvironment !=
                    Environment.production) ...[
                  _buildDivider(),
                  _buildMenuItem(
                    viewModel: viewModel,
                    icon: Icons.dns_outlined,
                    title: 'Environment Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EnvironmentSelectorScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar() {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.only(top: 32, bottom: 32),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: viewModel.profileImagePath.isNotEmpty
                      ? NetworkImage(viewModel.profileImagePath)
                      : const AssetImage('assets/images/profile.png')
                          as ImageProvider<Object>,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                viewModel.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                viewModel.position,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required ProfileViewModel viewModel,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: themeColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildLandingScreenSelector() {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.format_line_spacing_rounded,
                color: themeColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  viewModel.languageLogic.language.landingScreen,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLandingButton(
                      viewModel,
                      kLandingScreenDashboard,
                      viewModel.languageLogic.language.dashboard,
                    ),
                    _buildLandingButton(
                      viewModel,
                      kLandingScreenLeave,
                      viewModel.languageLogic.language.leave,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLandingButton(
    ProfileViewModel viewModel,
    int index,
    String label,
  ) {
    final isSelected = viewModel.landingScreenIndex == index;

    return GestureDetector(
      onTap: () {
        if (viewModel.landingScreenIndex != index) {
          viewModel.setLandingScreen(index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.language, color: themeColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  viewModel.languageLogic.language.language,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLanguageButton(viewModel, 'KH', 'ខ្មែរ'),
                    _buildLanguageButton(viewModel, 'EN', 'English'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton(
    ProfileViewModel viewModel,
    String languageCode,
    String label,
  ) {
    final isSelected = viewModel.languageLogic.language.code == languageCode;

    return GestureDetector(
      onTap: () {
        if (viewModel.languageLogic.language.code != languageCode) {
          viewModel.changeLanguage();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: Colors.grey.shade300,
      indent: 58,
    );
  }

  /// User-initiated update check from the menu.
  /// Shows a loading dialog, then either the update sheet or an
  /// "up to date" confirmation.
  Future<void> _checkForUpdate(viewModel) async {
    final language = viewModel.languageLogic.language;

    // Blocking progress dialog while the check runs.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitFadingCircle(color: themeColor, size: 36),
                    const SizedBox(height: 16),
                    Text(
                      language.checkingForUpdate,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    final result = await AppUpdateService.instance.check();

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss progress dialog
    if (!mounted) return;

    switch (result.state) {
      case UpdateCheckState.updateAvailable:
        // Optional: user can postpone even if the backend marks it mandatory,
        // because they reached this from the menu. The startup force-update
        // flow still enforces mandatory upgrades.
        await AppUpdateBottomSheet.show(
          context,
          appVersion: result.latest!,
          updateUrl: result.updateUrl,
          language: language,
          isMandatory: false,
        );
        break;

      case UpdateCheckState.upToDate:
        await _showUpToDateDialog(language, result.currentVersion);
        break;

      case UpdateCheckState.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.couldNotCheckForUpdate),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;
    }
  }

  Future<void> _showUpToDateDialog(dynamic language, String version) {
    return showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.elasticOut,
                  builder:
                      (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.green,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  language.youAreUpToDate,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  language.usingLatestVersion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey[600],
                  ),
                ),
                if (version.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${language.currentVersion}: $version',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(language.ok),
                ),
              ),
            ],
          ),
    );
  }

  // ✅ Updated Change Password Navigation
  Future<void> _navigateToChangePassword(viewModel) async {
    try {
      // The change-password endpoint is token-authenticated, so no eCard is
      // needed here.
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChangePasswordScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Updated Logout Function
  void _handleLogout(ProfileViewModel viewModel) async {
    final shouldLogout = await CustomAlertDialog.showConfirmation(
      context,
      title: viewModel.languageLogic.language.logout,
      message: viewModel.languageLogic.language.logoutConfirmation,
      icon: Icons.logout_rounded,
      iconColor: themeColor,
      yesButtonText: viewModel.languageLogic.language.logout,
      noButtonText: viewModel.languageLogic.language.cancel,
    );

    if (shouldLogout == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitFadingCircle(color: themeColor, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.languageLogic.language.loggingOut,
                    style: const TextStyle(
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

      try {
        // Get token from SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? '';

        if (token.isEmpty) {
          // If no token, just clear local data and navigate
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
          }
          await _clearLocalDataAndNavigate();
          return;
        }

        // Call logout API
        final response = await http
            .post(
          Uri.parse('${ServerService().baseUrl}logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: convert.jsonEncode({'token': token}),
        )
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }
        // Handle response
        if (response.statusCode == 200) {
          final data = convert.jsonDecode(response.body);

          if (data['success'] == true) {
            // Successful logout
            await _clearLocalDataAndNavigate();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    data['message'] ??
                        viewModel.languageLogic.language.loggedOutSuccessfully,
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            // API returned success: false
            await _clearLocalDataAndNavigate();
          }
        } else if (response.statusCode == 401) {
          // Token invalid or expired - still logout locally
          await _clearLocalDataAndNavigate();
        } else {
          // Other error - still logout locally
          await _clearLocalDataAndNavigate();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  viewModel.languageLogic.language.loggedOutLocally,
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Logout Error: $e');

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        // Even on error, clear local data and logout
        await _clearLocalDataAndNavigate();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().contains('timeout')
                    ? viewModel.languageLogic.language.connectionTimeout
                    : viewModel.languageLogic.language.networkErrorLoggedOut,
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // ✅ Clear local data and navigate to welcome screen
  Future<void> _clearLocalDataAndNavigate() async {
    try {
      // Call ViewModel logout to clear local data
      await _viewModel.logout();

      // Clear all SharedPreferences, but keep device-level settings (landing
      // screen choice and selected environment) so they survive logout/login.
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final landingScreenIndex = prefs.getInt('landingScreenIndex');
      final selectedEnvironment = prefs.getString('selected_environment');
      await prefs.clear();
      if (landingScreenIndex != null) {
        await prefs.setInt('landingScreenIndex', landingScreenIndex);
      }
      if (selectedEnvironment != null) {
        await prefs.setString('selected_environment', selectedEnvironment);
      }

      if (mounted) {
        // Navigate to Welcome Screen and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const WelcomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // Still navigate even if clearing fails
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const WelcomeScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  // Helper methods for environment indicator
  Color _getEnvironmentColor(Environment env) {
    switch (env) {
      case Environment.production:
        return Colors.red;
      case Environment.uat:
        return Colors.orange;
      case Environment.development:
        return Colors.blue;
    }
  }

  IconData _getEnvironmentIcon(Environment env) {
    switch (env) {
      case Environment.production:
        return Icons.cloud_done;
      case Environment.uat:
        return Icons.science;
      case Environment.development:
        return Icons.computer;
    }
  }
}
