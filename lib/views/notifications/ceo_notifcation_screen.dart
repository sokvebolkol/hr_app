import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../constants/constant.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../leaves/leave_approval/approver_leave_detail_screen.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';

class CeoNotificationScreen extends StatefulWidget {
  const CeoNotificationScreen({super.key});

  @override
  State<CeoNotificationScreen> createState() => _CeoNotificationScreenState();
}

class _CeoNotificationScreenState extends State<CeoNotificationScreen>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  late LanguageLogic languageLogic;
  late Language language;

  // Cache filtered notifications - only Leave Request notifications for CEO
  List<NotificationModel> _leaveRequestNotifications = [];

  bool _isInitialized = false;
  bool _isNavigating = false; // Prevent duplicate taps

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    languageLogic = LanguageLogic();
    _initializeLanguage();

    // Load notifications only once when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeLanguage() async {
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
    _isNavigating = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Text(language.notifications)]),
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
                        (context) => Center(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SpinKitCircle(
                                    color: secondary,
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
                                Text(
                                  '✅ ${language.allNotificationsMarkedAsRead}',
                                ),
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
                                Text('❌ ${language.failedToMarkAllAsRead}'),
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
                    SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: SpinKitCircle(
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
                        Consumer<NotificationViewModel>(
                          builder: (context, viewModel, child) {
                            final unreadCount = viewModel.summary?.unread ?? 0;
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
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          // Show loading only if we haven't initialized and there are no cached notifications
          if (!_isInitialized &&
              _leaveRequestNotifications.isEmpty &&
              viewModel.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitCircle(color: secondary, size: 50.0),
                  const SizedBox(height: 16),
                  Text(language.loadingLeaveRequests),
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
        color: notification.isRead ? Colors.white : secondary.withOpacity(0.05),
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
              ],
            ),
          ],
        ),
        onTap: () async {
          // Prevent duplicate taps
          if (_isNavigating) return;
          _isNavigating = true;

          try {
            // Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: SpinKitCircle(color: secondary, size: 50.0),
                    ),
                    const SizedBox(width: 12),
                    Text(language.openingLeaveRequest),
                  ],
                ),
                duration: const Duration(seconds: 1),
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
                  SnackBar(
                    content: Text(language.failedToMarkNotificationAsRead),
                    backgroundColor: Colors.red,
                  ),
                );
              }

              // Still navigate even if marking as read failed
              if (!mounted) return;
              _handleLeaveRequestTap(notification);
            }
          } finally {
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

  // Handle leave request notification tap
  void _handleLeaveRequestTap(NotificationModel notification) {
    try {
      if (notification.staffLeaveRequest == null) {
        _showErrorDialog('No information available');
        return;
      }
      // Convert to PendingLeaveRequest for ApproverLeaveDetailScreen
      final leaveRequest = notification.toLeaveRequest();
      _isNavigating = false; // Reset flag before navigation

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ApproverLeaveDetailScreen(
                leave: leaveRequest,
                isPending: leaveRequest.statu == '2',
                onActionComplete: _refreshNotifications,
              ),
        ),
      );
    } catch (e) {
      _isNavigating = false;
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
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(language.error),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: secondary),
                child: Text(language.ok),
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
              language.failedToLoadNotifications,
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              viewModel.error ?? language.unknownErrorOccurred,
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
              label: Text(language.tryAgain),
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
              language.allCaughtUp,
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              language.noNewLeaveRequests,
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
              label: Text(language.refresh),
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
