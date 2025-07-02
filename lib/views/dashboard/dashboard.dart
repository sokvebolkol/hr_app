import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/constant.dart';
import '../../widgets/annual_leave_card_widget.dart';
import '../../widgets/function_card.dart';
import '../../widgets/leave_request.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(237, 255, 255, 255),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: primary,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 60,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage(
                          'assets/images/profile.jpg',
                        ),
                        backgroundColor: Colors.blueAccent,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Good morning",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Kol Sokvebol",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 24,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Text(
              DateFormat('EEEE dd MMMM, yyyy').format(DateTime.now()),
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AnnualLeaveBalanceWidget(),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FunctionIconCardWidget(
                    iconData: Icons.access_time,
                    label: 'Clock In | Out',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: FunctionIconCardWidget(
                    iconData: Icons.history,
                    label: 'Leave History',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: FunctionIconCardWidget(
                    iconData: Icons.calendar_month,
                    label: 'Attendance Logs',
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Recently Leave Request",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 2,
              itemBuilder: (context, index) => const LeaveRequestWidget(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ConvexAppBar(
        key: ValueKey(_currentIndex),
        color: Colors.white,
        backgroundColor: primary,
        style: TabStyle.react,
        items: const [
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.home, title: 'Request Leave'),
          TabItem(icon: Icons.person, title: 'Profile'),
        ],
        initialActiveIndex: _currentIndex,
        onTap: (int i) {
          setState(() {
            _currentIndex = i;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 1;
          });
        },
        backgroundColor: primary,
        shape: const CircleBorder(),
        child: const Icon(FontAwesomeIcons.calendarPlus, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
