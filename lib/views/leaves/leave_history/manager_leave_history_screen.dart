import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../../constants/constant.dart';
import '../../../viewmodels/manager_leave_history_viewmodel.dart';
import '../../../models/leave_history_model.dart';
import '../../../models/manager_leave_history_model.dart';
import '../../../utils/file_helper.dart';
import '../leave_detail/leave_detail_screen.dart';

class ManagerLeaveHistoryScreen extends StatefulWidget {
  const ManagerLeaveHistoryScreen({super.key});

  @override
  State<ManagerLeaveHistoryScreen> createState() =>
      _ManagerLeaveHistoryScreenState();
}

class _ManagerLeaveHistoryScreenState extends State<ManagerLeaveHistoryScreen>
    with SingleTickerProviderStateMixin {
  late ManagerLeaveHistoryViewModel _viewModel;
  late TabController _tabController;

  // My Request Filters
  String? _mySelectedStatus;
  String? _mySelectedLeaveType;

  // Staff Request Filters
  String? _staffSelectedStatus;
  String? _staffSelectedLeaveType;
  String? _staffSelectedMember;

  @override
  void initState() {
    super.initState();
    _viewModel = ManagerLeaveHistoryViewModel();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.fetchLeaveHistory();
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
          title: const Text(
            'Leave History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: Colors.grey[200], 
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primary, 
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white, // White text for active tab
                  unselectedLabelColor:
                      Colors.grey[600], // Dark text for inactive
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(height: 40, child: Text('My Request')),
                    Tab(height: 40, child: Text('My Staff Request')),
                  ],
                ),
              ),
            ),

            // Tab Content
            Expanded(
              child: Consumer<ManagerLeaveHistoryViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading) {
                    return const Center(
                      child: SpinKitFadingCircle(color: primary),
                    );
                  }

                  if (viewModel.errorMessage != null) {
                    return _buildErrorState(viewModel);
                  }

                  return RefreshIndicator(
                    onRefresh: () => viewModel.refresh(),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMyRequestsTab(viewModel),
                        _buildStaffRequestsTab(viewModel),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ManagerLeaveHistoryViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading leave history',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.errorMessage!,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => viewModel.fetchLeaveHistory(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsTab(ManagerLeaveHistoryViewModel viewModel) {
    final filteredRequests = viewModel.getFilteredMyRequests(
      status: _mySelectedStatus,
      leaveType: _mySelectedLeaveType,
    );

    return Column(
      children: [
        _buildMyRequestsStats(viewModel),
        _buildMyRequestsActiveFilters(),
        Expanded(
          child:
              filteredRequests.isEmpty
                  ? _buildEmptyState('No leave requests found')
                  : _buildMyRequestsList(filteredRequests),
        ),
      ],
    );
  }

  Widget _buildStaffRequestsTab(ManagerLeaveHistoryViewModel viewModel) {
    final filteredRequests = viewModel.getFilteredStaffRequests(
      status: _staffSelectedStatus,
      leaveType: _staffSelectedLeaveType,
      staffMember: _staffSelectedMember,
    );

    return Column(
      children: [
        _buildStaffRequestsStats(viewModel),
        _buildStaffRequestsActiveFilters(),
        Expanded(
          child:
              filteredRequests.isEmpty
                  ? _buildEmptyState('No staff leave requests found')
                  : _buildStaffRequestsList(filteredRequests),
        ),
      ],
    );
  }

  Widget _buildMyRequestsStats(ManagerLeaveHistoryViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Total',
            viewModel.myLeaveRequests.length.toString(),
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'Pending',
            viewModel.myPendingCount.toString(),
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'Approved',
            viewModel.myApprovedCount.toString(),
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'Rejected',
            viewModel.myRejectedCount.toString(),
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffRequestsStats(ManagerLeaveHistoryViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Total',
            viewModel.staffLeaveRequests.length.toString(),
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'Pending',
            viewModel.staffPendingCount.toString(),
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'Approved',
            viewModel.staffApprovedCount.toString(),
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'Rejected',
            viewModel.staffRejectedCount.toString(),
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
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

  Widget _buildMyRequestsActiveFilters() {
    if (_mySelectedStatus == null && _mySelectedLeaveType == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_mySelectedStatus != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    'Status: ${FileHelper().getStatusText(_mySelectedStatus!)}',
                  ),
                  onDeleted: () => setState(() => _mySelectedStatus = null),
                  backgroundColor: primary.withOpacity(0.1),
                  deleteIconColor: primary,
                ),
              ),
            if (_mySelectedLeaveType != null)
              Chip(
                label: Text('Type: $_mySelectedLeaveType'),
                onDeleted: () => setState(() => _mySelectedLeaveType = null),
                backgroundColor: primary.withOpacity(0.1),
                deleteIconColor: primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffRequestsActiveFilters() {
    if (_staffSelectedStatus == null &&
        _staffSelectedLeaveType == null &&
        _staffSelectedMember == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_staffSelectedStatus != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    'Status: ${FileHelper().getStatusText(_staffSelectedStatus!)}',
                  ),
                  onDeleted: () => setState(() => _staffSelectedStatus = null),
                  backgroundColor: primary.withOpacity(0.1),
                  deleteIconColor: primary,
                ),
              ),
            if (_staffSelectedLeaveType != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('Type: $_staffSelectedLeaveType'),
                  onDeleted:
                      () => setState(() => _staffSelectedLeaveType = null),
                  backgroundColor: primary.withOpacity(0.1),
                  deleteIconColor: primary,
                ),
              ),
            if (_staffSelectedMember != null)
              Chip(
                label: Text('Staff: $_staffSelectedMember'),
                onDeleted: () => setState(() => _staffSelectedMember = null),
                backgroundColor: primary.withOpacity(0.1),
                deleteIconColor: primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequestsList(List<LeaveHistoryModel> requests) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final leave = requests[index];
        return _buildMyRequestCard(leave);
      },
    );
  }

  Widget _buildStaffRequestsList(List<StaffLeaveModel> requests) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final leave = requests[index];
        return _buildStaffRequestCard(leave);
      },
    );
  }

  Widget _buildMyRequestCard(LeaveHistoryModel leave) {
    final fromDate = FileHelper.formatDate(leave.fromDate);
    final toDate = FileHelper.formatDate(leave.toDate);
    final createDate = FileHelper.formatDate(leave.createdDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaveDetailScreen(leaveRequest: leave),
          ),
        ).then((result) {
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      leave.ltyp,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: FileHelper.getStatusColor(leave.statu),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      leave.statusText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    fromDate == toDate ? fromDate : '$fromDate - $toDate',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Icon(
                    leave.isFullDay ? Icons.wb_sunny : Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${leave.numleav} day${leave.numberOfDays > 1 ? 's' : ''}${leave.isFullDay ? '' : ' (Half Day)'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              if (leave.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leave.reason,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Applied: $createDate',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  Row(
                    children: [
                      Text(
                        'ID: ${leave.lreid}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffRequestCard(StaffLeaveModel leave) {
    final fromDate = FileHelper.formatDate(leave.fromDate);
    final toDate = FileHelper.formatDate(leave.toDate);
    final createDate = FileHelper.formatDate(leave.createdDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => LeaveDetailScreen(
                  leaveRequest: leave.toLeaveHistoryModel(),
                ),
          ),
        ).then((result) {
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.requesterName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        // const SizedBox(height: 2),
                        // Text(
                        //   '${leave.positionName} • ${leave.departmentName}',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.grey[600],
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: FileHelper.getStatusColor(leave.statu),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      leave.statusText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  leave.ltyp,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    fromDate == toDate ? fromDate : '$fromDate - $toDate',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Icon(
                    leave.isFullDay ? Icons.wb_sunny : Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${leave.numberOfDays} day${leave.numberOfDays > 1 ? 's' : ''}${leave.isFullDay ? '' : ' (Half Day)'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              if (leave.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leave.reason,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Applied: $createDate',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  Row(
                    children: [
                      Text(
                        'ID: ${leave.lreid} • Staff: ${leave.staffId}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Leave requests will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final currentTab = _tabController.index;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter ${currentTab == 0 ? 'My Requests' : 'Staff Requests'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status Filter
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusFilters(currentTab),

                    const SizedBox(height: 20),

                    // Leave Type Filter
                    const Text(
                      'Leave Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLeaveTypeFilters(currentTab),

                    // Staff Member Filter (only for Staff Requests tab)
                    if (currentTab == 1) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Staff Member',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStaffMemberFilters(),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusFilters(int currentTab) {
    final selectedStatus =
        currentTab == 0 ? _mySelectedStatus : _staffSelectedStatus;

    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: selectedStatus == null,
          onSelected: (selected) {
            setState(() {
              if (currentTab == 0) {
                _mySelectedStatus = null;
              } else {
                _staffSelectedStatus = null;
              }
            });
            Navigator.pop(context);
          },
        ),
        FilterChip(
          label: const Text('Pending'),
          selected: selectedStatus == '2',
          onSelected: (selected) {
            setState(() {
              if (currentTab == 0) {
                _mySelectedStatus = selected ? '2' : null;
              } else {
                _staffSelectedStatus = selected ? '2' : null;
              }
            });
            Navigator.pop(context);
          },
        ),
        FilterChip(
          label: const Text('Approved'),
          selected: selectedStatus == '1',
          onSelected: (selected) {
            setState(() {
              if (currentTab == 0) {
                _mySelectedStatus = selected ? '1' : null;
              } else {
                _staffSelectedStatus = selected ? '1' : null;
              }
            });
            Navigator.pop(context);
          },
        ),
        FilterChip(
          label: const Text('Rejected'),
          selected: selectedStatus == '0',
          onSelected: (selected) {
            setState(() {
              if (currentTab == 0) {
                _mySelectedStatus = selected ? '0' : null;
              } else {
                _staffSelectedStatus = selected ? '0' : null;
              }
            });
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildLeaveTypeFilters(int currentTab) {
    final currentViewModel = _viewModel;
    final leaveTypes =
        currentTab == 0
            ? currentViewModel.myLeaveTypes
            : currentViewModel.staffLeaveTypes;
    final selectedType =
        currentTab == 0 ? _mySelectedLeaveType : _staffSelectedLeaveType;

    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: selectedType == null,
          onSelected: (selected) {
            setState(() {
              if (currentTab == 0) {
                _mySelectedLeaveType = null;
              } else {
                _staffSelectedLeaveType = null;
              }
            });
            Navigator.pop(context);
          },
        ),
        ...leaveTypes.map(
          (type) => FilterChip(
            label: Text(type),
            selected: selectedType == type,
            onSelected: (selected) {
              setState(() {
                if (currentTab == 0) {
                  _mySelectedLeaveType = selected ? type : null;
                } else {
                  _staffSelectedLeaveType = selected ? type : null;
                }
              });
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStaffMemberFilters() {
    final staffMembers = _viewModel.staffMembers;

    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: _staffSelectedMember == null,
          onSelected: (selected) {
            setState(() {
              _staffSelectedMember = null;
            });
            Navigator.pop(context);
          },
        ),
        ...staffMembers.map(
          (member) => FilterChip(
            label: Text(member),
            selected: _staffSelectedMember == member,
            onSelected: (selected) {
              setState(() {
                _staffSelectedMember = selected ? member : null;
              });
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
