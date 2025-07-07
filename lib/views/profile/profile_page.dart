import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:chokchey_hr_app/constants/responsive.dart';
import 'package:chokchey_hr_app/localization/language.dart';
import 'package:chokchey_hr_app/localization/language_logic.dart';
import 'package:chokchey_hr_app/views/auth/login-page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constant.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String profileImagePath = 'assets/images/profile.jpg';
  double screenHeight = 0;
  double screenWidth = 0;

  Language language = Language();

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    language = context.watch<LanguageLogic>().language;

    const String username = "Kol Sokvebol";
    const String position = "HR Manager";

    final List<_ProfileItem> items = [
      _ProfileItem(
        icon: Icons.email,
        label: "Email",
        value: "sokvebol.kol@chokchey.com.kh",
      ),
      _ProfileItem(icon: Icons.phone, label: "Phone", value: "+855 12 345 678"),
      _ProfileItem(icon: Icons.badge, label: "Employee ID", value: "EMP00123"),
      _ProfileItem(
        icon: Icons.location_on,
        label: "Location",
        value: "Phnom Penh, Cambodia",
      ),
      _ProfileItem(
        icon: Icons.calendar_today,
        label: "Joined",
        value: "Jan 2022",
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            height: 165,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImagePath.startsWith('assets/')
                            ? AssetImage(profileImagePath) as ImageProvider
                            : FileImage(
                                // ignore: prefer_const_constructors
                                File(profileImagePath),
                              ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (context) => Padding(
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
                                      await _pickImage(context, ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library, color: Colors.black87),
                                    title: const Text("Gallery"),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await _pickImage(context, ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  position,
                  style: TextStyle(
                    fontSize: 16,
                    color: secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 8,
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < items.length; i++) ...[
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primary.withOpacity(0.13),
                                child: Icon(items[i].icon, color: primary),
                              ),
                              title: Text(
                                items[i].label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(items[i].value),
                            ),
                            if (i != items.length - 1)
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
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  onPressed: () {
                    onLogout();
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
        return;
      }
    } else {
      status = await Permission.photos.request(); // For iOS
      if (!status.isGranted) {
        status = await Permission.storage.request(); // For Android
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery permission denied')),
          );
          return;
        }
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        profileImagePath = pickedFile.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: ${pickedFile.path}')),
      );
    }
  }

  void onLogout() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AwesomeDialog(
        width: Responsive.isMobile(context) ? screenWidth : screenWidth / 2,
        transitionAnimationDuration: const Duration(milliseconds: 1000),
        context: context,
        dialogType: DialogType.info,
        title: "Logout",
        desc: "Are you sure you want to logout?",
        btnCancelText: "No",
        btnCancelOnPress: () {},
        btnOkText: "OK",
        btnOkOnPress: () {
          pref.remove('uid');
          pref.remove('eid');
          pref.remove('ucode');
          pref.clear();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const LoginScreen(),
            ),
            ModalRoute.withName('/'),
          );
        },
      ).show();
    });
  }
}

class _ProfileItem {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
