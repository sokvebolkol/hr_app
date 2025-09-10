import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../constants/constant.dart';
import '../../models/notification_model.dart';
import '../../viewmodels/nofitication_viewmodel.dart';
import '../../widgets/notification_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _viewModel = Provider.of<NotificationViewModel>(context, listen: false);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _viewModel.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Consumer<NotificationViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.hasNotifications) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) async {
                    switch (value) {
                      case 'mark_all_read':
                        await viewModel.markAllAsRead();
                        break;
                      case 'clear_all':
                        _showClearAllDialog();
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'mark_all_read',
                          child: Row(
                            children: [
                              Icon(Icons.mark_email_read, size: 20),
                              SizedBox(width: 8),
                              Text('Mark All Read'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear_all',
                          child: Row(
                            children: [
                              Icon(Icons.clear_all, size: 20),
                              SizedBox(width: 8),
                              Text('Clear All'),
                            ],
                          ),
                        ),
                      ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Consumer<NotificationViewModel>(
                builder: (context, viewModel, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('All'),
                      if (viewModel.notifications.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${viewModel.notifications.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Tab(
              child: Consumer<NotificationViewModel>(
                builder: (context, viewModel, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unread'),
                      if (viewModel.unreadCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${viewModel.unreadCount}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const Tab(text: 'Read'),
          ],
        ),
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: SpinKitFadingCircle(color: primary));
          }

          if (viewModel.error != null) {
            return _buildErrorWidget(viewModel.error!);
          }

          return RefreshIndicator(
            onRefresh: viewModel.refreshNotifications,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(viewModel.notifications),
                _buildNotificationsList(viewModel.unreadNotifications),
                _buildNotificationsList(viewModel.readNotifications),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationItemWidget(
          notification: notification,
          onTap: () => _handleNotificationTap(notification),
          onDismiss: () => _handleNotificationDismiss(notification),
        );
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _viewModel.loadNotifications,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read if not already read
    if (!notification.isRead) {
      await _viewModel.markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    _navigateBasedOnNotification(notification);
  }

  void _handleNotificationDismiss(NotificationModel notification) async {
    await _viewModel.deleteNotification(notification.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification dismissed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateBasedOnNotification(NotificationModel notification) {
    // Implement navigation based on notification type and data
    switch (notification.type) {
      case NotificationType.leave:
        _navigateToLeaveDetails(notification);
        break;
      case NotificationType.attendance:
        _navigateToAttendance(notification);
        break;
      case NotificationType.approval:
        _navigateToApproval(notification);
        break;
      default:
        // Handle general notifications
        break;
    }
  }

  void _navigateToLeaveDetails(NotificationModel notification) {
    final leaveId = notification.data['leave_id'];
    if (leaveId != null) {
      // Navigate to leave details
      // Navigator.pushNamed(context, '/leave-details', arguments: leaveId);
    }
  }

  void _navigateToAttendance(NotificationModel notification) {
    // Navigate to attendance screen
    // Navigator.pushNamed(context, '/attendance');
  }

  void _navigateToApproval(NotificationModel notification) {
    final approvalType = notification.data['approval_type'];
    final itemId = notification.data['item_id'];

    if (approvalType != null && itemId != null) {
      // Navigate to appropriate approval screen
      // Navigator.pushNamed(context, '/approvals', arguments: {...});
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Notifications'),
            content: const Text(
              'Are you sure you want to clear all notifications? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _viewModel.clearAllNotifications();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications cleared'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
