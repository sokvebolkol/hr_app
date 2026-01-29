import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../../constants/constant.dart';
import '../../../utils/file_helper.dart';
import '../../../viewmodels/leave_history_viewmodel.dart';
import '../../../models/leave_history_model.dart';
import '../../../widgets/calendar_card_widget.dart';
import '../../../widgets/clickable_date_card_widget.dart';
import '../leave_detail/my_leave_detail_screen.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  late LeaveHistoryViewModel _viewModel;

  DateTimeRange? _selectedDateRange;
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _viewModel = LeaveHistoryViewModel();
    _viewModel.fetchLeaveHistory();
  }

  @override
  void dispose() {
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
          title: const Text(
            'History Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: primary,
        ),
        body: Consumer<LeaveHistoryViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: SpinKitFadingCircle(color: primary));
            }

            if (viewModel.errorMessage != null) {
              return _buildErrorState(viewModel);
            }

            final filteredHistory = _filterLeaveHistory(viewModel.leaveHistory);

            return RefreshIndicator(
              onRefresh: viewModel.refresh,
              color: primary,
              child: Column(
                children: [
                  _buildStatsHeader(filteredHistory),

                  // ===== FILTER ROW (CEO STYLE) =====
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
          },
        ),
      ),
    );
  }

  /* =========================================================
     FILTER LOGIC (BETWEEN DATE + TYPE)
     ========================================================= */

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

      if (_selectedType != 'All') {
        if (_selectedType == 'Leave' && !item.isFullDay) return false;
        if (_selectedType == 'Attendance' && item.isFullDay) return false;
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

          const SizedBox(width: 12),

          Expanded(
            child: GestureDetector(
              onTap: _showTypeFilterBottomSheet,
              child: _buildFilterBox(_selectedType),
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
                                  label: 'Start Date',
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
                                  label: 'End Date',
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
                                child: const Text('Cancel'),
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
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Apply',
                                      style: TextStyle(
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
     TYPE FILTER
     ========================================================= */
  void _showTypeFilterBottomSheet() {
    final types = ['All', 'Leave', 'Attendance'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== HANDLE BAR =====
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // ===== HEADER =====
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.filter_alt_rounded,
                        color: primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter by Type',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Select request category',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ===== TYPE LIST =====
              ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: types.length,
                itemBuilder: (context, index) {
                  final type = types[index];
                  final isSelected = _selectedType == type;

                  IconData icon;
                  if (type == 'Attendance') {
                    icon = Icons.access_time;
                  } else if (type == 'Leave') {
                    icon = Icons.beach_access;
                  } else {
                    icon = Icons.all_inclusive;
                  }

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedType = type);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? primary.withOpacity(0.08)
                                  : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? primary : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon box
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? primary.withOpacity(0.15)
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                icon,
                                size: 20,
                                color: isSelected ? primary : Colors.grey[600],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Text
                            Expanded(
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                  color: isSelected ? primary : Colors.black87,
                                ),
                              ),
                            ),

                            // Selected check
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
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
                            'Total: ${leave.numleav} day${leave.numberOfDays > 1 ? 's' : ''}${leave.isFullDay ? '' : ' (Half Day)'}',
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
          _stat('Total', total, Colors.blue),
          _stat('Pending', pending, Colors.orange),
          _stat('Approved', approved, Colors.green),
          _stat('Rejected', rejected, Colors.red),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          
          width: 40,
          height: 40,
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
        child: const Text('Retry'),
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
