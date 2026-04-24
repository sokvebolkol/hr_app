import '../models/adjustment_request_model.dart';
import '../models/ceo_dashboard_model.dart';
import '../repositories/manager_dashboard_repository.dart';
import 'leave_history_model.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final String category;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final String timeAgo;
  final bool isRecent;
  final Map<String, dynamic>? staffLeaveRequest;
  final Map<String, dynamic>? ownLeaveRequestData;
  final Map<String, dynamic>? staffAttendanceAdjustmentData;
  final Map<String, dynamic>? ownAttendanceAdjustmentData;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.category,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.timeAgo,
    required this.isRecent,
    this.staffLeaveRequest,
    this.ownLeaveRequestData,
    this.staffAttendanceAdjustmentData,
    this.ownAttendanceAdjustmentData,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      data: json['data'] ?? {},
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'],
      createdAt: json['created_at'] ?? '',
      timeAgo: json['time_ago'] ?? '',
      isRecent: json['is_recent'] ?? false,
      staffLeaveRequest: json['staff_leave_request'],
      ownLeaveRequestData: json['own_leave_request_data'],
      staffAttendanceAdjustmentData:
          json['staff_adjustment_request'] as Map<String, dynamic>?,
      ownAttendanceAdjustmentData:
          json['own_attendance_request_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'category': category,
      'data': data,
      'is_read': isRead,
      'read_at': readAt,
      'created_at': createdAt,
      'time_ago': timeAgo,
      'is_recent': isRecent,
      'staff_leave_request': staffLeaveRequest,
      'own_leave_request_data': ownLeaveRequestData,
      'staff_adjustment_request': staffAttendanceAdjustmentData,
      'own_attendance_request_data': ownAttendanceAdjustmentData,
    };
  }

  // Helper method to get the appropriate leave data based on notification type
  Map<String, dynamic>? get leaveData {
    // For new requests (staff requesting leave) - use staff_leave_request
    if (data['action'] == 'new_request' && staffLeaveRequest != null) {
      return staffLeaveRequest;
    }

    // For own leave updates (approved/rejected) - use own_leave_request_data
    if ((data['action'] == 'approved' || data['action'] == 'rejected') &&
        ownLeaveRequestData != null) {
      return ownLeaveRequestData;
    }

    // Fallback to either available data
    return staffLeaveRequest ?? ownLeaveRequestData;
  }

  // Helper to get attendance adjustment data based on notification action.
  // Falls back to the raw `data` map so tapping always has something to show.
  Map<String, dynamic>? get attendanceAdjustmentData {
    final action = data['action']?.toString();
    Map<String, dynamic>? dedicated;
    if (action == 'new_request' || action == 'reminder') {
      dedicated = staffAttendanceAdjustmentData ?? ownAttendanceAdjustmentData;
    } else if (action == 'approved' || action == 'rejected') {
      dedicated = ownAttendanceAdjustmentData ?? staffAttendanceAdjustmentData;
    } else {
      dedicated = staffAttendanceAdjustmentData ?? ownAttendanceAdjustmentData;
    }
    // Fall back to the notification data payload — always present
    return dedicated ?? (data.isNotEmpty ? data : null);
  }

  static int _parseInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    return v.toString().toLowerCase() == 'true';
  }

  // Convert to AdjustmentRequestModel (for MyAttendanceAdjustmentRequestScreen)
  AdjustmentRequestModel toAdjustmentRequestModel() {
    final adj = attendanceAdjustmentData;
    if (adj == null) {
      throw Exception('No attendance adjustment information available');
    }
    return AdjustmentRequestModel(
      id: _parseInt(adj['id']),
      staffId: adj['staff_id']?.toString() ?? '',
      adjustType: adj['adjust_type']?.toString() ?? '',
      adjustDateTime: adj['adjust_datetime']?.toString() ?? '',
      reason: adj['reason']?.toString() ?? '',
      status: _parseInt(adj['status']),
      isAttendanceCanCancel: adj['is_attendance_can_cancel'] ?? false,
      checkInTime: adj['check_in']?.toString() ?? '',
      checkOutTime: adj['check_out']?.toString() ?? '',
      createdBy: adj['created_by']?.toString() ?? '',
      createdAt: adj['created_at']?.toString() ?? createdAt,
      requesterName: adj['requester_name']?.toString() ?? '',
      approverList:
          (adj['approver_list'] as List<dynamic>?)
              ?.map(
                (e) => AdjustmentApprover.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      statusText: adj['status_text']?.toString() ?? '',
      documentUrl:
          adj['document_url']?.toString() ??
          adj['adjustment_support_doc_url']?.toString(),
      hasDocument:
          _parseBool(adj['has_document']) ??
          (adj['adjustment_support_doc'] != null ||
              adj['adjustment_support_doc_url'] != null),
    );
  }

  // Convert to AttendanceAdjustmentRequest (for AttendanceAdjustmentApprovalDetailScreen)
  AttendanceAdjustmentRequest toAttendanceAdjustmentRequest() {
    final adj = attendanceAdjustmentData;
    if (adj == null) {
      throw Exception('No attendance adjustment information available');
    }
    return AttendanceAdjustmentRequest(
      id: _parseInt(adj['id']),
      staffId: adj['staff_id']?.toString() ?? '',
      adjustType: adj['adjust_type']?.toString() ?? '',
      checkInTime: adj['check_in']?.toString() ?? '',
      checkOutTime: adj['check_out']?.toString() ?? '',
      adjustDatetime: adj['adjust_datetime']?.toString() ?? '',
      reason: adj['reason']?.toString() ?? '',
      status: _parseInt(adj['status']),
      adjustmentSupportDoc: adj['adjustment_support_doc']?.toString(),
      createdBy: adj['created_by']?.toString() ?? '',
      createdAt: adj['created_at']?.toString() ?? createdAt,
      requesterName: adj['requester_name']?.toString() ?? '',
      ecard: adj['ecard']?.toString() ?? '',
      email: adj['email']?.toString() ?? '',
      profileImage: adj['profile_image']?.toString(),
      positionName: adj['position_name']?.toString() ?? '',
      departmentName: adj['department_name']?.toString() ?? '',
      branchShortName: adj['branch_short_name']?.toString() ?? '',
      branchFullName: adj['branch_full_name']?.toString() ?? '',
      approverList:
          (adj['approver_list'] as List<dynamic>?)
              ?.map(
                (e) =>
                    AttendanceApproverItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      statusText: adj['status_text']?.toString() ?? '',
      adjustTypeText: adj['adjust_type_text']?.toString() ?? '',
      hasDocument:
          _parseBool(adj['has_document']) ??
          (adj['adjustment_support_doc'] != null ||
              adj['adjustment_support_doc_url'] != null),
      documentUrl:
          adj['document_url']?.toString() ??
          adj['adjustment_support_doc_url']?.toString(),
      profileImageUrl: adj['profile_image_url']?.toString(),
    );
  }

  // Convert to PendingLeaveRequest (for ApproverLeaveDetailScreen)
  PendingLeaveRequest toPendingLeaveRequest() {
    final leave = leaveData;

    if (leave == null) {
      throw Exception('No leave information available');
    }

    return PendingLeaveRequest(
      lreid: leave['lreid']?.toString() ?? '',
      orgid: leave['orgid']?.toString() ?? '',
      eid: leave['eid']?.toString() ?? '',
      leaid: leave['leaid']?.toString() ?? '',
      frdat: leave['frdat']?.toString() ?? '',
      todat: leave['todat']?.toString() ?? '',
      numleav: leave['numleav']?.toString() ?? '',
      lfor: leave['lfor']?.toString() ?? '',
      lnot: leave['lnot']?.toString() ?? '',
      reason: leave['reason']?.toString() ?? '',
      remark: leave['remark']?.toString() ?? '',
      file: leave['file']?.toString(),
      createdate: leave['createdate']?.toString() ?? '',
      statu: leave['statu']?.toString() ?? '0',
      holiday: leave['holiday']?.toString() ?? '0',
      ltyp: leave['ltyp']?.toString() ?? '',
      requesterName:
          leave['dname']?.toString() ??
          leave['requester_name']?.toString() ??
          '',
      staffId: leave['staff_id']?.toString() ?? '',
      email: leave['email']?.toString() ?? '',
      positionName: leave['position_name']?.toString() ?? '',
      departmentName: leave['department_name']?.toString() ?? '',
      branchShortName: leave['branch_short_name']?.toString() ?? '',
      branchFullName: leave['branch_full_name']?.toString() ?? '',
      leaveNote: leave['leave_note']?.toString() ?? '',
      statuText: leave['statu_text']?.toString() ?? '',
      prioList:
          (leave['prio_list'] as List<dynamic>?)
              ?.map(
                (prio) => ApprovalItem.fromJson({
                  'approver_name': prio['approver_name'],
                  'prio': prio['prio'],
                  'apstatu': prio['apstatu'],
                  'remark': prio['remark'],
                  'apstatu_text': prio['apstatu_text'],
                  'prio_text': prio['prio_text'],
                }),
              )
              .toList() ??
          [],
    );
  }

  // Convert to LeaveRequest (for ApproverLeaveDetailScreen)
  LeaveRequest toLeaveRequest() {
    final leave = leaveData;

    if (leave == null) {
      throw Exception('No leave information available');
    }

    return LeaveRequest(
      lreid: leave['lreid']?.toString() ?? '',
      orgid: leave['orgid']?.toString() ?? '',
      eid: leave['eid']?.toString() ?? '',
      staff_id: leave['staff_id']?.toString() ?? '',
      email: leave['email']?.toString() ?? '',
      position: leave['position_name']?.toString() ?? '',
      department: leave['department_name']?.toString() ?? '',
      branch:
          leave['branch_short_name']?.toString() ??
          leave['branch_full_name']?.toString() ??
          '',
      leaid: leave['leaid']?.toString() ?? '',
      frdat: leave['frdat']?.toString() ?? '',
      todat: leave['todat']?.toString() ?? '',
      numleav: leave['numleav']?.toString() ?? '',
      lfor: leave['lfor']?.toString() ?? '',
      lnot: leave['lnot']?.toString() ?? '',
      leaveNote: leave['leave_note']?.toString() ?? '',
      reason: leave['reason']?.toString() ?? '',
      remark: leave['remark']?.toString() ?? '',
      file: leave['document_url']?.toString(),
      createdate: leave['createdate']?.toString() ?? '',
      statu: leave['statu']?.toString() ?? '0',
      holiday: leave['holiday']?.toString() ?? '0',
      ltyp: leave['ltyp']?.toString() ?? '',
      requesterName:
          leave['dname']?.toString() ??
          leave['requester_name']?.toString() ??
          '',
      statuText: leave['statu_text']?.toString() ?? '',
      requesterProfileImage: leave['profile_image_url']?.toString(),
      prioList:
          (leave['prio_list'] as List<dynamic>?)
              ?.map(
                (prio) => CeoApprovalItem.fromJson({
                  'approver_name': prio['approver_name'],
                  'prio': prio['prio'],
                  'apstatu': prio['apstatu'],
                  'remark': prio['remark'],
                  'apstatu_text': prio['apstatu_text'],
                  'prio_text': prio['prio_text'],
                }),
              )
              .toList() ??
          [],
    );
  }

  // Convert to LeaveHistoryModel (for MyLeaveDetailScreen)
  LeaveHistoryModel toLeaveHistoryModel() {
    final leave = leaveData;

    if (leave == null) {
      throw Exception('No leave information available');
    }

    // Convert prio_list from Map to PriorityModel objects
    List<PriorityModel> prioList = [];
    if (leave['prio_list'] != null) {
      prioList =
          (leave['prio_list'] as List<dynamic>).map((prioData) {
            // prioData is a Map<String, dynamic>, not a PriorityModel
            final Map<String, dynamic> prio = prioData as Map<String, dynamic>;
            return PriorityModel(
              approverName: prio['approver_name']?.toString() ?? 'Unknown',
              approverId: prio['approver_id']?.toString() ?? 'Unknown',
              userApproverToken: prio['user_approver_token']?.toString(),
              prio: prio['prio'] ?? 0,
              apstatu: prio['apstatu'] ?? 0,
              apstatuText: prio['apstatu_text']?.toString() ?? '',
              prioText: prio['prio_text']?.toString() ?? '',
              remark: prio['remark']?.toString() ?? '',
            );
          }).toList();
    }

    return LeaveHistoryModel(
      eid: leave['eid']?.toString() ?? '',
      dname: leave['dname']?.toString() ?? '',
      eCard: null,
      position: null,
      department: null,
      email: null,
      branchName: null,
      lreid: leave['lreid']?.toString() ?? '',
      frdat: leave['frdat']?.toString() ?? '',
      todat: leave['todat']?.toString() ?? '',
      leaid: leave['leaid']?.toString() ?? '',
      ltyp: leave['ltyp']?.toString() ?? '',
      numleav: leave['numleav']?.toString() ?? '',
      lfor: leave['lfor']?.toString() ?? '',
      leaveNote: leave['leave_note']?.toString() ?? '',
      isLeaveCanCancel: leave['isLeaveCanCancel'] ?? false,
      statu: leave['statu']?.toString() ?? '0',
      reason: leave['reason']?.toString() ?? '',
      createdate: leave['createdate']?.toString() ?? '',
      prioList: prioList,
      statusText: leave['statu_text']?.toString() ?? '',
    );
  }
}

class NotificationPagination {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasMorePages;

  NotificationPagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasMorePages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      hasMorePages: json['has_more_pages'] ?? false,
    );
  }
}

class NotificationSummary {
  final int total;
  final int unread;
  final int read;
  final Map<String, int> byType;
  final int recentUnread;

  NotificationSummary({
    required this.total,
    required this.unread,
    required this.read,
    required this.byType,
    required this.recentUnread,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    final rawByType = json['by_type'];
    final byType =
        (rawByType is Map) ? Map<String, int>.from(rawByType) : <String, int>{};
    return NotificationSummary(
      total: json['total'] ?? 0,
      unread: json['unread'] ?? 0,
      read: json['read'] ?? 0,
      byType: byType,
      recentUnread: json['recent_unread'] ?? 0,
    );
  }
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final NotificationPagination pagination;
  final NotificationSummary summary;

  NotificationResponse({
    required this.notifications,
    required this.pagination,
    required this.summary,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return NotificationResponse(
      notifications:
          (data['notifications'] as List<dynamic>?)
              ?.map((item) => NotificationModel.fromJson(item))
              .toList() ??
          [],
      pagination: NotificationPagination.fromJson(data['pagination'] ?? {}),
      summary: NotificationSummary.fromJson(data['summary'] ?? {}),
    );
  }
}

class NotificationCountResponse {
  final int unreadCount;
  final String checkedAt;

  NotificationCountResponse({
    required this.unreadCount,
    required this.checkedAt,
  });

  factory NotificationCountResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return NotificationCountResponse(
      unreadCount: data['unread_count'] ?? 0,
      checkedAt: data['checked_at'] ?? '',
    );
  }
}
