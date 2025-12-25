import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_model.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/profile_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  // State variables
  UserModel? _user;
  AppVersion? _appVersion;
  UserProfile? _userProfile;
  List<LeaveModel> _leaves = [];
  LeaveBalanceModel? _leaveBalance;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  AppVersion? get appVersion => _appVersion;
  UserProfile? get userProfile => _userProfile;
  List<LeaveModel> get leaves => _leaves;
  LeaveBalanceModel? get leaveBalance => _leaveBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get username => _userProfile?.fullName ?? _user?.uname ?? "User";
  String? get profileImageUrl =>
      _userProfile?.profileImageUrl ?? _userProfile?.profileImage;
  String? get empProfileImage =>
      leaves.isNotEmpty ? leaves.first.empProfileImage : null;
  String get usedLeave => _leaveBalance?.annualLeaveUsed ?? "0";
  String get availableLeave => _leaveBalance?.annualLeaveBalance ?? "0";

  // Check if user status is inactive
  bool get isUserInactive => _user?.ustatus == "I";

  // Sorted priority list for leaves
  List<LeaveModel> get sortedLeaves {
    final sortedList = [..._leaves];
    // Sort by date or any other criteria you prefer
    sortedList.sort((a, b) => b.frdat.compareTo(a.frdat));
    return sortedList;
  }

  // Initialize dashboard data
  Future<void> initialize() async {
    await fetchDashboard();
  }

  // Fetch dashboard data
  Future<void> fetchDashboard() async {
    try {
      _setLoading(true);
      _setError(null);

      // Fetch dashboard data and user profile in parallel
      final results = await Future.wait([
        _repository.getDashboardData(),
        _profileRepository.getUserProfile(),
      ]);

      final dashboardData = results[0] as DashboardData;
      final userProfile = results[1] as UserProfile?;

      _user = dashboardData.user;
      _leaves = dashboardData.leaves;
      _leaveBalance = dashboardData.leaveBalance;
      _appVersion = dashboardData.appVersion;
      _userProfile = userProfile;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Get user ID
  Future<String?> getUserId() async {
    try {
      return await _repository.getUserId();
    } catch (e) {
      _setError('Error getting user ID: $e');
      return null;
    }
  }

  // Refresh dashboard data
  Future<void> refresh() async {
    await fetchDashboard();
  }

  // Refresh only user profile data (more efficient when only profile changed)
  Future<void> refreshProfile() async {
    try {
      final userProfile = await _profileRepository.getUserProfile();
      _userProfile = userProfile;
      notifyListeners();
    } catch (e) {
      // Don't show error for profile refresh failures, just keep existing data
      print('Failed to refresh profile: $e');
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Force logout (for inactive users)
  Future<void> forceLogout() async {
    try {
      await _profileRepository.logout();
    } catch (e) {
      // Even if logout API fails, we should proceed with clearing local data
      print('Error during force logout: $e');
    }
  }

  // Check if app update is available
  Future<bool> isUpdateAvailable() async {
    if (_appVersion == null) return false;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      return _appVersion!.isVersionGreaterThan(currentVersion);
    } catch (e) {
      print('Error checking update: $e');
      return false;
    }
  }

  // Check if update is mandatory
  bool isUpdateMandatory() {
    return _appVersion?.isMandatory ?? false;
  }

  // Check if force update is required
  // Force update when: current version < new version AND isMandatory is true
  Future<bool> shouldForceUpdate() async {
    final updateAvailable = await isUpdateAvailable();
    final isMandatory = isUpdateMandatory();
    return updateAvailable && isMandatory;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
