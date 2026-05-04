import 'package:flutter/material.dart';
import '../../constants/constant.dart';
import '../../models/ceo_dashboard_model.dart';
import '../../widgets/pending_approval_request_widget.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import 'attendance_adjustment_approval_detail_screen.dart';

class AttendanceApprovalHistoryScreen extends StatefulWidget {
  final String filterType; // 'approved' or 'rejected'
  final dynamic viewModel; // ManagerDashboardViewModel
  final String? initialMonth;

  const AttendanceApprovalHistoryScreen({
    super.key,
    required this.filterType,
    required this.viewModel,
    this.initialMonth,
  });

  @override
  State<AttendanceApprovalHistoryScreen> createState() =>
      _AttendanceApprovalHistoryScreenState();
}

class _AttendanceApprovalHistoryScreenState
    extends State<AttendanceApprovalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedMonth;
  late TabController _tabController;
  late LanguageLogic languageLogic;
  Language language = LanguageLogic().language;
  final Map<String, DateTime> _monthStringToDate = {};

  @override
  void initState() {
    super.initState();
    languageLogic = LanguageLogic();
    _initializeLanguage();
    _selectedMonth = widget.initialMonth ?? 'All';
    _tabController = TabController(length: 2, vsync: this);
    if (widget.filterType == 'rejected') {
      _tabController.index = 1;
    }
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeLanguage() async {
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
    super.dispose();
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<String> _generateMonthOptions(
    List<AttendanceAdjustmentRequest> requests,
  ) {
    final Map<DateTime, String> monthMap = {};
    for (var r in requests) {
      final date = DateTime.tryParse(r.createdAt);
      if (date == null) continue;
      final key = DateTime(date.year, date.month, 1);
      final label = _monthLabel(date);
      monthMap[key] = label;
      _monthStringToDate[label] = key;
    }
    final sorted = monthMap.keys.toList()..sort((a, b) => b.compareTo(a));
    return ['All', ...sorted.map((k) => monthMap[k]!)];
  }

  bool _isSameMonth(DateTime date, String selectedMonth) {
    if (selectedMonth == 'All') return true;
    final cached = _monthStringToDate[selectedMonth];
    if (cached == null) return false;
    return date.year == cached.year && date.month == cached.month;
  }

  @override
  Widget build(BuildContext context) {
    final approvedList =
        widget.viewModel.approvedAttendanceRequests
            as List<AttendanceAdjustmentRequest>;
    final rejectedList =
        widget.viewModel.rejectedAttendanceRequests
            as List<AttendanceAdjustmentRequest>;

    final filteredApproved =
        approvedList.where((r) {
          final date = DateTime.tryParse(r.createdAt);
          return date != null && _isSameMonth(date, _selectedMonth);
        }).toList();

    final filteredRejected =
        rejectedList.where((r) {
          final date = DateTime.tryParse(r.createdAt);
          return date != null && _isSameMonth(date, _selectedMonth);
        }).toList();

    final allRequests = [...approvedList, ...rejectedList];
    final monthOptions = _generateMonthOptions(allRequests);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                indicator: BoxDecoration(
                  color: secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.zero,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          language.approved,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _tabController.index == 0
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.teal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${filteredApproved.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  _tabController.index == 0
                                      ? Colors.white
                                      : Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          language.rejected,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _tabController.index == 1
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${filteredRejected.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  _tabController.index == 1
                                      ? Colors.white
                                      : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Month Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 20, color: secondary),
                const SizedBox(width: 8),
                Text(
                  language.filterByMonth,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showMonthFilterBottomSheet(monthOptions),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedMonth,
                            style: const TextStyle(
                              fontSize: 14,
                              color: secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: secondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(filteredApproved, 'approved'),
                _buildList(filteredRejected, 'rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AttendanceAdjustmentRequest> requests, String type) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              type == 'approved'
                  ? 'No approved attendance found'
                  : 'No rejected attendance found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              language.tryChangingTheFilter,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AttendanceAdjustmentApprovalDetailScreen(
                      request: request,
                      isPending: false,
                    ),
              ),
            );
            if (result != null && mounted) {
              widget.viewModel.refresh();
              setState(() {});
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: PendingApprovalRequestWidget(
              reason: request.reason,
              status: request.statusText,
              fromDate: request.adjustDate.toString(),
              toDate: request.adjustDate.toString(),
              requesterName: request.requesterName,
              position: request.positionName,
              leaveType: request.adjustType,
              isLeaveRequest: false,
              currentUserName: '',
              currentUserProfileImageUrl: '',
              empProfileImage: request.profileImageUrl,
            ),
          ),
        );
      },
    );
  }

  void _showMonthFilterBottomSheet(List<String> monthOptions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: secondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            language.selectMonth,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: secondary,
                            ),
                          ),
                        ],
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
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: monthOptions.length,
                    itemBuilder: (context, index) {
                      final month = monthOptions[index];
                      final isSelected = _selectedMonth == month;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMonth = month;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? secondary.withOpacity(0.08)
                                      : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color:
                                      isSelected
                                          ? secondary
                                          : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  month == 'All'
                                      ? Icons.list_alt
                                      : Icons.calendar_today,
                                  size: 18,
                                  color:
                                      isSelected ? secondary : Colors.grey[500],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  month,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                    color:
                                        isSelected ? secondary : Colors.black87,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const Spacer(),
                                  const Icon(
                                    Icons.check,
                                    color: secondary,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
    );
  }
}
