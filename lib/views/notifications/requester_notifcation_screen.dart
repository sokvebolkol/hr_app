import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../constants/constant.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../leaves/leave_detail/my_leave_detail_screen.dart';

class RequesterNotificationScreen extends StatefulWidget {
  const RequesterNotificationScreen({super.key});

  @override
  State<RequesterNotificationScreen> createState() =>
      _RequesterNotificationScreenState();
}

class _RequesterNotificationScreenState
    extends State<RequesterNotificationScreen>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;

  // Cache filtered notifications - only leave status/approval notifications
  List<NotificationModel> _leaveStatusNotifications = [];

  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Load notifications only once when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
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
    // Filter notifications for leave status updates only (approved/rejected/submitted)
    _leaveStatusNotifications =
        allNotifications
            .where(
              (n) =>
                  !n.isRead &&
                  n.type == 'leave' &&
                  (n.data['action'] == 'approved' ||
                      n.data['action'] == 'rejected' ||
                      n.data['action'] == 'submitted'),
            )
            .toList();

    if (mounted) {
      setState(() {});
    }

    // Debug logging
    print('🔄 Updated requester notifications:');
    print('  Leave Status Updates: ${_leaveStatusNotifications.length}');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            // Show count badge in title
            if (_leaveStatusNotifications.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_leaveStatusNotifications.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
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
                                  SpinKitFadingCircle(color: primary),
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
                                Text('❌ Failed to mark all as read'),
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
                              Expanded(child: Text('❌ Error: ${e.toString()}')),
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
                            child: SpinKitFadingCircle(
                              size: 16,
                              color: Colors.white,
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
                        // Show count badge if there are unread notifications
                        if (_leaveStatusNotifications.isNotEmpty)
                          Container(
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
                              '${_leaveStatusNotifications.length}',
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
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          // Show loading only if we haven't initialized and there are no cached notifications
          if (!_isInitialized &&
              _leaveStatusNotifications.isEmpty &&
              viewModel.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCircle(color: primary),
                  SizedBox(height: 16),
                  Text('Loading leave status updates...'),
                ],
              ),
            );
          }

          // Show error only if we haven't initialized and there's an error
          if (!_isInitialized &&
              viewModel.error != null &&
              _leaveStatusNotifications.isEmpty) {
            return _buildErrorWidget(viewModel);
          }

          // Show empty state if no notifications
          if (_leaveStatusNotifications.isEmpty) {
            return _buildEmptyWidget();
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            color: primary,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount:
                  _leaveStatusNotifications.length +
                  (viewModel.hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _leaveStatusNotifications.length) {
                  // Loading indicator for pagination
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child:
                          viewModel.isLoadingMore
                              ? const SpinKitFadingCircle(color: primary)
                              : const SizedBox.shrink(),
                    ),
                  );
                }

                final notification = _leaveStatusNotifications[index];
                return _buildNotificationItem(notification, viewModel);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationViewModel viewModel,
  ) {
    // Determine notification color based on action
    Color cardColor;
    Color borderColor;
    IconData iconData;

    switch (notification.data['action']) {
      case 'approved':
        cardColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        iconData = Icons.check_circle_outline;
        break;
      case 'rejected':
        cardColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        iconData = Icons.cancel_outlined;
        break;
      case 'submitted':
        cardColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade300;
        iconData = Icons.send_outlined;
        break;
      default:
        cardColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade300;
        iconData = Icons.notifications_outlined;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, color: primary, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              width: 10,
              height: 10,
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
            const SizedBox(height: 6),
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  notification.timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                if (notification.isRecent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
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
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: SpinKitFadingCircle(size: 16, color: primary),
                  ),
                  SizedBox(width: 12),
                  Text('Opening leave details...'),
                ],
              ),
              duration: Duration(seconds: 1),
            ),
          );

          final success = await viewModel.markAsRead(notification.id);

          if (success) {
            _updateFilteredNotifications(viewModel.notifications);

            if (!mounted) return;

            // Handle leave status notification
            _handleLeaveStatusTap(notification);
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
            _handleLeaveStatusTap(notification);
          }
        },
      ),
    );
  }

  // Handle leave status notification tap
  void _handleLeaveStatusTap(NotificationModel notification) {
    try {
      final action = notification.data['action']?.toString() ?? '';

      print("🔔 Requester - Leave status tap - Action: $action");
      print("🔔 Has leave data: ${notification.leaveData != null}");

      if (notification.leaveData == null) {
        _showErrorDialog(
          'No leave information available for this status update',
        );
        return;
      }

      try {
        // Convert to LeaveHistoryModel for MyLeaveDetailScreen
        final leaveInfo = notification.toLeaveHistoryModel();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyLeaveDetailScreen(leaveRequest: leaveInfo),
          ),
        ).then((result) {
          if (result == true) {
            _refreshNotifications();
          }
        });
      } catch (e) {
        print("❌ Error converting to LeaveHistoryModel: $e");
        _showErrorDialog('Error processing leave data: ${e.toString()}');

        // Fallback: show notification details modal
        _showNotificationDetails(notification);
      }
    } catch (e) {
      print("❌ Error handling leave status notification: $e");
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
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: primary),
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
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleLeaveStatusTap(notification);
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
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildErrorWidget(NotificationViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Failed to load notifications',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              viewModel.error ?? 'Unknown error occurred',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                viewModel.clearError();
                await _refreshNotifications();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 80,
                color: primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All Up to Date! 🎉',
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No new leave status updates.\nYour leave requests are being processed!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _refreshNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
