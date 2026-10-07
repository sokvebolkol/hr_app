import 'package:flutter/material.dart';
import '../models/leave_history_model.dart';
import '../models/adjustment_request_model.dart';
import '../repositories/leave_history_repository.dart';

class LeaveHistoryViewModel extends ChangeNotifier {
  final LeaveHistoryRepository _repository = LeaveHistoryRepository();

  List<LeaveHistoryModel> _leaveHistory = [];
  List<AdjustmentRequestModel> _adjustmentHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<LeaveHistoryModel> get leaveHistory => _leaveHistory;
  List<AdjustmentRequestModel> get adjustmentHistory => _adjustmentHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get approvedCount =>
      _leaveHistory.where((leave) => leave.isApproved).length;
  int get rejectedCount =>
      _leaveHistory.where((leave) => leave.isRejected).length;

  // Fetch leave history
  Future<void> fetchLeaveHistory() async {
    try {
      _setLoading(true);
      _setError(null);

      final historyData = await _repository.getLeaveHistory();
      _leaveHistory = historyData.leaveRequests;
      _adjustmentHistory = historyData.adjustmentRequests;

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
