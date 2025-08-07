class ApproverModel {
  final int id;
  final int requesterId;
  final int approverId;
  final int approvalLevel;
  final String? createdAt;
  final String? updatedAt;
  final String dname;
  final String? userApproverToken;
  final String approverLevelName; // Add this new field

  ApproverModel({
    required this.id,
    required this.requesterId,
    required this.approverId,
    required this.approvalLevel,
    this.createdAt,
    this.updatedAt,
    required this.dname,
    this.userApproverToken,
    required this.approverLevelName, // Add this to constructor
  });

  factory ApproverModel.fromJson(Map<String, dynamic> json) {
    return ApproverModel(
      id: json['id'],
      requesterId: json['requester_id'],
      approverId: json['approver_id'],
      approvalLevel: json['approval_level'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      dname: json['dname'],
      userApproverToken: json['user_approver_token'],
      approverLevelName:
          json['approver_level_name'] ??
          'Level ${json['approval_level']} Approver', // Add with fallback
    );
  }
}
