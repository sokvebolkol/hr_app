import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../models/attendance_by_department_model.dart';
import '../../viewmodels/attendance_by_department_viewmodel.dart';
import '../../widgets/clickable_date_card_widget.dart';

class DepartmentAttendanceDetailScreen extends StatefulWidget {
  final Department department;
  final DateTimeRange? selectedDateRange;
  final AttendanceByDepartmentViewModel viewModel;
  final bool isTodayAttendance;

  const DepartmentAttendanceDetailScreen({
    super.key,
    required this.department,
    this.selectedDateRange,
    required this.viewModel,
    this.isTodayAttendance = false,
  });

  @override
  State<DepartmentAttendanceDetailScreen> createState() =>
      _DepartmentAttendanceDetailScreenState();
}

class _DepartmentAttendanceDetailScreenState
    extends State<DepartmentAttendanceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;

  Language language = Language();

  String get _dateRangeText {
    if (_selectedDateRange == null) {
      return language.today;
    }
    final formatter = DateFormat('MMM dd');
    return '${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedDateRange = widget.selectedDateRange;
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update tab colors
    });
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
      });
    }
  }

  // Get the current department data from viewModel (in case it was updated)
  Department get currentDepartment {
    final updatedDept = widget.viewModel.departments.firstWhere(
      (dept) => dept.departmentId == widget.department.departmentId,
      orElse: () => widget.department,
    );
    return updatedDept;
  }

  // Get tab color based on index
  Color _getTabColor(int index) {
    switch (index) {
      case 0: // Leave
        return Colors.orange[700]!;
      case 1: // Absent
        return Colors.red[700]!;
      case 2: // Late
        return Colors.yellow[700]!;
      case 3: // Present
        return Colors.green[700]!;
      default:
        return secondary;
    }
  }

  // Get translated status name
  String _getStatusName(String status) {
    switch (status) {
      case 'Leave':
        return language.leave;
      case 'Absent':
        return language.absent;
      case 'Late':
        return language.late;
      case 'Present':
        return language.present;
      default:
        return status;
    }
  }

  // Get icon based on status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Leave':
        return Icons.beach_access_rounded;
      case 'Absent':
        return Icons.person_off_rounded;
      case 'Late':
        return Icons.schedule_rounded;
      case 'Present':
        return Icons.check_circle_rounded;
      default:
        return Icons.people_rounded;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<StaffMember> _getFilteredStaff(String status) {
    switch (status) {
      case 'Leave':
        return currentDepartment.staffMembers
            .where((staff) => staff.leaveCount > 0)
            .toList();
      case 'Absent':
        return currentDepartment.staffMembers
            .where((staff) => staff.absentCount > 0)
            .toList();
      case 'Late':
        // Show all staff who have at least one late record (for per-day filtering)
        return currentDepartment.staffMembers
            .where((staff) => staff.dailyRecords.any((r) => r.isLate == true))
            .toList();
      case 'Present':
        // Show all staff (including late staff), but remove those with all daily records having both clockIn and clockOut null
        return currentDepartment.staffMembers
            .where(
              (staff) => staff.dailyRecords.any(
                (r) => r.clockIn != null || r.clockOut != null,
              ),
            )
            .toList();
      default:
        return currentDepartment.staffMembers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return the selected date range when navigating back
        Navigator.pop(context, _selectedDateRange);
        return false;
      },
      child: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: secondary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, _selectedDateRange),
              ),
              title: Text(
                currentDepartment.departmentName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: secondaryAvatarBackground,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: _getTabColor(_tabController.index),
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
                        Tab(text: language.leave),
                        Tab(text: language.absent),
                        Tab(text: language.late),
                        Tab(text: language.present),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (widget.isTodayAttendance) _buildFilterSection(),
                  Expanded(
                    child:
                        widget.viewModel.isLoading
                            ? const Center(
                              child: SpinKitCircle(
                                color: secondary,
                                size: 50.0,
                              ),
                            )
                            : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildStaffList('Leave'),
                                _buildStaffList('Absent'),
                                _buildStaffList('Late'),
                                _buildStaffList('Present'),
                              ],
                            ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _showDateRangePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _dateRangeText,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList(String status) {
    final staffList = _getFilteredStaff(status);

    if (staffList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getTabColor(_tabController.index).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status),
                size: 64,
                color: _getTabColor(_tabController.index).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No ${_getStatusName(status)} ${language.staff}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no staff members with\n${_getStatusName(status)} status for the selected date range',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTableHeader(status),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: staffList.length,
            separatorBuilder:
                (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return _buildStaffRow(staff, status);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String status) {
    final bool showClockColumns = status != 'Leave' && status != 'Absent';
    final bool showTotalColumn = status != 'Present';

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              language.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          if (showClockColumns)
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  language.clockIn,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (showClockColumns)
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  language.clockOut,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                language.office,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (showTotalColumn)
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  language.total,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Returns the date records relevant to display for a given status tab.
  List<DailyRecord> _getDisplayRecords(StaffMember staff, String status) {
    switch (status) {
      case 'Leave':
        // Prefer the API's own type field; fall back to the leaveCount-limited
        // slice of null-clock records when the field is absent.
        final leaveByType =
            staff.dailyRecords
                .where((r) => r.attendanceType == 'leave')
                .toList();
        if (leaveByType.isNotEmpty) return leaveByType;
        // Fallback: take only as many null-clock records as leaveCount indicates
        final nullRecords =
            staff.dailyRecords
                .where((r) => r.clockIn == null && r.clockOut == null)
                .toList();
        return nullRecords.take(staff.leaveCount).toList();
      case 'Absent':
        final absentByType =
            staff.dailyRecords
                .where((r) => r.attendanceType == 'absent')
                .toList();
        if (absentByType.isNotEmpty) return absentByType;
        final nullRecs =
            staff.dailyRecords
                .where((r) => r.clockIn == null && r.clockOut == null)
                .toList();
        return nullRecs.take(staff.absentCount).toList();
      case 'Late':
        return staff.dailyRecords.where((r) => r.isLate == true).toList();
      case 'Present':
        return staff.dailyRecords
            .where((r) => r.clockIn != null || r.clockOut != null)
            .toList();
      default:
        return staff.dailyRecords;
    }
  }

  /// A single indented date sub-row shown beneath an employee header row.
  Widget _buildDateSubRow(DailyRecord record, String status) {
    final bool isLate = record.isLate ?? false;
    final bool showClock = status == 'Late' || status == 'Present';
    final bool showTotalSpacer = status != 'Present';

    final Color dotColor =
        status == 'Leave'
            ? Colors.orange[400]!
            : status == 'Absent'
            ? Colors.red[300]!
            : isLate
            ? Colors.red[700]!
            : Colors.green[500]!;
    final Color timeColor = isLate ? Colors.yellow : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(top: 3, left: 8, bottom: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  _formatRecordDate(record.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (showClock) ...[
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  _formatTime(record.clockIn),
                  style: TextStyle(
                    fontSize: 12,
                    color: timeColor,
                    fontWeight: isLate ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  _formatTime(record.clockOut),
                  style: TextStyle(
                    fontSize: 12,
                    color: timeColor,
                    fontWeight: isLate ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ] else ...[
            const Expanded(flex: 1, child: SizedBox()),
            const Expanded(flex: 1, child: SizedBox()),
          ],
          const Expanded(flex: 1, child: SizedBox()),
          if (showTotalSpacer) const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildStaffRow(StaffMember staff, String status) {
    final bool showClockColumns = status != 'Leave' && status != 'Absent';
    final bool showTotalColumn = status != 'Present';
    final int totalCount = _getTotalCount(staff, status);

    final List<DailyRecord> allRecords = _getDisplayRecords(staff, status);
    if (allRecords.isEmpty) return const SizedBox();

    // Leave/Absent: no inline date rows (summary only on tap).
    // Present: show only the most-recent date inline; rest shown in bottom sheet.
    // Late: show all inline.
    final List<DailyRecord> inlineRecords =
        (status == 'Leave' || status == 'Absent')
            ? []
            : status == 'Present'
            ? [allRecords.last]
            : allRecords;

    return InkWell(
      onTap: () => _showStaffDetailBottomSheet(staff, allRecords, status),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee header row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staff.positionName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (showClockColumns) ...[
                  const Expanded(flex: 1, child: SizedBox()),
                  const Expanded(flex: 1, child: SizedBox()),
                ],
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      staff.branchShortName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                if (showTotalColumn)
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        totalCount.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Per-day sub-rows
            if (inlineRecords.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...inlineRecords.map((r) => _buildDateSubRow(r, status)),
            ],
            // Hint for Present when more records exist
            if (status == 'Present' && allRecords.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 14),
                child: Row(
                  children: [
                    Icon(Icons.expand_more, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      '${allRecords.length - 1} more'
                      ' date${allRecords.length > 2 ? "s" : ""}'
                      ' \u2022 tap to view all',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getTotalCount(StaffMember staff, String status) {
    switch (status) {
      case 'Leave':
        return staff.leaveCount;
      case 'Absent':
        return staff.absentCount;
      case 'Late':
        return staff.lateCount;
      case 'Present':
        return staff.dailyRecords
            .where((r) => r.clockIn != null || r.clockOut != null)
            .length;
      default:
        return staff.dailyRecords.length;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    try {
      // API returns HH:mm format, convertToAmPm expects HH:mm:ss
      String timeWithSeconds = time.length == 5 ? '$time:00' : time;
      return convertToAmPm(timeWithSeconds);
    } catch (e) {
      return '--:--';
    }
  }

  String _formatRecordDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM dd').format(dt);
    } catch (_) {
      return date;
    }
  }

  String _formatRecordDateFull(String date) {
    if (date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('EEEE, MMM dd, yyyy').format(dt);
    } catch (_) {
      return date;
    }
  }

  void _showStaffDetailBottomSheet(
    StaffMember staff,
    List<DailyRecord> records,
    String status,
  ) {
    final Color statusColor = _getTabColor(_tabController.index);
    const Color lateColor = Color(0xFFF59E0B); // amber-500
    const Color lateColorDark = Color(0xFFB45309); // amber-700
    const Color lateBg = Color(0xFFFFFBEB); // amber-50
    final bool showClock = status != 'Leave' && status != 'Absent';
    final int totalCount = _getTotalCount(staff, status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // ── Drag handle ──────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── Coloured header band ─────────────────────────────────
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              staff.fullName.isNotEmpty
                                  ? staff.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Name / position / branch
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                staff.positionName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 11,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    staff.branchFullName.isNotEmpty
                                        ? staff.branchFullName
                                        : staff.branchShortName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Count pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totalCount.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getStatusName(status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Column headers ───────────────────────────────────────
                  if (records.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              language.date,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[600],
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (showClock) ...[
                            SizedBox(
                              width: 64,
                              child: Center(
                                child: Text(
                                  language.clockIn,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: Center(
                                child: Text(
                                  language.clockOut,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 4),

                  // ── Records list ─────────────────────────────────────────
                  Expanded(
                    child:
                        records.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(status),
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    language.noAttendanceRecordsFound,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                24 + MediaQuery.of(context).padding.bottom,
                              ),
                              itemCount: records.length,
                              itemBuilder: (context, index) {
                                final record = records[index];
                                final bool isLate = record.isLate ?? false;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isLate && showClock
                                            ? lateBg
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isLate && showClock
                                              ? lateColor.withOpacity(0.35)
                                              : Colors.grey[200]!,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Coloured left bar
                                      Container(
                                        width: 4,
                                        height: 40,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isLate && showClock
                                                  ? lateColor
                                                  : statusColor,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      // Date + optional late badge
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatRecordDateFull(
                                                record.date,
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                                height: 1.3,
                                              ),
                                            ),
                                            if (isLate && showClock) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: lateColor.withOpacity(
                                                    0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: lateColor
                                                        .withOpacity(0.4),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.schedule_rounded,
                                                      size: 10,
                                                      color: lateColorDark,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      language.late,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: lateColorDark,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Clock In / Out
                                      if (showClock) ...[
                                        SizedBox(
                                          width: 64,
                                          child: Column(
                                            children: [
                                              Text(
                                                _formatTime(record.clockIn),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      isLate
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                  color:
                                                      isLate
                                                          ? lateColorDark
                                                          : Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 64,
                                          child: Text(
                                            _formatTime(record.clockOut),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    DateTimeRange tempDateRange =
        _selectedDateRange ?? DateTimeRange(start: now, end: now);
    bool isSelectingStart = true;
    String? selectedChip;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with gradient
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [secondary, secondary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language.selectDateRange,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    language.chooseYourDesiredDateRange,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        isSelectingStart = true;
                                      });
                                    },
                                    child: ClickableDateCard(
                                      label: language.startDate,
                                      date: tempDateRange.start,
                                      icon: Icons.event_available,
                                      color: secondary,
                                      isActive: isSelectingStart,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        isSelectingStart = false;
                                      });
                                    },
                                    child: ClickableDateCard(
                                      label: language.endDate,
                                      date: tempDateRange.end,
                                      icon: Icons.event_busy,
                                      color: logoPink,
                                      isActive: !isSelectingStart,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildQuickSelectChip(
                                  'Last 7 Days',
                                  isSelected: selectedChip == 'Last 7 Days',
                                  () {
                                    setDialogState(() {
                                      selectedChip = 'Last 7 Days';
                                      tempDateRange = DateTimeRange(
                                        start: now.subtract(
                                          const Duration(days: 6),
                                        ),
                                        end: now,
                                      );
                                    });
                                  },
                                ),
                                _buildQuickSelectChip(
                                  'Last 30 Days',
                                  isSelected: selectedChip == 'Last 30 Days',
                                  () {
                                    setDialogState(() {
                                      selectedChip = 'Last 30 Days';
                                      tempDateRange = DateTimeRange(
                                        start: now.subtract(
                                          const Duration(days: 29),
                                        ),
                                        end: now,
                                      );
                                    });
                                  },
                                ),
                                _buildQuickSelectChip(
                                  'This Month',
                                  isSelected: selectedChip == 'This Month',
                                  () {
                                    setDialogState(() {
                                      selectedChip = 'This Month';
                                      tempDateRange = DateTimeRange(
                                        start: DateTime(now.year, now.month, 1),
                                        end: now,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Calendar
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: secondary,
                            onPrimary: Colors.white,
                            onSurface: Colors.black87,
                            surface: Colors.white,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: secondary,
                            ),
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate:
                              isSelectingStart
                                  ? tempDateRange.start
                                  : tempDateRange.end,
                          firstDate: DateTime(
                            DateTime.now().year - 1,
                            DateTime.now().month,
                            DateTime.now().day,
                          ),
                          lastDate: DateTime.now(),
                          onDateChanged: (date) {
                            setDialogState(() {
                              if (isSelectingStart) {
                                // Setting start date
                                if (date.isAfter(tempDateRange.end)) {
                                  // If selected start date is after end date, set both to the same
                                  tempDateRange = DateTimeRange(
                                    start: date,
                                    end: date,
                                  );
                                } else {
                                  tempDateRange = DateTimeRange(
                                    start: date,
                                    end: tempDateRange.end,
                                  );
                                }
                                isSelectingStart = false; // Now select end date
                              } else {
                                // Setting end date
                                if (date.isBefore(tempDateRange.start)) {
                                  // If selected end date is before start date, swap them
                                  tempDateRange = DateTimeRange(
                                    start: date,
                                    end: tempDateRange.start,
                                  );
                                } else {
                                  tempDateRange = DateTimeRange(
                                    start: tempDateRange.start,
                                    end: date,
                                  );
                                }
                                isSelectingStart =
                                    true; // Reset to select start date for next time
                              }
                            });
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Close the dialog
                                  Navigator.pop(context);
                                  // Update the local state
                                  setState(() {
                                    _selectedDateRange = tempDateRange;
                                  });
                                  // Fetch updated data with new date range
                                  final formatter = DateFormat('yyyy-MM-dd');
                                  await widget.viewModel
                                      .fetchAttendanceByDepartment(
                                        startDate: formatter.format(
                                          tempDateRange.start,
                                        ),
                                        endDate: formatter.format(
                                          tempDateRange.end,
                                        ),
                                      );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Apply',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickSelectChip(
    String label,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? secondary : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? secondary : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
