import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/leave_history_model.dart';
import '../repositories/update_leave_repository.dart';

class UpdateLeaveViewModel extends ChangeNotifier {
  final UpdateLeaveRepository _repository = UpdateLeaveRepository();
  final LeaveHistoryModel _originalLeave;

  bool _isLoading = false;
  String? _errorMessage;

  UpdateLeaveViewModel(this._originalLeave);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LeaveHistoryModel get originalLeave => _originalLeave;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> updateLeave(
    Map<String, dynamic> updateData,
    XFile? documentPhoto,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.updateLeaveRequest(
        _originalLeave.lreid,
        updateData,
        documentPhoto,
      );

      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update leave request: $e');
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
