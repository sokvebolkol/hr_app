import 'package:flutter/material.dart';
import '../models/leave_balance_model.dart';
import '../repositories/leave_balance_repository.dart';

class LeaveBalanceViewModel extends ChangeNotifier {
  final LeaveBalanceRepository _repository = LeaveBalanceRepository();

  // State variables
  LeaveBalanceModel? _leaveBalance;
  List<dynamic> _approvedLeaveRequests = [];
  bool _isLoading = false;
  bool _isViewMaternityLeave = false;
  String? _errorMessage;
  int _selectedYear = DateTime.now().year;
  String? _joinDate;

  // Getters
  LeaveBalanceModel? get leaveBalance => _leaveBalance;
  List<dynamic> get approvedLeaveRequests => _approvedLeaveRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedYear => _selectedYear;
  String? get joinDate => _joinDate;
  bool get isViewMaternityLeave => _isViewMaternityLeave;
  // Get available years based on join date
  List<int> get availableYears {
    if (_joinDate == null) {
      // Default to last 5 years if no join date
      final currentYear = DateTime.now().year;
      return List.generate(5, (index) => currentYear - index);
    }

    try {
      final joinDateTime = DateTime.parse(_joinDate!);
      final joinYear = joinDateTime.year;
      final currentYear = DateTime.now().year;

      // Generate years from join year to current year
      return List.generate(
        currentYear - joinYear + 1,
        (index) => joinYear + index,
      ).reversed.toList(); // Most recent first
    } catch (e) {
      // Fallback if date parsing fails
      final currentYear = DateTime.now().year;
      return List.generate(5, (index) => currentYear - index);
    }
  }

  // Computed properties for easy access
  String get annualLeaveForwardBalance =>
      _leaveBalance?.annualLeaveForwardBalance ?? "0";
  String get annualLeaveEntitlement =>
      _leaveBalance?.annualLeaveEntitlement ?? "0";
  String get annualLeaveUsed => _leaveBalance?.annualLeaveUsed ?? "0";
  String get annualLeaveBalance => _leaveBalance?.annualLeaveBalance ?? "0";

  String get sickLeaveEntitlement => _leaveBalance?.sickLeaveEntitlement ?? "0";
  String get sickLeaveUsed => _leaveBalance?.sickLeaveUsed ?? "0";
  String get sickLeaveBalance => _leaveBalance?.sickLeaveBalance ?? "0";

  String get specialLeaveEntitlement =>
      _leaveBalance?.specialLeaveEntitlement ?? "0";
  String get specialLeaveUsed => _leaveBalance?.specialLeaveUsed ?? "0";
  String get specialLeaveBalance => _leaveBalance?.specialLeaveBalance ?? "0";

  String get maternityLeaveEntitlement =>
      _leaveBalance?.maternityLeaveEntitlement ?? "0";
  String get maternityLeaveUsed => _leaveBalance?.maternityLeaveUsed ?? "0";
  String get maternityLeaveBalance =>
      _leaveBalance?.maternityLeaveBalance ?? "0";

  String get unpaidLeaveUsed => _leaveBalance?.unpaidLeaveUsed ?? "0";
  String get approvedLeaveRequest => _leaveBalance?.approvedLeaveRequest ?? "0";
  String get pendingLeaveRequest => _leaveBalance?.pendingLeaveRequest ?? "0";
  String get rejectedLeaveRequest => _leaveBalance?.rejectedLeaveRequest ?? "0";

  // Calculate total leave used (all types combined)
  double get totalLeaveUsed {
    try {
      final annual = double.tryParse(annualLeaveUsed) ?? 0;
      final sick = double.tryParse(sickLeaveUsed) ?? 0;
      final special = double.tryParse(specialLeaveUsed) ?? 0;
      final maternity = double.tryParse(maternityLeaveUsed) ?? 0;
      // final unpaid = double.tryParse(unpaidLeaveUsed) ?? 0;
      return annual + sick + special + maternity;
    } catch (e) {
      return 0;
    }
  }

  // Fetch leave balance for selected year
  Future<void> fetchLeaveBalance() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _repository.getLeaveBalance(_selectedYear);

      if (response != null && response.data.isNotEmpty) {
        _leaveBalance =
            response.data.first; // Get the first item from data array
        _approvedLeaveRequests = response.approvedLeaveRequest;
        _joinDate = response.joinDate; // Store join date for year filtering
        _isViewMaternityLeave = response.isViewMaternityLeave;
      } else {
        _leaveBalance = null;
        _approvedLeaveRequests = [];
        _joinDate = null;
        _isViewMaternityLeave = false;
      }

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Change selected year and refresh data
  Future<void> changeYear(int year) async {
    _selectedYear = year;
    notifyListeners();
    await fetchLeaveBalance();
  }

  // Refresh current data
  Future<void> refresh() async {
    await fetchLeaveBalance();
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

  @override
  void dispose() {
    super.dispose();
  }
}
