class LeaveHistoryModel {
  final String lreid;
  final String frdat;
  final String todat;
  final String leaid;
  final String ltyp;
  final String numleav;
  final String lfor;
  final String statu;
  final String reason;
  final String createdate;

  LeaveHistoryModel({
    required this.lreid,
    required this.frdat,
    required this.todat,
    required this.leaid,
    required this.ltyp,
    required this.numleav,
    required this.lfor,
    required this.statu,
    required this.reason,
    required this.createdate,
  });

  factory LeaveHistoryModel.fromJson(Map<String, dynamic> json) {
    return LeaveHistoryModel(
      lreid: json['lreid']?.toString() ?? '',
      frdat: json['frdat']?.toString() ?? '',
      todat: json['todat']?.toString() ?? '',
      leaid: json['leaid']?.toString() ?? '',
      ltyp: json['ltyp']?.toString() ?? '',
      numleav: json['numleav']?.toString() ?? '',
      lfor: json['lfor']?.toString() ?? '',
      statu: json['statu']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      createdate: json['createdate']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lreid': lreid,
      'frdat': frdat,
      'todat': todat,
      'leaid': leaid,
      'ltyp': ltyp,
      'numleav': numleav,
      'lfor': lfor,
      'statu': statu,
      'reason': reason,
      'createdate': createdate,
    };
  }

  // Helper getters for display
  String get statusText {
    switch (statu) {
      case '0':
        return 'Pending';
      case '1':
        return 'Approved';
      case '2':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  String get statusColor {
    switch (statu) {
      case '0':
        return '#FFA500'; // Orange for pending
      case '1':
        return '#4CAF50'; // Green for approved
      case '2':
        return '#F44336'; // Red for rejected
      default:
        return '#9E9E9E'; // Gray for unknown
    }
  }
}

class LeaveHistoryResponse {
  final bool success;
  final List<LeaveHistoryModel> data;

  LeaveHistoryResponse({required this.success, required this.data});

  factory LeaveHistoryResponse.fromJson(Map<String, dynamic> json) {
    return LeaveHistoryResponse(
      success: json['success'] ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => LeaveHistoryModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}
