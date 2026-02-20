import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../models/attendance_adjustment_model.dart';
import '../../viewmodels/attendance_adjustment_viewmodel.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import 'attendance_adjustment_detail_screen.dart';

class AttendanceAdjustmentScreen extends StatefulWidget {
  const AttendanceAdjustmentScreen({super.key});

  @override
  State<AttendanceAdjustmentScreen> createState() =>
      _AttendanceAdjustmentScreenState();
}

class _AttendanceAdjustmentScreenState
    extends State<AttendanceAdjustmentScreen> {
  AttendanceMissing? _selectedAttendance;
  String _selectedAdjustmentType = '';
  AttendanceAdjustmentViewModel? _viewModel;
  Language language = Language();

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AttendanceAdjustmentViewModel>(
      create: (_) {
        _viewModel = AttendanceAdjustmentViewModel();
        _viewModel!.loadAttendanceData();
        return _viewModel!;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(language.adjustmentRequest),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<AttendanceAdjustmentViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.data == null) {
              return const Center(child: SpinKitFadingCircle(color: primary));
            }

            if (viewModel.errorMessage.isNotEmpty && viewModel.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: ${viewModel.errorMessage}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final viewModel =
                            Provider.of<AttendanceAdjustmentViewModel>(
                              context,
                              listen: false,
                            );
                        viewModel.refresh();
                      },
                      child: Text(language.retry),
                    ),
                  ],
                ),
              );
            }

            return _buildMainContent(viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(AttendanceAdjustmentViewModel viewModel) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request Limit Header - Fancy version
          if (viewModel.data?.requestLimit != null)
            _buildFancyRequestLimitCard(viewModel),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              language.selectDateForAdjustment,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          _buildAttendanceList(viewModel),
          const SizedBox(height: 64),
          _buildRequestButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(AttendanceAdjustmentViewModel viewModel) {
    final attendanceList = viewModel.data?.attendanceMissing ?? [];

    if (attendanceList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            language.noAttendanceRecordsFound,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children:
            attendanceList
                .map((attendance) => _buildAttendanceItem(attendance))
                .toList(),
      ),
    );
  }

  Widget _buildAttendanceItem(AttendanceMissing attendance) {
    final day = _formatDay(attendance.date);
    final dayName = _formatDayName(attendance.dayOfWeek);
    final adjustmentType = _getAdjustmentType(attendance);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Date column (keep fixed size)
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    dayName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Time in (Expanded)
            Expanded(
              flex: 2,
              child: Text(
                _formatTime(attendance.checkedIn),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Time out or status (Expanded)
            Expanded(
              flex: 3,
              child: Text(
                _getTimeOutDisplay(attendance),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getTimeOutColor(attendance),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Radio and label (Expanded)
            Expanded(
              flex: 4,
              child: GestureDetector(
                onTap: () => _selectAttendance(attendance, adjustmentType),
                child: Row(
                  children: [
                    Radio<String>(
                      value: attendance.date,
                      groupValue: _selectedAttendance?.date,
                      onChanged:
                          (value) =>
                              _selectAttendance(attendance, adjustmentType),
                      activeColor: primary,
                    ),
                    Flexible(
                      child: Text(
                        adjustmentType,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getAdjustmentTypeColor(adjustmentType),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDay(String date) {
    try {
      final DateTime dateTime = DateTime.parse(date);
      return dateTime.day.toString();
    } catch (e) {
      return date.split('-').last;
    }
  }

  String _formatDayName(String dayOfWeek) {
    return dayOfWeek.substring(0, 3);
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) {
      return '--:--';
    }
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = timeParts[1];

      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time;
    }
  }

  String _getTimeOutDisplay(AttendanceMissing attendance) {
    final timeOut = attendance.scanOut ?? attendance.clockOut;
    if (timeOut == null || timeOut.isEmpty) {
      return attendance.status;
    }
    return _formatTime(timeOut);
  }

  Color _getTimeOutColor(AttendanceMissing attendance) {
    final timeOut = attendance.scanOut ?? attendance.clockOut;
    if (timeOut == null || timeOut.isEmpty) {
      return Colors.red;
    }
    return Colors.blue;
  }

  String _getAdjustmentType(AttendanceMissing attendance) {
    // Use the status from API or derive from data
    if (attendance.status.isNotEmpty) {
      return attendance.status == 'Absent' ? 'Missed scan' : attendance.status;
    }

    final timeOut = attendance.scanOut ?? attendance.clockOut;
    if (timeOut == null || timeOut.isEmpty) {
      return 'Missed scan';
    }

    // Check if left early (before 5 PM)
    try {
      final timeParts = timeOut.split(':');
      final hour = int.parse(timeParts[0]);
      if (hour < 17) {
        return 'Leave early';
      }
    } catch (e) {
      // ignore
    }

    return 'Late scan';
  }

  Color _getAdjustmentTypeColor(String type) {
    switch (type) {
      case 'Leave early':
        return Colors.orange;
      case 'Missed scan':
        return Colors.red;
      case 'Late scan':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _selectAttendance(AttendanceMissing attendance, String adjustmentType) {
    setState(() {
      _selectedAttendance = attendance;
      _selectedAdjustmentType = adjustmentType;
    });
  }

  Widget _buildRequestButton() {
    final canSubmit = _selectedAttendance != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitRequest : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: Text(
          language.request,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (_selectedAttendance == null || _viewModel == null) {
      return;
    }

    // Navigate to detailed request screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AttendanceAdjustmentDetailScreen(
              selectedAttendance: _selectedAttendance!,
              adjustmentType: _selectedAdjustmentType,
              approvers: _viewModel!.data?.approvers ?? [],
            ),
      ),
    );

    // If request was submitted successfully, go back to dashboard
    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildFancyRequestLimitCard(AttendanceAdjustmentViewModel viewModel) {
    final limit = viewModel.data!.requestLimit;
    // Safely calculate progress value to avoid division by zero
    final progressValue =
        (limit.monthlyLimit > 0)
            ? (limit.requestsUsed / limit.monthlyLimit).clamp(0.0, 1.0)
            : 0.0;
    final isLimitReached = !limit.canRequest;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isLimitReached
                  ? [Colors.red[100]!, Colors.red[50]!, Colors.white]
                  : [Colors.green[100]!, Colors.green[50]!, Colors.white],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isLimitReached
                    ? Colors.red.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isLimitReached
                              ? [Colors.red, Colors.red[700]!]
                              : [Colors.green, Colors.green[700]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isLimitReached
                                ? Colors.red.withOpacity(0.4)
                                : Colors.green.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isLimitReached
                        ? Icons.block_rounded
                        : Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.monthlyRequestLimit,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            limit.currentMonth,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color:
                          isLimitReached
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${limit.requestsUsed}/${limit.monthlyLimit}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isLimitReached ? Colors.red[700] : Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLimitReached ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
