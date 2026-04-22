class AdjustmentRequestModel {
  final int id;
  final String staffId;
  final String adjustType;
  final String adjustDateTime;
  final String reason;
  final int status;
  final bool isAttendanceCanCancel;
  final String checkInTime;
  final String checkOutTime;
  final String createdBy;
  final String createdAt;
  final String requesterName;
  final List<AdjustmentApprover> approverList;
  final String statusText;
  final String? documentUrl;
  final bool? hasDocument;

  AdjustmentRequestModel({
    required this.id,
    required this.staffId,
    required this.adjustType,
    required this.adjustDateTime,
    required this.reason,
    required this.status,
    required this.isAttendanceCanCancel,
    required this.checkInTime,
    required this.checkOutTime,
    required this.createdBy,
    required this.createdAt,
    required this.requesterName,
    required this.approverList,
    required this.statusText,
    this.documentUrl,
    this.hasDocument,
  });

  factory AdjustmentRequestModel.fromJson(Map<String, dynamic> json) {
    return AdjustmentRequestModel(
      id: json['id'] ?? 0,
      staffId: json['staff_id'] ?? '',
      adjustType: json['adjust_type'] ?? '',
      adjustDateTime: json['adjust_datetime'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 0,
      isAttendanceCanCancel: json['is_attendance_can_cancel'] ?? false,
      checkInTime: json['check_in'] ?? '',
      checkOutTime: json['check_out'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] ?? '',
      requesterName: json['requester_name'] ?? '',
      approverList:
          (json['approver_list'] as List<dynamic>?)
              ?.map((e) => AdjustmentApprover.fromJson(e))
              .toList() ??
          [],
      statusText: json['status_text'] ?? '',
      documentUrl: json['document_url'],
      hasDocument: json['has_document'],
    );
  }
  // Helper getters
  bool get isPending => status == 2;
  bool get isApproved => status == 1;
  bool get isRejected => status == 0;
  bool get isCancelled => status == 3;
  DateTime get createdDate => DateTime.parse(createdAt);
}

class AdjustmentApprover {
  final String approverName;
  final String approverId;
  final int priority;
  final int approvalStatus;
  final String? remark;
  final String approvalStatusText;
  final String priorityText;

  AdjustmentApprover({
    required this.approverName,
    required this.approverId,
    required this.priority,
    required this.approvalStatus,
    this.remark,
    required this.approvalStatusText,
    required this.priorityText,
  });

  factory AdjustmentApprover.fromJson(Map<String, dynamic> json) {
    return AdjustmentApprover(
      approverName: json['approver_name'] ?? '',
      approverId: json['approver_id'] ?? '',
      priority: json['priority'] ?? 0,
      approvalStatus: json['approval_status'] ?? 0,
      remark: json['remark'],
      approvalStatusText: json['approval_status_text'] ?? '',
      priorityText: json['priority_text'] ?? '',
    );
  }

  // Helper getters
  bool get isPending => approvalStatus == 2;
  bool get isApproved => approvalStatus == 1;
  bool get isRejected => approvalStatus == 0;
}
