import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../utils/error_handler.dart';
import '../../viewmodels/dashboardviewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/leave_balance_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../widgets/annual_leave_card_widget.dart';
import '../../widgets/date_section.dart';
import '../../widgets/function_card.dart';
import '../../widgets/request_card_widget.dart';
import '../attendance/attendance_logs_screen.dart';
import '../attendance/attendance_clock_screen.dart';
import '../attendance/attendance_adjustment_listing_screen.dart';
import '../attendance/my_attendance_adjustment_request.screen.dart';
import '../auth/login-screen.dart';
import '../holidays/holiday_calendar_screen.dart';
import '../leaves/leave_detail/my_leave_detail_screen.dart';
import '../leaves/leave_request/leave_request_screen.dart';
import '../leaves/leave_balance/leave_balance.dart';
import '../leaves/leave_history/history_request_screen.dart';
import '../menu/menu_screen.dart';
import '../../models/leave_model.dart';
import '../../utils/file_helper.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../notifications/manager_notifcation_screen.dart';
import '../notifications/requester_notification_screen.dart';
import '../birthday_screen.dart';

class RequesterDashboardScreen extends StatefulWidget {
  final bool hideBottomNav;
  final VoidCallback? onNavigateToMenu;
  final VoidCallback? onRefreshNeeded;

  const RequesterDashboardScreen({
    super.key,
    this.hideBottomNav = false,
    this.onNavigateToMenu,
    this.onRefreshNeeded,
  });

  @override
  State<RequesterDashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<RequesterDashboardScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  bool isApproverUser = false;
  late DashboardViewModel _dashboardViewModel;
  Language language = Language();

  final List<Widget> _screens = [
    const RequesterDashboardScreen(),
    const MenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _initializeLanguage();
    WidgetsBinding.instance.addObserver(this);
    _dashboardViewModel = DashboardViewModel();
    _dashboardViewModel.initialize();
    // _dashboardViewModel.initialize().then((_) => _checkAndShowBirthday());

    // Listen for profile updates
    ProfileViewModel.onProfileUpdated = () {
      if (mounted && (_currentIndex == 0 || widget.hideBottomNav)) {
        _dashboardViewModel.refreshProfile();
      }
    };
  }

  // Enable this method to check birthday on dashboard load, currently commented out to avoid showing birthday screen every time during development
  Future<void> _checkAndShowBirthday() async {
    final user = _dashboardViewModel.user;
    final profile = _dashboardViewModel.userProfile;
    if (user == null || profile == null) return;
    if (user.dob == null || user.dob!.isEmpty) return;

    // Parse dob
    DateTime dob;
    try {
      dob = DateTime.parse(user.dob!.split(' ')[0]);
    } catch (_) {
      return;
    }

    final now = DateTime.now();
    if (dob.month != now.month || dob.day != now.day) return;

    // Only show once per year
    final prefs = await SharedPreferences.getInstance();
    final shownKey = 'birthday_shown_${now.year}';
    // change this to false to testing for every hot reload
    // if (prefs.getBool(shownKey) == false) return;
    if (prefs.getBool(shownKey) == true) return;
    await prefs.setBool(shownKey, true);

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    await showBirthdayScreen(context, user: user, profile: profile);
  }

  Future<void> _checkUserRole() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final approverUserValue = pref.getBool("isApprover") ?? false;
    setState(() {
      isApproverUser = approverUserValue;
    });
  }

  Future<void> _initializeLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
      });
    }
  }

  Future<Language> _getCurrentLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    return languageLogic.language;
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? primary : Colors.grey[600],
                size: 30,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primary : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() async {
    await CustomAlertDialog.show(
      context,
      title: language.doYouWantToExit,
      message: language.doYouWantToExit,
      icon: Icons.exit_to_app,
      iconColor: primary,
      primaryButtonText: language.no,
      secondaryButtonText: language.yes,
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

    return FutureBuilder<Language>(
      future: _getCurrentLanguage(),
      builder: (context, languageSnapshot) {
        if (languageSnapshot.hasData) {
          language = languageSnapshot.data!;
        }

        // Set the home content dynamically
        _screens[0] = const _DashboardHomeContent();
        // Set menu screen dynamically to ensure it rebuilds with language changes
        _screens[1] = MenuScreen(key: ValueKey(language.home));

        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: _onBackPressed,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.grey[100],
            body: ChangeNotifierProvider.value(
              value: _dashboardViewModel,
              child: Consumer<DashboardViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading) {
                    return const Center(
                      child: SpinKitFadingCircle(color: primary),
                    );
                  }

                  // Force logout if inactive
                  if (viewModel.isUserInactive) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await viewModel.forceLogout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder:
                                (BuildContext context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    });

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpinKitFadingCircle(color: primary),
                          const SizedBox(height: 16),
                          Text(language.accountInactiveLoggingOut),
                        ],
                      ),
                    );
                  }

                  // Force update check
                  if (viewModel.appVersion != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final shouldUpdate = await viewModel.shouldForceUpdate();

                      if (shouldUpdate && mounted) {
                        final updateUrl =
                            Platform.isAndroid
                                ? viewModel.appVersion!.androidUrl
                                : viewModel.appVersion!.iosUrl;

                        CustomAlertDialog.show(
                          // ignore: use_build_context_synchronously
                          context,
                          title: language.updateAvailable,
                          message:
                              '${language.aNewVersion} ${viewModel.appVersion?.version} '
                              '${language.isAvailableAndMustBeInstalled}\n\n'
                              '${viewModel.appVersion?.releaseNotes ?? ''}',
                          icon: Icons.system_update,
                          iconColor: primary,
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

                  // Error handling
                  if (viewModel.errorMessage != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ErrorHandler.showErrorDialog(
                        context,
                        message: viewModel.errorMessage!,
                        onRetry: () {
                          _dashboardViewModel.fetchDashboard();
                        },
                        onDismiss: () {
                          viewModel.clearError();
                        },
                      );
                    });
                  }

                  // Home screen with sticky header
                  if (_currentIndex == 0 || widget.hideBottomNav) {
                    return Column(
                      children: [
                        _buildStickyHeader(viewModel),
                        Expanded(
                          child: _screens[0],
                        ), // Always show home content when hideBottomNav is true
                      ],
                    );
                  }

                  return _screens[_currentIndex];
                },
              ),
            ),

            /// ✅ Hide / Show Bottom Navigation
            bottomNavigationBar:
                widget.hideBottomNav
                    ? null
                    : Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            icon: Icons.home,
                            label: language.home,
                            isSelected: _currentIndex == 0,
                            onTap: () {
                              setState(() {
                                _currentIndex = 0;
                              });
                            },
                          ),
                          const SizedBox(width: 60), // Space for FAB
                          _buildNavItem(
                            icon: Icons.menu,
                            label: language.menu,
                            isSelected: _currentIndex == 1,
                            onTap: () {
                              setState(() {
                                _currentIndex = 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
            floatingActionButton:
                widget.hideBottomNav
                    ? null
                    : Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          // Main soft shadow
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),

                          // Ambient light
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          // Primary glow
                          BoxShadow(
                            color: primary.withOpacity(0.18),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: FloatingActionButton(
                          elevation: 0,
                          backgroundColor: primary,
                          shape: const CircleBorder(),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const LeaveRequestScreen(),
                              ),
                            );
                            if (result == true && mounted) {
                              _dashboardViewModel.refresh();
                            }
                          },
                        ),
                      ),
                    ),
            floatingActionButtonLocation:
                widget.hideBottomNav
                    ? null
                    : FloatingActionButtonLocation.centerDocked,
          ),
        );
      },
    );
  }

  // Add this new method for the sticky header
  Widget _buildStickyHeader(DashboardViewModel viewModel) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
                        FutureBuilder<String>(
                          future: FileHelper().getGreeting(),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            );
                          },
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
                            builder:
                                (context) =>
                                    isApproverUser
                                        ? const ManagerNotificationScreen()
                                        : const RequesterNotificationScreen(),
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
    ProfileViewModel.onProfileUpdated = null; // Clean up callback
    _dashboardViewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh profile data when app resumes (user might have updated profile in another part of the app)
    if (state == AppLifecycleState.resumed &&
        (_currentIndex == 0 || widget.hideBottomNav)) {
      _dashboardViewModel.refreshProfile();
    }
  }

  // Method to navigate to profile page
  void navigateToProfile() {
    if (widget.hideBottomNav && widget.onNavigateToMenu != null) {
      widget.onNavigateToMenu!();
    } else {
      setState(() {
        _currentIndex = 1;
      });
    }
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
  late TabController _tabController;
  int _currentScrollIndex = 0;
  Language language = Language();

  Future<void> _initializeLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
      });
    }
  }

  // Function buttons data
  List<Map<String, dynamic>> _getFunctionButtons(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return [
      {
        'icon': Icons.access_time,
        'label': language.clockInOut,
        'onPressed':
            (BuildContext context) => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AttendanceClock()),
            ),
      },
      {
        'icon': Icons.event_available,
        'label': language.attendanceLogs,
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
        'icon': Icons.edit_calendar_outlined,
        'label': language.attendanceRequests,
        'onPressed': (BuildContext context) async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AttendanceAdjustmentScreen(),
            ),
          );
          if (result == true) {
            viewModel.refresh();
          }
        },
      },
      {
        'icon': Icons.calendar_month,
        'label': language.holidays,
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
  }

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
    _scrollController = ScrollController();
    _tabController = TabController(length: 2, vsync: this);

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
      final vm = Provider.of<DashboardViewModel>(context, listen: false);
      final items = _getFunctionButtons(context, vm);

      if (_scrollController.hasClients && items.length > 1) {
        _currentScrollIndex = (_currentScrollIndex + 1) % items.length;

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
    _tabController.dispose();
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
                Padding(
                  padding: EdgeInsetsGeometry.only(
                    top: 16,
                    left: 16,
                    right: 16,
                  ),
                  child: const DateSection(),
                ),
                const SizedBox(height: 16),
                _buildLeaveBalanceSection(viewModel),
                const SizedBox(height: 16),
                _buildFunctionButtons(context, viewModel),
                const SizedBox(height: 20),
                // Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        language.myRequest,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _buildRequestTabs(viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaveBalanceSection(DashboardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
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
        child: AnnualLeaveBalanceWidget(
          title: language.remainingLeaveBalance,
          usedLeave: viewModel.usedLeave,
          viewDetailsText: language.viewDetails,
          availableLeave: viewModel.availableLeave,
          usedLeaveText: language.usedLeave,
          availableLeaveText: language.availableLeave,
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
      ),
    );
  }

  Widget _buildFunctionButtons(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    final functionButtons = _getFunctionButtons(context, viewModel);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 100,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                functionButtons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final button = entry.value;

                  return Row(
                    children: [
                      SizedBox(
                        width: 155,
                        child: FunctionIconCardWidget(
                          iconData: button['icon'] as IconData,
                          label: button['label'] as String,
                          onPressed: () => button['onPressed'](context),
                        ),
                      ),
                      // Add spacing between items except for the last one
                      if (index < functionButtons.length - 1)
                        const SizedBox(width: 16),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestTabs(DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Text(
                    language.pendingLeave,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Tab(
                  child: Text(
                    language.pendingAdjustment,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryRequestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history, size: 16, color: primary),
                label: Text(
                  language.viewRequestedHistory,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tab Content
        SizedBox(
          height: 330,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingLeaveTab(viewModel),
              _buildPendingAdjustmentTab(viewModel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingLeaveTab(DashboardViewModel viewModel) {
    final pendingLeaves = viewModel.sortedLeaves;

    if (pendingLeaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              language.noPendingLeaveRequests,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pendingLeaves.length,
      itemBuilder: (context, index) {
        final leave = pendingLeaves[index];
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
          child: RequestCardWidget(
            reason: leave.reason,
            status: leave.statuText,
            totalLabel: language.total,
            leaveType: leave.ltyp,
            fromDate: leave.frdat,
            toDate: leave.todat,
            totalDays: leave.numleav,
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
    );
  }

  Widget _buildPendingAdjustmentTab(DashboardViewModel viewModel) {
    final adjustmentRequests = viewModel.adjustmentRequests;

    if (adjustmentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              language.noPendingAdjustmentRequests,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: adjustmentRequests.length,
      itemBuilder: (context, index) {
        final adjustment = adjustmentRequests[index];
        // Sort approver list by priority ascending
        final sortedApproverList = [...adjustment.approverList]
          ..sort((a, b) => a.priority.compareTo(b.priority));

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MyAttendanceAdjustmentRequestScreen(
                      adjustmentRequest: adjustment,
                    ),
              ),
            );
          },
          child: RequestCardWidget(
            reason: adjustment.reason,
            status: adjustment.statusText,
            isLeave: false,
            totalLabel: '',
            leaveType: adjustment.adjustType,
            fromDate: adjustment.adjustDateTime,
            toDate: adjustment.adjustDateTime,
            totalDays: '',
            appliedDate:
                'Applied: ${FileHelper.formatDate(adjustment.createdDate)}',
            prioList:
                sortedApproverList
                    .map(
                      (a) => {
                        'prio': a.priority,
                        'apstatu': a.approvalStatus,
                        'apstatu_text': a.approvalStatusText,
                        'prio_text': a.priorityText,
                        'remark': a.remark ?? '',
                      },
                    )
                    .toList(),
          ),
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
