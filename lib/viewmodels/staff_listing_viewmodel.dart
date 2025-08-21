import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/staff_listing_model.dart';
import '../repositories/staff_listing_repository.dart';

class StaffListingViewModel extends ChangeNotifier {
  final StaffListingRepository _repository = StaffListingRepository();

  // State variables
  StaffListingData? _staffData;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  String _selectedStatus = 'all';
  String? _selectedBranchId;
  String? _selectedDepartmentId;
  String? _selectedDate;

  // Getters
  StaffListingData? get staffData => _staffData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String get selectedStatus => _selectedStatus;
  String? get selectedBranchId => _selectedBranchId;
  String? get selectedDepartmentId => _selectedDepartmentId;
  String? get selectedDate => _selectedDate;

  // Filtered staff lists by category
  List<StaffMember> get presentStaff =>
      _staffData?.staffListing
          .where((staff) => staff.category == 'present')
          .toList() ??
      [];

  List<StaffMember> get lateStaff =>
      _staffData?.staffListing
          .where((staff) => staff.category == 'late')
          .toList() ??
      [];

  List<StaffMember> get absentStaff =>
      _staffData?.staffListing
          .where((staff) => staff.category == 'absent')
          .toList() ??
      [];

  List<StaffMember> get leaveStaff =>
      _staffData?.staffListing
          .where((staff) => staff.category == 'leave')
          .toList() ??
      [];

  // Summary stats
  SummaryStats? get summaryStats => _staffData?.summaryStats;
  int get presentCount => summaryStats?.presentCount ?? 0;
  int get lateCount => summaryStats?.lateCount ?? 0;
  int get absentCount => summaryStats?.absentCount ?? 0;
  int get leaveCount => summaryStats?.leaveCount ?? 0;
  int get totalStaff => summaryStats?.totalStaff ?? 0;

  // Date info
  DateInfo? get dateInfo => _staffData?.dateInfo;
  String get formattedDate => dateInfo?.formattedDate ?? '';
  String get dayOfWeek => dateInfo?.dayOfWeek ?? '';

  // Filter options
  List<Branch> get branches => _staffData?.filterOptions.branches ?? [];
  List<Department> get departments =>
      _staffData?.filterOptions.departments ?? [];

  // Initialize
  void initialize() {
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    loadStaffListing();
  }

  // Load staff listing
  Future<void> loadStaffListing({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        _setLoading(true);
        _currentPage = 1;
      }
      _setError(null);

      print('Loading staff listing...');
      print(
        'Status: $_selectedStatus, Branch: $_selectedBranchId, Department: $_selectedDepartmentId',
      );
      print('Date: $_selectedDate, Page: $_currentPage');

      final response = await _repository.getStaffListing(
        status: _selectedStatus,
        branchId: _selectedBranchId,
        departmentId: _selectedDepartmentId,
        page: _currentPage,
        date: _selectedDate,
      );

      if (response.success) {
        if (loadMore && _staffData != null) {
          // Append new data for pagination
          final existingStaff = _staffData!.staffListing;
          final newStaff = response.data.staffListing;

          _staffData = StaffListingData(
            dateInfo: response.data.dateInfo,
            filterInfo: response.data.filterInfo,
            filterOptions: response.data.filterOptions,
            summaryStats: response.data.summaryStats,
            staffListing: [...existingStaff, ...newStaff],
            pagination: response.data.pagination,
          );
        } else {
          _staffData = response.data;
        }

        print('Successfully loaded staff listing');
        print('Total staff: ${_staffData!.summaryStats.totalStaff}');
        print(
          'Present: $presentCount, Late: $lateCount, Absent: $absentCount, Leave: $leaveCount',
        );
      } else {
        throw Exception('API returned success: false');
      }

      _setLoading(false);
    } catch (e) {
      print('Error in loadStaffListing: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Load more data (pagination)
  Future<void> loadMore() async {
    if (_staffData?.pagination.hasNext == true && !_isLoading) {
      _currentPage++;
      await loadStaffListing(loadMore: true);
    }
  }

  // Set filters and refresh
  Future<void> setStatusFilter(String status) async {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      await loadStaffListing();
    }
  }

  Future<void> setBranchFilter(String? branchId) async {
    if (_selectedBranchId != branchId) {
      _selectedBranchId = branchId;
      await loadStaffListing();
    }
  }

  Future<void> setDepartmentFilter(String? departmentId) async {
    if (_selectedDepartmentId != departmentId) {
      _selectedDepartmentId = departmentId;
      await loadStaffListing();
    }
  }

  Future<void> setDateFilter(String? date) async {
    if (_selectedDate != date) {
      _selectedDate = date;
      await loadStaffListing();
    }
  }

  // Clear filters
  Future<void> clearFilters() async {
    _selectedStatus = 'all';
    _selectedBranchId = null;
    _selectedDepartmentId = null;
    await loadStaffListing();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadStaffListing();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get branch name by ID
  String getBranchName(String? branchId) {
    if (branchId == null) return 'All Branches';
    final branch = branches.firstWhere(
      (b) => b.branchId == branchId,
      orElse:
          () => Branch(
            branchId: branchId,
            branchShortName: 'Unknown',
            branchFullName: 'Unknown',
          ),
    );
    return branch.branchFullName;
  }

  // Get department name by ID
  String getDepartmentName(String? departmentId) {
    if (departmentId == null) return 'All Departments';
    final department = departments.firstWhere(
      (d) => d.departmentId == departmentId,
      orElse:
          () =>
              Department(departmentId: departmentId, departmentName: 'Unknown'),
    );
    return department.departmentName;
  }
}
