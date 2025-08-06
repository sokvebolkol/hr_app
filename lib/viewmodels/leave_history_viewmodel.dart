import 'package:flutter/material.dart';
import '../models/leave_history_model.dart';
import '../repositories/leave_history_repository.dart';

class LeaveHistoryViewModel extends ChangeNotifier {
  final LeaveHistoryRepository _repository = LeaveHistoryRepository();

  // State variables
  List<LeaveHistoryModel> _leaveHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<LeaveHistoryModel> get leaveHistory => _leaveHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch leave history data
  Future<void> fetchLeaveHistory() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _repository.getLeaveHistory();
      if (response != null) {
        _leaveHistory = response.data;
        _sortLeaveHistory();
      } else {
        _setError('No leave history data found');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Sort leave history by creation date (newest first)
  void _sortLeaveHistory() {
    _leaveHistory.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.createdate);
        final dateB = DateTime.parse(b.createdate);
        return dateB.compareTo(dateA); // Newest first
      } catch (e) {
        return 0; // Keep original order if date parsing fails
      }
    });
  }

  // Refresh data
  Future<void> refresh() async {
    await fetchLeaveHistory();
  }

  // Filter methods
  List<LeaveHistoryModel> getFilteredHistory({
    String? status,
    String? leaveType,
  }) {
    var filtered = _leaveHistory;

    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((leave) => leave.statu == status).toList();
    }

    if (leaveType != null && leaveType.isNotEmpty) {
      filtered = filtered.where((leave) => leave.ltyp == leaveType).toList();
    }

    return filtered;
  }

  // Get unique leave types for filtering
  List<String> get availableLeaveTypes {
    final types = <String>{};
    for (final leave in _leaveHistory) {
      if (leave.ltyp.isNotEmpty) {
        types.add(leave.ltyp);
      }
    }
    return types.toList()..sort();
  }

  // Get counts by status
  int get pendingCount =>
      _leaveHistory.where((leave) => leave.statu == '0').length;
  int get approvedCount =>
      _leaveHistory.where((leave) => leave.statu == '1').length;
  int get rejectedCount =>
      _leaveHistory.where((leave) => leave.statu == '2').length;

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
