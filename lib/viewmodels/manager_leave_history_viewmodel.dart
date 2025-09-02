import 'package:flutter/material.dart';
import '../models/leave_history_model.dart';
import '../models/manager_leave_history_model.dart';
import '../repositories/manager_leave_history_repository.dart';

class ManagerLeaveHistoryViewModel extends ChangeNotifier {
  final ManagerLeaveHistoryRepository _repository =
      ManagerLeaveHistoryRepository();

  // State
  bool _isLoading = false;
  String? _errorMessage;

  // Data
  List<LeaveHistoryModel> _myLeaveRequests = [];
  List<StaffLeaveModel> _staffLeaveRequests = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LeaveHistoryModel> get myLeaveRequests => _myLeaveRequests;
  List<StaffLeaveModel> get staffLeaveRequests => _staffLeaveRequests;

  // My Request Stats
  int get myPendingCount =>
      _myLeaveRequests.where((leave) => leave.isPending).length;
  int get myApprovedCount =>
      _myLeaveRequests.where((leave) => leave.isApproved).length;
  int get myRejectedCount =>
      _myLeaveRequests.where((leave) => leave.isRejected).length;

  // Staff Request Stats
  int get staffPendingCount =>
      _staffLeaveRequests.where((leave) => leave.isPending).length;
  int get staffApprovedCount =>
      _staffLeaveRequests.where((leave) => leave.isApproved).length;
  int get staffRejectedCount =>
      _staffLeaveRequests.where((leave) => leave.isRejected).length;

  // Available filters
  List<String> get myLeaveTypes {
    return _myLeaveRequests.map((leave) => leave.ltyp).toSet().toList();
  }

  List<String> get staffLeaveTypes {
    return _staffLeaveRequests.map((leave) => leave.ltyp).toSet().toList();
  }

  List<String> get staffMembers {
    return _staffLeaveRequests
        .map((leave) => leave.requesterName)
        .toSet()
        .toList();
  }

  // Fetch data
  Future<void> fetchLeaveHistory() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _repository.getManagerLeaveHistory();

      _myLeaveRequests = response.myLeaveRequest;
      _staffLeaveRequests = response.approvedLeaves;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await fetchLeaveHistory();
  }

  // Filter my leave requests
  List<LeaveHistoryModel> getFilteredMyRequests({
    String? status,
    String? leaveType,
  }) {
    var filtered = _myLeaveRequests;

    if (status != null) {
      filtered = filtered.where((leave) => leave.statu == status).toList();
    }

    if (leaveType != null) {
      filtered = filtered.where((leave) => leave.ltyp == leaveType).toList();
    }

    // Sort by created date (newest first)
    filtered.sort((a, b) => b.createdDate.compareTo(a.createdDate));

    return filtered;
  }

  // Filter staff leave requests
  List<StaffLeaveModel> getFilteredStaffRequests({
    String? status,
    String? leaveType,
    String? staffMember,
  }) {
    var filtered = _staffLeaveRequests;

    if (status != null) {
      filtered = filtered.where((leave) => leave.statu == status).toList();
    }

    if (leaveType != null) {
      filtered = filtered.where((leave) => leave.ltyp == leaveType).toList();
    }

    if (staffMember != null) {
      filtered =
          filtered
              .where((leave) => leave.requesterName == staffMember)
              .toList();
    }

    // Sort by created date (newest first)
    filtered.sort((a, b) => b.createdDate.compareTo(a.createdDate));

    return filtered;
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

  @override
  void dispose() {
    super.dispose();
  }
}
