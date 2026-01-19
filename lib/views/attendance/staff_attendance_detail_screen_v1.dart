import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../models/staff_listing_model.dart';
import '../../viewmodels/staff_listing_viewmodel.dart';

class StaffAttendanceDetailScreen extends StatefulWidget {
  final bool isGettingTodayAttendance;

  const StaffAttendanceDetailScreen({
    super.key,
    this.isGettingTodayAttendance = false,
  });

  @override
  State<StaffAttendanceDetailScreen> createState() =>
      _StaffAttendanceDetailScreenState();
}

class _StaffAttendanceDetailScreenState
    extends State<StaffAttendanceDetailScreen>
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
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          centerTitle: false,
          title: Text(
            widget.isGettingTodayAttendance
                ? 'Today\'s Attendance'
                : 'Staff Attendance',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            // Only show filter button if not getting today's attendance
            if (!widget.isGettingTodayAttendance)
              IconButton(
                onPressed: _showFilters,
                icon: const Icon(Icons.filter_list),
              ),
          ],
        ),
        body: Consumer<StaffListingViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.staffData == null) {
              return const Center(child: SpinKitFadingCircle(color: secondary));
            }

            if (viewModel.errorMessage != null && viewModel.staffData == null) {
              return _buildErrorState(viewModel);
            }

            return Column(
              children: [
                if (!widget.isGettingTodayAttendance) ...[
                  _buildHeader(viewModel),
                ],
                _buildTabBar(viewModel),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStaffList(viewModel.presentStaff, 'present'),
                      _buildStaffList(viewModel.leaveStaff, 'leave'),
                      _buildStaffList(viewModel.lateStaff, 'late'),
                      _buildStaffList(viewModel.absentStaff, 'absent'),
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
                backgroundColor: secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(StaffListingViewModel viewModel) {
    return Container(
      color: Colors.white,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black87,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          tabs: [
            Tab(
              height: 40,
              child: _buildTabWithBadge('Present', viewModel.presentCount),
            ),
            Tab(
              height: 40,
              child: _buildTabWithBadge('Leave', viewModel.leaveCount),
            ),
            Tab(
              height: 40,
              child: _buildTabWithBadge('Late', viewModel.lateCount),
            ),
            Tab(
              height: 40,
              child: _buildTabWithBadge('Absent', viewModel.absentCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StaffListingViewModel viewModel) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_sharp, color: secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.isGettingTodayAttendance
                    ? 'Today - ${viewModel.dayOfWeek}'
                    : '${viewModel.selectedDate != null ? DateFormat('MMM dd, yyyy').format(DateFormat('yyyy-MM-dd').parse(viewModel.selectedDate!)) : viewModel.formattedDate} - ${viewModel.dayOfWeek}',
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
          Row(
            children: [
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
                  'Late',
                  viewModel.lateCount,
                  Colors.blueGrey,
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

  Widget _buildTabWithBadge(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
      child: Column(
        children: [
          // Only show table header for non-leave categories
          if (category != 'leave') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  // Name column header (50%)
                  Expanded(
                    flex: 50,
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Clock In header (25%)
                  Expanded(
                    flex: 25,
                    child: Text(
                      'Clock In',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Vertical divider line
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // Clock Out header (25%)
                  Expanded(
                    flex: 25,
                    child: Text(
                      'Clock Out',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Staff list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(category == 'leave' ? 16 : 8),
              itemCount: staff.length + (_viewModel.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == staff.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: SpinKitCircle(color: secondary, size: 50.0),
                    ),
                  );
                }
                // Use different card layouts based on category
                if (category == 'leave') {
                  return _buildLeaveCard(staff[index]);
                } else {
                  return _buildStaffCard(staff[index]);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    Map<String, Map<String, dynamic>> categoryInfo = {
      'present': {
        'icon': Icons.check_circle_outline,
        'title': 'No Present Staff',
        'subtitle':
            widget.isGettingTodayAttendance
                ? 'No staff members are marked as present today'
                : 'No staff members are marked as present for this date',
        'color': Colors.green,
      },
      'leave': {
        'icon': Icons.beach_access_outlined,
        'title': 'No Staff on Leave',
        'subtitle':
            widget.isGettingTodayAttendance
                ? 'No staff members are on leave today'
                : 'No staff members are on leave for this date',
        'color': Colors.orange,
      },
      'late': {
        'icon': Icons.access_time_outlined,
        'title': 'No Late Staff',
        'subtitle':
            widget.isGettingTodayAttendance
                ? 'No staff members were late today'
                : 'No staff members were late for this date',
        'color': const Color.fromRGBO(255, 193, 7, 1),
      },
      'absent': {
        'icon': Icons.cancel_outlined,
        'title': 'No Absent Staff',
        'subtitle':
            widget.isGettingTodayAttendance
                ? 'No staff members are marked as absent today'
                : 'No staff members are marked as absent for this date',
        'color': Colors.red,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            // Main row with name, times (Branch column removed)
            Row(
              children: [
                // Name column (50%) - Increased width
                Expanded(
                  flex: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staff.positionName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Branch moved under position
                      const SizedBox(height: 2),
                      Text(
                        _getBranchShortName(staff.branchFullName),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Clock In column (25%) - Increased width
                Expanded(
                  flex: 25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _getClockInTime(staff),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              _getClockInTime(staff) != '--'
                                  ? Colors.green[700]
                                  : Colors.grey[500],
                        ),
                      ),
                      Text(
                        'Clock In',
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),

                // Vertical divider line
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // Clock Out column (25%) - Increased width
                Expanded(
                  flex: 25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _getClockOutTime(staff),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              _getClockOutTime(staff) != '--'
                                  ? Colors.red[700]
                                  : Colors.grey[500],
                        ),
                      ),
                      Text(
                        'Clock Out',
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Additional info for leave/absent staff
            if (staff.category == 'leave' && staff.leaveDetails != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${staff.leaveDetails!.leaveType} • ${staff.leaveDetails!.totalDays.toString().split('.')[0]} day${double.parse(staff.leaveDetails!.totalDays.toString()) > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (staff.category == 'absent') ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        staff.statusDetail,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: secondary.withOpacity(0.3)),
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

  // Helper methods
  String _getClockInTime(StaffMember staff) {
    if (staff.category == 'present' || staff.category == 'late') {
      if (staff.attendanceDetails.checkIn != null) {
        return _formatTime(staff.attendanceDetails.checkIn!);
      }
    }
    return '--';
  }

  String _getClockOutTime(StaffMember staff) {
    if (staff.category == 'present' || staff.category == 'late') {
      if (staff.attendanceDetails.checkOut != null) {
        return _formatTime(staff.attendanceDetails.checkOut!);
      }
    }
    return '--';
  }

  String _formatTime(String timeString) {
    try {
      // Parse the time string and format to 12-hour format
      DateTime time = DateFormat('HH:mm:ss').parse(timeString);
      return DateFormat('hh:mm a').format(time).toUpperCase();
    } catch (e) {
      // If parsing fails, return the original string
      return timeString;
    }
  }

  String _getBranchShortName(String fullBranchName) {
    // Convert "Head Office" to "Head office", etc.
    if (fullBranchName.toLowerCase().contains('head office')) {
      return 'Head office';
    }
    // For other branches, return first 10 characters
    if (fullBranchName.length > 15) {
      return '${fullBranchName.substring(0, 15)}...';
    }
    return fullBranchName;
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
                            initialDate:
                                viewModel.selectedDate != null
                                    ? DateFormat(
                                      'yyyy-MM-dd',
                                    ).parse(viewModel.selectedDate!)
                                    : DateTime.now(),
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
                              Text(
                                viewModel.selectedDate != null
                                    ? DateFormat('MMM dd, yyyy').format(
                                      DateFormat(
                                        'yyyy-MM-dd',
                                      ).parse(viewModel.selectedDate!),
                                    )
                                    : 'Select Date',
                              ),
                              const Icon(Icons.calendar_month_outlined),
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
                                backgroundColor: secondary,
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

  Widget _buildLeaveCard(StaffMember staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with employee info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  radius: 24,
                  child: Text(
                    staff.fullName.isNotEmpty
                        ? staff.fullName[0].toUpperCase()
                        : 'S',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
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
                          color: Colors.black87,
                        ),
                      ),
                      // Text(
                      //   'ID: ${staff.staffId}',
                      //   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      // ),
                      const SizedBox(height: 2),
                      Text(
                        staff.positionName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getBranchShortName(staff.branchFullName),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'On Leave',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Leave details section
            if (staff.leaveDetails != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
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
                        Icon(
                          Icons.beach_access,
                          color: Colors.orange[700],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Leave Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Leave type
                    _buildLeaveInfoRow(
                      Icons.category_outlined,
                      'Leave Type',
                      staff.leaveDetails!.leaveType,
                    ),

                    const SizedBox(height: 8),

                    // Duration
                    _buildLeaveInfoRow(
                      Icons.schedule_outlined,
                      'Duration',
                      '${double.parse(staff.leaveDetails!.totalDays) % 1 == 0 ? double.parse(staff.leaveDetails!.totalDays).toInt() : double.parse(staff.leaveDetails!.totalDays)} day${double.parse(staff.leaveDetails!.totalDays) == 1 ? '' : 's'}',
                    ),

                    const SizedBox(height: 8),

                    // Leave period
                    _buildLeaveInfoRow(
                      Icons.date_range_outlined,
                      'Period',
                      '${DateFormat('MMM dd, yyyy').format(DateTime.parse(staff.leaveDetails!.startDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(staff.leaveDetails!.endDate))}',
                    ),

                    // Reason (if available)
                    if (staff.leaveDetails!.reason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildLeaveInfoRow(
                        Icons.description_outlined,
                        'Reason',
                        staff.leaveDetails!.reason,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.orange[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
