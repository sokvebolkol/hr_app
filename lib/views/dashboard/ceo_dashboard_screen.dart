import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../constants/responsive.dart';
import '../../utils/file_helper.dart';
import '../../viewmodels/dashboardviewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/ceo_dashboard_viewmodel.dart';
import '../../models/ceo_dashboard_model.dart';
import '../auth/login-page.dart';
import '../leaves/ceo_leave_detail_screen.dart';
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
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: _dashboardViewModel),
            ChangeNotifierProvider.value(value: _ceoDashboardViewModel),
          ],
          child: Consumer2<DashboardViewModel, CeoDashboardViewModel>(
            builder: (context, dashboardViewModel, ceoViewModel, child) {
              if (dashboardViewModel.isLoading) {
                return const Center(child: SpinKitFadingCircle(color: primary));
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
                      SpinKitFadingCircle(color: primary),
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

              return _currentIndex == 0
                  ? _CeoDashboardHomeContent(
                    dashboardViewModel: dashboardViewModel,
                    ceoViewModel: ceoViewModel,
                  )
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
            TabItem(icon: Icons.calendar_month, title: 'Holiday'),
            TabItem(icon: Icons.campaign, title: 'Memo'),
            TabItem(icon: Icons.more_horiz_sharp, title: 'More'),
          ],
          initialActiveIndex: _currentIndex,
          onTap: (int i) {
            if (i == 1 || i == 2) return; // Disable holiday and reports for now

            final newIndex = i == 3 ? 1 : 0; // Map profile to index 1

            // If switching back to home (dashboard), refresh the data
            if (_currentIndex != 0 && newIndex == 0) {
              _dashboardViewModel.refreshProfile();
              _ceoDashboardViewModel.refresh();
            }
            setState(() {
              _currentIndex = newIndex;
            });
          },
        ),
      ),
    );
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
      _currentIndex = 1;
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
          color: primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildDateSection(),
                _buildTodayAttendanceCard(ceoViewModel),
                _buildLeaveManagementTabs(ceoViewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
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
                InkWell(
                  onTap: () {
                    final scaffoldState =
                        context
                            .findAncestorStateOfType<
                              _CeoDashboardScreenState
                            >();
                    scaffoldState?.navigateToProfile();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        _buildProfileAvatar(),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FileHelper().greeting,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.dashboardViewModel.username,
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
    return Consumer<CeoDashboardViewModel>(
      builder: (context, viewModel, child) {
        final pendingCount = viewModel.pendingLeavesCount;

        return Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 24,
            ),
            if (pendingCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    pendingCount > 99 ? '99+' : pendingCount.toString(),
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
    );
  }

  Widget _buildProfileAvatar() {
    final imageUrl = widget.dashboardViewModel.profileImageUrl;

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

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Row(
        children: [
          Text(
            DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceCard(CeoDashboardViewModel viewModel) {
    if (viewModel.isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.3),
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
        height: 180,
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
          colors: [primary, primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  onPressed: () {},
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
                      Colors.red[100]!,
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

                      return ListTile(
                        title: Text(
                          month['display']!,
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color: isSelected ? primary : Colors.black87,
                          ),
                        ),
                        trailing:
                            isSelected
                                ? Icon(Icons.check_circle, color: primary)
                                : null,
                        onTap: () {
                          viewModel.setSelectedMonth(month['value']);
                          Navigator.pop(context);
                        },
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        isPending ? Colors.orange[100] : Colors.green[100],
                    radius: 20,
                    child: Text(
                      leave.requesterName.isNotEmpty
                          ? leave.requesterName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isPending ? Colors.orange[700] : Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.requesterName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'ID: ${leave.eid}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          leave.ltyp,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${leave.numLeaveDays} day(s)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${DateFormat('MMM dd').format(leave.fromDate)} - ${DateFormat('MMM dd, yyyy').format(leave.toDate)}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (leave.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  leave.reason,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Requested: ${DateFormat('MMM dd, yyyy').format(leave.requestDate)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                  if (isPending)
                    GestureDetector(
                      onTap: () {
                        // Prevent parent GestureDetector from triggering
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Handle reject action
                              _showLeaveActionDialog(leave, false);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Handle approve action
                              _showLeaveActionDialog(leave, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Approve',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveActionDialog(LeaveRequest leave, bool isApprove) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isApprove ? 'Approve Leave' : 'Reject Leave'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employee: ${leave.requesterName}'),
                Text('Leave Type: ${leave.ltyp}'),
                Text('Duration: ${leave.numLeaveDays} day(s)'),
                Text(
                  'Dates: ${DateFormat('MMM dd - dd, yyyy').format(leave.fromDate)}',
                ),
                const SizedBox(height: 12),
                Text(
                  isApprove
                      ? 'Are you sure you want to approve this leave request?'
                      : 'Are you sure you want to reject this leave request?',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle the action here
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isApprove
                            ? 'Leave request approved successfully'
                            : 'Leave request rejected successfully',
                      ),
                      backgroundColor: isApprove ? Colors.green : Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApprove ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(isApprove ? 'Approve' : 'Reject'),
              ),
            ],
          ),
    );
  }
}
