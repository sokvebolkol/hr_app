import 'package:flutter/material.dart';
import '../../constants/constant.dart';
import '../../models/ceo_dashboard_model.dart';
import '../../widgets/pending_approval_request_widget.dart';
import '../leaves/leave_approval/ceo_leave_detail_screen.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';

class ApprovalHistoryScreen extends StatefulWidget {
  final String filterType; // 'approved' or 'rejected'
  final dynamic
  viewModel; // Accepts CeoDashboardViewModel or ManagerDashboardViewModel
  final String? initialMonth; // Pass the current selected month from dashboard

  const ApprovalHistoryScreen({
    super.key,
    required this.filterType,
    required this.viewModel,
    this.initialMonth,
  });

  @override
  State<ApprovalHistoryScreen> createState() => _ApprovalHistoryScreenState();
}

class _ApprovalHistoryScreenState extends State<ApprovalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedMonth;
  late TabController _tabController;
  late LanguageLogic languageLogic;
  Language language = LanguageLogic().language;

  @override
  void initState() {
    super.initState();
    languageLogic = LanguageLogic();
    _initializeLanguage();

    // Use the month passed from dashboard, or default to 'All'
    _selectedMonth = widget.initialMonth ?? 'All';

    // Initialize tab controller with 2 tabs
    _tabController = TabController(length: 2, vsync: this);

    // Set initial tab based on filterType
    if (widget.filterType == 'rejected') {
      _tabController.index = 1;
    }

    // Add listener to rebuild when tab changes
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

  @override
  Widget build(BuildContext context) {
    final approvedLeaves = widget.viewModel.approvedLeaves;
    final rejectedLeaves = widget.viewModel.rejectedLeaves;

    // Filter approved leaves by month
    final filteredApprovedLeaves =
        _selectedMonth == language.all || _selectedMonth == 'All'
            ? approvedLeaves
            : approvedLeaves.where((leave) {
              DateTime? leaveDate =
                  leave.todat.isNotEmpty
                      ? DateTime.tryParse(leave.todat)
                      : null;
              if (leaveDate == null && leave.frdat.isNotEmpty) {
                leaveDate = DateTime.tryParse(leave.frdat);
              }
              if (leaveDate == null) return false;
              final monthYear = _monthLabel(leaveDate);
              return monthYear == _selectedMonth;
            }).toList();

    // Filter rejected leaves by month
    final filteredRejectedLeaves =
        _selectedMonth == language.all || _selectedMonth == 'All'
            ? rejectedLeaves
            : rejectedLeaves.where((leave) {
              DateTime? leaveDate =
                  leave.todat.isNotEmpty
                      ? DateTime.tryParse(leave.todat)
                      : null;
              if (leaveDate == null && leave.frdat.isNotEmpty) {
                leaveDate = DateTime.tryParse(leave.frdat);
              }
              if (leaveDate == null) return false;
              final monthYear = _monthLabel(leaveDate);
              return monthYear == _selectedMonth;
            }).toList();

    final allLeaves = [...approvedLeaves, ...rejectedLeaves];
    final monthOptions = _generateMonthOptions(allLeaves);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          language.approvalHistory,
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
                                    : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${filteredApprovedLeaves.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  _tabController.index == 0
                                      ? Colors.white
                                      : Colors.green,
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
                                    : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${filteredRejectedLeaves.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  _tabController.index == 1
                                      ? Colors.white
                                      : Colors.red,
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
          // TabBarView with leave lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaveList(filteredApprovedLeaves, 'approved'),
                _buildLeaveList(filteredRejectedLeaves, 'rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveList(List<LeaveRequest> leaves, String type) {
    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              type == 'approved'
                  ? language.noApprovedLeavesFound
                  : language.noRejectedLeavesFound,
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
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leave = leaves[index];
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        CeoLeaveDetailScreen(leave: leave, isPending: false),
              ),
            );
            if (result != null && mounted) {
              widget.viewModel.refresh();
              setState(() {}); // Refresh the counts
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: PendingApprovalRequestWidget(
              reason: leave.reason,
              label: '${language.reason}: ',
              status: leave.statuText,
              fromDate: leave.fromDate.toString(),
              toDate: leave.toDate.toString(),
              requesterName: leave.requesterName,
              position: leave.position,
              leaveType: leave.ltyp,
              totalDays: leave.numLeaveDays.toString(),
              currentUserName: "",
              currentUserProfileImageUrl: "",
              empProfileImage: leave.requesterProfileImage,
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
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
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

                // Month options list
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
                      final isAll = month == 'All';

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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? secondary.withOpacity(0.15)
                                            : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isAll
                                        ? Icons.all_inclusive
                                        : Icons.calendar_today,
                                    color:
                                        isSelected
                                            ? secondary
                                            : Colors.grey[600],
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    month,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                      color:
                                          isSelected
                                              ? secondary
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
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

  /// Returns a localized "Month Year" label (e.g. "March 2026" / "មីនា 2026").
  String _monthLabel(DateTime date) {
    final lang = LanguageLogic().language;
    final monthNames = [
      lang.january,
      lang.february,
      lang.march,
      lang.april,
      lang.may,
      lang.june,
      lang.july,
      lang.august,
      lang.september,
      lang.october,
      lang.november,
      lang.december,
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  List<String> _generateMonthOptions(List<dynamic> leaves) {
    final Map<DateTime, String> monthMap = {};

    for (var leave in leaves) {
      DateTime? leaveDate =
          leave.todat.isNotEmpty ? DateTime.tryParse(leave.todat) : null;
      if (leaveDate == null && leave.frdat.isNotEmpty) {
        leaveDate = DateTime.tryParse(leave.frdat);
      }

      if (leaveDate != null) {
        final monthKey = DateTime(leaveDate.year, leaveDate.month, 1);
        monthMap[monthKey] = _monthLabel(leaveDate);
      }
    }

    final sortedMonths = monthMap.keys.toList()..sort((a, b) => b.compareTo(a));

    final result = <String>[language.all];
    for (var monthKey in sortedMonths) {
      result.add(monthMap[monthKey]!);
    }

    return result;
  }
}
