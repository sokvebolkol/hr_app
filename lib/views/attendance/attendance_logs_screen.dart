import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
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
  late Language language;

  // Currently selected period filter chip.
  String _selectedPeriod = 'this_month';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _viewModel = AttendanceCalendarViewModel();
    _viewModel.initialize();
    _initializeLanguage();
  }

  @override
  void dispose() {
    // Don't manually dispose _viewModel here as ChangeNotifierProvider will handle it
    super.dispose();
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
      title: Text(
        language.attendanceReport,
        style: const TextStyle(fontWeight: FontWeight.bold),
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
                      : () => _selectPeriod(viewModel, _selectedPeriod),
            );
          },
        ),
      ],
    );
  }

  // Apply a period filter chip and load the matching date range.
  Future<void> _selectPeriod(
    AttendanceCalendarViewModel viewModel,
    String period,
  ) async {
    final now = DateTime.now();
    switch (period) {
      case 'this_month':
        setState(() => _selectedPeriod = 'this_month');
        await viewModel.loadAttendanceForDateRange(
          DateTime(now.year, now.month, 1),
          now,
        );
        break;
      case 'last_month':
        setState(() => _selectedPeriod = 'last_month');
        await viewModel.loadAttendanceForDateRange(
          DateTime(now.year, now.month - 1, 1),
          DateTime(now.year, now.month, 0),
        );
        break;
      case 'three_months':
        setState(() => _selectedPeriod = 'three_months');
        await viewModel.loadAttendanceForDateRange(
          DateTime(now.year, now.month - 2, 1),
          now,
        );
        break;
      case 'custom':
        await _showDateRangePicker(viewModel);
        break;
    }
  }

  Widget _buildErrorState(AttendanceCalendarViewModel viewModel) {
    return SafeArea(
      top: false,
      child: Center(
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
                Text(
                  language.errorLoadingReport,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                    label: Text(language.tryAgain),
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
        ), // closes Padding
      ), // closes Center
    ); // closes SafeArea
  }

  Widget _buildMainContent(AttendanceCalendarViewModel viewModel) {
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: () => viewModel.loadCurrentMonthAttendance(),
        color: primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSummaryCards(viewModel)),
            SliverToBoxAdapter(child: _buildDateRangeHeader(viewModel)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildAttendanceReportTable(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  // Monthly Summary card: teal header + a white 4-column stat row.
  Widget _buildSummaryCards(AttendanceCalendarViewModel viewModel) {
    final summary = viewModel.summary;
    if (summary == null) return const SizedBox();

    final statusCounts = viewModel.getStatusCounts();
    final recordCount = viewModel.attendanceReports.length;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, primary.withOpacity(0.85)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.monthlySummary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        language.yourAttendanceOverview,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$recordCount ${language.records}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stat row: Present | Absent | Late | Leave
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildStatItem(
                    language.present,
                    statusCounts['Present'].toString(),
                    Colors.green,
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    language.absent,
                    statusCounts['Absent'].toString(),
                    Colors.red,
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    language.late,
                    statusCounts['Late'].toString(),
                    Colors.orange,
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    language.leave,
                    statusCounts['On Leave'].toString(),
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, color: Colors.grey[200]);
  }

  Widget _buildStatItem(String label, String value, Color accentColor) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${DateFormat('MMM dd, yyyy').format(DateTime.parse(summary.dateRange.startDate))} → ${DateFormat('MMM dd, yyyy').format(DateTime.parse(summary.dateRange.endDate))}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${summary.workingDays} ${language.workingDays}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Period filter — outlined pills
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _buildPeriodChip(viewModel, language.thisMonth, 'this_month'),
              _buildPeriodChip(viewModel, language.lastMonth, 'last_month'),
              _buildPeriodChip(viewModel, language.threeMonths, 'three_months'),
              _buildPeriodChip(
                viewModel,
                language.custom,
                'custom',
                icon: Icons.tune_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(
    AttendanceCalendarViewModel viewModel,
    String label,
    String period, {
    IconData? icon,
  }) {
    final bool isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => _selectPeriod(viewModel, period),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primary : Colors.grey[300]!,
            width: 1.3,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: primary.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
                language.noAttendanceDataFound,
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
                Icon(Icons.list_alt_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  language.attendanceReport,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${reports.length} ${language.records}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

          // Table Content
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Builder(
              builder: (context) {
                const double hMargin = 12;
                const double colSpacing = 2;
                // Distribute the full card width across the four columns.
                // Card has 16px horizontal margin on each side.
                final double cardWidth = MediaQuery.of(context).size.width - 32;
                final double content = cardWidth - hMargin * 2 - colSpacing * 3;
                final double dateW = content * 0.18;
                final double inW = content * 0.30;
                final double outW = content * 0.30;
                final double statusW = content * 0.22;

                return SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: colSpacing,
                    horizontalMargin: hMargin,
                    headingRowHeight: 50,
                    dataRowHeight: 70,
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      fontSize: 11,
                    ),
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: dateW,
                          child: Text(
                            language.date,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: inW,
                          child: Text(
                            language.checkIn,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: outW,
                          child: Text(
                            language.checkOut,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: statusW,
                          child: Text(
                            language.status,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    rows:
                        reports
                            .map(
                              (report) => _buildDataRow(
                                report,
                                dateW,
                                inW,
                                outW,
                                statusW,
                              ),
                            )
                            .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    AttendanceReport report,
    double dateW,
    double inW,
    double outW,
    double statusW,
  ) {
    final statusColor = _viewModel.getStatusColor(report.status);

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: dateW,
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
            width: inW,
            child: _buildCheckCell(
              clockIcon: Icons.login_rounded,
              fingerTime: report.scanIn,
              clockTime: report.clockIn,
              color: Colors.green,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: outW,
            child: _buildCheckCell(
              clockIcon: Icons.logout_rounded,
              fingerTime: report.scanOut,
              clockTime: report.clockOut,
              color: Colors.red,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: statusW,
            child: _buildStatusCell(report.status, statusColor),
          ),
        ),
      ],
    );
  }

  // Merged cell showing the biometric finger scan (fingerprint icon) on the
  // first line and the app clock time (login/logout arrow) on the second.
  Widget _buildCheckCell({
    required IconData clockIcon,
    required String? fingerTime,
    required String? clockTime,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCheckLine(Icons.fingerprint, fingerTime, color),
        const SizedBox(height: 4),
        _buildCheckLine(clockIcon, clockTime, color),
      ],
    );
  }

  Widget _buildCheckLine(IconData icon, String? time, Color color) {
    final hasData = time != null;
    final lineColor = hasData ? color : Colors.grey[400]!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: lineColor),
        const SizedBox(width: 3),
        Text(
          time ?? '---',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: hasData ? color : Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusCell(String status, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_viewModel.getStatusIcon(status), size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          status,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _showDateRangePicker(
    AttendanceCalendarViewModel viewModel,
  ) async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => _CustomDateRangePicker(
            language: language,
            firstDate: DateTime(now.year - 1, now.month, now.day),
            lastDate: now,
            initialStart: DateTime(now.year, now.month, 1),
            initialEnd: now,
          ),
    );

    if (picked != null) {
      setState(() => _selectedPeriod = 'custom');
      await viewModel.loadAttendanceForDateRange(picked.start, picked.end);
    }
  }
}

/// Bottom-sheet date range picker with From/To fields and an inline calendar.
class _CustomDateRangePicker extends StatefulWidget {
  final Language language;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const _CustomDateRangePicker({
    required this.language,
    required this.firstDate,
    required this.lastDate,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  DateTime? _start;
  DateTime? _end;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _focusedMonth = DateTime(
      (_start ?? widget.lastDate).year,
      (_start ?? widget.lastDate).month,
    );
  }

  bool get _selectingStart => _start == null || _end != null;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _onDayTapped(DateTime day) {
    setState(() {
      if (_start == null || _end != null) {
        // Begin a new range.
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  bool _canGoNext() {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    return !next.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  bool _canGoPrev() {
    final prev = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final first = DateTime(widget.firstDate.year, widget.firstDate.month);
    return !prev.isBefore(first);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.language.selectDateRange,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // From / To fields
            Row(
              children: [
                Expanded(
                  child: _buildRangeField(
                    label: widget.language.from,
                    date: _start,
                    isActive: _selectingStart,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 18),
                ),
                Expanded(
                  child: _buildRangeField(
                    label: widget.language.to,
                    date: _end,
                    isActive: !_selectingStart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCalendarHeader(),
            const SizedBox(height: 12),
            _buildWeekdayRow(),
            const SizedBox(height: 4),
            _buildCalendarGrid(),
            const SizedBox(height: 20),
            // Cancel / Apply
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.language.cancel,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_start != null)
                            ? () => Navigator.pop(
                              context,
                              DateTimeRange(
                                start: _start!,
                                end: _end ?? _start!,
                              ),
                            )
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary.withOpacity(0.4),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.language.apply,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeField({
    required String label,
    required DateTime? date,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? primary.withOpacity(0.06) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? primary : Colors.grey[300]!,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: isActive ? primary : Colors.grey[500],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                date != null ? DateFormat('MMM dd').format(date) : '--',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      children: [
        _buildNavButton(
          Icons.chevron_left,
          _canGoPrev() ? () => _changeMonth(-1) : null,
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(_focusedMonth),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        _buildNavButton(
          Icons.chevron_right,
          _canGoNext() ? () => _changeMonth(1) : null,
        ),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback? onTap) {
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? Colors.black87 : Colors.grey[350],
        ),
      ),
    );
  }

  Widget _buildWeekdayRow() {
    const days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      children: List.generate(7, (i) {
        final bool isWeekend = i == 0 || i == 6;
        return Expanded(
          child: Center(
            child: Text(
              days[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isWeekend ? Colors.orange : Colors.grey[500],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalendarGrid() {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7; // Sunday = 0
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - leadingBlanks + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }
            return Expanded(
              child: _buildDayCell(
                DateTime(_focusedMonth.year, _focusedMonth.month, dayNum),
                col == 0 || col == 6,
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime day, bool isWeekend) {
    final d = _dateOnly(day);
    final start = _start != null ? _dateOnly(_start!) : null;
    final end = _end != null ? _dateOnly(_end!) : null;

    final bool isStart = start != null && d == start;
    final bool isEnd = end != null && d == end;
    final bool inRange =
        start != null && end != null && d.isAfter(start) && d.isBefore(end);

    final bool disabled =
        d.isBefore(_dateOnly(widget.firstDate)) ||
        d.isAfter(_dateOnly(widget.lastDate));

    // Range-highlight bar background (connects cells).
    BorderRadius? barRadius;
    if (isStart && end != null) {
      barRadius = const BorderRadius.horizontal(left: Radius.circular(22));
    } else if (isEnd) {
      barRadius = const BorderRadius.horizontal(right: Radius.circular(22));
    }
    final bool showBar = inRange || (isStart && end != null) || isEnd;

    Color textColor;
    if (isStart || isEnd) {
      textColor = Colors.white;
    } else if (disabled) {
      textColor = Colors.grey[300]!;
    } else if (isWeekend) {
      textColor = Colors.orange;
    } else {
      textColor = Colors.black87;
    }

    return GestureDetector(
      onTap: disabled ? null : () => _onDayTapped(day),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showBar)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: barRadius,
                    ),
                  ),
                ),
              ),
            if (isStart || isEnd)
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    (isStart || isEnd) ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
