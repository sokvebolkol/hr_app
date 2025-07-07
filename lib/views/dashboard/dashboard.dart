import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:chokchey_hr_app/views/auth/login-page.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constant.dart';
import '../../constants/responsive.dart';
import '../../widgets/annual_leave_card_widget.dart';
import '../../widgets/function_card.dart';
import '../../widgets/leave_request.dart';
import 'package:intl/intl.dart';
import '../profile/profile_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  double screenWidth = 0.0;
  double screenHeight = 0.0;

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

  // Android back button handler
  Future<bool> _onBackPressed() async {
    AwesomeDialog(
      context: context,
      width: Responsive.isMobile(context) ? screenWidth : screenWidth / 2,
      headerAnimationLoop: false,
      dialogType: DialogType.info,
      transitionAnimationDuration: const Duration(milliseconds: 500),
      title: 'Information',
      desc: 'Do you want to exit?',
      btnOkOnPress: () async {
        Future.delayed(const Duration(milliseconds: 500), () {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        });
      },
      btnCancelText: "No",
      btnCancelOnPress: () {},
      btnOkColor: primary,
      btnOkText: 'Yes',
    ).show();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        // drawer: _buildDrawer(),
        backgroundColor: const Color.fromARGB(237, 255, 255, 255),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: primary,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundImage: AssetImage(
                            'assets/images/profile.jpg',
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Good morning",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Kol Sokvebol",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            const Icon(
                              Icons.notifications_none,
                              color: Colors.white,
                              size: 24,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: const Text(
                                  '1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: Text(
                DateFormat('EEEE dd MMMM, yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: AnnualLeaveBalanceWidget(),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FunctionIconCardWidget(
                      iconData: Icons.access_time,
                      label: 'Clock In | Out',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: FunctionIconCardWidget(
                      iconData: Icons.history,
                      label: 'Leave History',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: FunctionIconCardWidget(
                      iconData: Icons.calendar_month,
                      label: 'Attendance Logs',
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Recently Leave Request",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 2,
                itemBuilder: (context, index) => const LeaveRequestWidget(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ],
        ),
        bottomNavigationBar: ConvexAppBar(
          key: ValueKey(_currentIndex),
          color: Colors.white,
          backgroundColor: primary,
          style: TabStyle.react,
          items: const [
            TabItem(icon: Icons.home, title: 'Home'),
            TabItem(icon: Icons.home, title: 'Request Leave'),
            TabItem(icon: Icons.person, title: 'Profile'),
          ],
          initialActiveIndex: _currentIndex,
          onTap: (int i) {
            if (i == 2) { // Profile tab index
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            } else {
              setState(() {
                _currentIndex = i;
              });
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _currentIndex = 1;
            });
          },
          backgroundColor: primary,
          shape: const CircleBorder(),
          child: const Icon(FontAwesomeIcons.calendarPlus, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // Drawer is commented out to avoid cluttering the UI.
  // Widget _buildDrawer() {
  //   return Drawer(
  //     child: ListView(
  //       padding: EdgeInsets.zero,
  //       physics: const NeverScrollableScrollPhysics(),
  //       children: [
  //         UserAccountsDrawerHeader(
  //           decoration: BoxDecoration(color: primary),
  //           accountName: Text(
  //             "Kol Sokvebol",
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           accountEmail: Text("sokvebol.kol@chokchey.com.kh"),
  //           currentAccountPicture: CircleAvatar(
  //             backgroundColor: Colors.grey[200],
  //             child: ClipOval(
  //               child: Image.asset(
  //                 'assets/images/profile.jpg',
  //                 fit: BoxFit.cover,
  //                 width: 90,
  //                 height: 90,
  //               ),
  //             ),
  //           ),
  //         ),
  //         _buildDrawerItem(Icons.person, 'My Profile', () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(builder: (context) => const DashboardScreen()),
  //           );
  //         }),
  //         // _buildDrawerItem(Icons.color_lens, 'Change Theme', () {
  //         //   changeTheme(context);
  //         // }),
  //         // _buildDrawerItem(Icons.article, 'Term & Condition', () {}),
  //         // _buildDrawerItem(Icons.privacy_tip, 'Privacy Policy', () {}),
  //         // _buildDrawerItem(Icons.language, 'Visit Chokchey', () async {
  //         //   const url = 'https://chokchey.com.kh/';
  //         //   if (await canLaunch(url)) {
  //         //     await launch(url);
  //         //   } else {
  //         //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //         //       ScaffoldMessenger.of(context).showSnackBar(
  //         //         const SnackBar(content: Text('Could not launch $url')),
  //         //       );
  //         //     });
  //         //   }
  //         // }),
  //         // _buildDrawerItem(Icons.info, 'Version: $currentVersion', () {}),
  //         _buildDrawerItem(Icons.logout, 'Logout', () {
  //           onLogout();
  //         }),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
  //   return ListTile(
  //     leading: Icon(icon, color: primary),
  //     title: Text(title),
  //     onTap: () {
  //       Navigator.pop(context);
  //       onTap();
  //     },
  //   );
  // }
}
