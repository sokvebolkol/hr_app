import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/leave_history_model.dart';
import '../repositories/update_leave_repository.dart';

class UpdateLeaveViewModel extends ChangeNotifier {
  final UpdateLeaveRepository _repository = UpdateLeaveRepository();
  final LeaveHistoryModel originalRequest;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  UpdateLeaveViewModel(this.originalRequest);

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Update leave request
  Future<bool> updateLeave(
    Map<String, dynamic> updateData,
    XFile? documentPhoto,
  ) async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await _repository.updateLeaveRequestDetailed(
        originalRequest.lreid,
        updateData,
        documentPhoto,
      );

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Leave updated successfully';
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update leave';

        // Handle validation errors
        if (result['errors'] != null) {
          final errors = result['errors'] as Map<String, dynamic>;
          final errorMessages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.cast<String>());
            } else {
              errorMessages.add(value.toString());
            }
          });
          _errorMessage = errorMessages.join('\n');
        }

        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Cancel leave request
  Future<bool> cancelLeave() async {
    _setLoading(true);
    _clearMessages();

    try {
      final result = await _repository.cancelLeaveRequest(
        originalRequest.lreid,
      );

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Leave cancelled successfully';
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to cancel leave';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Get update history
  Future<List<Map<String, dynamic>>?> getUpdateHistory() async {
    try {
      final result = await _repository.getLeaveUpdateHistory(
        originalRequest.lreid,
      );

      if (result['success'] == true) {
        return List<Map<String, dynamic>>.from(result['data'] ?? []);
      } else {
        _errorMessage =
            result['message'] ?? 'Failed to retrieve update history';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      return null;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
