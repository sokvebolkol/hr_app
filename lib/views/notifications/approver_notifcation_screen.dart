import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../constants/constant.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../leaves/leave_approval/approver_leave_detail_screen.dart';
import '../leaves/leave_detail/my_leave_detail_screen.dart';

class ApproverNotificationScreen extends StatefulWidget {
  const ApproverNotificationScreen({super.key});

  @override
  State<ApproverNotificationScreen> createState() =>
      _ApproverNotificationScreenState();
}

class _ApproverNotificationScreenState extends State<ApproverNotificationScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  late TabController _tabController;

  // Cache filtered notifications - updated to only handle Leave Request and Leave Approval
  List<NotificationModel> _leaveRequestNotifications = [];
  List<NotificationModel> _leaveApprovalNotifications = [];

  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 2, vsync: this);

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
    // Filter notifications based on leave status and action type
    _leaveRequestNotifications =
        allNotifications
            .where(
              (n) =>
                  n.type == 'leave' && n.data['action'] == 'new_request' ||
                  n.type == 'leave' && n.data['action'] == 'reminder',
            ) // All leave requests
            .toList();

    _leaveApprovalNotifications =
        allNotifications
            .where(
              (n) =>
                  n.type == 'leave' &&
                  (n.data['action'] == 'approved' ||
                      n.data['action'] == 'rejected' ||
                      n.data['action'] == 'submitted'),
            ) // All approved/rejected/submitted leaves
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
                        (context) => const Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Marking all as read...'),
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
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('All notifications marked as read'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Failed to mark all as read'),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
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
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Refreshing notifications...'),
                        ],
                      ),
                      duration: Duration(seconds: 1),
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
                        const Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: secondary),
                        SizedBox(width: 8),
                        Text('Refresh'),
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
                        const Flexible(
                          child: Text(
                            'Leave Request',
                            style: TextStyle(fontSize: 14, color: Colors.white),
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
                        const Flexible(
                          child: Text(
                            'Leave Approval',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_leaveApprovalNotifications.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_leaveApprovalNotifications.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
          return const Center(child: CircularProgressIndicator());
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length + (viewModel.hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= notifications.length) {
                // Loading indicator for pagination
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child:
                        viewModel.isLoadingMore
                            ? const CircularProgressIndicator()
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
                    child: const Text(
                      'NEW',
                      style: TextStyle(
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
                const SnackBar(
                  content: Text('❌ Failed to mark notification as read'),
                  backgroundColor: Colors.red,
                ),
              );
            }

            // Still navigate even if marking as read failed
            if (!mounted) return;
            _handleLeaveNotificationTap(notification);
          }
        },
      ),
    );
  }

  // Handle leave notification tap (works for both request and approval)
  void _handleLeaveNotificationTap(NotificationModel notification) {
    try {
      final action = notification.data['action']?.toString() ?? '';

      print("🔔 Notification tap - Action: $action");
      print("🔔 Has leave data: ${notification.leaveData != null}");

      if (action == 'new_request') {
        // For new leave requests, use ApproverLeaveDetailScreen with PendingLeaveRequest
        print(
          "➡️ Navigating to ApproverLeaveDetailScreen (PendingLeaveRequest)",
        );

        if (notification.leaveData == null) {
          _showErrorDialog('No leave information available for this request');
          return;
        }

        final leaveRequest = notification.toPendingLeaveRequest();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ApproverLeaveDetailScreen(leave: leaveRequest),
          ),
        ).then((result) {
          if (result == true) {
            _refreshNotifications();
          }
        });
      } else if (action == 'approved' ||
          action == 'rejected' ||
          action == 'submitted') {
        // For approved/rejected/submitted leaves, use MyLeaveDetailScreen with LeaveHistoryModel
        print("➡️ Navigating to MyLeaveDetailScreen (LeaveHistoryModel)");

        if (notification.leaveData == null) {
          _showErrorDialog(
            'No leave information available for this status update',
          );
          return;
        }

        try {
          final leaveInfo = notification.toLeaveHistoryModel();
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
          print("❌ Error converting to LeaveHistoryModel: $e");
          _showErrorDialog('Error processing leave data: ${e.toString()}');
        }
      } else {
        // Fallback: show notification details modal
        _showNotificationDetails(notification);
      }
    } catch (e) {
      print("❌ Error handling leave notification: $e");
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
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
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
                          const Text(
                            'Details:',
                            style: TextStyle(
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
                            label: const Text('View Leave Details'),
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
                              print(
                                'Navigate to: ${notification.data['click_action']}',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Text('View Details'),
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
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.error ?? 'Unknown error occurred',
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
            label: const Text('Retry'),
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
        title = 'No leave requests';
        subtitle = 'No new leave requests to review';
        break;
      case 'leave_approval':
        title = 'No leave updates';
        subtitle = 'No leave status updates available';
        break;
      default:
        title = 'No notifications';
        subtitle = 'No new notifications available';
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
