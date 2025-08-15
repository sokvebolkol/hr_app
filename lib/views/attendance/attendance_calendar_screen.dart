import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/constant.dart';
import '../../viewmodels/attendance_calendar_viewmodel.dart';
import '../../models/attendance_calendar_model.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  State<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  late AttendanceCalendarViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AttendanceCalendarViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AttendanceCalendarViewModel>(
      create: (_) => _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Consumer<AttendanceCalendarViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(child: SpinKitFadingCircle(color: primary));
            }

            if (viewModel.errorMessage != null) {
              return _buildErrorState(viewModel);
            }

            return _buildMainContent(viewModel);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Attendance Report',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, primary.withOpacity(0.8)],
          ),
        ),
      ),
      actions: [
        Consumer<AttendanceCalendarViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed:
                  viewModel.isLoading
                      ? null
                      : () => viewModel.loadCurrentMonthAttendance(),
            );
          },
        ),
        Consumer<AttendanceCalendarViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: const Icon(Icons.date_range_rounded),
              onPressed: () => _showDateRangePicker(viewModel),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(AttendanceCalendarViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error Loading Report',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    viewModel.clearError();
                    viewModel.loadCurrentMonthAttendance();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(AttendanceCalendarViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.loadCurrentMonthAttendance(),
      color: primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildUserInfoHeader(viewModel)),
          SliverToBoxAdapter(child: _buildSummaryCards(viewModel)),
          SliverToBoxAdapter(child: _buildDateRangeHeader(viewModel)),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildAttendanceReportTable(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader(AttendanceCalendarViewModel viewModel) {
    final userInfo = viewModel.userInfo;
    if (userInfo == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 30,
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userInfo.username.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Employee ID: ${userInfo.employeeId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Staff ID: ${userInfo.staffId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AttendanceCalendarViewModel viewModel) {
    final summary = viewModel.summary;
    if (summary == null) return const SizedBox();

    final statusCounts = viewModel.getStatusCounts();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Monthly Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Present',
                  statusCounts['Present'].toString(),
                  Colors.green,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Absent',
                  statusCounts['Absent'].toString(),
                  Colors.red,
                  Icons.cancel_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Late',
                  statusCounts['Late'].toString(),
                  Colors.orange,
                  Icons.access_time_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'On Leave',
                  statusCounts['On Leave'].toString(),
                  Colors.blue,
                  Icons.beach_access_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withOpacity(0.1), primary.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${summary.attendanceRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeHeader(AttendanceCalendarViewModel viewModel) {
    final summary = viewModel.summary;
    if (summary == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, color: primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Report Period: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              '${DateFormat('MMM dd, yyyy').format(DateTime.parse(summary.dateRange.startDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(summary.dateRange.endDate))}',
              style: TextStyle(fontWeight: FontWeight.bold, color: primary),
            ),
          ),
          Text(
            '${summary.totalDays} days',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceReportTable(AttendanceCalendarViewModel viewModel) {
    final reports = viewModel.attendanceReports;

    if (reports.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No attendance data found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Attendance Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${reports.length} records',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

          // Table Content with proper constraints
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 2,
                  horizontalMargin: 16,
                  headingRowHeight: 50,
                  dataRowHeight: 65,
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primary,
                    fontSize: 11,
                  ),
                  columns: const [
                    DataColumn(
                      label: SizedBox(
                        width: 25,
                        child: Text('Date', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 65,
                        child: Text('Finger In', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 65,
                        child: Text('Finger Out', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 65,
                        child: Text('Clock In', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 65,
                        child: Text('Clock Out', textAlign: TextAlign.center),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 65,
                        child: Text('Status', textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                  rows: reports.map((report) => _buildDataRow(report)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(AttendanceReport report) {
    final statusColor = _viewModel.getStatusColor(report.status);

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 25,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  report.dayOfWeek.substring(0, 3),
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('dd').format(report.dateTime),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(report.dateTime),
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 65,
            child: _buildTimeCell(
              report.scanIn,
              Icons.fingerprint,
              Colors.green,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 65,
            child: _buildTimeCell(
              report.scanOut,
              Icons.fingerprint,
              Colors.red,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 65,
            child: _buildTimeCell(
              report.clockIn,
              Icons.login_rounded,
              Colors.blue,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 65,
            child: _buildTimeCell(
              report.clockOut,
              Icons.logout_rounded,
              Colors.orange,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 65,
            child: _buildStatusCell(report.status, statusColor),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCell(String? time, IconData icon, Color color) {
    if (time == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(height: 2),
          Text(
            'N/A',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusCell(String status, Color color) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_viewModel.getStatusIcon(status), size: 12, color: color),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(
    AttendanceCalendarViewModel viewModel,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await viewModel.loadAttendanceForDateRange(picked.start, picked.end);
    }
  }
}
