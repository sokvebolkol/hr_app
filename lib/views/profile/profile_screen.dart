import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constant.dart';
import '../../viewmodels/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  final int currentIndex;
  const ProfilePage({super.key, this.currentIndex = 0});

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
                    _buildProfileDetails(viewModel),
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
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top / 1.5),
          widget.currentIndex == 0
              ? Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              )
              : SizedBox(height: 16),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        viewModel.profileImagePath.isNotEmpty
                            ? _getProfileImage(viewModel.profileImagePath)
                            : const AssetImage('assets/images/profile.png'),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            viewModel.position,
            style: TextStyle(
              fontSize: 14,
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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Column(
        children: [
          for (int i = 0; i < viewModel.profileItems.length; i++) ...[
            ListTile(
              minTileHeight: 70,
              leading: CircleAvatar(
                backgroundColor: themeColor.withOpacity(0.13),
                child: Icon(
                  viewModel.profileItems[i].icon,
                  color: themeColor,
                  size: 20,
                ),
              ),
              title: Text(
                viewModel.profileItems[i].label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(viewModel.profileItems[i].value),
              trailing:
                  viewModel.profileItems[i].isClickable
                      ? Icon(Icons.chevron_right, color: Colors.grey[600])
                      : null,
              onTap:
                  viewModel.profileItems[i].isClickable
                      ? () =>
                          _handleItemTap(viewModel, viewModel.profileItems[i])
                      : null,
            ),
            if (i != viewModel.profileItems.length - 1)
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 0,
                thickness: 0.2,
              ),
          ],
        ],
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
    // For iOS 14+, photo library picker doesn't require permission (uses PHPicker)
    // PHPicker provides "Limited Photos Access" automatically without explicit permissions
    // Only camera requires permission check

    try {
      // Only check camera permission, not photos (PHPicker handles photos automatically)
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.status;

        // If camera permission is permanently denied, show settings guidance
        if (cameraStatus.isPermanentlyDenied) {
          _showSettingsGuidanceDialog(context, 'Camera');
          return;
        }
      }

      // Let image_picker handle the permission request naturally
      // For camera: triggers native iOS permission dialog on first use
      // For photos: uses PHPicker which doesn't need permissions
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
    } catch (e) {
      // Handle permission denial or other errors
      if (mounted) {
        // Only check camera status on error, not photos
        if (source == ImageSource.camera) {
          final cameraStatus = await Permission.camera.status;

          if (cameraStatus.isPermanentlyDenied) {
            _showSettingsGuidanceDialog(context, 'Camera');
          } else if (cameraStatus.isDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Camera access is needed to use this feature. Please try again and allow access.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            // Other camera errors
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to process image: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Photo errors (network, file issues, etc.)
          // Don't show permission errors for photos since PHPicker handles it
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to process image: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _handleItemTap(ProfileViewModel viewModel, dynamic item) {
    if (item.label == viewModel.languageLogic.language.language) {
      _showLanguageDialog(viewModel);
    }
  }

  void _showSettingsGuidanceDialog(
    BuildContext context,
    String permissionType,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$permissionType Access Required'),
            content: Text(
              'This feature requires $permissionType access. You have previously denied this permission.\n\nTo enable it, please go to Settings > CHOKCHEY and allow $permissionType access.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_viewModel.languageLogic.language.no),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                child: Text(_viewModel.languageLogic.language.openSettings),
              ),
            ],
          ),
    );
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
