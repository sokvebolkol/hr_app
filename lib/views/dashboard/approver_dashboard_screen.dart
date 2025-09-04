import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:chokchey_hr_app/models/leave_model.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../constants/responsive.dart';
import '../../repositories/approver_dashboard_repository.dart';
import '../../utils/file_helper.dart';
import '../../viewmodels/approver_dashboard_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/leave_balance_viewmodel.dart';
import '../../widgets/annual_leave_card_widget.dart';
import '../../widgets/date_section.dart';
import '../../widgets/function_card.dart';
import '../../widgets/leave_request.dart';
import '../../widgets/request_leave_card_widget.dart';
import '../attendance/attendance_calendar_screen.dart';
import '../attendance/attendance_clock_screen.dart';
import '../auth/login-screen.dart';
import '../holidays/holiday_calendar_screen.dart';
import '../leaves/leave_detail/my_leave_detail_screen.dart';
import '../leaves/leave_history/manager_leave_history_screen.dart';
import '../leaves/leave_request/leave_request_screen.dart';
import '../leaves/leave_balance/leave_balance.dart';
import '../memo/memo_screen.dart';
import '../profile/profile_screen.dart';
import '../leaves/leave_approval/approver_leave_detail_screen.dart';

class ApproverDashboardScreen extends StatefulWidget {
  const ApproverDashboardScreen({super.key});

  @override
  _ApproverDashboardScreenState createState() =>
      _ApproverDashboardScreenState();
}

class _ApproverDashboardScreenState extends State<ApproverDashboardScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  late ApproverDashboardViewModel _dashboardViewModel;

  final List<Widget> _screens = [
    const _DashboardHomeContent(),
    const HolidayCalendarScreen(),
    const _DashboardHomeContent(),
    const MemoScreen(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardViewModel = ApproverDashboardViewModel();
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
          child: Consumer<ApproverDashboardViewModel>(
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

              return _screens[_currentIndex];
            },
          ),
        ),
        bottomNavigationBar: ConvexAppBar(
          key: ValueKey(_currentIndex),
          color: Colors.white,
          backgroundColor: primary,
          style: TabStyle.react,
          items: [
            TabItem(icon: Icons.home, title: 'Home'),
            TabItem(icon: Icons.calendar_month, title: 'Holiday'),
            TabItem(
              icon: Container(width: 24, height: 24, color: Colors.transparent),
              title: '',
            ),
            TabItem(icon: Icons.campaign, title: 'Memo'),
            TabItem(icon: Icons.more_horiz_sharp, title: 'More'),
          ],
          initialActiveIndex: _currentIndex,
          onTap: (int i) {
            setState(() {
              _currentIndex = i;
              if (_currentIndex == 0) {
                _dashboardViewModel.refreshProfile();
              }
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ProfileViewModel.onProfileUpdated = null;
    _dashboardViewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _currentIndex == 0) {
      _dashboardViewModel.refreshProfile();
    }
  }

  void navigateToProfile() {
    setState(() {
      _currentIndex = 4;
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
  late TabController _tabController;

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
            MaterialPageRoute(
              builder: (context) => const ManagerLeaveHistoryScreen(),
            ),
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
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 2, vsync: this);

    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_scrollController.hasClients && _functionButtons.length > 3) {
        _currentScrollIndex =
            (_currentScrollIndex + 1) % (_functionButtons.length - 2);

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
    return Consumer<ApproverDashboardViewModel>(
      builder: (context, viewModel, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await viewModel.refresh();
          },
          color: primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(viewModel),
                const DateSection(),
                _buildLeaveBalanceSection(viewModel),
                const SizedBox(height: 16),
                _buildFunctionButtons(context),
                _buildLeaveManagementTabs(viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ApproverDashboardViewModel viewModel) {
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
                    final scaffoldState =
                        context
                            .findAncestorStateOfType<
                              _ApproverDashboardScreenState
                            >();
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
                _buildNotificationIcon(viewModel.pendingLeavesCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(int count) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
          size: 24,
        ),
        if (count > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : count.toString(),
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
  }

  Widget _buildProfileAvatar(ApproverDashboardViewModel viewModel) {
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

  Widget _buildLeaveBalanceSection(ApproverDashboardViewModel viewModel) {
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
    double screenWidth = MediaQuery.of(context).size.width;
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
                        width: screenWidth / 3.6,
                        child: FunctionIconCardWidget(
                          iconData: button['icon'] as IconData,
                          label: button['label'] as String,
                          onPressed: () => button['onPressed'](context),
                        ),
                      ),
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

  Widget _buildLeaveManagementTabs(ApproverDashboardViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16.0),
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
                            color: isSelected ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: primary.withOpacity(0.3),
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
                                  'Pending Approval',
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
                              if (viewModel.filteredPendingLeavesCount > 0) ...[
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
                                    viewModel.filteredPendingLeavesCount > 99
                                        ? '99+'
                                        : viewModel.filteredPendingLeavesCount
                                            .toString(),
                                    style: TextStyle(
                                      color:
                                          isSelected ? primary : Colors.white,
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
                            color: isSelected ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: primary.withOpacity(0.3),
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
                                  'My Leave Request',
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
                              if (viewModel.filteredOwnLeavesCount > 0) ...[
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
                                    viewModel.filteredOwnLeavesCount > 99
                                        ? '99+'
                                        : viewModel.filteredOwnLeavesCount
                                            .toString(),
                                    style: TextStyle(
                                      color:
                                          isSelected ? primary : Colors.white,
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
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingApprovalsTab(viewModel),
                _buildMyLeaveRequestsTab(viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthFilter(ApproverDashboardViewModel viewModel) {
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
                      _getSelectedMonthDisplay(),
                      style: TextStyle(
                        fontSize: 14,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: primary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedMonthDisplay() {
    final viewModel = Provider.of<ApproverDashboardViewModel>(
      context,
      listen: false,
    );
    return DateFormat('MMMM yyyy').format(viewModel.selectedMonth);
  }

  void _showMonthPicker(ApproverDashboardViewModel viewModel) {
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
                      final monthDate = DateFormat(
                        'yyyy-MM',
                      ).parse(month['value']!);
                      final isSelected =
                          viewModel.selectedMonth.year == monthDate.year &&
                          viewModel.selectedMonth.month == monthDate.month;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              viewModel.setSelectedMonth(monthDate);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient:
                                    isSelected
                                        ? LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            primary.withOpacity(0.1),
                                            primary.withOpacity(0.05),
                                          ],
                                        )
                                        : null,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? primary.withOpacity(0.3)
                                          : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? primary.withOpacity(0.1)
                                              : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.calendar_month,
                                      color:
                                          isSelected
                                              ? primary
                                              : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      month['display']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                        color:
                                            isSelected
                                                ? primary
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
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
        'value': DateFormat('yyyy-MM').format(monthDate),
        'display': DateFormat('MMMM yyyy').format(monthDate),
      });
    }

    return months.reversed.toList();
  }

  Widget _buildPendingApprovalsTab(ApproverDashboardViewModel viewModel) {
    if (viewModel.filteredPendingLeaveRequests.isEmpty) {
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
              'No leave requests found for ${DateFormat('MMMM yyyy').format(viewModel.selectedMonth)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.filteredPendingLeaveRequests.length,
      itemBuilder:
          (context, index) => _buildCompactPendingLeaveItem(
            viewModel.filteredPendingLeaveRequests[index],
          ),
    );
  }

  Widget _buildMyLeaveRequestsTab(ApproverDashboardViewModel viewModel) {
    final filteredLeaves = viewModel.filteredOwnLeaves;
    final screenWidth = MediaQuery.of(context).size.width;
    if (filteredLeaves.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.beach_access, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Leave Requests',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No leave requests found for ${DateFormat('MMMM yyyy').format(viewModel.selectedMonth)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredLeaves.length,
      itemBuilder: (context, index) {
        final leave = filteredLeaves[index];
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
              if (result == true) {
                viewModel.refresh();
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: LeaveRequestWidget(
              reason: leave.reason,
              status: leave.statuText,
              fromDate: leave.frdat,
              toDate: leave.todat,
              requesterName: leave.dname,
              totalDays: leave.numleav,
              currentUserName: viewModel.username,
              currentUserProfileImageUrl: viewModel.profileImageUrl,
              lineWidth: screenWidth / 2 * 0.58,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactPendingLeaveItem(PendingLeaveRequest leave) {
    return GestureDetector(
      onTap: () {
        _navigateToLeaveDetail(leave);
      },
      child: RequesterLeaveCardWidget(
        requesterName: leave.requesterName,
        positionName: leave.positionName,
        leaveType: leave.ltyp,
        numLeaveDays: leave.numLeaveDays,
        fromDate: leave.fromDate,
        toDate: leave.toDate,
        reason: leave.reason,
        requestDate: leave.requestDate,
        onTap: () => _navigateToLeaveDetail(leave),
        actionText: 'Tap to review',
        avatarBackgroundColor: Colors.orange[100],
        avatarTextColor: Colors.orange[700],
      ),
    );
  }

  void _navigateToLeaveDetail(PendingLeaveRequest leave) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApproverLeaveDetailScreen(leave: leave),
      ),
    );
    // Handle the result and refresh if needed
    if (result != null &&
        result['success'] == true &&
        result['refresh'] == true) {
      if (mounted) {
        Provider.of<ApproverDashboardViewModel>(
          context,
          listen: false,
        ).refresh();
      }
    }
  }
}
