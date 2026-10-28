import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../models/announcement_model.dart';
import '../../repositories/announcement_repository.dart';
import '../../widgets/simple_html_text.dart';
import 'join_team_sheet.dart';

/// Microsoft Teams brand purple, used only for the external "Open in Teams"
/// action so it reads as leaving the app.
const Color teamsPurple = Color(0xFF6264A7);

/// Full announcement body, attachments and the Teams deep link.
///
/// The list marks the message read when it opens this screen, so no read
/// call is made here.
class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementMessage message;

  const AnnouncementDetailScreen({super.key, required this.message});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  Language language = Language();

  @override
  void initState() {
    super.initState();
    _initLanguage();
  }

  Future<void> _initLanguage() async {
    final logic = LanguageLogic();
    await logic.initialize();
    if (mounted) setState(() => language = logic.language);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Opens the message in the Microsoft Teams app, falling back to the
  /// browser. Always external: an in-app WebView would hit a login wall and
  /// would not hand off to the installed Teams app.
  ///
  /// Not a member of the team: shows "Request to join" instead, since Teams
  /// would only answer "no access".
  Future<void> _openInTeams() async {
    // Live membership check; only a confirmed non-member gets the sheet.
    // "Unknown" still opens Teams here because the user asked for it.
    final access = await AnnouncementRepository().resolveTeamsAccess(
      widget.message,
    );
    if (!mounted) return;
    if (access == TeamsAccess.notMember) {
      HapticFeedback.selectionClick();
      final choice = await JoinTeamSheet.show(
        context,
        message: widget.message,
        language: language,
      );
      if (!mounted || choice != JoinTeamSheetResult.openInTeams) return;
    }

    final url = widget.message.webUrl;
    if (url == null || url.trim().isEmpty) {
      _toast(language.linkNotAvailable);
      return;
    }

    HapticFeedback.selectionClick();
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      _toast(language.linkNotAvailable);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) _toast(language.couldNotOpenTeams);
    } catch (_) {
      if (mounted) _toast(language.couldNotOpenTeams);
    }
  }

  Future<void> _openAttachment(MessageAttachment attachment) async {
    final url = attachment.contentUrl;
    if (url == null || url.trim().isEmpty) {
      _toast(language.linkNotAvailable);
      return;
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      _toast(language.linkNotAvailable);
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) _toast(language.linkNotAvailable);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final body =
        message.content.raw.trim().isNotEmpty
            ? message.content.raw
            : message.content.text;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(language.announcement),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.channelDisplayName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
                if (message.subject != null &&
                    message.subject!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    message.subject!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: primary.withOpacity(0.12),
                      child: Text(
                        message.senderInitial,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.senderName.isEmpty
                                ? language.unknownSender
                                : message.senderName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            message.isEdited
                                ? '${_formatDate(message.createdAt)}  ·  ${language.edited}'
                                : _formatDate(message.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 26),

                // Body. Rendered through a restricted HTML subset; scripts,
                // iframes and styles are discarded rather than executed.
                if (body.trim().isEmpty)
                  Text(
                    language.noContent,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[500],
                    ),
                  )
                else
                  SimpleHtmlText(
                    html: body,
                    accentColor: primary,
                    // Teams images need a Microsoft Graph token, so the
                    // only place to view them is Teams itself.
                    imagePlaceholder: language.imageViewInTeams,
                    onImageTap: _openInTeams,
                  ),

                if (message.hasReactions) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        message.reactions
                            .map(
                              (r) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Text(
                                  r.label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
          ),

          if (message.hasAttachments) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        size: 17,
                        color: primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${language.attachments} (${message.attachments.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...message.attachments.map(
                    (a) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.insert_drive_file_outlined,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      title: Text(
                        a.name,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing:
                          a.contentUrl == null
                              ? null
                              : const Icon(Icons.open_in_new_rounded, size: 16),
                      onTap:
                          a.contentUrl == null
                              ? null
                              : () => _openAttachment(a),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInTeams,
              icon: Icon(
                message.canOpenInTeams
                    ? Icons.open_in_new_rounded
                    : Icons.group_add_rounded,
                size: 18,
              ),
              label: Text(
                message.canOpenInTeams
                    ? language.openInTeams
                    : language.requestToJoin,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    message.canOpenInTeams ? teamsPurple : primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
