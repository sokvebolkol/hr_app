import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../constants/constant.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../leaves/leave_approval/approver_leave_detail_screen.dart';

class CeoNotificationScreen extends StatefulWidget {
  const CeoNotificationScreen({super.key});

  @override
  State<CeoNotificationScreen> createState() => _CeoNotificationScreenState();
}

class _CeoNotificationScreenState extends State<CeoNotificationScreen>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;

  // Cache filtered notifications - only Leave Request notifications for CEO
  List<NotificationModel> _leaveRequestNotifications = [];

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
    // Filter notifications for Leave Requests only (new requests for CEO to approve)
    _leaveRequestNotifications =
        allNotifications
            .where(
              (n) =>
                  n.type == 'leave' && n.data['action'] == 'new_request' ||
                  n.type == 'leave' && n.data['action'] == 'reminder',
            ) // Only new leave requests
            .toList();

    if (mounted) {
      setState(() {});
    }

    // Debug logging
    print('🔄 Updated CEO notifications:');
    print('  Leave Requests: ${_leaveRequestNotifications.length}');
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
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
        title: Row(children: [const Text('Notifications')]),
        backgroundColor: secondary, // CEO uses secondary color
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
                                  SpinKitCircle(color: secondary, size: 50.0),
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
                                Text('✅ All notifications marked as read'),
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
                            child: SpinKitCircle(
                              color: Colors.white,
                              size: 16.0,
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
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          // Show loading only if we haven't initialized and there are no cached notifications
          if (!_isInitialized &&
              _leaveRequestNotifications.isEmpty &&
              viewModel.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitCircle(color: secondary, size: 50.0),
                  SizedBox(height: 16),
                  Text('Loading leave requests...'),
                ],
              ),
            );
          }

          // Show error only if we haven't initialized and there's an error
          if (!_isInitialized &&
              viewModel.error != null &&
              _leaveRequestNotifications.isEmpty) {
            return _buildErrorWidget(viewModel);
          }

          // Show empty state if no notifications
          if (_leaveRequestNotifications.isEmpty) {
            return _buildEmptyWidget();
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            color: secondary,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount:
                  _leaveRequestNotifications.length +
                  (viewModel.hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _leaveRequestNotifications.length) {
                  // Loading indicator for pagination
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child:
                          viewModel.isLoadingMore
                              ? const SpinKitCircle(
                                color: secondary,
                                size: 50.0,
                              )
                              : const SizedBox.shrink(),
                    ),
                  );
                }

                final notification = _leaveRequestNotifications[index];
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: secondary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: secondary.withOpacity(0.1),
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
            color: secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.assignment_ind_rounded, color: secondary, size: 28),
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
                    child: SpinKitCircle(color: secondary, size: 50.0),
                  ),
                  SizedBox(width: 12),
                  Text('Opening leave request...'),
                ],
              ),
              duration: Duration(seconds: 1),
            ),
          );

          final success = await viewModel.markAsRead(notification.id);

          if (success) {
            _updateFilteredNotifications(viewModel.notifications);

            if (!mounted) return;

            // Handle leave request notification
            _handleLeaveRequestTap(notification);
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
            _handleLeaveRequestTap(notification);
          }
        },
      ),
    );
  }

  // Handle leave request notification tap
  void _handleLeaveRequestTap(NotificationModel notification) {
    try {
      if (notification.staffLeaveRequest == null) {
        _showErrorDialog('No information available');
        return;
      }

      print("🔔 CEO - Opening request for approval");

      // Convert to PendingLeaveRequest for ApproverLeaveDetailScreen
      final leaveRequest = notification.toPendingLeaveRequest();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ApproverLeaveDetailScreen(leave: leaveRequest),
        ),
      ).then((result) {
        if (result == true) {
          _refreshNotifications();
        }
      });
    } catch (e) {
      print("❌ Error handling leave request: $e");
      _showErrorDialog('Error opening leave request: ${e.toString()}');
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
                style: TextButton.styleFrom(foregroundColor: secondary),
                child: const Text('OK'),
              ),
            ],
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
                backgroundColor: secondary,
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
                color: secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_turned_in_rounded,
                size: 80,
                color: secondary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up! 🎉',
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No new leave requests to review.\nYour team is all set!',
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
                foregroundColor: secondary,
                side: BorderSide(color: secondary),
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
