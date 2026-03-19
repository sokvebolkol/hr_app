import 'package:chokchey_hr_app/views/leaves/leave_request/leave_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constant.dart';
import '../menu/menu_screen.dart';
import 'requester_dashboard.dart';
import 'staff_dashboard_screen.dart';

// Combine RequesterDashboardScreen and StaffDashboardScreen into ManagerDashboard with toggle switch in bottom nav bar.
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _currentIndex = 0;
  bool _showStaffView = false; // false = Personal, true = Staff
  bool _triggerPersonalRefresh = false;

  static const _kShowStaffViewKey = 'manager_dashboard_show_staff_view';

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showStaffView = prefs.getBool(_kShowStaffViewKey) ?? false;
      });
    }
  }

  Future<void> _setStaffView(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowStaffViewKey, value);
    setState(() => _showStaffView = value);
  }

  void _refreshPersonalDashboard() {
    setState(() {
      _triggerPersonalRefresh = !_triggerPersonalRefresh;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton:
          _showStaffView
              ? null
              : Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    // Main soft shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),

                    // Ambient light
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    // Primary glow
                    BoxShadow(
                      color: primary.withOpacity(0.18),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: FloatingActionButton(
                    elevation: 0,
                    backgroundColor: primary,
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaveRequestScreen(),
                        ),
                      );
                      if (result == true) {
                        _refreshPersonalDashboard();
                      }
                    },
                  ),
                ),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardView();
      case 1:
        return const MenuScreen();
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
              ? StaffDashboardScreen(
                key: const ValueKey('staff'),
                onNavigateToMenu: () {
                  setState(() => _currentIndex = 1);
                },
              )
              : RequesterDashboardScreen(
                key: ValueKey('personal-$_triggerPersonalRefresh'),
                hideBottomNav: true,
                onNavigateToMenu: () {
                  setState(() => _currentIndex = 1);
                },
              ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.95), Colors.white],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Container(
        constraints: BoxConstraints(
          minHeight: isSmallScreen ? 80 : 90,
          maxHeight: isSmallScreen ? 85 : 95,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ Toggle Switch Button
            _buildToggleSwitchNavItem(),
            SizedBox(width: isSmallScreen ? 80 : 100), // Space for FAB
            _buildNavItem(icon: Icons.menu_rounded, label: 'Menu', index: 1),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Toggle Switch Style Button
  Widget _buildToggleSwitchNavItem() {
    final isSelected = _currentIndex == 0;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: GestureDetector(
          onTap: () {
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
              HapticFeedback.lightImpact();
            } else {
              // Toggle between views when already on dashboard
              _setStaffView(!_showStaffView);
              HapticFeedback.mediumImpact();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle Switch Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 64,
                height: 34,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        _showStaffView
                            ? [
                              secondary,
                              secondary.withOpacity(0.8),
                              secondary.withOpacity(0.9),
                            ]
                            : [
                              primary,
                              primary.withOpacity(0.8),
                              primary.withOpacity(0.9),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: (_showStaffView ? secondary : primary).withOpacity(
                        0.4,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: (_showStaffView ? secondary : primary).withOpacity(
                        0.2,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Animated sliding circle
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      alignment:
                          _showStaffView
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFFAFAFA)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          _showStaffView
                              ? Icons.groups_rounded
                              : Icons.person_rounded,
                          size: 16,
                          color: _showStaffView ? secondary : primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? primary : Colors.grey[600],
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                child: Text(
                  _showStaffView ? 'Staff' : 'Personal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: GestureDetector(
          onTap: () {
            setState(() => _currentIndex = index);
            HapticFeedback.lightImpact();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient:
                      isSelected
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary.withOpacity(0.2),
                              primary.withOpacity(0.1),
                            ],
                          )
                          : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: primary.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: isSelected ? 1.1 : 1.0,
                  child: Icon(icon, color: color, size: 24),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
