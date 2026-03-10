import 'package:chokchey_hr_app/localization/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../../constants/constant.dart';
import '../../../localization/language_logic.dart';
import '../../../utils/file_helper.dart';
import '../../../viewmodels/leave_history_viewmodel.dart';
import '../../../models/leave_history_model.dart';
import '../../../widgets/calendar_card_widget.dart';
import '../../../widgets/clickable_date_card_widget.dart';
import '../leave_detail/my_leave_detail_screen.dart';
import '../../attendance/my_attendance_adjustment_request.screen.dart';

class HistoryRequestScreen extends StatefulWidget {
  const HistoryRequestScreen({super.key});

  @override
  State<HistoryRequestScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<HistoryRequestScreen>
    with SingleTickerProviderStateMixin {
  late LeaveHistoryViewModel _viewModel;
  late TabController _tabController;
  Language language = Language();

  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel = LeaveHistoryViewModel();
    _viewModel.fetchLeaveHistory();
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

  @override
  void dispose() {
    _tabController.dispose();
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
          title: Text(
            language.historyRequests,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: primary,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note, size: 20),
                    const SizedBox(width: 6),
                    Text(language.leaveRequest),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 6),
                    Text(language.adjustmentRequest),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Consumer<LeaveHistoryViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: SpinKitFadingCircle(color: primary));
            }

            if (viewModel.errorMessage != null) {
              return _buildErrorState(viewModel);
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildLeaveRequestTab(viewModel),
                _buildAdjustmentRequestTab(viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  /* =========================================================
     TAB VIEWS
     ========================================================= */

  Widget _buildLeaveRequestTab(LeaveHistoryViewModel viewModel) {
    final filteredHistory = _filterLeaveHistory(viewModel.leaveHistory);

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: primary,
      child: Column(
        children: [
          _buildStatsHeader(filteredHistory),
          _buildFilterRow(),
          Expanded(
            child:
                filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : _buildLeaveHistoryList(filteredHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentRequestTab(LeaveHistoryViewModel viewModel) {
    final filteredAdjustments = _filterAdjustmentHistory(
      viewModel.adjustmentHistory,
    );

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: primary,
      child: Column(
        children: [
          _buildAdjustmentStatsHeader(filteredAdjustments),
          _buildFilterRow(),
          Expanded(
            child:
                filteredAdjustments.isEmpty
                    ? _buildEmptyState()
                    : _buildAdjustmentHistoryList(filteredAdjustments),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentHistoryList(List<dynamic> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildAdjustmentHistoryCard(list[i]),
    );
  }

  Widget _buildAdjustmentHistoryCard(dynamic adjustment) {
    final statusIcon = FileHelper.getStatusIcon(adjustment.statusText ?? '');
    final statusColor = FileHelper.getStatusColor(adjustment.statusText ?? '');

    // Parse adjustDateTime to extract month and day
    DateTime adjustDate;
    try {
      adjustDate = DateTime.parse(adjustment.adjustDateTime ?? '');
    } catch (e) {
      adjustDate = DateTime.now();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MyAttendanceAdjustmentRequestScreen(
                  adjustmentRequest: adjustment,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              adjustment.isPending
                  ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: CalendarCardWidget(
                        month: adjustDate.month,
                        day: adjustDate.day,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adjustment.reason ?? 'No reason provided',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Applied: ${FileHelper.formatDate(adjustment.createdDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: FileHelper()
                                  .getAdjustmentTypeColor(
                                    adjustment.adjustType ?? '',
                                  )
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: FileHelper()
                                    .getAdjustmentTypeColor(
                                      adjustment.adjustType ?? '',
                                    )
                                    .withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              adjustment.adjustType ?? 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                overflow: TextOverflow.ellipsis,
                                color: FileHelper().getAdjustmentTypeColor(
                                  adjustment.adjustType ?? '',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 6,
                            ),
                            child: Icon(
                              statusIcon,
                              size: 22,
                              color: statusColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              adjustment.statusText ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* =========================================================
     FILTER LOGIC (BETWEEN DATE + TYPE)
     ========================================================= */

  List<dynamic> _filterAdjustmentHistory(List<dynamic> history) {
    return history.where((item) {
      DateTime date;
      try {
        date = DateTime.parse(item.adjustDateTime ?? '');
      } catch (e) {
        date = DateTime.now();
      }

      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );

        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );

        if (date.isBefore(start) || date.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<LeaveHistoryModel> _filterLeaveHistory(List<LeaveHistoryModel> history) {
    return history.where((item) {
      final date = item.toDate;

      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );

        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );

        if (date.isBefore(start) || date.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /* =========================================================
     FILTER BETWEEN DATE
     ========================================================= */

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 20, color: secondary),
          const SizedBox(width: 8),
          const Text(
            'Filter:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: secondary,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: GestureDetector(
              onTap: _showDateRangePicker,
              child: _buildFilterBox(_getDateRangeText()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 20, color: secondary),
        ],
      ),
    );
  }

  /* =========================================================
     DATE RANGE TEXT
     ========================================================= */

  String _getDateRangeText() {
    if (_selectedDateRange == null) return 'All Dates';

    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;

    // Same month
    if (start.month == end.month && start.year == end.year) {
      return '${_formatShortDate(start)} – ${end.day.toString().padLeft(2, '0')}';
    }

    // Different months or years
    return '${_formatShortDate(start)} – ${_formatShortDate(end)}';
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day.toString().padLeft(2, '0')}';
  }

  /* =========================================================
     CUSTOM DATE RANGE DIALOG 
     ========================================================= */

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
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [secondary, secondary.withOpacity(0.8)],
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Date Range',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Choose your desired date range',
                                    style: TextStyle(
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
                        padding: const EdgeInsets.all(12),
                        child: Row(
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
                      ),

                      const Divider(height: 1),

                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: secondary,
                            onPrimary: primary,
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
                                tempDateRange = DateTimeRange(
                                  start: date,
                                  end:
                                      date.isAfter(tempDateRange.end)
                                          ? date
                                          : tempDateRange.end,
                                );
                                isSelectingStart = false;
                              } else {
                                tempDateRange = DateTimeRange(
                                  start:
                                      date.isBefore(tempDateRange.start)
                                          ? date
                                          : tempDateRange.start,
                                  end: date,
                                );
                                isSelectingStart = true;
                              }
                            });
                          },
                        ),
                      ),

                      const Divider(height: 1),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(language.cancel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _selectedDateRange = tempDateRange;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondary,
                                  foregroundColor: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      language.apply,
                                      style: const TextStyle(
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

  /* =========================================================
     LIST & STATES
     ========================================================= */

  Widget _buildLeaveHistoryList(List<LeaveHistoryModel> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildLeaveHistoryCard(list[i]),
    );
  }

  Widget _buildLeaveHistoryCard(LeaveHistoryModel leave) {
    final statusIcon = FileHelper.getStatusIcon(leave.statu);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyLeaveDetailScreen(leaveRequest: leave),
          ),
        ).then((result) {
          // Refresh the list if the leave was updated/cancelled
          if (result == true) {
            _viewModel.refresh();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              leave.isPending
                  ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: CalendarCardWidget(
                        month: leave.toDate.month,
                        day: leave.toDate.day,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.reason,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${language.total}: ${leave.numleav} day${leave.numberOfDays > 1 ? 's' : ''}${leave.isFullDay ? '' : ' (Half Day)'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: FileHelper()
                                  .getLeaveTypeColor(leave.ltyp)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: FileHelper()
                                    .getLeaveTypeColor(leave.ltyp)
                                    .withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              leave.ltyp,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: FileHelper().getLeaveTypeColor(
                                  leave.ltyp,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 6,
                            ),
                            child: Icon(
                              statusIcon,
                              size: 22,
                              color: FileHelper.getStatusColor(leave.statu),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              leave.statusText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(List<LeaveHistoryModel> filteredList) {
    final total = filteredList.length;

    final pending =
        filteredList.where((e) => e.statu == '0' || e.isPending).length;

    final approved = filteredList.where((e) => e.statu == '1').length;

    final rejected = filteredList.where((e) => e.statu == '2').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat(language.total, total, Colors.blue),
          _stat(language.pending, pending, Colors.orange),
          _stat(language.approved, approved, Colors.green),
          _stat(language.rejected, rejected, Colors.red),
        ],
      ),
    );
  }

  Widget _buildAdjustmentStatsHeader(List<dynamic> filteredList) {
    final total = filteredList.length;

    final pending = filteredList.where((e) => e.isPending).length;

    final approved = filteredList.where((e) => e.isApproved).length;

    final rejected = filteredList.where((e) => e.isRejected).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat(language.total, total, Colors.blue),
          _stat(language.pending, pending, Colors.orange),
          _stat(language.approved, approved, Colors.green),
          _stat(language.rejected, rejected, Colors.red),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(LeaveHistoryViewModel vm) {
    return Center(
      child: ElevatedButton(
        onPressed: vm.fetchLeaveHistory,
        child: Text(language.retry),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          'No Leave or Attendance Requests Found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You have no leave or attendance requests yet',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
