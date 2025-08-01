import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../constants/responsive.dart';
import '../../viewmodels/dashboardviewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
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
                return const Center(child: CircularProgressIndicator());
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
      _currentIndex = 1; // Profile page index
    });
  }
}

class _DashboardHomeContent extends StatefulWidget {
  const _DashboardHomeContent();

  @override
  State<_DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<_DashboardHomeContent> {
  @override
  void initState() {
    super.initState();
    // Refresh profile data when dashboard content is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<DashboardViewModel>(context, listen: false);
      viewModel.refreshProfile();
    });
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
                _buildDateSection(),
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
                              viewModel.greeting,
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
            placeholder: 'assets/images/profile.jpg',
            image: imageUrl,
            fit: BoxFit.cover,
            imageErrorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/profile.jpg',
                fit: BoxFit.cover,
              );
            },
          ),
        ),
      );
    } else {
      return const CircleAvatar(
        backgroundImage: AssetImage('assets/images/profile.jpg'),
        backgroundColor: Colors.blueAccent,
      );
    }
  }

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsetsDirectional.all(16),
      child: Text(
        DateFormat('EEEE dd MMMM, yyyy').format(DateTime.now()),
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceSection(DashboardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnnualLeaveBalanceWidget(
        usedLeave: viewModel.usedLeave,
        availableLeave: viewModel.availableLeave,
        onViewDetails: () {
          // Show details or navigate
        },
      ),
    );
  }

  Widget _buildFunctionButtons(BuildContext context) {
    return Padding(
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
                  MaterialPageRoute(builder: (context) => AttendanceClock()),
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
          height: 400, // Fixed height for the list
          child: ListView.builder(
            itemCount: viewModel.sortedLeaves.length,
            itemBuilder: (context, index) {
              final leave = viewModel.sortedLeaves[index];
              // Sort prioList by prio ascending
              final sortedPrioList = [...leave.prioList]
                ..sort((a, b) => a.prio.compareTo(b.prio));
              return LeaveRequestWidget(
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
  }
}
