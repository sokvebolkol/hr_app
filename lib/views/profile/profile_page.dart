import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/constant.dart';
import '../../services/global_service.dart';
import '../auth/login-page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String profileImagePath = 'assets/images/profile.jpg';
  bool isLoading = true;
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final String username = userProfile?['username'] ?? "Unknown User";
    final String position = userProfile?['position_name'] ?? "Unknown Position";
    final String email = userProfile?['email'] ?? "";
    final String employeeId = userProfile?['employee_id'] ?? "";
    final String fullName = userProfile?['full_name'] ?? "";
    final String department = userProfile?['department_name'] ?? "";
    final String branch = userProfile?['branch_full_name'] ?? "";
    final String joinedDate =
        userProfile?['joined_date'] != null
            ? userProfile!['joined_date'].toString().split(
              ' ',
            )[0] // Get date part only
            : "";
    final String employmentType = userProfile?['employment_type'] ?? "";
    final String gender = userProfile?['gender'] ?? "";

    final List<_ProfileItem> items = [
      _ProfileItem(icon: Icons.email, label: "Email", value: email),
      _ProfileItem(icon: Icons.badge, label: "Employee ID", value: employeeId),
      _ProfileItem(icon: Icons.person, label: "Full Name", value: fullName),
      _ProfileItem(icon: Icons.wc, label: "Gender", value: gender),
      _ProfileItem(
        icon: Icons.business,
        label: "Department",
        value: department,
      ),
      _ProfileItem(icon: Icons.location_on, label: "Branch", value: branch),
      _ProfileItem(
        icon: Icons.work,
        label: "Employment Type",
        value: employmentType,
      ),
      _ProfileItem(
        icon: Icons.calendar_today,
        label: "Joined Date",
        value: joinedDate,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchUserProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 48,
                  bottom: 24,
                  left: 16,
                  right: 16,
                ),
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
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 28,
                          ),
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
                          backgroundImage:
                              profileImagePath.startsWith('http')
                                  ? NetworkImage(profileImagePath)
                                  : profileImagePath.startsWith('assets/')
                                  ? AssetImage(profileImagePath)
                                      as ImageProvider
                                  : FileImage(File(profileImagePath)),
                        ),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder:
                                  (context) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                      horizontal: 16,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          "Please choose one",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.black87,
                                          ),
                                          title: const Text("Camera"),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            await _pickImage(
                                              context,
                                              ImageSource.camera,
                                            );
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
                                            await _pickImage(
                                              context,
                                              ImageSource.gallery,
                                            );
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
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
        // Android
        status = await Permission.storage.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            showPermissionDialog(context, 'Storage');
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied')),
            );
          }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Selected: ${pickedFile.path}')));
      }
      await uploadProfileImage(File(pickedFile.path));
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final userId = pref.getString("userId");
    if (userId == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ServerService().baseUrl}user/upload-profile'),
    );
    request.fields['uid'] = userId;
    request.files.add(
      await http.MultipartFile.fromPath('profile_image', imageFile.path),
    );

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      if (mounted) {
        setState(() {
          profileImagePath = data['profile_image_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Profile image uploaded')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile image')),
        );
      }
    }
  }

  void onLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
        MaterialPageRoute(
          builder: (BuildContext context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  Future<void> fetchUserProfile() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final userId = pref.getString("userId");
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ServerService().baseUrl}user/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            userProfile = data;
            if (data['profile_image_url'] != null &&
                data['profile_image_url'].toString().isNotEmpty) {
              profileImagePath = data['profile_image_url'];
            }
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to fetch user profile: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching profile: $e')));
      }
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
