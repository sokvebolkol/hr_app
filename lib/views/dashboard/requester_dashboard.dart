import 'dart:async';
import 'dart:io';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
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
import '../../widgets/leave_card_widget.dart';
import '../attendance/attendance_logs_screen.dart';
import '../attendance/attendance_clock_screen.dart';
import '../attendance/attendance_adjustment_screen.dart';
import '../auth/login-screen.dart';
import '../holidays/holiday_calendar_screen.dart';
import '../leaves/leave_detail/my_leave_detail_screen.dart';
import '../leaves/leave_request/leave_request_screen.dart';
import '../leaves/leave_balance/leave_balance.dart';
import '../leaves/leave_history/leave_history_screen.dart';
import '../menu/menu_screen.dart';
import '../../models/leave_model.dart';
import '../../utils/file_helper.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../notifications/requester_notification_screen.dart';

class RequesterDashboardScreen extends StatefulWidget {
  final bool hideBottomNav;

  const RequesterDashboardScreen({super.key, this.hideBottomNav = false});

  @override
  State<RequesterDashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<RequesterDashboardScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  late DashboardViewModel _dashboardViewModel;
  Language language = Language();

  final List<Widget> _screens = [
    const RequesterDashboardScreen(),
    const MenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
    WidgetsBinding.instance.addObserver(this);
    _dashboardViewModel = DashboardViewModel();
    _dashboardViewModel.initialize();

    // Listen for profile updates
    ProfileViewModel.onProfileUpdated = () {
      if (mounted && (_currentIndex == 0 || widget.hideBottomNav)) {
        _dashboardViewModel.refreshProfile();
      }
    };
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

    // Set the home content dynamically
    _screens[0] = const _DashboardHomeContent();

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
                return const Center(child: SpinKitFadingCircle(color: primary));
              }

              // Force logout if inactive
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
                : ConvexAppBar(
                  key: ValueKey(_currentIndex),
                  backgroundColor: Colors.white,
                  activeColor: primary,
                  shadowColor: Colors.grey[200],
                  color: primary,
                  style: TabStyle.react,
                  items: [
                    TabItem(icon: Icons.home, title: language.home),
                    TabItem(icon: Icons.home, title: language.leaveRequest),
                    TabItem(icon: Icons.menu, title: language.menu),
                  ],
                  initialActiveIndex: _currentIndex == 0 ? 0 : 2,
                  onTap: (int i) {
                    if (i == 1) return;

                    final newIndex = i == 2 ? 1 : 0;

                    if (_currentIndex != 0 && newIndex == 0) {
                      _dashboardViewModel.refreshProfile();
                    }

                    setState(() {
                      _currentIndex = newIndex;
                    });
                  },
                ),

        floatingActionButton:
            widget.hideBottomNav
                ? null
                : FloatingActionButton(
                  backgroundColor: primary,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveRequestScreen(),
                      ),
                    );

                    if (result == true && mounted) {
                      _dashboardViewModel.refresh();
                    }
                  },
                ),

        floatingActionButtonLocation:
            widget.hideBottomNav
                ? null
                : FloatingActionButtonLocation.centerDocked,
      ),
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
                                    const RequesterNotificationScreen(),
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
  List<Map<String, dynamic>> _getFunctionButtons(BuildContext context) {
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
        'onPressed': (BuildContext context) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AttendanceAdjustmentScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.history,
        'label': language.historyRequests,
        'onPressed':
            (BuildContext context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LeaveHistoryScreen(),
              ),
            ),
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
      if (_scrollController.hasClients &&
          _getFunctionButtons(context).length > 3) {
        // Calculate the next scroll position
        _currentScrollIndex =
            (_currentScrollIndex + 1) %
            (_getFunctionButtons(context).length - 2);

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
                _buildFunctionButtons(context),
                _buildRecentLeaveRequests(viewModel),
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
    );
  }

  Widget _buildFunctionButtons(BuildContext context) {
    final functionButtons = _getFunctionButtons(context);
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

  Widget _buildRecentLeaveRequests(DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                right: 16.0,
                bottom: 8.0,
                top: 8.0,
              ),
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: secondary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaveHistoryScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      language.viewRequestedHistory,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ],
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
                child: LeaveCardWidget(
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
          ),
        ),
      ],
    );
  }
}
