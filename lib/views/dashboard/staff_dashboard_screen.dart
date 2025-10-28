import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../constants/constant.dart';

class StaffDashboardView extends StatefulWidget {
  const StaffDashboardView({super.key});

  @override
  State<StaffDashboardView> createState() => _StaffDashboardViewState();
}

class _StaffDashboardViewState extends State<StaffDashboardView> {
  bool _isLoading = false;

  // Mock data - Replace with actual API calls
  final Map<String, dynamic> _staffStats = {
    'presentToday': 24,
    'onLeave': 3,
    'pendingApprovals': 5,
    'totalStaff': 32,
    'absent': 2,
    'late': 3,
  };

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => _isLoading = true);
    // TODO: Load actual staff data from API
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStaffData,
      color: primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStaffHeader(),
            _buildQuickStats(),
            _buildQuickActions(),
            _buildTodayAttendance(),
            _buildPendingApprovals(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Staff Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Today\'s Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'Present',
                  _staffStats['presentToday'].toString(),
                  Icons.check_circle_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'Absent',
                  _staffStats['absent'].toString(),
                  Icons.cancel_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'On Leave',
                  _staffStats['onLeave'].toString(),
                  Icons.beach_access_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'Late',
                  _staffStats['late'].toString(),
                  Icons.access_time_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Expanded(
              //   child: _buildActionCard(
              //     'Approve\nLeaves',
              //     Icons.approval_rounded,
              //     Colors.blue,
              //     _staffStats['pendingApprovals'].toString(),
              //     () => Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (_) => const LeaveApprovalScreen(),
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Staff\nAttendance',
                  Icons.groups_2_rounded,
                  Colors.green,
                  _staffStats['totalStaff'].toString(),
                  () => _showComingSoon('Staff Attendance'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Generate\nReport',
                  Icons.description_rounded,
                  Colors.orange,
                  null,
                  () => _showComingSoon('Reports'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    String? badge,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAttendance() {
    // Mock data - Replace with actual API data
    final attendanceList = [
      {
        'name': 'John Doe',
        'avatar': 'JD',
        'clockIn': '08:15 AM',
        'status': 'On Time',
        'statusColor': Colors.green,
      },
      {
        'name': 'Jane Smith',
        'avatar': 'JS',
        'clockIn': '09:30 AM',
        'status': 'Late',
        'statusColor': Colors.orange,
      },
      {
        'name': 'Bob Wilson',
        'avatar': 'BW',
        'clockIn': 'Not Clocked In',
        'status': 'Absent',
        'statusColor': Colors.red,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    color: primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Today\'s Attendance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showComingSoon('Full Attendance List'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...attendanceList.map(
            (item) => _buildAttendanceItem(
              name: item['name'] as String,
              avatar: item['avatar'] as String,
              clockIn: item['clockIn'] as String,
              status: item['status'] as String,
              statusColor: item['statusColor'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem({
    required String name,
    required String avatar,
    required String clockIn,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primary.withOpacity(0.1),
            child: Text(
              avatar,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.login_rounded,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      clockIn,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovals() {
    // Mock data - Replace with actual API data
    final pendingList = [
      {
        'name': 'Sarah Johnson',
        'avatar': 'SJ',
        'type': 'Annual Leave',
        'duration': '3 days',
        'date': 'Dec 25-27, 2024',
        'reason': 'Family vacation',
      },
      {
        'name': 'Mike Brown',
        'avatar': 'MB',
        'type': 'Sick Leave',
        'duration': '1 day',
        'date': 'Dec 24, 2024',
        'reason': 'Medical appointment',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pending_actions_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Pending Approvals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // TextButton(
              //   onPressed: () => Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) => const LeaveApprovalScreen(),
              //     ),
              //   ),
              //   child: const Text('View All'),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          ...pendingList.map(
            (item) => _buildPendingItem(
              name: item['name'] as String,
              avatar: item['avatar'] as String,
              type: item['type'] as String,
              duration: item['duration'] as String,
              date: item['date'] as String,
              reason: item['reason'] as String,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingItem({
    required String name,
    required String avatar,
    required String type,
    required String duration,
    required String date,
    required String reason,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primary.withOpacity(0.1),
                child: Text(
                  avatar,
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event_note_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$type • $duration',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleReject(name),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApprove(name),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleApprove(String name) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Approved leave request for $name'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleReject(String name) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Rejected leave request for $name'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
