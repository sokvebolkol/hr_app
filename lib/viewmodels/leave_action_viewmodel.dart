import 'package:flutter/foundation.dart';
import '../repositories/leave_repository.dart';

class LeaveActionViewModel extends ChangeNotifier {
  final LeaveActionRepository _repository = LeaveActionRepository();

  // State
  bool _isLoading = false;
  bool _isApproving = false;
  bool _isRejecting = false;
  String? _errorMessage;
  String? _successMessage;

  // Action results
  bool _hasActionTaken = false;
  String? _lastAction; // 'approve' or 'reject'
  String? _lastRemark;

  // Getters
  bool get isLoading => _isLoading;
  bool get isApproving => _isApproving;
  bool get isRejecting => _isRejecting;
  bool get isProcessing => _isApproving || _isRejecting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasActionTaken => _hasActionTaken;
  String? get lastAction => _lastAction;
  String? get lastRemark => _lastRemark;

  // Approve leave request
  Future<bool> approveLeave({required String leaveId, String? remark}) async {
    _setApproving(true);
    _clearMessages();

    try {
      final result = await _repository.approveLeave(
        leaveId: leaveId,
        remark: remark,
      );

      if (result['success']) {
        _setSuccess(result['message'] ?? 'Leave request approved successfully');
        _setActionTaken('approve', remark);
        _setApproving(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to approve leave request');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    }
  }

  // Reject leave request
  Future<bool> rejectLeave({required String leaveId, String? remark}) async {
    _setRejecting(true);
    _clearMessages();

    try {
      final result = await _repository.rejectLeave(
        leaveId: leaveId,
        remark: remark,
      );

      if (result['success']) {
        _setSuccess(result['message'] ?? 'Leave request rejected successfully');
        _setActionTaken('reject', remark);
        _setRejecting(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to reject leave request');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    }
  }

  // Get leave details
  Future<Map<String, dynamic>?> getLeaveDetails(String leaveId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await _repository.getLeaveDetails(leaveId);

      if (result['success']) {
        _setLoading(false);
        return result['data'];
      } else {
        _setError(result['message'] ?? 'Failed to get leave details');
        return null;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return null;
    }
  }

  // Clear all messages
  void clearMessages() {
    _clearMessages();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear success
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // Reset action state
  void resetActionState() {
    _hasActionTaken = false;
    _lastAction = null;
    _lastRemark = null;
    _clearMessages();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setApproving(bool approving) {
    _isApproving = approving;
    notifyListeners();
  }

  void _setRejecting(bool rejecting) {
    _isRejecting = rejecting;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _successMessage = null;
    _isLoading = false;
    _isApproving = false;
    _isRejecting = false;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void _setActionTaken(String action, String? remark) {
    _hasActionTaken = true;
    _lastAction = action;
    _lastRemark = remark;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
