import 'dart:io';
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

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageLogic>().language;
    const String username = "Kol Sokvebol";
    const String position = "Mobile App Developer";

    final List<_ProfileItem> items = [
      _ProfileItem(icon: Icons.email, label: "Email", value: "sokvebol.kol@chokchey.com.kh"),
      _ProfileItem(icon: Icons.phone, label: "Phone", value: "+855 12 345 678"),
      _ProfileItem(icon: Icons.badge, label: "Employee ID", value: "EMP00123"),
      _ProfileItem(icon: Icons.location_on, label: "Location", value: "Phnom Penh, Cambodia"),
      _ProfileItem(icon: Icons.calendar_today, label: "Joined", value: "Jan 2022"),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 48, bottom: 24, left: 16, right: 16),
              decoration: BoxDecoration(
                color: primary,
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
                        onPressed: () {
                          onLogout();
                        },
                      ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImagePath.startsWith('assets/')
                            ? AssetImage(profileImagePath) as ImageProvider
                            : FileImage(File(profileImagePath)),
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
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    position,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
          ],
        ),
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
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      SharedPreferences pref = await SharedPreferences.getInstance();
      await pref.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (BuildContext context) => const LoginScreen()),
        (route) => false,
      );
    }
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
