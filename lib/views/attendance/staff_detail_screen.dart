import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../models/staff_listing_model.dart';
import '../../viewmodels/staff_listing_viewmodel.dart';

class StaffDetailScreen extends StatefulWidget {
  const StaffDetailScreen({super.key});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late StaffListingViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _viewModel = StaffListingViewModel();
    _viewModel.initialize();

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _viewModel.loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          centerTitle: false,
          title: const Text(
            'Staff Attendance ',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              onPressed: _showFilters,
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ),
        body: Consumer<StaffListingViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.staffData == null) {
              return const Center(child: SpinKitFadingCircle(color: primary));
            }

            if (viewModel.errorMessage != null && viewModel.staffData == null) {
              return _buildErrorState(viewModel);
            }

            return Column(
              children: [
                _buildHeader(viewModel),
                _buildTabBar(viewModel),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStaffList(viewModel.presentStaff, 'present'),
                      _buildStaffList(viewModel.leaveStaff, 'leave'),
                      _buildStaffList(viewModel.absentStaff, 'absent'),
                      _buildStaffList(viewModel.lateStaff, 'late'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(StaffListingViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => viewModel.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StaffListingViewModel viewModel) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '${viewModel.formattedDate} - ${viewModel.dayOfWeek}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (viewModel.dateInfo?.isHoliday == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Holiday: ${viewModel.dateInfo!.holidayName}',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (viewModel.dateInfo?.isWeekend == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.weekend, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Weekend',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Summary stats
          Row(
            children: [
              // Expanded(
              //   child: _buildStatCard(
              //     'Total',
              //     viewModel.totalStaff,
              //     Colors.blue,
              //   ),
              // ),
              // const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Present',
                  viewModel.presentCount,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Leave',
                  viewModel.leaveCount,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Absent',
                  viewModel.absentCount,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(StaffListingViewModel viewModel) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 11,
        ),
        isScrollable: false,
        tabs: [
          Tab(child: _buildTabWithBadge('Present', viewModel.presentCount)),
          Tab(child: _buildTabWithBadge('Leave', viewModel.leaveCount)),
          Tab(child: _buildTabWithBadge('Absent', viewModel.absentCount)),
          Tab(child: _buildTabWithBadge('Late', viewModel.lateCount)),
        ],
      ),
    );
  }

  Widget _buildTabWithBadge(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffList(List<StaffMember> staff, String category) {
    if (staff.isEmpty) {
      return _buildEmptyState(category);
    }

    return RefreshIndicator(
      onRefresh: () => _viewModel.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: staff.length + (_viewModel.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == staff.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: primary),
              ),
            );
          }
          return _buildStaffCard(staff[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    Map<String, Map<String, dynamic>> categoryInfo = {
      'present': {
        'icon': Icons.check_circle_outline,
        'title': 'No Present Staff',
        'subtitle': 'No staff members are marked as present for this date',
        'color': Colors.green,
      },
      'leave': {
        'icon': Icons.beach_access_outlined,
        'title': 'No Staff on Leave',
        'subtitle': 'No staff members are on leave for this date',
        'color': Colors.orange,
      },
      'absent': {
        'icon': Icons.cancel_outlined,
        'title': 'No Absent Staff',
        'subtitle': 'No staff members are marked as absent for this date',
        'color': Colors.red,
      },
      'late': {
        'icon': Icons.access_time_outlined,
        'title': 'No Late Staff',
        'subtitle': 'No staff members were late for this date',
        'color': Colors.amber,
      },
    };

    final info = categoryInfo[category] ?? categoryInfo['present']!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(info['icon'], size: 64, color: info['color'].withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              info['title'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info['subtitle'],
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffMember staff) {
    Color statusColor = _getStatusColor(staff.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  radius: 24,
                  child: Text(
                    staff.fullName.isNotEmpty
                        ? staff.fullName[0].toUpperCase()
                        : 'S',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${staff.staffId}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    staff.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Employee details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.work_outline,
                    'Position',
                    staff.positionName,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.business_outlined,
                    'Department',
                    staff.departmentName,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'Branch',
                    staff.branchFullName,
                  ),
                  if (staff.email != null && staff.email!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.email_outlined,
                      'Email',
                      staff.email!,
                    ),
                  ],
                ],
              ),
            ),

            // Status details
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                staff.statusDetail,
                style: TextStyle(
                  color: statusColor.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Attendance details for present/late staff
            if (staff.category == 'present' || staff.category == 'late') ...[
              if (staff.attendanceDetails.clockIn != null ||
                  staff.attendanceDetails.clockOut != null) ...[
                const SizedBox(height: 12),
                _buildAttendanceDetails(staff.attendanceDetails),
              ],
            ],

            // Leave details for staff on leave
            if (staff.category == 'leave' && staff.leaveDetails != null) ...[
              const SizedBox(height: 12),
              _buildLeaveDetails(staff.leaveDetails!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceDetails(AttendanceDetails attendance) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.green[700], size: 16),
              const SizedBox(width: 6),
              Text(
                'Attendance Times',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (attendance.clockIn != null) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clock In',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[600],
                        ),
                      ),
                      Text(
                        attendance.clockIn!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (attendance.clockOut != null) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clock Out',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[600],
                        ),
                      ),
                      Text(
                        attendance.clockOut!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (attendance.workingHours != null) ...[
            const SizedBox(height: 6),
            Text(
              'Working Hours: ${attendance.workingHours}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaveDetails(LeaveDetails leave) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.beach_access, color: Colors.orange[700], size: 16),
              const SizedBox(width: 6),
              Text(
                'Leave Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${leave.leaveType}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (leave.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: ${leave.reason}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Duration: ${leave.totalDays} days',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Period: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(leave.startDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(leave.endDate))}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String category) {
    switch (category) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.amber[700]!;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ChangeNotifierProvider.value(
            value: _viewModel,
            child: Consumer<StaffListingViewModel>(
              builder: (context, viewModel, child) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Date Filter
                      const Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            viewModel.setDateFilter(
                              DateFormat('yyyy-MM-dd').format(date),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(viewModel.selectedDate ?? 'Select Date'),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Branch Filter
                      if (viewModel.branches.isNotEmpty) ...[
                        const Text(
                          'Branch',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: viewModel.selectedBranchId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          hint: const Text('All Branches'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Branches'),
                            ),
                            ...viewModel.branches.map(
                              (branch) => DropdownMenuItem(
                                value: branch.branchId,
                                child: Text(branch.branchFullName),
                              ),
                            ),
                          ],
                          onChanged:
                              (value) => viewModel.setBranchFilter(value),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Department Filter
                      if (viewModel.departments.isNotEmpty) ...[
                        const Text(
                          'Department',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: viewModel.selectedDepartmentId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          hint: const Text('All Departments'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Departments'),
                            ),
                            ...viewModel.departments.map(
                              (dept) => DropdownMenuItem(
                                value: dept.departmentId,
                                child: Text(dept.departmentName),
                              ),
                            ),
                          ],
                          onChanged:
                              (value) => viewModel.setDepartmentFilter(value),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                viewModel.clearFilters();
                                Navigator.pop(context);
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }
}
