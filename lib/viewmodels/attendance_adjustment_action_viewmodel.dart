import 'package:flutter/material.dart';
import '../repositories/attendance_adjustment_action_repository.dart';

class AttendanceAdjustmentActionViewModel extends ChangeNotifier {
  final AttendanceAdjustmentActionRepository _repository =
      AttendanceAdjustmentActionRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _hasActionTaken = false;
  String? _actionType; // 'approve' or 'reject'
  bool _isApproving = false;
  bool _isRejecting = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasActionTaken => _hasActionTaken;
  String? get actionType => _actionType;
  bool get isProcessing => _isApproving || _isRejecting;
  bool get isApproving => _isApproving;
  bool get isRejecting => _isRejecting;

  Future<Map<String, dynamic>> approveAttendance({
    required String adjustmentId,
    String? remark,
  }) async {
    _isLoading = true;
    _isApproving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _repository.approveAttendanceAdjustment(
        adjustmentId: adjustmentId,
        remark: remark,
      );

      if (result['success'] == true) {
        _hasActionTaken = true;
        _actionType = 'approve';
        _successMessage =
            result['message'] ?? 'Attendance adjustment approved successfully';
      } else {
        _errorMessage = result['message'] ?? 'Failed to approve attendance';
      }

      _isLoading = false;
      _isApproving = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      _isApproving = false;
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();

      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<Map<String, dynamic>> rejectAttendance({
    required String adjustmentId,
    String? remark,
  }) async {
    _isLoading = true;
    _isRejecting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _repository.rejectAttendanceAdjustment(
        adjustmentId: adjustmentId,
        remark: remark,
      );

      if (result['success'] == true) {
        _hasActionTaken = true;
        _actionType = 'reject';
        _successMessage =
            result['message'] ?? 'Attendance adjustment rejected successfully';
      } else {
        _errorMessage = result['message'] ?? 'Failed to reject attendance';
      }

      _isLoading = false;
      _isRejecting = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      _isRejecting = false;
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();

      return {'success': false, 'message': _errorMessage};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
