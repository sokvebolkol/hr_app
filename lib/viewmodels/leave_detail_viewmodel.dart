// import 'package:flutter/material.dart';
// import '../models/leave_history_model.dart';
// import '../repositories/leave_detail_repository.dart';
//
// class LeaveDetailViewModel extends ChangeNotifier {
//   final LeaveDetailRepository _repository = LeaveDetailRepository();
//
//   LeaveHistoryModel _leaveRequest;
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   LeaveDetailViewModel(this._leaveRequest);
//
//   // Getters
//   LeaveHistoryModel get leaveRequest => _leaveRequest;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//
//   // Update leave request data locally
//   void updateLeaveRequest(LeaveHistoryModel updatedRequest) {
//     _leaveRequest = updatedRequest;
//     notifyListeners();
//   }
//
//   // Cancel leave request
//   Future<void> cancelLeaveRequest() async {
//     _setLoading(true);
//     _clearError();
//
//     try {
//       final success = await _repository.cancelLeaveRequest(_leaveRequest.lreid);
//       if (success) {
//         // Update the status to cancelled locally
//         _leaveRequest = LeaveHistoryModel(
//           lreid: _leaveRequest.lreid,
//           frdat: _leaveRequest.frdat,
//           todat: _leaveRequest.todat,
//           leaid: _leaveRequest.leaid,
//           ltyp: _leaveRequest.ltyp,
//           numleav: _leaveRequest.numleav,
//           lfor: _leaveRequest.lfor,
//           statu: '3', // Cancelled status
//           reason: _leaveRequest.reason,
//           createdate: _leaveRequest.createdate,
//         );
//         notifyListeners();
//       } else {
//         _setError('Failed to cancel leave request');
//       }
//     } catch (e) {
//       _setError('Error cancelling leave request: $e');
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Send follow-up message
//   Future<void> sendFollowUpMessage(String message) async {
//     _setLoading(true);
//     _clearError();
//
//     try {
//       final success = await _repository.sendFollowUpMessage(
//         _leaveRequest.lreid,
//         message,
//       );
//       if (!success) {
//         _setError('Failed to send follow-up message');
//       }
//     } catch (e) {
//       _setError('Error sending follow-up message: $e');
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Update leave request
//   Future<void> updateLeave({
//     required String fromDate,
//     required String toDate,
//     required String reason,
//     required String leaveType,
//     required String numDays,
//   }) async {
//     _setLoading(true);
//     _clearError();
//
//     try {
//       final success = await _repository.updateLeaveRequest(
//         leaveId: _leaveRequest.lreid,
//         fromDate: fromDate,
//         toDate: toDate,
//         reason: reason,
//         leaveType: leaveType,
//         numDays: numDays,
//       );
//
//       if (success) {
//         // Update the local leave request data
//         _leaveRequest = LeaveHistoryModel(
//           lreid: _leaveRequest.lreid,
//           frdat: fromDate,
//           todat: toDate,
//           leaid: _leaveRequest.leaid,
//           ltyp: leaveType,
//           numleav: numDays,
//           lfor: _leaveRequest.lfor,
//           statu: '0', // Reset to pending after update
//           reason: reason,
//           createdate: _leaveRequest.createdate,
//         );
//         notifyListeners();
//       } else {
//         _setError('Failed to update leave request');
//       }
//     } catch (e) {
//       _setError('Error updating leave request: $e');
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Helper methods
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }
//
//   void _setError(String error) {
//     _errorMessage = error;
//     notifyListeners();
//   }
//
//   void _clearError() {
//     _errorMessage = null;
//     notifyListeners();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
// }
