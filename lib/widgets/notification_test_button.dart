import 'package:flutter/material.dart';
import '../services/firebase_notification_service.dart';

/// Test notification button widget
/// Add this to any screen to test notifications
class NotificationTestButton extends StatelessWidget {
  const NotificationTestButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final notificationService = FirebaseNotificationService();

        // Show debug info
        await notificationService.debugNotificationStatus();

        // Show test notification
        await notificationService.showTestNotification();

        // Show confirmation
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Test notification sent! Check notification center.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      icon: const Icon(Icons.notifications_active),
      label: const Text('Test Notification'),
    );
  }
}
