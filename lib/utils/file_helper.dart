import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../constants/constant.dart';
import '../localization/language.dart';
import '../localization/language_logic.dart';

class FileHelper {

  // Helper method to get month name
  Future<String> getMonthName(int month) async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    final Language language = languageLogic.language;
    final monthNames = [
      language.january,
      language.february,
      language.march,
      language.april,
      language.may,
      language.june,
      language.july,
      language.august,
      language.september,
      language.october,
      language.november,
      language.december,
    ];
    return monthNames[month - 1];
  }

  // DateFormat.MMM() gives Jan, Feb, etc.
  String getMonthShortName(int month) {
    return DateFormat.MMM().format(DateTime(0, month));
  }

  /**
   * Get current date by format Day Date Month, Year for En
   */

  /**
   * Get current date by format Day Date Month, Year for Kh
   */

  /**
   * Date format
   */
  static formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty || time == '00:00') {
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

  /**
   * Get color based on leave status
   * @param status: Leave status as a string
   * @return Color: Corresponding color for the status
   * Example: statusColor(status: "Approved") returns Colors.green
   */
  static Color statusColor({required String status}) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      case "Pending":
        return logoPink;
      case "Cancelled":
        return Colors.grey;
      default:
        return Colors.orangeAccent;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case '0' || 'Rejected': // Rejected
        return Icons.cancel_outlined;
      case '1' || 'Approved': // Approved
        return Icons.check_circle_outline;
      case '2' || 'Pending': // Pending
        return Icons.hourglass_empty;
      case '3' || 'Cancelled': // Cancelled
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  static getStatusColor(String status) {
    switch (status) {
      case '0' || 'Rejected':
        return Colors.red;
      case '1' || 'Approved':
        return Colors.green;
      case '2' || 'Pending':
        return Colors.orange;
      case '3' || 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Computed properties
  Future<String> getGreeting() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    final Language language = languageLogic.language;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return language.goodMorning;
    } else if (hour < 18) {
      return language.goodAfternoon;
    } else {
      return language.goodEvening;
    }
  }

  Color getLeaveTypeColor(String? leaveType) {
    if (leaveType == null) return secondary;

    switch (leaveType.toLowerCase()) {
      case 'annual leave':
        return secondary;
      case 'sick leave':
        return const Color(0xFFFF9800); // Orange
      case 'special leave':
        return const Color(0xFF9C27B0); // Purple
      case 'maternity leave':
        return const Color(0xFF4CAF50); // Green
      case 'unpaid leave':
        return const Color(0xFF607D8B); // Blue Grey
      default:
        return secondary;
    }
  }

  Color getAdjustmentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'late | missed checked-in':
      case 'early | missed checked-out':
        return Colors.orange;
      case 'missed scan':
        return Colors.red;
      default:
        return primary;
    }
  }

  static void viewImageFullScreen(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Supporting Document'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SpinKitFadingCircle(
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _isImageFile(String url) {
    final ext = url.split('?').first.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  static IconData _getDocFileIcon(String url) {
    final ext = url.split('?').first.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  static String _getDocFileName(String url) {
    return url.split('/').last.split('?').first;
  }

  static String _getDocFileType(String url) {
    final ext = url.split('?').first.split('.').last.toUpperCase();
    return '$ext Document';
  }

  /// Shared supporting-document card widget.
  /// [accentColor] defaults to [primary] if not provided.
  static Widget buildSupportingDocumentCard(
    BuildContext context,
    String fileUrl, {
    Color? accentColor,
  }) {
    final color = accentColor ?? primary;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, color: color, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Supporting Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isImageFile(fileUrl)) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: GestureDetector(
                  onTap: () => viewImageFullScreen(context, fileUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Image.network(
                          fileUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: SpinKitFadingCircle(
                                  color: color,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (ctx, _, __) => Container(
                            color: Colors.grey[100],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getDocFileIcon(fileUrl),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDocFileName(fileUrl),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getDocFileType(fileUrl),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
