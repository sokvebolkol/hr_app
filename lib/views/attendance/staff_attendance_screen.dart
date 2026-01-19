import 'package:chokchey_hr_app/widgets/date_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../models/attendance_by_department_model.dart';
import '../../viewmodels/attendance_by_department_viewmodel.dart';
import 'department_attendance_detail_screen.dart';

class StaffAttendanceScreen extends StatefulWidget {
  final bool isTodayAttendance;
  const StaffAttendanceScreen({super.key, this.isTodayAttendance = false});

  @override
  State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {
  late AttendanceByDepartmentViewModel _viewModel;
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
    _initializeLanguage();
    _viewModel = AttendanceByDepartmentViewModel();
    _viewModel.initialize();
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          !widget.isTodayAttendance
              ? language.todaysAttendance
              : language.staffAttendance,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          if (_viewModel.isLoading) {
            return const Center(
              child: SpinKitCircle(color: secondary, size: 50.0),
            );
          }

          if (_viewModel.errorMessage != null) {
            return _buildErrorState();
          }

          if (_viewModel.attendanceData == null) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildOverallSummary(),
              _buildTableHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _selectedDateRange = null;
                    });
                    await _viewModel.refresh();
                  },
                  color: secondary,
                  child: _buildDepartmentTable(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverallSummary() {
    final summary = _viewModel.overallSummary;
    if (summary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.isTodayAttendance
              ? Text(
                language.overallSummary,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              )
              : DateSection(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  language.present,
                  summary.totalPresentOccurrences,
                  Colors.green[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  language.late,
                  summary.totalLateOccurrences,
                  Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  language.leave,
                  summary.totalLeaveOccurrences,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  language.absent,
                  summary.totalAbsentOccurrences,
                  Colors.red[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
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

  Widget _buildTableHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          widget.isTodayAttendance
              ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _showDateRangePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
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
              )
              : const SizedBox(),
          const SizedBox(height: 12),
          // Column headers
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  language.deptBranch,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    language.leave,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    language.absent,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    language.late,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildDepartmentTable() {
    final departments = _viewModel.departments;

    if (departments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              language.noDepartmentsFound,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: departments.length,
      separatorBuilder:
          (context, index) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final dept = departments[index];
        return _buildDepartmentRow(dept);
      },
    );
  }

  Widget _buildDepartmentRow(Department dept) {
    return InkWell(
      onTap: () async {
        final newDateRange = await Navigator.push<DateTimeRange>(
          context,
          MaterialPageRoute(
            builder:
                (context) => DepartmentAttendanceDetailScreen(
                  department: dept,
                  selectedDateRange: _selectedDateRange,
                  viewModel: _viewModel,
                  isTodayAttendance: widget.isTodayAttendance,
                ),
          ),
        );

        // If a new date range was returned, update and refetch data
        if (newDateRange != null && newDateRange != _selectedDateRange) {
          setState(() {
            _selectedDateRange = newDateRange;
          });
          final formatter = DateFormat('yyyy-MM-dd');
          await _viewModel.fetchAttendanceByDepartment(
            startDate: formatter.format(newDateRange.start),
            endDate: formatter.format(newDateRange.end),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '${dept.departmentName} (${dept.totalEmployees})',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '${dept.attendanceCounts.leave}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        dept.attendanceCounts.leave > 0
                            ? Colors.green[700]
                            : Colors.grey[400],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '${dept.attendanceCounts.absent}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        dept.attendanceCounts.absent > 0
                            ? Colors.red[700]
                            : Colors.grey[400],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '${dept.attendanceCounts.late}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        dept.attendanceCounts.late > 0
                            ? Colors.orange[700]
                            : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    DateTimeRange tempDateRange =
        _selectedDateRange ?? DateTimeRange(start: now, end: now);
    bool isSelectingStart = true;

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
                            // ignore: deprecated_member_use
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
                                // ignore: deprecated_member_use
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
                                    child: _buildClickableDateCard(
                                      language.startDate,
                                      tempDateRange.start,
                                      Icons.event_available,
                                      secondary,
                                      isSelectingStart,
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
                                    child: _buildClickableDateCard(
                                      language.endDate,
                                      tempDateRange.end,
                                      Icons.event_busy,
                                      logoPink,
                                      !isSelectingStart,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildQuickSelectChip(language.last7Days, () {
                                  setDialogState(() {
                                    tempDateRange = DateTimeRange(
                                      start: now.subtract(
                                        const Duration(days: 6),
                                      ),
                                      end: now,
                                    );
                                  });
                                }),
                                _buildQuickSelectChip(language.last30Days, () {
                                  setDialogState(() {
                                    tempDateRange = DateTimeRange(
                                      start: now.subtract(
                                        const Duration(days: 29),
                                      ),
                                      end: now,
                                    );
                                  });
                                }),
                                _buildQuickSelectChip(language.thisMonth, () {
                                  setDialogState(() {
                                    tempDateRange = DateTimeRange(
                                      start: DateTime(now.year, now.month, 1),
                                      end: now,
                                    );
                                  });
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: secondary,
                            onPrimary: primary,
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
                          firstDate: DateTime(2020),
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
                                child: Text(
                                  language.cancel,
                                  style: const TextStyle(
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
                                  Navigator.pop(context);
                                  setState(() {
                                    _selectedDateRange = tempDateRange;
                                  });
                                  // Fetch data with selected date range
                                  final formatter = DateFormat('yyyy-MM-dd');
                                  await _viewModel.fetchAttendanceByDepartment(
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      language.apply,
                                      style: const TextStyle(
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

  Widget _buildClickableDateCard(
    String label,
    DateTime date,
    IconData icon,
    Color color,
    bool isActive,
  ) {
    final formatter = DateFormat('MMM dd, yyyy');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : color.withOpacity(0.3),
          width: isActive ? 1 : 0.5,
        ),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              if (isActive) Icon(Icons.check_circle, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(date),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelectChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              language.errorLoadingData,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _viewModel.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _viewModel.refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(language.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No attendance data found',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
