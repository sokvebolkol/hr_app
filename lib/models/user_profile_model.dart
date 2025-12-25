class UserProfile {
  final String userId;
  final String username;
  final String? profileImage;
  final String employeeId;
  final String? employeeCard;
  final String fullName;
  final String email;
  final String gender;
  final String joinedDate;
  final String employmentType;
  final double? monthlySalary;
  final String? previousMonthSalary;
  final String contract;
  final String salaryType;
  final String positionName;
  final String departmentName;
  final String branchShortName;
  final String branchFullName;
  final String? profileImageUrl;

  UserProfile({
    required this.userId,
    required this.username,
    this.profileImage,
    required this.employeeId,
    this.employeeCard,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.joinedDate,
    required this.employmentType,
    required this.monthlySalary,
    this.previousMonthSalary,
    required this.contract,
    required this.salaryType,
    required this.positionName,
    required this.departmentName,
    required this.branchShortName,
    required this.branchFullName,
    this.profileImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profileImage: json['profile_image']?.toString(),
      employeeId: json['employee_id']?.toString() ?? '',
      employeeCard: json['employee_card']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      joinedDate: json['joined_date']?.toString() ?? '',
      employmentType: json['employment_type']?.toString() ?? '',
      monthlySalary: _parseToDouble(json['monthly_salary']),
      previousMonthSalary: json['previous_month_salary']?.toString(),
      contract: json['contract']?.toString() ?? '',
      salaryType: json['salary_type']?.toString() ?? '',
      positionName: json['position_name']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      branchShortName: json['branch_short_name']?.toString() ?? '',
      branchFullName: json['branch_full_name']?.toString() ?? '',
      profileImageUrl: json['profile_image_url']?.toString(),
    );
  }

  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    if (value is String) {
      if (value.isEmpty) return null;
      try {
        return double.parse(value);
      } catch (e) {
        print('⚠️ Warning: Could not parse "$value" to double, returning null');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'profile_image': profileImage,
      'employee_id': employeeId,
      'employee_card': employeeCard,
      'full_name': fullName,
      'email': email,
      'gender': gender,
      'joined_date': joinedDate,
      'employment_type': employmentType,
      'monthly_salary': monthlySalary,
      'previous_month_salary': previousMonthSalary,
      'contract': contract,
      'salary_type': salaryType,
      'position_name': positionName,
      'department_name': departmentName,
      'branch_short_name': branchShortName,
      'branch_full_name': branchFullName,
      'profile_image_url': profileImageUrl,
    };
  }

  UserProfile copyWith({
    String? userId,
    String? username,
    String? profileImage,
    String? employeeId,
    String? employeeCard,
    String? fullName,
    String? email,
    String? gender,
    String? joinedDate,
    String? employmentType,
    double? monthlySalary,
    String? previousMonthSalary,
    String? contract,
    String? salaryType,
    String? positionName,
    String? departmentName,
    String? branchShortName,
    String? branchFullName,
    String? profileImageUrl,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      employeeId: employeeId ?? this.employeeId,
      employeeCard: employeeCard ?? this.employeeCard,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      joinedDate: joinedDate ?? this.joinedDate,
      employmentType: employmentType ?? this.employmentType,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      previousMonthSalary: previousMonthSalary ?? this.previousMonthSalary,
      contract: contract ?? this.contract,
      salaryType: salaryType ?? this.salaryType,
      positionName: positionName ?? this.positionName,
      departmentName: departmentName ?? this.departmentName,
      branchShortName: branchShortName ?? this.branchShortName,
      branchFullName: branchFullName ?? this.branchFullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // Helper getter for formatted joined date
  String get formattedJoinedDate {
    if (joinedDate.isEmpty) return '';
    try {
      return joinedDate.split(' ')[0]; // Get date part only
    } catch (e) {
      return joinedDate;
    }
  }

  // Helper getter for current profile image path
  String get currentProfileImagePath {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return profileImageUrl!;
    }
    return "";
  }
}
