import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/constant.dart';
import '../../models/holiday_model.dart';
import '../../repositories/holiday_repository.dart';

class HolidayCalendarScreen extends StatefulWidget {
  const HolidayCalendarScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HolidayCalendarScreenState createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  Map<DateTime, List<HolidayModel>> _holidays = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  List<HolidayModel> _currentMonthHolidays = [];

  bool isCeoUser = false;
  Color get themeColor => isCeoUser ? secondary : primary;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
    _checkUserRole();
  }

  Future<void> _loadHolidays() async {
    try {
      List<HolidayModel> holidays = await HolidayRepository().fetchHolidays(
        year: _focusedDay.year,
      );
      _groupHolidaysByDate(holidays);
      _updateCurrentMonthHolidays();
    } catch (error) {
      print('Error loading holidays: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _groupHolidaysByDate(List<HolidayModel> holidays) {
    for (var holiday in holidays) {
      final date = DateTime(
        holiday.holidayDate.year,
        holiday.holidayDate.month,
        holiday.holidayDate.day,
      );

      if (_holidays[date] == null) {
        _holidays[date] = [];
      }
      _holidays[date]!.add(holiday);
    }
  }

  List<HolidayModel> _getHolidaysForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _holidays[normalizedDate] ?? [];
  }

  void _updateCurrentMonthHolidays() {
    final selectedMonth = _focusedDay.month;
    final selectedYear = _focusedDay.year;

    _currentMonthHolidays =
        _holidays.entries
            .where(
              (entry) =>
                  entry.key.month == selectedMonth &&
                  entry.key.year == selectedYear,
            )
            .expand((entry) => entry.value)
            .toList();
    setState(() {});
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _checkUserRole() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final ceoUserValue = pref.getBool("ceoUser") ?? false;
    setState(() {
      isCeoUser = ceoUserValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Column(
          children: [
            Text(
              "Calendar",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ?  Center(child: SpinKitFadingCircle(color: themeColor))
              : Column(
                children: [
                  TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: DateTime(2023, 1, 1),
                    lastDay: DateTime(2025, 12, 31),
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getHolidaysForDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                        _updateCurrentMonthHolidays();
                      });
                    },
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekendStyle: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      weekdayStyle: TextStyle(
                        color: secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: const BoxDecoration(
                        color: logoPink,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: secondary,
                        shape: BoxShape.circle,
                      ),
                      holidayDecoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      defaultDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      holidayTextStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: secondary,
                        size: 30.0,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: secondary,
                        size: 30.0,
                      ),
                      leftChevronMargin: EdgeInsets.only(right: 1.0),
                      rightChevronMargin: EdgeInsets.only(left: 1.0),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        return const SizedBox();
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        final isHoliday = _getHolidaysForDay(day).isNotEmpty;
                        return Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color:
                                isHoliday
                                    ? Colors.grey[400]
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    day.weekday == DateTime.sunday ||
                                            day.weekday == DateTime.saturday
                                        ? Colors.redAccent
                                        : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            width: MediaQuery.of(context).size.width,
                            height: 56,
                            color: themeColor,
                            child: const Text(
                              "Holidays",
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _currentMonthHolidays.isEmpty
                              ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 32.0),
                                    Icon(
                                      Icons.calendar_month,
                                      size: 48.0,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16.0),
                                    Text(
                                      'No holidays this month',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16.0,
                                    right: 16.0,
                                    left: 16,
                                  ),
                                  child: ListView.separated(
                                    itemCount: _currentMonthHolidays.length,
                                    separatorBuilder:
                                        (context, index) => const Padding(
                                          padding: EdgeInsets.only(left: 55.0),
                                          child: Divider(
                                            color: Colors.grey,
                                            thickness: 0.1,
                                            height: 24.0,
                                          ),
                                        ),
                                    itemBuilder: (context, index) {
                                      final holiday =
                                          _currentMonthHolidays[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.blueAccent
                                                    .withOpacity(0.05),
                                                border: Border.all(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.event_note,
                                                color: Colors.grey,
                                                size: 20.0,
                                              ),
                                            ),
                                            const SizedBox(width: 16.0),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    holiday.holidayName,
                                                    style: const TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4.0),
                                                  // Space between text
                                                  Text(
                                                    _formatDate(
                                                      holiday.holidayDate,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 14.0,
                                                      color: Colors.blueGrey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
