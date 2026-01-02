import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import '../../constants/constant.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../services/global_service.dart';
import '../auth/welcome.dart';
import '../../widgets/custom_alert_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileViewModel _viewModel;

  bool isCeoUser = false;
  Color get themeColor => isCeoUser ? secondary : primary;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.initialize();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final ceoUserValue = pref.getBool("ceoUser") ?? false;
    setState(() {
      isCeoUser = ceoUserValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Scaffold(
              backgroundColor: Colors.grey[100],
              body: Center(
                child: Center(child: SpinKitFadingCircle(color: themeColor)),
              ),
            );
          }

          if (viewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
              viewModel.clearError();
            });
          }

          return Scaffold(
            backgroundColor: Colors.grey[100],
            body: RefreshIndicator(
              onRefresh: () async {
                await viewModel.fetchUserProfile();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(viewModel),
                    const SizedBox(height: 24),
                    _buildProfileDetails(viewModel),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(ProfileViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 48, bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                tooltip: "Logout",
                onPressed: () => _handleLogout(viewModel),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _getProfileImage(
                      viewModel.profileImagePath,
                    ),
                  ),
                  if (viewModel.isUploadingImage)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                ],
              ),
              GestureDetector(
                onTap:
                    viewModel.isUploadingImage
                        ? null
                        : () => _showImagePickerModal(viewModel),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            viewModel.username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            viewModel.position,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(ProfileViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              for (int i = 0; i < viewModel.profileItems.length; i++) ...[
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: themeColor.withOpacity(0.13),
                    child: Icon(
                      viewModel.profileItems[i].icon,
                      color: themeColor,
                    ),
                  ),
                  title: Text(
                    viewModel.profileItems[i].label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(viewModel.profileItems[i].value),
                  trailing:
                      viewModel.profileItems[i].isClickable
                          ? Icon(Icons.chevron_right, color: Colors.grey[600])
                          : null,
                  onTap:
                      viewModel.profileItems[i].isClickable
                          ? () => _handleItemTap(
                            viewModel,
                            viewModel.profileItems[i],
                          )
                          : null,
                ),
                if (i != viewModel.profileItems.length - 1)
                  const Divider(
                    indent: 16,
                    endIndent: 16,
                    height: 0,
                    thickness: 0.7,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getProfileImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath) as ImageProvider;
    } else {
      return FileImage(File(imagePath));
    }
  }

  void _showImagePickerModal(ProfileViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Please choose one",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.black87),
                  title: const Text("Camera"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(viewModel, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.black87,
                  ),
                  title: const Text("Gallery"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(viewModel, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(
    ProfileViewModel viewModel,
    ImageSource source,
  ) async {
    void showPermissionDialog(BuildContext context, String permissionType) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('$permissionType Permission Required'),
              content: Text(
                'Please enable $permissionType permission in app settings to use this feature.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
      );
    }

    PermissionStatus status;

    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          showPermissionDialog(context, 'Camera');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied')),
          );
        }
        return;
      }
    } else {
      // Gallery permission handling
      if (Platform.isIOS) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            showPermissionDialog(context, 'Photos');
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo library permission denied')),
            );
          }
          return;
        }
      } else {
        // Android gallery permission handling
        // For Android 13+ (API 33+), Photo Picker is used automatically by image_picker
        // and doesn't require any permissions - skip permission request entirely
        // For Android 12 and below (API 32-), we need READ_EXTERNAL_STORAGE

        // Only request storage permission for Android 12 and below
        // Android 13+ will use Photo Picker which doesn't need permissions
      }
    }

    // Use ViewModel to handle image selection and upload
    final result = await viewModel.pickAndUploadImage(source);

    if (mounted && result != null) {
      final isSuccess =
          result.contains('successfully') || result.contains('uploaded');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          duration: Duration(seconds: isSuccess ? 3 : 4),
        ),
      );
    }
  }

  // ✅ Updated Logout Function
  void _handleLogout(ProfileViewModel viewModel) async {
    final shouldLogout = await CustomAlertDialog.showConfirmation(
      context,
      title: "Logout",
      message: "Are you sure you want to logout?",
      icon: Icons.logout_rounded,
      iconColor: themeColor,
      yesButtonText: "Logout",
      noButtonText: "Cancel",
    );

    if (shouldLogout == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => WillPopScope(
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
                      const Text(
                        'Logging out...',
                        style: TextStyle(
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
                  content: Text(data['message'] ?? 'Logged out successfully'),
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
              const SnackBar(
                content: Text('Logged out locally'),
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
                    ? 'Connection timeout. Logged out locally.'
                    : 'Network error. Logged out locally.',
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

      // Clear all SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

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

  void _handleItemTap(ProfileViewModel viewModel, dynamic item) {
    if (item.label == "Language" || item.label == "ភាសា") {
      _showLanguageDialog(viewModel);
    }
  }

  void _showLanguageDialog(ProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(viewModel.languageLogic.language.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text("English"),
                trailing:
                    viewModel.languageLogic.language.code == "EN"
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                onTap: () {
                  if (viewModel.languageLogic.language.code != "EN") {
                    viewModel.changeLanguage();
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text("ខ្មែរ (Khmer)"),
                trailing:
                    viewModel.languageLogic.language.code == "KH"
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                onTap: () {
                  if (viewModel.languageLogic.language.code != "KH") {
                    viewModel.changeLanguage();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(viewModel.languageLogic.language.cancel),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
