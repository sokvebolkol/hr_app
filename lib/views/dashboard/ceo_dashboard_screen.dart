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
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../utils/file_helper.dart';
import '../../viewmodels/dashboardviewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/ceo_dashboard_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../models/ceo_dashboard_model.dart';
import '../../widgets/pending_approval_request_widget.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../widgets/date_section.dart';
import '../../widgets/statistics_card.dart';
import '../attendance/staff_attendance_screen.dart';
import '../auth/login-screen.dart';
import '../chokchey_team/chockchey_team_screen.dart';
import '../leaves/approval_history_screen.dart';
import '../leaves/leave_approval/ceo_leave_detail_screen.dart';
import '../menu/menu_screen.dart';
import '../notifications/ceo_notifcation_screen.dart';
import '../profile/profile_screen.dart';

class CeoDashboardScreen extends StatefulWidget {
  const CeoDashboardScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
  Language language = Language();
  bool _hasShownUpdateDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardViewModel = DashboardViewModel();
    _ceoDashboardViewModel = CeoDashboardViewModel();
    _initializeLanguage();

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
      title: language.information,
      message: language.doYouWantToExit,
      icon: Icons.exit_to_app,
      iconColor: secondary,
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SpinKitFadingCircle(color: secondary),
                      const SizedBox(height: 16),
                      Text(language.yourAccountIsInactiveLoggingOut),
                    ],
                  ),
                );
              }

              // Check for force update
              if (dashboardViewModel.appVersion != null &&
                  !_hasShownUpdateDialog) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (_hasShownUpdateDialog) return; // Double check

                  final shouldUpdate =
                      await dashboardViewModel.shouldForceUpdate();
                  if (shouldUpdate && mounted) {
                    _hasShownUpdateDialog = true; // Set flag before showing

                    final updateUrl =
                        Platform.isAndroid
                            ? dashboardViewModel.appVersion!.androidUrl
                            : dashboardViewModel.appVersion!.iosUrl;

                    showModalBottomSheet(
                      // ignore: use_build_context_synchronously
                      context: context,
                      isDismissible: false,
                      enableDrag: false,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) => WillPopScope(
                            onWillPop: () async => false,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.2,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.system_update,
                                            size: 48,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          language.updateRequired,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${language.aNewVersion} ${dashboardViewModel.appVersion?.version} ${language.isAvailableAndMustBeInstalled}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (dashboardViewModel
                                                .appVersion
                                                ?.releaseNotes
                                                .isNotEmpty ??
                                            false) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              dashboardViewModel
                                                  .appVersion!
                                                  .releaseNotes,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final uri = Uri.parse(updateUrl);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(
                                                  uri,
                                                  mode:
                                                      LaunchMode
                                                          .externalApplication,
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              language.updateNow,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).padding.bottom,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
          items: [
            TabItem(icon: Icons.home, title: language.home),
            TabItem(icon: Icons.person, title: language.profile),
            TabItem(icon: Icons.menu, title: language.menu),
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
      _currentIndex = 2;
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
  String _selectedMonth = 'All'; // Default filter for Approval History tab
  String _selectedMonthPending =
      'All'; // Default filter for Pending Approval tab
  Language language = Language();
  final FileHelper _fileHelper = FileHelper();

  // Cache to store month string to DateTime mapping for filtering
  final Map<String, DateTime> _monthStringToDate = {};

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
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

  Future<void> _initializeLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
      });
    }
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
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: const DateSection(),
                ),
                InkWell(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const StaffAttendanceScreen(
                                isTodayAttendance: false,
                              ),
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
                Text(
                  language.errorLoadingDashboard,
                  style: const TextStyle(
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
                  child: Text(language.retry),
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
                Expanded(
                  child: Text(
                    language.todaysAttendance,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  language.viewDetails,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
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
                      language.late,
                      viewModel.lateCount.toString(),
                      Colors.orange[100]!,
                    ),
                  ),
                  _buildSeparator(),
                  Expanded(
                    child: _buildSimpleAttendanceStatItem(
                      language.leave,
                      viewModel.onLeaveCount.toString(),
                      Colors.blue[100]!,
                    ),
                  ),
                  _buildSeparator(),
                  Expanded(
                    child: _buildSimpleAttendanceStatItem(
                      language.absent,
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
                label: language.chokcheyTeam,
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
                label: language.staffAttendances,
                textSize: 14,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const StaffAttendanceScreen(
                            isTodayAttendance: true,
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
                  Text(
                    language.present,
                    style: const TextStyle(
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
                                  language.pendingApproval,
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
                                  language.approvalHistory,
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
                _buildApprovedLeavesTab(viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingLeavesTab(List<LeaveRequest> leaves) {
    // Filter by month
    List<LeaveRequest> filteredLeaves =
        _selectedMonthPending == 'All'
            ? leaves
            : leaves.where((leave) {
              // Try todat first, then frdat
              DateTime? leaveDate = DateTime.tryParse(leave.todat);

              if (leaveDate == null && leave.frdat.isNotEmpty) {
                leaveDate = DateTime.tryParse(leave.frdat);
              }

              if (leaveDate == null) return false;
              return _isSameMonth(leaveDate, _selectedMonthPending);
            }).toList();

    _generateMonthOptions(leaves).then((monthOptions) {
      // Store month options for later use if needed
    });

    return Column(
      children: [
        // Month Filter
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: secondary),
              const SizedBox(width: 8),
              const Text(
                'Filter by Month:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final monthOptions = await _generateMonthOptions(leaves);
                    _showMonthFilterBottomSheetPending(monthOptions);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedMonthPending,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              filteredLeaves.isEmpty
                  ? Container(
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
                          language.noPendingRequests,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedMonthPending == 'All'
                              ? language.allLeaveRequestsAreUpToDate
                              : '${language.noRequestsFoundFor} $_selectedMonthPending',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredLeaves.length,
                    itemBuilder:
                        (context, index) =>
                            _buildCompactLeaveItem(filteredLeaves[index], true),
                  ),
        ),
      ],
    );
  }

  Widget _buildApprovedLeavesTab(CeoDashboardViewModel viewModel) {
    // Get data from viewmodel
    final approvedLeaves = viewModel.approvedLeaves;
    final rejectedLeaves = viewModel.rejectedLeaves;
    final allLeaves = [...approvedLeaves, ...rejectedLeaves];

    // Filter by month
    List<LeaveRequest> filteredLeaves =
        _selectedMonth == 'All'
            ? allLeaves
            : allLeaves.where((leave) {
              // Try todat first, then frdat
              DateTime? leaveDate = DateTime.tryParse(leave.todat);

              if (leaveDate == null && leave.frdat.isNotEmpty) {
                leaveDate = DateTime.tryParse(leave.frdat);
              }

              if (leaveDate == null) return false;
              return _isSameMonth(leaveDate, _selectedMonth);
            }).toList();

    // Calculate approved and rejected counts from filtered data
    final approvedCount =
        filteredLeaves.where((l) => approvedLeaves.contains(l)).length;
    final rejectedCount =
        filteredLeaves.where((l) => rejectedLeaves.contains(l)).length;

    _generateMonthOptions(allLeaves).then((monthOptions) {
      // Store month options for later use if needed
    });

    return Column(
      children: [
        // Month Filter
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: secondary),
              const SizedBox(width: 8),
              const Text(
                'Filter by Month:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final monthOptions = await _generateMonthOptions(allLeaves);
                    _showMonthFilterBottomSheet(monthOptions);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedMonth,
                          style: const TextStyle(
                            fontSize: 14,
                            color: secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: secondary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Statistics Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              StatisticsCard(
                title: language.approved,
                count: approvedCount,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ApprovalHistoryScreen(
                            filterType: 'approved',
                            viewModel: viewModel,
                            initialMonth: _selectedMonth,
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              StatisticsCard(
                title: language.rejected,
                count: rejectedCount,
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ApprovalHistoryScreen(
                            filterType: 'rejected',
                            viewModel: viewModel,
                            initialMonth: _selectedMonth,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to generate month options from leaves
  // Helper to check if a date is in the selected month
  bool _isSameMonth(DateTime date, String selectedMonth) {
    if (selectedMonth == 'All') return true;
    // Check if the selected month matches this date using the cache
    final cachedDate = _monthStringToDate[selectedMonth];
    if (cachedDate == null) return false;
    return date.year == cachedDate.year && date.month == cachedDate.month;
  }

  Future<List<String>> _generateMonthOptions(List<LeaveRequest> leaves) async {
    final Map<DateTime, String> monthMap = {};

    for (var leave in leaves) {
      // Try todat first, then frdat
      DateTime? leaveDate = DateTime.tryParse(leave.todat);

      if (leaveDate == null && leave.frdat.isNotEmpty) {
        leaveDate = DateTime.tryParse(leave.frdat);
      }

      if (leaveDate != null) {
        // Create a key for the month (first day of the month)
        final monthKey = DateTime(leaveDate.year, leaveDate.month, 1);
        final monthName = await _fileHelper.getMonthName(leaveDate.month);
        final monthYear = '$monthName ${leaveDate.year}';
        monthMap[monthKey] = monthYear;
        // Cache the mapping for filtering
        _monthStringToDate[monthYear] = monthKey;
      }
    }

    // Sort months in descending order (most recent first)
    final sortedMonths = monthMap.keys.toList()..sort((a, b) => b.compareTo(a));

    // Build the result with 'All' first, then sorted months
    final result = <String>['All'];
    for (var monthKey in sortedMonths) {
      result.add(monthMap[monthKey]!);
    }

    return result;
  }

  // Show month filter bottom sheet
  void _showMonthFilterBottomSheetPending(List<String> monthOptions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: secondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            language.selectMonth,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Month options list
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: monthOptions.length,
                    itemBuilder: (context, index) {
                      final month = monthOptions[index];
                      final isSelected = _selectedMonthPending == month;
                      final isAll = month == 'All';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMonthPending = month;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? secondary.withOpacity(0.08)
                                      : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color:
                                      isSelected
                                          ? secondary
                                          : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? secondary.withOpacity(0.15)
                                            : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isAll
                                        ? Icons.all_inclusive
                                        : Icons.calendar_today,
                                    color:
                                        isSelected
                                            ? secondary
                                            : Colors.grey[600],
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    month,
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
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
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

  void _showMonthFilterBottomSheet(List<String> monthOptions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: secondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${language.selectMonth}\n',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: language.twelveMonthsAvailable,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Month options list
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: monthOptions.length,
                    itemBuilder: (context, index) {
                      final month = monthOptions[index];
                      final isSelected = _selectedMonth == month;
                      final isAll = month == 'All';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMonth = month;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? secondary.withOpacity(0.08)
                                      : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color:
                                      isSelected
                                          ? secondary
                                          : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? secondary.withOpacity(0.15)
                                            : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isAll
                                        ? Icons.all_inclusive
                                        : Icons.calendar_today,
                                    color:
                                        isSelected
                                            ? secondary
                                            : Colors.grey[600],
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Month text
                                Expanded(
                                  child: Text(
                                    month,
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
                                    ),
                                  ),
                                ),

                                // Selected check icon
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: secondary,
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
                      );
                    },
                  ),
                ),

                // Bottom padding
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
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
        child: PendingApprovalRequestWidget(
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
