import 'package:flutter/foundation.dart';
import '../repositories/approver_dashboard_repository.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_model.dart';

class ApproverDashboardViewModel extends ChangeNotifier {
  final ApproverDashboardRepository _repository = ApproverDashboardRepository();

  // State
  bool _isLoading = false;
  String? _errorMessage;

  // Data
  ApproverUser? _user;
  List<LeaveModel> _myLeaveRequests = [];
  List<PendingLeaveRequest> _pendingLeaveRequests = [];
  LeaveBalanceModel? _leaveBalance;
  int _pendingLeavesCount = 0;
  int _ownLeavesCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ApproverUser? get user => _user;
  List<LeaveModel> get myLeaveRequests => _myLeaveRequests;
  List<PendingLeaveRequest> get pendingLeaveRequests => _pendingLeaveRequests;
  LeaveBalanceModel? get leaveBalance => _leaveBalance;
  int get pendingLeavesCount => _pendingLeavesCount;
  int get ownLeavesCount => _ownLeavesCount;

  // Computed properties
  String get username => _user?.uname ?? 'User';
  String? get profileImageUrl => _user?.profileImageUrl;
  bool get isUserInactive => _user?.ustatus != 'A';

  String get usedLeave => _leaveBalance?.annualLeaveUsed ?? '0';
  String get availableLeave => _leaveBalance?.annualLeaveBalance ?? '0';

  List<LeaveModel> get sortedLeaves {
    final sorted = [..._myLeaveRequests];
    sorted.sort((a, b) => b.createdate.compareTo(a.createdate));
    return sorted.take(5).toList(); // Show only recent 5 leaves
  }

  // Initialize
  Future<void> initialize() async {
    await fetchDashboardData();
  }

  // Fetch dashboard data
  Future<void> fetchDashboardData() async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _repository.getApproverDashboard();

      _user = data.user;
      _myLeaveRequests = data.myLeaveRequests;
      _pendingLeaveRequests = data.pendingLeaveNeedsApproval;
      _pendingLeavesCount = data.pendingLeavesCount;
      _ownLeavesCount = data.ownLeavesCount;

      // Get the first leave balance if available
      if (data.leaveBalances.isNotEmpty) {
        _leaveBalance = data.leaveBalances.first;
      }

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await fetchDashboardData();
  }

  // Refresh profile specifically
  Future<void> refreshProfile() async {
    await fetchDashboardData();
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Force logout
  Future<void> forceLogout() async {
    // Implement logout logic here
    // Clear shared preferences, etc.
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
