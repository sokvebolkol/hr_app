import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../models/team_join_request_model.dart';
import '../../repositories/announcement_repository.dart';
import '../../utils/exceptions.dart';

/// Team owners: requests to join their teams, with Approve / Decline.
///
/// After approval the backend worker adds the person in Microsoft Teams
/// within a few minutes and tells them. Opened from the banner on the
/// announcement list and from "join request" notifications.
class JoinRequestsScreen extends StatefulWidget {
  const JoinRequestsScreen({super.key});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  final AnnouncementRepository _repository = AnnouncementRepository();
  Language language = Language();

  List<TeamJoinRequest> _requests = [];
  bool _loading = true;
  String? _error;

  /// Request IDs with an approve / decline call in flight.
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _initLanguage();
    _load();
  }

  Future<void> _initLanguage() async {
    final logic = LanguageLogic();
    await logic.initialize();
    if (mounted) setState(() => language = logic.language);
  }

  String _describe(Object e) => e is AppException ? e.message : '$e';

  Future<void> _load() async {
    setState(() {
      _loading = _requests.isEmpty;
      _error = null;
    });
    try {
      final rows = await _repository.getIncomingJoinRequests();
      if (!mounted) return;
      setState(() => _requests = rows);
    } catch (e) {
      if (mounted) setState(() => _error = _describe(e));
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _decide(TeamJoinRequest request, bool approve) async {
    if (_busy.contains(request.id)) return;

    String? note;
    if (!approve) {
      note = await _askReason();
      if (note == null) return; // dialog dismissed
    }

    setState(() => _busy.add(request.id));
    try {
      final message = await _repository.decideJoinRequest(
        id: request.id,
        approve: approve,
        note: note,
      );
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      if (message.isNotEmpty) _toast(message);
    } catch (e) {
      // 409: another owner already answered; reload to show the real state.
      _toast(_describe(e), isError: true);
      await _load();
    } finally {
      if (mounted) setState(() => _busy.remove(request.id));
    }
  }

  /// Optional decline reason. Null when cancelled, '' when left empty.
  Future<String?> _askReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(language.reject),
            content: TextField(
              controller: controller,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: language.declineReasonHint,
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(language.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(language.reject),
              ),
            ],
          ),
    ).whenComplete(controller.dispose);
  }

  String _date(DateTime? d) =>
      d == null ? '' : DateFormat('MMM dd, yyyy HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(language.joinRequests),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: SpinKitFadingCircle(color: primary));
    }

    if (_error != null && _requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
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
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: primary,
      child:
          _requests.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Icon(
                    Icons.group_add_outlined,
                    size: 60,
                    color: Colors.grey[350],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    language.noJoinRequests,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              )
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _requests.length,
                itemBuilder: (_, i) => _buildCard(_requests[i]),
              ),
    );
  }

  Widget _buildCard(TeamJoinRequest r) {
    final busy = _busy.contains(r.id);
    final name = r.requesterName ?? r.requesterEmail ?? '';
    final where = [
      if (r.teamName != null) r.teamName!,
      if (r.channelName != null) r.channelName!,
    ].join('  ·  ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withOpacity(0.12),
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
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
                      name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (r.requesterEmail != null && r.requesterName != null)
                      Text(
                        r.requesterEmail!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (where.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.groups_rounded, size: 15, color: primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    where,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (r.note != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                r.note!,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${language.requestedOn}: ${_date(r.createdAt)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => _decide(r, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(language.reject),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : () => _decide(r, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      busy
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(language.approve),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
