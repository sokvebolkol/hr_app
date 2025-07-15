import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/constant.dart';
import '../../constants/responsive.dart';
import '../../widgets/annual_leave_card_widget.dart';
import '../../widgets/function_card.dart';
import '../../widgets/leave_request.dart';
import 'package:intl/intl.dart';
import '../attendance/attendance_clock.dart';
import '../dashboard/leave_request_screen.dart';
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

  // Example pages, replace with your actual widgets
  final List<Widget> _pages = [
    const _DashboardHomeContent(), // Dashboard as Home
    ProfilePage(),
  ];

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
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color.fromARGB(237, 255, 255, 255),
        body: _pages[_currentIndex],
        bottomNavigationBar: ConvexAppBar(
          key: ValueKey(_currentIndex),
          color: Colors.white,
          backgroundColor: primary,
          style: TabStyle.react,
          items: const [
            TabItem(icon: Icons.home, title: 'Home'),
            TabItem(icon: Icons.home, title: 'Request Leave'), // This will be disabled
            TabItem(icon: Icons.person, title: 'Profile'),
          ],
          initialActiveIndex: _currentIndex == 0 ? 0 : 2, // Only Home or Profile can be active
          onTap: (int i) {
            if (i == 1) return; // Prevent selecting "Request Leave"
            setState(() {
              _currentIndex = i == 2 ? 1 : 0; // 0: Home, 1: Profile
            });
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primary,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LeaveRequestScreen(),
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

class _DashboardHomeContent extends StatelessWidget {
  const _DashboardHomeContent();

  @override
  Widget build(BuildContext context) {
    return Column(
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
                      backgroundImage: AssetImage('assets/images/profile.jpg'),
                      backgroundColor: Colors.blueAccent,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Good morning!",
                            style: TextStyle(fontSize: 14, color: Colors.white),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FunctionIconCardWidget(
                  iconData: Icons.access_time,
                  label: 'Clock In | Out',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  AttendanceClock(), 
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: FunctionIconCardWidget(
                  iconData: Icons.history,
                  label: 'Leave History',
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
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
    );
  }
}
