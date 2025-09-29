import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:chokchey_hr_app/widgets/function_card.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../constants/responsive.dart';
import '../../utils/file_helper.dart';
import '../../viewmodels/dashboardviewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/ceo_dashboard_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../models/ceo_dashboard_model.dart';
import '../../widgets/date_section.dart';
import '../../widgets/leave_request.dart';
import '../attendance/staff_attendance_detail_screen.dart';
import '../auth/login-screen.dart';
import '../chokchey_team/chockchey_team_screen.dart';
import '../leaves/leave_approval/ceo_leave_detail_screen.dart';
import '../notifications/ceo_notifcation_screen.dart';
import '../profile/profile_screen.dart';
import '../memo/memo_screen.dart';
import '../holidays/holiday_calendar_screen.dart';

class CeoDashboardScreen extends StatefulWidget {
  const CeoDashboardScreen({super.key});

  @override
  _CeoDashboardScreenState createState() => _CeoDashboardScreenState();
}

class _CeoDashboardScreenState extends State<CeoDashboardScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CeoDashboardScreen(),
    const HolidayCalendarScreen(),
    const MemoScreen(),
    const ProfilePage(),
  ];

  double screenWidth = 0.0;
  double screenHeight = 0.0;
  late DashboardViewModel _dashboardViewModel;
  late CeoDashboardViewModel _ceoDashboardViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardViewModel = DashboardViewModel();
    _ceoDashboardViewModel = CeoDashboardViewModel();

    _dashboardViewModel.initialize();
    _ceoDashboardViewModel.initialize();

    // Listen for profile updates
    ProfileViewModel.onProfileUpdated = () {
      if (mounted && _currentIndex == 0) {
        _dashboardViewModel.refreshProfile();
        _ceoDashboardViewModel.refresh();
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
      btnOkColor: secondary,
      btnOkText: 'Yes',
    ).show();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    // Set the home content dynamically
    _screens[0] = _CeoDashboardHomeContent(
      dashboardViewModel: _dashboardViewModel,
      ceoViewModel: _ceoDashboardViewModel,
    );

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color.fromARGB(237, 255, 255, 255),
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: _dashboardViewModel),
            ChangeNotifierProvider.value(value: _ceoDashboardViewModel),
          ],
          child: Consumer2<DashboardViewModel, CeoDashboardViewModel>(
            builder: (context, dashboardViewModel, ceoViewModel, child) {
              if (dashboardViewModel.isLoading) {
                return const Center(
                  child: SpinKitFadingCircle(color: secondary),
                );
              }

              // Check if user is inactive and force logout
              if (dashboardViewModel.isUserInactive) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await dashboardViewModel.forceLogout();
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
                      SpinKitFadingCircle(color: secondary),
                      SizedBox(height: 16),
                      Text("Your account is inactive. Logging out..."),
                    ],
                  ),
                );
              }

              if (dashboardViewModel.errorMessage != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(dashboardViewModel.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  dashboardViewModel.clearError();
                });
              }

              // Show screens with header for home page
              if (_currentIndex == 0) {
                return Column(
                  children: [
                    _buildStickyHeader(dashboardViewModel),
                    Expanded(child: _screens[_currentIndex]),
                  ],
                );
              }
              return _screens[_currentIndex];
            },
          ),
        ),
        bottomNavigationBar: ConvexAppBar(
          key: ValueKey(_currentIndex),
          color: Colors.black87,
          backgroundColor: Colors.white,
          activeColor: secondary,
          shadowColor: Colors.grey[200],
          style: TabStyle.react,
          items: const [
            TabItem(icon: Icons.home, title: 'Home'),
            TabItem(icon: Icons.calendar_month, title: 'Holiday'),
            TabItem(icon: Icons.campaign, title: 'Memo'),
            TabItem(icon: Icons.more_horiz_sharp, title: 'More'),
          ],
          initialActiveIndex: _currentIndex,
          onTap: (int i) {
            setState(() {
              _currentIndex = i;
              // Optionally refresh data when switching to Home or Profile
              if (_currentIndex == 0) {
                _dashboardViewModel.refreshProfile();
                _ceoDashboardViewModel.refresh();
              }
            });
          },
        ),
      ),
    );
  }

  // Add this new method for the sticky header
  Widget _buildStickyHeader(DashboardViewModel viewModel) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: secondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
          top: 16,
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                navigateToProfile();
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
                        SizedBox(
                          width: 180,
                          child: Text(
                            viewModel.username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Global notifications from NotificationViewModel
            Consumer<NotificationViewModel>(
              builder: (context, notificationViewModel, child) {
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CeoNotificationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    if (notificationViewModel.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notificationViewModel.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method for profile avatar in sticky header
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ProfileViewModel.onProfileUpdated = null;
    _dashboardViewModel.dispose();
    _ceoDashboardViewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _currentIndex == 0) {
      _dashboardViewModel.refreshProfile();
      _ceoDashboardViewModel.refresh();
    }
  }

  void navigateToProfile() {
    setState(() {
      _currentIndex = 3;
    });
  }
}

class _CeoDashboardHomeContent extends StatefulWidget {
  final DashboardViewModel dashboardViewModel;
  final CeoDashboardViewModel ceoViewModel;

  const _CeoDashboardHomeContent({
    required this.dashboardViewModel,
    required this.ceoViewModel,
  });

  @override
  State<_CeoDashboardHomeContent> createState() =>
      _CeoDashboardHomeContentState();
}

class _CeoDashboardHomeContentState extends State<_CeoDashboardHomeContent>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Refresh data when dashboard content is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.dashboardViewModel.refreshProfile();
      widget.ceoViewModel.refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CeoDashboardViewModel>(
      builder: (context, ceoViewModel, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              widget.dashboardViewModel.refresh(),
              ceoViewModel.refresh(),
            ]);
          },
          color: secondary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Remove the old _buildHeader() since it's now in sticky header
                const DateSection(),
                _buildTodayAttendanceCard(ceoViewModel),
                _buildFunctionButtons(context),
                _buildLeaveManagementTabs(ceoViewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  // Remove the old _buildNotificationIcon method since it's now in sticky header

  // Remove the old _buildProfileAvatar method since it's now in sticky header

  Widget _buildTodayAttendanceCard(CeoDashboardViewModel viewModel) {
    if (viewModel.isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [secondary, secondary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: secondary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (viewModel.errorMessage != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 220,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Error Loading Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.errorMessage!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [secondary, secondary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: secondary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.today_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Today\'s Attendance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const StaffAttendanceDetailScreen(
                                isGettingTodayAttendance: true,
                              ),
                        ),
                      ),
                  child: const Text(
                    'View Details >',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Attendance Stats with Separators
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildSimpleAttendanceStatItem(
                      'Present',
                      viewModel.presentCount.toString(),
                      Colors.green[100]!,
                    ),
                  ),
                  _buildSeparator(),
                  Expanded(
                    child: _buildSimpleAttendanceStatItem(
                      'Late',
                      viewModel.lateCount.toString(),
                      Colors.orange[100]!,
                    ),
                  ),
                  _buildSeparator(),
                  Expanded(
                    child: _buildSimpleAttendanceStatItem(
                      'Leave',
                      viewModel.onLeaveCount.toString(),
                      Colors.blue[100]!,
                    ),
                  ),
                  _buildSeparator(),
                  Expanded(
                    child: _buildSimpleAttendanceStatItem(
                      'Absent',
                      viewModel.absentCount.toString(),
                      Colors.red[200]!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionButtons(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            SizedBox(
              width: screenWidth / 2 * 0.87,
              child: FunctionIconCardWidget(
                iconColor: secondary.withOpacity(0.8),
                iconData: FontAwesomeIcons.networkWired,
                iconSize: 30,
                label: 'CHOKCHEY Team',
                textSize: 14,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChockcheyTeamScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 16.0),
            SizedBox(
              width: screenWidth / 2 * 0.87,
              child: FunctionIconCardWidget(
                iconColor: secondary.withOpacity(0.8),
                iconData: FontAwesomeIcons.userClock,
                iconSize: 30,
                label: 'Staff Attendances',
                textSize: 14,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaffAttendanceDetailScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleAttendanceStatItem(
    String title,
    String value,
    Color numberColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: numberColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3)),
    );
  }

  Widget _buildLeaveManagementTabs(CeoDashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Custom Tab Bar with Full Background
          Container(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        final isSelected = _tabController.index == 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? secondary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: secondary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Pending Leave Approval',
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (viewModel.pendingLeavesCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    viewModel.pendingLeavesCount > 99
                                        ? '99+'
                                        : viewModel.pendingLeavesCount
                                            .toString(),
                                    style: TextStyle(
                                      color:
                                          isSelected ? secondary : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        final isSelected = _tabController.index == 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? secondary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: secondary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Leave Approval History',
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (viewModel.approvedLeavesCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    viewModel.approvedLeavesCount > 99
                                        ? '99+'
                                        : viewModel.approvedLeavesCount
                                            .toString(),
                                    style: TextStyle(
                                      color:
                                          isSelected ? secondary : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Month Filter Section
          _buildMonthFilter(viewModel),

          // Tab Content
          SizedBox(
            height: 400, // Fixed height for the tab content
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingLeavesTab(viewModel.pendingLeaves),
                _buildApprovedLeavesTab(viewModel.approvedLeaves),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthFilter(CeoDashboardViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Filter by Month:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showMonthPicker(viewModel),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      viewModel.selectedMonthDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: secondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(CeoDashboardViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Month - ${DateTime.now().year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _getCurrentYearMonths().length,
                    itemBuilder: (context, index) {
                      final month = _getCurrentYearMonths()[index];
                      final isSelected =
                          viewModel.selectedMonth == month['value'];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              viewModel.setSelectedMonth(month['value']);
                              Navigator.pop(context);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient:
                                    isSelected
                                        ? LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            secondary.withOpacity(0.1),
                                            secondary.withOpacity(0.05),
                                          ],
                                        )
                                        : null,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? secondary.withOpacity(0.3)
                                          : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: secondary.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Row(
                                children: [
                                  // Month icon with animation
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? secondary.withOpacity(0.1)
                                              : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.calendar_month,
                                      color:
                                          isSelected
                                              ? secondary
                                              : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Month text with improved typography
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          month['display']!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                            color:
                                                isSelected
                                                    ? secondary
                                                    : Colors.black87,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Selected month',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: secondary.withOpacity(0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Animated check icon
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      );
                                    },
                                    child:
                                        isSelected
                                            ? Container(
                                              key: const ValueKey('selected'),
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: secondary,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: secondary
                                                        .withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            )
                                            : Container(
                                              key: const ValueKey('unselected'),
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                  width: 1.5,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  List<Map<String, String>> _getCurrentYearMonths() {
    List<Map<String, String>> months = [];
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    // Generate months from January to current month of current year
    for (int month = 1; month <= currentMonth; month++) {
      DateTime monthDate = DateTime(currentYear, month, 1);
      months.add({
        'value': DateFormat('yyyy-MM').format(monthDate), // "2025-01"
        'display': DateFormat('MMMM yyyy').format(monthDate), // "January 2025"
      });
    }

    // Reverse the list to show most recent months first
    return months.reversed.toList();
  }

  Widget _buildPendingLeavesTab(List<LeaveRequest> leaves) {
    if (leaves.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Pending Requests',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All leave requests are up to date',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder:
          (context, index) => _buildCompactLeaveItem(leaves[index], true),
    );
  }

  Widget _buildApprovedLeavesTab(List<LeaveRequest> leaves) {
    if (leaves.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.approval_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Recent Approvals',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recently approved leaves will appear here',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder:
          (context, index) => _buildCompactLeaveItem(leaves[index], false),
    );
  }

  Widget _buildCompactLeaveItem(LeaveRequest leave, bool isPending) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Sort the approval list by priority
    final sortedPrioList = [...leave.prioList]
      ..sort((a, b) => a.prio.compareTo(b.prio));

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    CeoLeaveDetailScreen(leave: leave, isPending: isPending),
          ),
        );

        // Handle the result if action was taken
        if (result != null && mounted) {
          // Refresh the CEO dashboard data
          widget.ceoViewModel.refresh();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: LeaveRequestWidget(
          reason: leave.reason,
          status: leave.statuText,
          fromDate: leave.fromDate.toString(),
          toDate: leave.toDate.toString(),
          requesterName: leave.requesterName,
          totalDays: leave.numLeaveDays.toString(),
          currentUserName: widget.dashboardViewModel.username,
          currentUserProfileImageUrl: widget.dashboardViewModel.profileImageUrl,
          lineWidth:
              sortedPrioList.length == 3
                  ? screenWidth / 2 * 0.58
                  : screenWidth / 2 * 1.2,
          prioList:
              sortedPrioList
                  .map(
                    (p) => {
                      'prio': p.prio,
                      'apstatu': p.apstatu,
                      'apstatu_text': p.apstatuText,
                      'prio_text': p.prioText,
                      'approver_name': p.approverName,
                      'remark': p.remark,
                    },
                  )
                  .toList(),
        ),
      ),
    );
  }
}
