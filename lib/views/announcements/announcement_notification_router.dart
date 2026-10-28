import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/constant.dart';
import '../../localization/language_logic.dart';
import '../../models/announcement_model.dart';
import '../../models/notification_model.dart';
import '../../repositories/announcement_repository.dart';
import '../../services/announcement_unread_service.dart';
import 'announcement_detail_screen.dart';
import 'announcement_list_screen.dart';
import 'join_requests_screen.dart';
import 'join_team_sheet.dart';

/// Opens the right screen for announcement related notifications (new
/// announcement, request to join, result of a request).
///
/// - In-app notification list: the notification screens call [open] first
///   and fall back to their own leave / attendance handling when it returns
///   false.
/// - Push taps: [openFromPush] is wired to
///   `FirebaseNotificationService.onNavigationRequired` in main.dart and
///   navigates through [navigatorKey].
///
/// An announcement opens that exact post: in Microsoft Teams when the user is
/// a member, otherwise via the "Request to join" sheet. When the post cannot
/// be identified or loaded, the announcement list is shown instead.
class AnnouncementNotificationRouter {
  AnnouncementNotificationRouter._();

  /// Set on the app's MaterialApp so push taps can navigate without a
  /// widget context.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const Set<String> _types = {
    'announcement',
    'join_request',
    'join_request_result',
  };

  static bool handles(NotificationModel n) =>
      _handles(n.type, n.data['click_action']?.toString());

  static bool _handles(String? type, String? clickAction) =>
      _types.contains(type) ||
      clickAction == 'announcement_screen' ||
      clickAction == 'join_request_screen';

  /// In-app notification list. Returns true when the notification was
  /// handled here.
  static bool open(BuildContext context, NotificationModel n) {
    if (!handles(n)) return false;
    _route(context, n.type, n.data['click_action']?.toString(), n.data);
    return true;
  }

  /// Push notification tap. Does nothing when the app has no navigator yet
  /// or the notification is not announcement related.
  static void openFromPush(String clickAction, Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final type = data['type']?.toString();
    if (!_handles(type, clickAction)) return;
    _route(context, type, clickAction, data);
  }

  static void _route(
    BuildContext context,
    String? type,
    String? clickAction,
    Map<String, dynamic> data,
  ) {
    if (type == 'join_request' || clickAction == 'join_request_screen') {
      _push(context, const JoinRequestsScreen());
      return;
    }
    _openPost(context, data);
  }

  // ───────────────────────────── Open the post ─────────────────────────────

  static Future<void> _openPost(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final teamId = _str(data['team_id']);
    final channelId = _str(data['channel_id']);
    final messageId = _str(data['message_id']);

    if (teamId == null || channelId == null || messageId == null) {
      _openList(context);
      return;
    }

    AnnouncementMessage message;
    _showLoading(context);
    try {
      message = await AnnouncementRepository().getMessage(
        teamId: teamId,
        channelId: channelId,
        messageId: messageId,
      );
    } catch (e) {
      debugPrint('Announcement load failed: $e');
      if (!context.mounted) return;
      _hideLoading(context);
      _openList(context);
      return;
    }
    if (!context.mounted) return;

    // getMessage marked the post read; update the badges.
    AnnouncementUnreadService.instance.refresh();

    // Check membership live (spinner still showing). A non-member sent to
    // Teams would see an empty channel instead of the post.
    final access = await AnnouncementRepository().resolveTeamsAccess(message);
    if (!context.mounted) return;
    _hideLoading(context);

    if (access == TeamsAccess.unknown) {
      _openDetail(context, message);
      return;
    }

    if (access == TeamsAccess.notMember) {
      final languageLogic = LanguageLogic();
      await languageLogic.initialize();
      if (!context.mounted) return;

      final choice = await JoinTeamSheet.show(
        context,
        message: message,
        language: languageLogic.language,
      );
      if (!context.mounted || choice == null) return;
      if (choice == JoinTeamSheetResult.viewInApp) {
        _openDetail(context, message);
        return;
      }
      // openInTeams: the user is a member now, continue to Teams below.
    }

    await _openInTeams(context, message);
  }

  /// Opens the post's Teams link, falling back to the in-app detail screen
  /// when there is no link or it cannot be opened.
  static Future<void> _openInTeams(
    BuildContext context,
    AnnouncementMessage message,
  ) async {
    final url = message.webUrl?.trim();
    final uri = (url == null || url.isEmpty) ? null : Uri.tryParse(url);
    if (uri != null) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (e) {
        debugPrint('Could not open Teams link: $e');
      }
    }
    if (!context.mounted) return;
    _openDetail(context, message);
  }

  // ─────────────────────────────── Helpers ────────────────────────────────

  static String? _str(dynamic value) {
    final s = value?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static void _openList(BuildContext context) =>
      _push(context, const AnnouncementListScreen());

  static void _openDetail(BuildContext context, AnnouncementMessage message) =>
      _push(context, AnnouncementDetailScreen(message: message));

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Small blocking spinner while the post loads.
  static void _showLoading(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder:
          (_) => const PopScope(
            canPop: false,
            child: Center(child: SpinKitFadingCircle(color: primary)),
          ),
    );
  }

  static void _hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
