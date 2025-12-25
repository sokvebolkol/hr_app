import 'dart:async';
import 'dart:io';
import 'package:chokchey_hr_app/widgets/function_card.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/constant.dart';
import '../../utils/file_helper.dart';
import '../../viewmodels/dashboardviewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/ceo_dashboard_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../models/ceo_dashboard_model.dart';
import '../../widgets/ceo_leave_request_widget.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../widgets/date_section.dart';
import '../attendance/staff_attendance_detail_screen.dart';
import '../auth/login-screen.dart';
import '../chokchey_team/chockchey_team_screen.dart';
import '../leaves/leave_approval/ceo_leave_detail_screen.dart';
import '../menu/menu_screen.dart';
import '../notifications/ceo_notifcation_screen.dart';
import '../profile/profile_screen.dart';

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
    ProfilePage(currentIndex: 1),
    const MenuScreen(),
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
    await CustomAlertDialog.show(
      context,
      title: 'Information',
      message: 'Do you want to exit?',
      icon: Icons.exit_to_app,
      iconColor: secondary,
      primaryButtonText: 'No',
      secondaryButtonText: 'Yes',
      onPrimaryPressed: () async {
        Navigator.of(context).pop();
      },
      onSecondaryPressed: () {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
    );
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

              // Check for force update
              if (dashboardViewModel.appVersion != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  final shouldUpdate =
                      await dashboardViewModel.shouldForceUpdate();
                  if (shouldUpdate && mounted) {
                    final updateUrl =
                        Platform.isAndroid
                            ? dashboardViewModel.appVersion!.androidUrl
                            : dashboardViewModel.appVersion!.iosUrl;

                    CustomAlertDialog.show(
                      // ignore: use_build_context_synchronously
                      context,
                      title: 'Update Required',
                      message:
                          'A new version ${dashboardViewModel.appVersion?.version} is available and must be installed to continue using the app.\n\n${dashboardViewModel.appVersion?.releaseNotes ?? ''}',
                      icon: Icons.system_update,
                      iconColor: Colors.orange,
                      primaryButtonText: 'Update Now',
                      onPrimaryPressed: () async {
                        final uri = Uri.parse(updateUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      barrierDismissible: false,
                    );
                  }
                });
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
          color: Colors.black,
          backgroundColor: Colors.white,
          activeColor: secondary,
          shadowColor: Colors.grey[200],
          style: TabStyle.fixedCircle,
          items: const [
            TabItem(icon: Icons.home, title: 'Home'),
            TabItem(icon: Icons.person, title: 'Profile'),
            TabItem(icon: Icons.menu, title: 'Menu'),
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
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _progressAnimationController.forward();

    // Refresh data when dashboard content is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.dashboardViewModel.refreshProfile();
      widget.ceoViewModel.refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressAnimationController.dispose();
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
                InkWell(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const StaffAttendanceDetailScreen(),
                        ),
                      ),
                  child: _buildTodayAttendanceCard(ceoViewModel),
                ),
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
    if (viewModel.errorMessage != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 230,
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
      height: 210,
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
                Text(
                  'View Details >',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
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
                    flex: 2,
                    child: _buildPresentWithProgress(viewModel),
                  ),
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

  Widget _buildPresentWithProgress(CeoDashboardViewModel viewModel) {
    final totalStaff =
        viewModel.presentCount + viewModel.onLeaveCount + viewModel.absentCount;
    final progress = totalStaff > 0 ? viewModel.presentCount / totalStaff : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: progress * _progressAnimation.value,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    );
                  },
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${viewModel.presentCount}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: '/',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        TextSpan(
                          text: '$totalStaff',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Present',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
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
        margin: const EdgeInsets.only(bottom: 1),
        child: CeoLeaveRequestWidget(
          reason: leave.reason,
          status: leave.statuText,
          fromDate: leave.fromDate.toString(),
          toDate: leave.toDate.toString(),
          requesterName: leave.requesterName,
          position: leave.position,
          leaveType: leave.ltyp,
          totalDays: leave.numLeaveDays.toString(),
          currentUserName: widget.dashboardViewModel.username,
          currentUserProfileImageUrl: widget.dashboardViewModel.profileImageUrl,
          empProfileImage: leave.requesterProfileImage,
        ),
      ),
    );
  }

}
