import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constant.dart';
import '../../constants/responsive.dart';
import '../../viewmodels/dashboardviewmodel.dart';
import '../../widgets/annual_leave_card_widget.dart';
import '../../widgets/function_card.dart';
import '../../widgets/leave_request.dart';
import '../attendance/attendance_clock.dart';
import '../dashboard/leave_request_screen.dart';
import '../profile/profile_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  double screenWidth = 0.0;
  double screenHeight = 0.0;

  final List<Widget> _pages = [const _DashboardHomeContent(), ProfilePage()];

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
        body: FutureBuilder<String?>(
          future: _getUserId(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final userId = snapshot.data;
            return _currentIndex == 0
                ? ChangeNotifierProvider(
                  create: (_) => DashboardViewModel()..fetchDashboard(userId!),
                  child: const _DashboardHomeContent(),
                )
                : _pages[_currentIndex];
          },
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
          initialActiveIndex: _currentIndex == 0 ? 0 : 2,
          onTap: (int i) {
            if (i == 1) return;
            setState(() {
              _currentIndex = i == 2 ? 1 : 0;
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

  Future<String?> _getUserId() async {
    final pref = await SharedPreferences.getInstance();
    // print(pref.getKeys());
    return pref.getString("userId");
  }
}

class _DashboardHomeContent extends StatelessWidget {
  const _DashboardHomeContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        final leaveBalance = vm.leaveBalance;
        final leaves = vm.leaves;
        final user = vm.user;

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
                          backgroundImage: AssetImage(
                            'assets/images/profile.jpg',
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greetingByTime(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                user?.uname ?? "",
                                style: const TextStyle(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnnualLeaveBalanceWidget(
                usedLeave: leaveBalance?.annualLeaveUsed ?? "0",
                availableLeave: leaveBalance?.annualLeaveBalance ?? "0",
                onViewDetails: () {
                  // Show details or navigate
                },
              ),
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
                            builder: (context) => AttendanceClock(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FunctionIconCardWidget(
                      iconData: Icons.history,
                      label: 'Leave History',
                      onPressed: () {
                        // Implement navigation to leave history
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FunctionIconCardWidget(
                      iconData: Icons.calendar_month,
                      label: 'Attendance Logs',
                      onPressed: () {
                        // Implement navigation to attendance logs
                      },
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
                itemCount: leaves.length,
                itemBuilder: (context, index) {
                  final leave = leaves[index];
                  // Sort prioList by prio ascending
                  final sortedPrioList = [...leave.prioList]
                    ..sort((a, b) => a.prio.compareTo(b.prio));
                  return LeaveRequestWidget(
                    reason: leave.reason,
                    status:
                        leave
                            .statuText, // Use statu_text from API for status display
                    fromDate: leave.frdat,
                    toDate: leave.todat,
                    requesterName: leave.dname,
                    totalDays: leave.numleav,
                    prioList:
                        sortedPrioList
                            .map(
                              (p) => {
                                'prio': p.prio,
                                'apstatu': p.apstatu,
                                'apstatu_text': p.apstatuText,
                                'prio_text': p.priText,
                              },
                            )
                            .toList(),
                  );
                },
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning!";
    } else if (hour < 18) {
      return "Good afternoon!";
    } else {
      return "Good evening!";
    }
  }
}
