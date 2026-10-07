import 'package:flutter/material.dart';

import '../services/announcement_unread_service.dart';

/// Tab label for the Announcement tab inside the Notification screens, with
/// the unread badge from `GET /messages/unread-count`.
///
/// Listens to [AnnouncementUnreadService] so the count updates itself
/// without the host screen rebuilding manually.
class AnnouncementBadgeTabLabel extends StatelessWidget {
  final String label;
  final Color badgeColor;
  final Color badgeTextColor;

  const AnnouncementBadgeTabLabel({
    super.key,
    required this.label,
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AnnouncementUnreadService.instance,
      builder: (context, _) {
        final service = AnnouncementUnreadService.instance;

        return Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              if (service.hasUnread) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    service.badgeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
