import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../attendance/attendance_adjustment_approval_detail_screen.dart';
import '../attendance/my_attendance_adjustment_request.screen.dart';
import '../leaves/leave_approval/approver_leave_detail_screen.dart';
import '../leaves/leave_detail/my_leave_detail_screen.dart';

class ManagerNotificationScreen extends StatefulWidget {
  const ManagerNotificationScreen({super.key});

  @override
  State<ManagerNotificationScreen> createState() =>
      _ManagerNotificationScreenState();
}

class _ManagerNotificationScreenState extends State<ManagerNotificationScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  late TabController _tabController;

  // Cache filtered notifications - updated to only handle Leave Request and Leave Approval
  List<NotificationModel> _leaveRequestNotifications = [];
  List<NotificationModel> _leaveApprovalNotifications = [];

  bool _isInitialized = false;
  bool _isNavigating = false; // Prevent duplicate taps

  Language language = Language();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 2, vsync: this);
    _initializeLanguage();

    // Load notifications only once when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });

    // Listen to tab changes - but don't reload data
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {});
      }
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

  Future<void> _initializeNotifications() async {
    if (_isInitialized) return;

    final viewModel = context.read<NotificationViewModel>();

    // Load all notifications once
    await viewModel.fetchNotifications(refresh: true);

    // Filter and cache notifications
    _updateFilteredNotifications(viewModel.notifications);

    _isInitialized = true;
  }

  void _updateFilteredNotifications(List<NotificationModel> allNotifications) {
    // Personal Tab - show approved/rejected leave requests and attendance adjustments
    _leaveRequestNotifications =
        allNotifications
            .where(
              (n) =>
                  n.type == 'leave' &&
                      (n.data['action'] == 'approved' ||
                          n.data['action'] == 'rejected') ||
                  n.type == 'attendance_adjustment' &&
                      (n.data['action'] == 'approved' ||
                          n.data['action'] == 'rejected'),
            ) // Approved/rejected/ leaves
            .toList();

    // Staff Tab - show new leave requests and reminders for pending approvals
    _leaveApprovalNotifications =
        allNotifications
            .where(
              (n) =>
                  n.type == 'leave' && n.data['action'] == 'new_request' ||
                  n.type == 'leave' && n.data['action'] == 'reminder' ||
                  n.type == 'attendance_adjustment' &&
                      (n.data['action'] == 'new_request' ||
                          n.data['action'] == 'reminder'),
            ) // Only new leave requests and reminders
            .toList();

    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadMoreNotifications() async {
    final viewModel = context.read<NotificationViewModel>();
    if (!viewModel.isLoadingMore && viewModel.hasMorePages) {
      await viewModel.loadMoreNotifications();
      _updateFilteredNotifications(viewModel.notifications);
    }
  }

  Future<void> _refreshNotifications() async {
    final viewModel = context.read<NotificationViewModel>();
    await viewModel.fetchNotifications(refresh: true);
    _updateFilteredNotifications(viewModel.notifications);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _isNavigating = false; // Reset navigation flag
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Reset navigation flag when widget rebuilds to prevent stuck state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isNavigating) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _isNavigating = false;
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(language.notifications),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              final viewModel = context.read<NotificationViewModel>();
              switch (value) {
                case 'mark_all_read':
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => Center(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SpinKitFadingCircle(
                                    color: primary,
                                    size: 50.0,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(language.markingAllAsRead),
                                ],
                              ),
                            ),
                          ),
                        ),
                  );

                  try {
                    final success = await viewModel.markAllAsRead();

                    // Close loading dialog
                    if (mounted) Navigator.pop(context);

                    if (success) {
                      _updateFilteredNotifications(viewModel.notifications);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(language.allNotificationsMarkedAsRead),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(language.failedToMarkAllAsRead),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) Navigator.pop(context);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Error: ${e.toString()}')),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                  break;
                case 'refresh':
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: SpinKitFadingCircle(
                              color: Colors.white,
                              size: 16.0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(language.refreshingNotifications),
                        ],
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  await _refreshNotifications();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        const Icon(Icons.done_all, color: secondary),
                        const SizedBox(width: 8),
                        Text(language.markAllAsRead),
                        // Show count badge if there are unread notifications
                        Consumer<NotificationViewModel>(
                          builder: (context, viewModel, child) {
                            final unreadCount = viewModel.summary!.unread;

                            if (unreadCount > 0) {
                              return Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        const Icon(Icons.refresh, color: secondary),
                        const SizedBox(width: 8),
                        Text(language.refresh),
                      ],
                    ),
                  ),
                ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            child: TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(
                color: secondary,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.zero,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
              tabAlignment: TabAlignment.fill,
              tabs: [
                Tab(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            language.personal,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            language.staffMember,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList('leave_request', _leaveRequestNotifications),
          _buildNotificationList('leave_approval', _leaveApprovalNotifications),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    String tabType,
    List<NotificationModel> notifications,
  ) {
    return Consumer<NotificationViewModel>(
      builder: (context, viewModel, child) {
        // Show loading only if we haven't initialized and there are no cached notifications
        if (!_isInitialized && notifications.isEmpty && viewModel.isLoading) {
          return const Center(
            child: SpinKitFadingCircle(color: primary, size: 50.0),
          );
        }

        // Show error only if we haven't initialized and there's an error
        if (!_isInitialized &&
            viewModel.error != null &&
            notifications.isEmpty) {
          return _buildErrorWidget(viewModel);
        }

        // Show empty state for this specific tab
        if (notifications.isEmpty) {
          return _buildEmptyWidget(tabType);
        }

        return RefreshIndicator(
          onRefresh: _refreshNotifications,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 80,
              left: 0,
              right: 0,
            ),
            itemCount: notifications.length + (viewModel.hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= notifications.length) {
                // Loading indicator for pagination
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child:
                        viewModel.isLoadingMore
                            ? const SpinKitFadingCircle(
                              color: primary,
                              size: 50.0,
                            )
                            : const SizedBox.shrink(),
                  ),
                );
              }

              final notification = notifications[index];
              return _buildNotificationItem(notification, viewModel);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  notification.timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                if (notification.isRecent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      language.newLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () async {
          // Prevent duplicate taps
          if (_isNavigating) return;
          _isNavigating = true;

          try {
            final success = await viewModel.markAsRead(notification.id);

            if (success) {
              _updateFilteredNotifications(viewModel.notifications);

              if (!mounted) return;

              // Handle leave notifications (both request and approval)
              _handleLeaveNotificationTap(notification);
            } else {
              // Show error if marking as read failed
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(language.failedToMarkNotificationAsRead),
                    backgroundColor: Colors.red,
                  ),
                );
              }

              // Still navigate even if marking as read failed
              if (!mounted) return;
              _handleLeaveNotificationTap(notification);
            }
          } finally {
            // Reset the flag after a brief delay to ensure navigation completes
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _isNavigating = false;
              }
            });
          }
        },
      ),
    );
  }

  // Handle attendance adjustment notification tap
  void _handleAttendanceAdjustmentNotificationTap(
    NotificationModel notification,
    String action,
  ) {
    try {
      if (action == 'new_request' || action == 'reminder') {
        final request = notification.toAttendanceAdjustmentRequest();
        _isNavigating = false; // Reset flag before navigation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AttendanceAdjustmentApprovalDetailScreen(
                  request: request,
                  isPending: true,
                ),
          ),
        ).then((result) {
          if (result != null && result['refresh'] == true) {
            _refreshNotifications();
          }
        });
      } else if (action == 'approved' || action == 'rejected') {
        final adjustmentRequest = notification.toAdjustmentRequestModel();
        _isNavigating = false; // Reset flag before navigation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MyAttendanceAdjustmentRequestScreen(
                  adjustmentRequest: adjustmentRequest,
                ),
          ),
        );
      } else {
        _isNavigating = false; // Reset flag before showing modal
        _showNotificationDetails(notification);
      }
    } catch (e) {
      _isNavigating = false; // Reset flag before showing modal
      _showNotificationDetails(notification);
    }
  }

  // Handle leave notification tap (works for both request and approval)
  void _handleLeaveNotificationTap(NotificationModel notification) {
    try {
      final action = notification.data['action']?.toString() ?? '';

      // Route attendance adjustment notifications to dedicated handler
      if (notification.type == 'attendance_adjustment') {
        _handleAttendanceAdjustmentNotificationTap(notification, action);
        return;
      }

      if (action == 'new_request') {
        if (notification.leaveData == null) {
          _isNavigating = false; // Reset flag before showing error
          _showErrorDialog('No leave information available for this request');
          return;
        }

        final leaveRequest = notification.toLeaveRequest();
        _isNavigating = false; // Reset flag before navigation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ApproverLeaveDetailScreen(
                  leave: leaveRequest,
                  isPending: true,
                ),
          ),
        ).then((result) {
          if (result != null && result['refresh'] == true) {
            _refreshNotifications();
          }
        });
      } else if (action == 'approved' || action == 'rejected') {
        // For approved/rejected leaves, navigate to MyLeaveDetailScreen
        if (notification.leaveData == null) {
          _isNavigating = false; // Reset flag before showing error
          _showErrorDialog(
            'No leave information available for this status update',
          );
          return;
        }
        try {
          final leaveInfo = notification.toLeaveHistoryModel();
          _isNavigating = false; // Reset flag before navigation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MyLeaveDetailScreen(leaveRequest: leaveInfo),
            ),
          ).then((result) {
            if (result == true) {
              _refreshNotifications();
            }
          });
        } catch (e) {
          _isNavigating = false; // Reset flag before showing error
          _showErrorDialog('Error processing leave data: ${e.toString()}');
        }
      } else if (action == 'reminder') {
        if (notification.leaveData == null) {
          _isNavigating = false; // Reset flag before showing error
          _showErrorDialog('No leave information available for this reminder');
          return;
        }

        try {
          // Check if it's a pending request that needs approval
          final leaveRequest = notification.toLeaveRequest();
          _isNavigating = false; // Reset flag before navigation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ApproverLeaveDetailScreen(
                    leave: leaveRequest,
                    isPending: true,
                  ),
            ),
          ).then((result) {
            if (result != null && result['refresh'] == true) {
              _refreshNotifications();
            }
          });
        } catch (e) {
          _isNavigating = false; // Reset flag before showing error
          _showErrorDialog('Error processing reminder data: ${e.toString()}');
        }
      } else {
        // Fallback: show notification details modal
        _isNavigating = false; // Reset flag before showing modal
        _showNotificationDetails(notification);
      }
    } catch (e) {
      _isNavigating = false; // Reset flag before showing error
      _showErrorDialog('Error opening leave details: ${e.toString()}');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(language.error),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(language.ok),
              ),
            ],
          ),
    );
  }

  // Show notification details modal
  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.timeAgo,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.body,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),

                        if (notification.data.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            language.details,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...notification.data.entries.map((entry) {
                            if (entry.key == 'staff_leave_request' ||
                                entry.key == 'own_leave_request_data') {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.key.replaceAll('_', ' ').toUpperCase()}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.value.toString(),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // If it's a leave notification, show "View Leave Details" button
                      if (notification.type == 'leave' &&
                          notification.leaveData != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleLeaveNotificationTap(notification);
                            },
                            icon: const Icon(Icons.visibility),
                            label: Text(language.viewLeaveDetails),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),

                      // Generic action button for other click actions
                      if (notification.data['click_action'] != null &&
                          notification.data['click_action'] != 'leave_screen')
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Text(language.viewDetails),
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

  Widget _buildErrorWidget(NotificationViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            language.failedToLoadNotifications,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.error ?? language.unknownErrorOccurred,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              viewModel.clearError();
              await _refreshNotifications();
            },
            icon: const Icon(Icons.refresh),
            label: Text(language.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String tabType) {
    String title, subtitle;

    switch (tabType) {
      case 'leave_request':
        title = language.noLeaveRequestsEmpty;
        subtitle = language.noNewLeaveRequests;
        break;
      case 'leave_approval':
        title = language.noLeaveUpdates;
        subtitle = language.noLeaveStatusUpdatesAvailable;
        break;
      default:
        title = language.noNotificationsAvailable;
        subtitle = language.noNewNotificationsAvailable;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '📭',
            style: TextStyle(fontSize: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
