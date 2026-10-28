import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import 'announcement_list_screen.dart';
import 'join_requests_screen.dart';

/// Opens the right screen for announcement related in-app notifications
/// (new announcement, request to join, result of a request). The
/// notification screens call [open] first and fall back to their own leave /
/// attendance handling when it returns false.
class AnnouncementNotificationRouter {
  AnnouncementNotificationRouter._();

  static bool handles(NotificationModel n) {
    final click = n.data['click_action']?.toString();
    return const {
          'announcement',
          'join_request',
          'join_request_result',
        }.contains(n.type) ||
        click == 'announcement_screen' ||
        click == 'join_request_screen';
  }

  /// Returns true when the notification was handled here.
  static bool open(BuildContext context, NotificationModel n) {
    if (!handles(n)) return false;

    final ownerRequest =
        n.type == 'join_request' ||
        n.data['click_action']?.toString() == 'join_request_screen';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                ownerRequest
                    ? const JoinRequestsScreen()
                    : const AnnouncementListScreen(),
      ),
    );
    return true;
  }
}
