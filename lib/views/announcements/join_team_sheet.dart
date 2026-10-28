import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../models/announcement_model.dart';
import '../../models/team_join_request_model.dart';
import '../../repositories/announcement_repository.dart';
import '../../utils/exceptions.dart';

/// What the user picked in [JoinTeamSheet].
enum JoinTeamSheetResult {
  /// The user is a member after all (e.g. just added): open the Teams link.
  openInTeams,

  /// Read the post in the in-app detail screen.
  viewInApp,
}

/// Shown instead of opening Microsoft Teams when the user is not a member of
/// the post's team. Lets them ask the team owners to add them, see the state
/// of an earlier request, or cancel it.
///
/// All rules (duplicates, cooldown after a decline, who approves) live in the
/// API; this sheet only shows its state and its messages.
class JoinTeamSheet extends StatefulWidget {
  final AnnouncementMessage message;
  final Language language;

  const JoinTeamSheet({
    super.key,
    required this.message,
    required this.language,
  });

  static Future<JoinTeamSheetResult?> show(
    BuildContext context, {
    required AnnouncementMessage message,
    required Language language,
  }) {
    return showModalBottomSheet<JoinTeamSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => JoinTeamSheet(message: message, language: language),
    );
  }

  @override
  State<JoinTeamSheet> createState() => _JoinTeamSheetState();
}

class _JoinTeamSheetState extends State<JoinTeamSheet> {
  final AnnouncementRepository _repository = AnnouncementRepository();
  final TextEditingController _note = TextEditingController();

  TeamMembership? _membership;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  /// Feedback from the last action (API message), shown in the sheet.
  String? _info;

  Language get language => widget.language;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _describe(Object e) => e is AppException ? e.message : '$e';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final membership = await _repository.getMembership(
        channelId: widget.message.channelId,
      );
      if (!mounted) return;
      setState(() => _membership = membership);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _describe(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _info = null;
    });
    try {
      final request = await _repository.requestJoin(
        channelId: widget.message.channelId,
        messageId: widget.message.id,
        note: _note.text,
      );
      if (!mounted) return;
      final m = _membership;
      setState(() {
        _membership = TeamMembership(
          teamId: m?.teamId ?? request.teamId,
          teamName: m?.teamName ?? request.teamName,
          isMember: m?.isMember,
          isOwner: m?.isOwner ?? false,
          canRequestJoin: false,
          joinRequest: request,
        );
      });
    } catch (e) {
      if (!mounted) return;
      // 409 (already a member) means Teams will open now; reload to show it.
      setState(() => _info = _describe(e));
      if (e is ClientException && e.statusCode == 409) await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(TeamJoinRequest request) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _info = null;
    });
    try {
      await _repository.cancelJoinRequest(request);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (mounted) setState(() => _info = _describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime? d) =>
      d == null ? '' : DateFormat('MMM dd, yyyy HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
      child: SingleChildScrollView(
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
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: SpinKitFadingCircle(color: primary),
              )
            else if (_error != null)
              _buildError()
            else
              ..._buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(language.retry),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        _viewInAppButton(),
      ],
    );
  }

  List<Widget> _buildContent() {
    final m = _membership!;
    final request = m.joinRequest;
    final teamName = m.teamName ?? request?.teamName ?? '';

    // Membership changed since the feed loaded (e.g. the owner added the
    // user): let the caller open Teams.
    if (m.isMember != false) {
      return [
        _header(Icons.check_circle_rounded, Colors.green, teamName, null),
        const SizedBox(height: 18),
        _primaryButton(
          icon: Icons.open_in_new_rounded,
          label: language.openInTeams,
          color: const Color(0xFF6264A7),
          onPressed:
              () => Navigator.pop(context, JoinTeamSheetResult.openInTeams),
        ),
      ];
    }

    final widgets = <Widget>[
      _header(
        Icons.group_add_rounded,
        primary,
        language.notTeamMemberTitle,
        teamName.isEmpty ? null : teamName,
      ),
      const SizedBox(height: 10),
      Text(
        language.notTeamMemberBody,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey[700]),
      ),
      const SizedBox(height: 18),
    ];

    if (request != null && request.isOpen) {
      // Waiting for an owner, or approved and about to be added.
      widgets.add(
        _statusCard(
          icon:
              request.isPending
                  ? Icons.hourglass_top_rounded
                  : Icons.check_circle_outline_rounded,
          color: request.isPending ? Colors.orange : Colors.green,
          text:
              request.isPending
                  ? language.joinRequestPending
                  : language.joinRequestApproved,
          detail: '${language.requestedOn}: ${_date(request.createdAt)}',
        ),
      );
      if (request.isPending) {
        widgets.addAll([
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _cancel(request),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(language.cancelRequest),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ]);
      }
    } else {
      // An earlier request that ended without joining.
      final last = request?.status;
      final lastText = switch (last) {
        TeamJoinRequest.rejected => language.joinRequestRejected,
        TeamJoinRequest.expired => language.joinRequestExpired,
        TeamJoinRequest.failed => language.joinRequestFailed,
        _ => null,
      };
      if (lastText != null) {
        widgets.addAll([
          _statusCard(
            icon: Icons.info_outline_rounded,
            color: Colors.grey.shade700,
            text: lastText,
            detail: request?.decisionNote,
          ),
          const SizedBox(height: 14),
        ]);
      }

      widgets.addAll([
        TextField(
          controller: _note,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: language.joinRequestNoteHint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _primaryButton(
          icon: Icons.send_rounded,
          label: language.sendJoinRequest,
          color: primary,
          onPressed: _busy ? null : _send,
        ),
      ]);
    }

    if (_info != null) {
      widgets.addAll([
        const SizedBox(height: 12),
        Text(
          _info!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.red),
        ),
      ]);
    }

    widgets.addAll([const SizedBox(height: 8), _viewInAppButton()]);
    return widgets;
  }

  Widget _header(IconData icon, Color color, String title, String? subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _statusCard({
    required IconData icon,
    required Color color,
    required String text,
    String? detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (detail != null && detail.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon:
          _busy
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withOpacity(0.5),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    );
  }

  Widget _viewInAppButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context, JoinTeamSheetResult.viewInApp),
      child: Text(
        language.viewPostInApp,
        style: const TextStyle(fontWeight: FontWeight.w600, color: primary),
      ),
    );
  }
}
