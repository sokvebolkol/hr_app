import 'package:chokchey_hr_app/views/leaves/leave_request/leave_request_screen.dart';
import 'package:chokchey_hr_app/views/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/constant.dart';
import 'requester_dashboard.dart';
import 'staff_dashboard_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _currentIndex = 0;
  bool _showStaffView = false; // false = Personal, true = Staff

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _showStaffView ? 'Staff Dashboard' : 'Personal Dashboard',
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
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardView();
      case 1:
        return const LeaveRequestScreen();
      case 2:
        return const ProfilePage();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child:
          _showStaffView
              ? const StaffDashboardView(key: ValueKey('staff'))
              : const DashboardScreen(key: ValueKey('personal')),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ✅ Toggle Switch Button
              _buildToggleSwitchNavItem(),
              _buildNavItem(
                icon: Icons.add_circle_rounded,
                label: 'Request Leave',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Toggle Switch Style Button
  Widget _buildToggleSwitchNavItem() {
    final isSelected = _currentIndex == 0;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
            HapticFeedback.lightImpact();
          } else {
            // Toggle between views when already on dashboard
            setState(() => _showStaffView = !_showStaffView);
            HapticFeedback.mediumImpact();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle Switch Container
              Container(
                width: 60,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        _showStaffView
                            ? [Colors.green, Colors.green.shade600]
                            : [Colors.blue, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_showStaffView ? Colors.green : Colors.blue)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Animated sliding circle
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment:
                          _showStaffView
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _showStaffView
                              ? Icons.groups_rounded
                              : Icons.person_rounded,
                          size: 16,
                          color: _showStaffView ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Label
              Text(
                _showStaffView ? 'Staff' : 'Personal',
                style: TextStyle(
                  color: isSelected ? primary : Colors.grey[600],
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? primary : Colors.grey[600];

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
