import 'package:chokchey_hr_app/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../constants/constant.dart';
import '../../../viewmodels/leave_history_viewmodel.dart';
import '../../../models/leave_history_model.dart';
import '../leave_detail/leave_detail_screen.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  late LeaveHistoryViewModel _viewModel;
  String? _selectedStatus;
  String? _selectedLeaveType;

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
        body: Consumer<LeaveHistoryViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
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

            final filteredHistory = viewModel.getFilteredHistory(
              status: _selectedStatus,
              leaveType: _selectedLeaveType,
            );

            return RefreshIndicator(
              onRefresh: () => viewModel.refresh(),
              child: Column(
                children: [
                  _buildStatsHeader(viewModel),
                  _buildActiveFilters(),
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

  Widget _buildStatsHeader(LeaveHistoryViewModel viewModel) {
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
            viewModel.leaveHistory.length.toString(),
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'Pending',
            viewModel.pendingCount.toString(),
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'Approved',
            viewModel.approvedCount.toString(),
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            'Rejected',
            viewModel.rejectedCount.toString(),
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

  Widget _buildActiveFilters() {
    if (_selectedStatus == null && _selectedLeaveType == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedStatus != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    'Status: ${FileHelper().getStatusText(_selectedStatus!)}',
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedStatus = null;
                    });
                  },
                  backgroundColor: primary.withOpacity(0.1),
                  deleteIconColor: primary,
                ),
              ),
            if (_selectedLeaveType != null)
              Chip(
                label: Text('Type: $_selectedLeaveType'),
                onDeleted: () {
                  setState(() {
                    _selectedLeaveType = null;
                  });
                },
                backgroundColor: primary.withOpacity(0.1),
                deleteIconColor: primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveHistoryList(List<LeaveHistoryModel> leaveHistory) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaveHistory.length,
      itemBuilder: (context, index) {
        final leave = leaveHistory[index];
        return _buildLeaveHistoryCard(leave);
      },
    );
  }

  Widget _buildLeaveHistoryCard(LeaveHistoryModel leave) {
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
                      color: FileHelper.statusColor(status: leave.statusText),
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

  Widget _buildPriorityIndicator(PriorityModel priority) {
    Color color;
    IconData icon;

    if (priority.isApproved) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (priority.isRejected) {
      color = Colors.red;
      icon = Icons.cancel;
    } else {
      color = Colors.orange;
      icon = Icons.schedule;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: '${priority.prioText}: ${priority.apstatuText}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                priority.prioText.split(' ').first, // Show first word only
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No leave history found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your leave requests will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final currentViewModel = _viewModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
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
                    const Text(
                      'Filter Leave History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedStatus == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = null;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        FilterChip(
                          label: const Text('Pending'),
                          selected: _selectedStatus == '2',
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = selected ? '2' : null;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        FilterChip(
                          label: const Text('Approved'),
                          selected: _selectedStatus == '1',
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = selected ? '1' : null;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        FilterChip(
                          label: const Text('Rejected'),
                          selected: _selectedStatus == '0',
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = selected ? '0' : null;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (currentViewModel.availableLeaveTypes.isNotEmpty) ...[
                      const Text(
                        'Leave Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedLeaveType == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedLeaveType = null;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          ...currentViewModel.availableLeaveTypes.map(
                            (type) => FilterChip(
                              label: Text(type),
                              selected: _selectedLeaveType == type,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedLeaveType = selected ? type : null;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
