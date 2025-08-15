import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';
import '../services/location_service.dart';

class AttendanceClockViewModel extends ChangeNotifier {
  final AttendanceRepository _repository = AttendanceRepository();

  // State variables
  AttendanceClockData? _attendanceData;
  Branch? _selectedBranch;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isClockingInOut = false;
  String? _errorMessage;
  Timer? _timer;
  String _currentTime = '';

  // Getters
  AttendanceClockData? get attendanceData => _attendanceData;
  Branch? get selectedBranch => _selectedBranch;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  bool get isClockingInOut => _isClockingInOut;
  String? get errorMessage => _errorMessage;
  String get currentTime => _currentTime;

  List<Branch> get branches => _attendanceData?.branches ?? [];

  // Get only branches that have valid coordinates
  List<Branch> get branchesWithCoordinates =>
      branches.where((branch) => branch.hasValidCoordinates).toList();

  List<AttendanceRecord> get todayAttendance {
    if (_attendanceData == null) return [];

    final today = DateTime.now();
    return _attendanceData!.attendance.where((record) {
        return record.clockDate.year == today.year &&
            record.clockDate.month == today.month &&
            record.clockDate.day == today.day;
      }).toList()
      ..sort((a, b) => a.timeClock.compareTo(b.timeClock));
  }

  bool get isWithinRange {
    if (_currentPosition == null || _selectedBranch == null) return false;

    // Check if selected branch has valid coordinates
    if (!_selectedBranch!.hasValidCoordinates) return false;

    final distance = LocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedBranch!.latitude!,
      _selectedBranch!.longitude!,
    );

    return distance <= (_attendanceData?.rangeAllowClock ?? 300);
  }

  String get nextClockType {
    if (_attendanceData == null) return 'In';

    if (todayAttendance.isEmpty) return 'In';

    final lastRecord = todayAttendance.last;
    return lastRecord.isClockIn ? 'Out' : 'In';
  }

  bool get canClock =>
      _currentPosition != null &&
      isWithinRange &&
      !_isClockingInOut &&
      _selectedBranch != null &&
      _selectedBranch!.hasValidCoordinates;

  String get locationStatusText {
    if (_currentPosition == null) return 'Getting location...';
    if (_selectedBranch == null) return 'Please select a branch';
    if (!_selectedBranch!.hasValidCoordinates) {
      return 'Branch coordinates not available';
    }
    if (isWithinRange) return 'Within allowed range';
    return 'Outside allowed range (${_attendanceData?.rangeAllowClock ?? 300}m)';
  }

  Color get locationStatusColor {
    if (_currentPosition == null) return Colors.orange;
    if (_selectedBranch == null || !_selectedBranch!.hasValidCoordinates) {
      return Colors.grey;
    }
    return isWithinRange ? Colors.green : Colors.red;
  }

  // Initialize
  void initialize() {
    _startTimer();
    loadAttendanceData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Timer for current time
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      notifyListeners();
    });
  }

  // Load attendance data
  Future<void> loadAttendanceData() async {
    try {
      _setLoading(true);
      _setError(null);

      final data = await _repository.getAttendanceClockData();

      _attendanceData = data;

      // Auto-select user's branch if it has valid coordinates
      final userBranch = data.branches.firstWhere(
        (branch) => branch.branchId == data.user.branchId,
        orElse: () => data.branches.first,
      );

      // Only auto-select if the user's branch has coordinates
      if (userBranch.hasValidCoordinates) {
        _selectedBranch = userBranch;
      } else {
        // Select first branch with coordinates as fallback
        final branchWithCoords = data.branches.firstWhere(
          (branch) => branch.hasValidCoordinates,
          orElse: () => data.branches.first,
        );
        _selectedBranch = branchWithCoords;
      }

      _setLoading(false);

      // Get current location after loading data
      await _getCurrentLocation();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      _currentPosition = position;
      notifyListeners();
    } catch (e) {
      _setError('Failed to get location: $e');
    }
  }

  // Refresh location
  Future<void> refreshLocation() async {
    await _getCurrentLocation();
  }

  // Select branch
  void selectBranch(Branch? branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  // Perform clock in/out
  Future<ClockInOutResponse> performClockInOut() async {
    if (!canClock) {
      throw Exception(
        'Cannot perform clock action. Check location and permissions.',
      );
    }

    if (!_selectedBranch!.hasValidCoordinates) {
      throw Exception('Selected branch does not have valid coordinates.');
    }

    try {
      _setClockingInOut(true);

      final request = ClockInOutRequest(
        branchId: _selectedBranch!.branchId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        clockType: nextClockType,
      );

      final response = await _repository.clockInOut(request);

      if (response.success) {
        // Reload data to get updated attendance
        await loadAttendanceData();
      }

      _setClockingInOut(false);
      return response;
    } catch (e) {
      _setClockingInOut(false);
      throw e;
    }
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setClockingInOut(bool clocking) {
    _isClockingInOut = clocking;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get distance to selected branch
  double? getDistanceToSelectedBranch() {
    if (_currentPosition == null ||
        _selectedBranch == null ||
        !_selectedBranch!.hasValidCoordinates) {
      return null;
    }

    return LocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedBranch!.latitude!,
      _selectedBranch!.longitude!,
    );
  }

  // Format distance for display
  String getFormattedDistance() {
    final distance = getDistanceToSelectedBranch();
    if (distance == null) return 'Unknown';

    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  // Get branch validation message
  String getBranchValidationMessage(Branch branch) {
    if (!branch.hasValidCoordinates) {
      return 'No coordinates available';
    }
    return '';
  }

  // Check if any branches have coordinates
  bool get hasAnyBranchWithCoordinates =>
      branches.any((branch) => branch.hasValidCoordinates);
}
