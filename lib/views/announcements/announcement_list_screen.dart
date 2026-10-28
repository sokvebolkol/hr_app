import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../models/announcement_model.dart';
import '../../viewmodels/announcement_viewmodel.dart';
import 'announcement_detail_screen.dart';
import 'channel_picker_sheet.dart';
import 'join_requests_screen.dart';
import 'join_team_sheet.dart';

/// Announcement feed: every channel's messages for Chokchey Finance.
///
/// [embedded] renders without a Scaffold/AppBar so it can sit inside the
/// Notification screen's tab.
class AnnouncementListScreen extends StatelessWidget {
  final bool embedded;

  const AnnouncementListScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnnouncementViewModel()..initialize(),
      child: _AnnouncementListBody(embedded: embedded),
    );
  }
}

class _AnnouncementListBody extends StatefulWidget {
  final bool embedded;

  const _AnnouncementListBody({required this.embedded});

  @override
  State<_AnnouncementListBody> createState() => _AnnouncementListBodyState();
}

class _AnnouncementListBodyState extends State<_AnnouncementListBody> {
  final ScrollController _scrollController = ScrollController();
  Language language = Language();

  @override
  void initState() {
    super.initState();
    _initLanguage();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initLanguage() async {
    final logic = LanguageLogic();
    await logic.initialize();
    if (mounted) setState(() => language = logic.language);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<AnnouncementViewModel>().loadMore();
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// One tap opens the message straight in Microsoft Teams.
  ///
  /// The message is marked read first (endpoint 3), fire-and-forget, so the
  /// list updates in place while Teams opens. If the message has no link, or
  /// the launcher cannot open it, the in-app detail screen is used instead
  /// so the tap is never a dead end.
  ///
  /// When the user is not a member of the post's team, Teams would only show
  /// "no access", so the "Request to join" sheet is shown instead.
  Future<void> _openMessage(
    AnnouncementViewModel vm,
    AnnouncementMessage message,
  ) async {
    vm.markRead(message);

    if (!message.canOpenInTeams) {
      HapticFeedback.selectionClick();
      final choice = await JoinTeamSheet.show(
        context,
        message: message,
        language: language,
      );
      if (!mounted || choice == null) return;
      if (choice == JoinTeamSheetResult.viewInApp) {
        await _openDetail(message);
        return;
      }
      // The user became a member since the feed loaded: refresh the flags
      // and open Teams below.
      vm.refresh();
    }

    final url = message.webUrl?.trim();
    final uri = (url == null || url.isEmpty) ? null : Uri.tryParse(url);

    if (uri != null) {
      HapticFeedback.selectionClick();
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {
        // Fall through to the in-app view.
      }
      if (!mounted) return;
      _toast(language.couldNotOpenTeams, isError: true);
    }

    if (!mounted) return;
    await _openDetail(message);
  }

  Future<void> _openDetail(AnnouncementMessage message) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailScreen(message: message),
      ),
    );
  }

  /// Team owners: the requests waiting for them.
  Future<void> _openJoinRequests(AnnouncementViewModel vm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinRequestsScreen()),
    );
    if (mounted) vm.loadJoinRequestCount();
  }

  /// Long-press actions sheet: a preview of the message plus actions.
  Future<void> _onLongPress(
    AnnouncementViewModel vm,
    AnnouncementMessage message,
  ) async {
    HapticFeedback.mediumImpact();
    final preview =
        (message.subject != null && message.subject!.trim().isNotEmpty)
            ? message.subject!.trim()
            : (message.content.preview.isNotEmpty
                ? message.content.preview
                : (message.hasInlineImages ? language.imageMessage : ''));

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder:
          (ctx) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              16 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message preview card.
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary.withOpacity(0.12),
                        primary.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: primary.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                message.channelDisplayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  message.isRead
                                      ? Colors.grey.shade200
                                      : Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        message.isRead
                                            ? Colors.grey
                                            : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  message.isRead
                                      ? language.read
                                      : language.unread,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        message.isRead
                                            ? Colors.grey[700]
                                            : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${message.senderName}  ·  ${_postedAt(message.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                _sheetAction(
                  icon:
                      message.isRead
                          ? Icons.mark_email_unread_rounded
                          : Icons.mark_email_read_rounded,
                  color: primary,
                  title:
                      message.isRead ? language.markAsUnread : language.markAsRead,
                  subtitle:
                      message.isRead
                          ? language.markAsUnreadHint
                          : language.markAsReadHint,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (message.isRead) {
                      vm.markUnread(message);
                    } else {
                      vm.markRead(message);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _sheetAction(
                  icon:
                      message.canOpenInTeams
                          ? Icons.open_in_new_rounded
                          : Icons.group_add_rounded,
                  color: message.canOpenInTeams ? teamsPurple : primary,
                  title:
                      message.canOpenInTeams
                          ? language.openInTeams
                          : language.requestToJoin,
                  subtitle:
                      message.canOpenInTeams
                          ? language.openInTeamsHint
                          : language.requestToJoinHint,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openMessage(vm, message);
                  },
                ),
              ],
            ),
          ),
    );
  }

  /// A large tappable action row for the long-press sheet. Uses its own
  /// Material so the ripple renders (a bare ListTile inside a coloured
  /// container triggers Flutter's "ink splashes may be invisible" assert).
  Widget _sheetAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer<AnnouncementViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            _buildChannelDropdown(vm),
            if (vm.pendingJoinRequests > 0) _buildJoinRequestsBanner(vm),
            Expanded(child: _buildList(vm)),
          ],
        );
      },
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(language.announcement),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: body,
    );
  }

  /// Shown to team owners while requests to join their teams are waiting.
  Widget _buildJoinRequestsBanner(AnnouncementViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openJoinRequests(vm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.group_add_rounded,
                  size: 20,
                  color: Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    language.joinRequestsWaiting(vm.pendingJoinRequests),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sentinel item for "All Channels". An empty id maps to no channel
  /// filter, which the API treats as every channel.
  AnnouncementChannel get _allChannelsItem =>
      AnnouncementChannel(id: '', name: language.allChannels);

  Future<void> _openChannelPicker(AnnouncementViewModel vm) async {
    final picked = await ChannelPickerSheet.show(
      context,
      channels: [_allChannelsItem, ...vm.channels],
      selectedId: vm.channelId ?? '',
      language: language,
    );
    if (picked == null || !mounted) return; // dismissed
    vm.setChannel(picked.id.isEmpty ? null : picked.id);
  }

  /// Filter box that looks like a dropdown and opens [ChannelPickerSheet].
  Widget _buildChannelDropdown(AnnouncementViewModel vm) {
    final selectedName =
        vm.channelId == null
            ? language.allChannels
            : vm.channels
                .firstWhere(
                  (c) => c.id == vm.channelId,
                  orElse: () => _allChannelsItem,
                )
                .displayName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openChannelPicker(vm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 20, color: primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(AnnouncementViewModel vm) {
    // Same loader as the Notification tab next to it: fading circle plus a
    // caption.
    if (vm.isLoading && vm.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitFadingCircle(color: primary),
            const SizedBox(height: 16),
            Text(language.loadingAnnouncements),
          ],
        ),
      );
    }

    if (vm.errorMessage != null && vm.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                vm.noAccess ? Icons.lock_outline_rounded : Icons.error_outline,
                size: 60,
                color: vm.noAccess ? Colors.orange : Colors.red,
              ),
              const SizedBox(height: 14),
              Text(
                vm.noAccess ? language.noAccess : language.somethingWentWrong,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              // The API's own message, as the spec requires.
              Text(
                vm.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              if (!vm.noAccess) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: vm.load,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(language.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (vm.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.refresh,
        color: primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 60,
                    color: Colors.grey[350],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    language.noAnnouncements,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      color: primary,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: vm.messages.length + (vm.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= vm.messages.length) {
            // Pagination loader, matching the Notification tab.
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: SpinKitFadingCircle(color: primary)),
            );
          }
          return _buildTile(vm, vm.messages[index]);
        },
      ),
    );
  }

  /// Posted date and time, in the app's standard formats: "MMM dd, yyyy"
  /// for the date and 24-hour "HH:mm" for the time, e.g.
  /// "Oct 06, 2026 10:30". [createdAt] is already converted to local time
  /// by the model.
  String _postedAt(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  Widget _buildTile(AnnouncementViewModel vm, AnnouncementMessage message) {
    final unread = !message.isRead;
    // Image-only posts have empty text; say so instead of showing nothing.
    final preview =
        message.content.preview.isNotEmpty
            ? message.content.preview
            : (message.hasInlineImages ? language.imageMessage : '');

    // Same read/unread treatment as the Notification cards: unread is
    // tinted with a coloured border and a red dot, read turns plain white.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: unread ? primary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread ? primary.withOpacity(0.45) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(unread ? 0.12 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openMessage(vm, message),
          onLongPress: () => _onLongPress(vm, message),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title block on the left; importance and the unread dot
                // on the right.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.subject != null &&
                              message.subject!.trim().isNotEmpty) ...[
                            Text(
                              message.subject!,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight:
                                    unread ? FontWeight.bold : FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (preview.isNotEmpty)
                            Text(
                              preview,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight:
                                    unread ? FontWeight.w600 : FontWeight.normal,
                                color:
                                    unread ? Colors.black87 : Colors.grey[700],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (message.isImportant || unread) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.isImportant)
                              Container(
                                margin: EdgeInsets.only(right: unread ? 8 : 0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  language.important,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            // Unread dot, right-aligned, red like the
                            // Notification cards.
                            if (unread)
                              Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Footer: sender, attachments and posted date/time, with
                // reactions at the far right.
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: primary.withOpacity(0.12),
                      child: Text(
                        message.senderInitial,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (message.hasAttachments) ...[
                      Icon(
                        Icons.attach_file_rounded,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      Text(
                        '${message.attachments.length}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.access_time,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _postedAt(message.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    // Reactions sit at the far right of the footer.
                    if (message.hasReactions) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message.reactionsLabel,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
