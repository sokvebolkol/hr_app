import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:chokchey_hr_app/models/leave_model.dart';
import 'package:chokchey_hr_app/utils/file_helper.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../constants/responsive.dart';
import '../../viewmodels/dashboardviewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/leave_balance_viewmodel.dart';
import '../../widgets/annual_leave_card_widget.dart';
import '../../widgets/date_section.dart';
import '../../widgets/function_card.dart';
import '../../widgets/leave_request.dart';
import '../attendance/attendance_calendar_screen.dart';
import '../attendance/attendance_clock_screen.dart';
import '../auth/login-screen.dart';
import '../holidays/holiday_calendar_screen.dart';
import '../leaves/leave_detail/my_leave_detail_screen.dart';
import '../leaves/leave_request/leave_request_screen.dart';
import '../leaves/leave_balance/leave_balance.dart';
import '../leaves/leave_history/leave_history_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  late DashboardViewModel _dashboardViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardViewModel = DashboardViewModel();
    _dashboardViewModel.initialize();

    // Listen for profile updates
    ProfileViewModel.onProfileUpdated = () {
      if (mounted && _currentIndex == 0) {
        _dashboardViewModel.refreshProfile();
      }
    };
  }

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
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color.fromARGB(237, 255, 255, 255),
        body: ChangeNotifierProvider.value(
          value: _dashboardViewModel,
          child: Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: SpinKitFadingCircle(color: primary));
              }

              // Check if user is inactive and force logout
              if (viewModel.isUserInactive) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await viewModel.forceLogout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                });
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitFadingCircle(color: primary),
                      SizedBox(height: 16),
                      Text("Your account is inactive. Logging out..."),
                    ],
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

              return _currentIndex == 0
                  ? const _DashboardHomeContent()
                  : const ProfilePage();
            },
          ),
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

            final newIndex = i == 2 ? 1 : 0;

            // If switching back to home (dashboard), refresh the profile data
            if (_currentIndex != 0 && newIndex == 0) {
              _dashboardViewModel.refreshProfile();
            }
            setState(() {
              _currentIndex = newIndex;
            });
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primary,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LeaveRequestScreen(),
              ),
            );
            // If a leave was requested, refresh the dashboard
            if (result == true && mounted) {
              _dashboardViewModel.refresh();
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ProfileViewModel.onProfileUpdated = null; // Clean up callback
    _dashboardViewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh profile data when app resumes (user might have updated profile in another part of the app)
    if (state == AppLifecycleState.resumed && _currentIndex == 0) {
      _dashboardViewModel.refreshProfile();
    }
  }

  // Method to navigate to profile page
  void navigateToProfile() {
    setState(() {
      _currentIndex = 1;
    });
  }
}

class _DashboardHomeContent extends StatefulWidget {
  const _DashboardHomeContent();

  @override
  State<_DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<_DashboardHomeContent>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late Timer _timer;
  int _currentScrollIndex = 0;

  // Function buttons data
  final List<Map<String, dynamic>> _functionButtons = [
    {
      'icon': Icons.access_time,
      'label': 'Clock In | Out',
      'onPressed':
          (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AttendanceClock()),
          ),
    },
    {
      'icon': Icons.history,
      'label': 'Leaves History',
      'onPressed':
          (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaveHistoryScreen()),
          ),
    },
    {
      'icon': Icons.event_available,
      'label': 'Attendances',
      'onPressed': (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AttendanceCalendarScreen(),
          ),
        );
      },
    },
    {
      'icon': Icons.calendar_month,
      'label': 'Holidays',
      'onPressed': (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HolidayCalendarScreen(),
          ),
        );
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Start auto-slide after 3 seconds delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _startAutoSlide();
      }
    });

    // Refresh profile data when dashboard content is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<DashboardViewModel>(context, listen: false);
      viewModel.refreshProfile();
    });
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_scrollController.hasClients && _functionButtons.length > 3) {
        // Calculate the next scroll position
        _currentScrollIndex =
            (_currentScrollIndex + 1) % (_functionButtons.length - 2);

        // Each item width (110) + spacing (16)
        const double itemWidth = 110.0 + 16.0;
        final double targetOffset = _currentScrollIndex * itemWidth;

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await viewModel.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(viewModel),
                const DateSection(),
                const SizedBox(height: 16),
                _buildLeaveBalanceSection(viewModel),
                const SizedBox(height: 16),
                _buildFunctionButtons(context),
                _buildRecentLeaveRequests(viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(DashboardViewModel viewModel) {
    return Container(
      color: primary,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 50,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () {
                    // Navigate to profile page by changing the current index
                    final scaffoldState =
                        context
                            .findAncestorStateOfType<_DashboardScreenState>();
                    scaffoldState?.navigateToProfile();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        _buildProfileAvatar(viewModel),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FileHelper().greeting,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              viewModel.username,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                _buildNotificationIcon(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        const Icon(Icons.notifications_none, color: Colors.white, size: 24),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
            child: const Text(
              '1',
              style: TextStyle(color: Colors.white, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(DashboardViewModel viewModel) {
    final imageUrl = viewModel.profileImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent,
        ),
        child: ClipOval(
          child: FadeInImage.assetNetwork(
            placeholder: 'assets/images/profile.png',
            image: imageUrl,
            fit: BoxFit.cover,
            imageErrorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/profile.png',
                fit: BoxFit.cover,
              );
            },
          ),
        ),
      );
    } else {
      return const CircleAvatar(
        backgroundImage: AssetImage('assets/images/profile.png'),
        backgroundColor: Colors.blueAccent,
      );
    }
  }

  Widget _buildLeaveBalanceSection(DashboardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnnualLeaveBalanceWidget(
        usedLeave: viewModel.usedLeave,
        availableLeave: viewModel.availableLeave,
        onViewDetails: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChangeNotifierProvider(
                    create: (context) => LeaveBalanceViewModel(),
                    child: const LeaveBalanceDetailScreen(),
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFunctionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 100,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                _functionButtons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final button = entry.value;

                  return Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: FunctionIconCardWidget(
                          iconData: button['icon'] as IconData,
                          label: button['label'] as String,
                          onPressed: () => button['onPressed'](context),
                        ),
                      ),
                      // Add spacing between items except for the last one
                      if (index < _functionButtons.length - 1)
                        const SizedBox(width: 16),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLeaveRequests(DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Recently Leave Request",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ),
        SizedBox(
          height: 330,
          child: ListView.builder(
            itemCount: viewModel.sortedLeaves.length,
            itemBuilder: (context, index) {
              final leave = viewModel.sortedLeaves[index];
              // Sort prioList by prio ascending
              final sortedPrioList = [...leave.prioList]
                ..sort((a, b) => a.prio.compareTo(b.prio));
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MyLeaveDetailScreen(
                            leaveRequest: leave.toLeaveHistoryModel(),
                          ),
                    ),
                  ).then((result) {
                    // Refresh the dashboard if the leave was updated/cancelled
                    if (result == true) {
                      viewModel.refresh();
                    }
                  });
                },
                child: LeaveRequestWidget(
                  reason: leave.reason,
                  status: leave.statuText,
                  fromDate: leave.frdat,
                  toDate: leave.todat,
                  requesterName: leave.dname,
                  totalDays: leave.numleav,
                  currentUserName: viewModel.username,
                  currentUserProfileImageUrl: viewModel.profileImageUrl,
                  prioList:
                      sortedPrioList
                          .map(
                            (p) => {
                              'prio': p.prio,
                              'apstatu': p.apstatu,
                              'apstatu_text': p.apstatuText,
                              'prio_text': p.priText,
                              'remark': p.remark,
                            },
                          )
                          .toList(),
                ),
              );
            },
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ],
    );
  }
}
