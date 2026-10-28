import 'package:flutter/material.dart';

/// Tab label with an unread count pill, for the Notification screen tabs.
///
/// Matches the look of [AnnouncementBadgeTabLabel] so every tab in the
/// Notification screens shows its count the same way. The pill is hidden
/// when [count] is 0 and shows "99+" above 99.
class NotificationTabLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color badgeColor;
  final Color badgeTextColor;

  const NotificationTabLabel({
    super.key,
    required this.label,
    required this.count,
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder:
                (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
            child:
                count > 0
                    ? Padding(
                      key: ValueKey(count),
                      padding: const EdgeInsets.only(left: 5),
                      child: Container(
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
                          count > 99 ? '99+' : '$count',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(key: ValueKey(0)),
          ),
        ],
      ),
    );
  }
}
