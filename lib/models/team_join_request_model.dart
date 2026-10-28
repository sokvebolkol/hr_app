/// "Request to join" for announcement teams (Microsoft Teams).
///
/// A user who is not a member of the team can read its announcements in the
/// app, but Teams itself will not open the post for them. They can ask the
/// team owners to add them; owners approve or decline in the app.

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

String? _str(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class TeamJoinRequest {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';
  static const joined = 'joined';
  static const failed = 'failed';
  static const expired = 'expired';

  final int id;
  final String teamId;
  final String? teamName;
  final String? channelId;
  final String? channelName;

  /// pending, approved, rejected, cancelled, joined, failed or expired.
  final String status;
  final String? note;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionNote;
  final DateTime? joinedAt;
  final DateTime? createdAt;

  /// Owner view only.
  final String? requesterName;
  final String? requesterEmail;
  final String? error;

  const TeamJoinRequest({
    required this.id,
    required this.teamId,
    required this.status,
    this.teamName,
    this.channelId,
    this.channelName,
    this.note,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
    this.joinedAt,
    this.createdAt,
    this.requesterName,
    this.requesterEmail,
    this.error,
  });

  factory TeamJoinRequest.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'];
    return TeamJoinRequest(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      teamId: json['team_id']?.toString() ?? '',
      teamName: _str(json['team_name']),
      channelId: _str(json['channel_id']),
      channelName: _str(json['channel_name']),
      status: json['status']?.toString() ?? pending,
      note: _str(json['note']),
      decidedBy: _str(json['decided_by']),
      decidedAt: _date(json['decided_at']),
      decisionNote: _str(json['decision_note']),
      joinedAt: _date(json['joined_at']),
      createdAt: _date(json['created_at']),
      requesterName: requester is Map ? _str(requester['name']) : null,
      requesterEmail: requester is Map ? _str(requester['email']) : null,
      error: _str(json['error']),
    );
  }

  static TeamJoinRequest? tryParse(dynamic json) =>
      json is Map<String, dynamic> ? TeamJoinRequest.fromJson(json) : null;

  /// Waiting for an owner, or approved and about to be added.
  bool get isOpen => status == pending || status == approved;
  bool get isPending => status == pending;
}

/// GET /teams/{teamId}/membership
class TeamMembership {
  final String teamId;
  final String? teamName;

  /// Null when the member list has not been synced yet (treat as member).
  final bool? isMember;
  final bool isOwner;
  final bool canRequestJoin;

  /// The user's latest request for this team, any status.
  final TeamJoinRequest? joinRequest;

  const TeamMembership({
    required this.teamId,
    this.teamName,
    this.isMember,
    this.isOwner = false,
    this.canRequestJoin = false,
    this.joinRequest,
  });

  factory TeamMembership.fromJson(Map<String, dynamic> json) => TeamMembership(
    teamId: json['team_id']?.toString() ?? '',
    teamName: _str(json['team_name']),
    isMember: json['is_member'] is bool ? json['is_member'] as bool : null,
    isOwner: json['is_owner'] == true,
    canRequestJoin: json['can_request_join'] == true,
    joinRequest: TeamJoinRequest.tryParse(json['join_request']),
  );
}
