import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/**
 * App colors
 */

const primary = Color(0xFF0fbab5);
const secondary = Color(0xFF052744);
const logoPink = Color(0xffDE6EA0);

/**
 * App size padding
 */

const appPadding = 16.0;

/**
 * font size label
 */

const labelHeading = 20;
const labelSubHeading = 18;
const labelBody = 16;

// Validation for email address
bool validateEmail(String email) {
  bool isValid = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  ).hasMatch(email);
  return isValid;
}

// Function to check if the input contains a number
bool isNumber(String input) {
  final numberRegex = RegExp(r'^[0-9]+$');
  return numberRegex.hasMatch(input);
}

// Function to check if the input contains an emoji
bool isEmoji(String input) {
  final emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
    unicode: true,
  );
  return emojiRegex.hasMatch(input);
}

const getIosUpdateUrl = "itms-beta://testflight.apple.com/join/FeNKCUGS";
const getAndroidUpdateUrl =
    "https://drive.google.com/file/d/1E2VcMH2lDqC76ZaoY9FwaYlmcAVX3CXe/view?usp=sharing";

enum LoadingStatus { none, loading, error, done }

final leaveTypes = [
  {"label": "Annual Leave", "value": 700001},
  {"label": "Sick Leave", "value": 700002},
  {"label": "Unpaid Leave", "value": 700003},
  {"label": "Maternity Leave", "value": 700004},
  {"label": "Special Leave", "value": 700005},
];

final leavesFor = [
  {"label": "Half Day", "value": 0},
  {"label": "Full Day", "value": 1},
];

final leaveNotes = [
  {"label": "Morning", "value": 1},
  {"label": "Afternoon", "value": 0},
  // {"label": "Full Day", "value": 10},
];

final approvalLevels = [
  {"label": "First Approver", "value": 1},
  {"label": "Second Approver", "value": 2},
];

// Convert time format to AM or PM
String convertToAmPm(String time24) {
  DateTime dateTime = DateFormat("HH:mm:ss").parse(time24);
  String time12 = DateFormat.jm().format(dateTime);
  return time12;
}

// Get branch name base on branch ID
String getBranchName(String branchId) {
  final Map<String, String> branches = {
    '0120': 'SMC',
    '0150': 'TTT',
    '0140': 'TKH',
    '0160': 'KPS',
    '0170': 'CHP',
    '0100': 'HQ',
    // '0180': 'KOP',
    '0190': 'KPL',
    '0200': 'TRK',
    '0130': 'SSK',
    '0210': 'CHK',
    '0220': 'SST',
  };

  return branches[branchId] ?? 'Branch ID not found';
}

const annualLeave = '700001';
const sickLeave = '700002';
const unPaidLeave = '700003';
const maternityLeave = '700004';
const specialLeave = '700005';

// Leave Status that is cancelled by user
String leaveCancelled = 'Unknown';

getDateTimeYMD(time) {
  DateTime dateTimeApproved = DateTime.parse(time);
  String dateTime = DateFormat("yyyy-MM-dd").format(dateTimeApproved);
  return dateTime;
}

/**
 * Avatar colors - Light background and darker text variants
 */

// Primary avatar colors
final primaryAvatarBackground = primary.withOpacity(0.2);
final primaryAvatarText = primary;

// Secondary avatar colors
final secondaryAvatarBackground = secondary.withOpacity(0.1);
final secondaryAvatarText = secondary;

// Logo pink avatar colors
final pinkAvatarBackground = logoPink.withOpacity(0.15);
final pinkAvatarText = logoPink;

// Additional avatar color variants
final orangeAvatarBackground = Colors.orange.withOpacity(0.15);
final orangeAvatarText = Colors.orange[700]!;

final blueAvatarBackground = Colors.blue.withOpacity(0.15);
final blueAvatarText = Colors.blue[700]!;

final greenAvatarBackground = Colors.green.withOpacity(0.15);
final greenAvatarText = Colors.green[700]!;

final redAvatarBackground = Colors.red.withOpacity(0.15);
final redAvatarText = Colors.red[700]!;

final purpleAvatarBackground = Colors.purple.withOpacity(0.15);
final purpleAvatarText = Colors.purple[700]!;

/**
 * Avatar Color Generator - Returns different colors based on name or index
 */
class AvatarColorGenerator {
  static const List<Map<String, Color>> _colorPalette = [
    {'background': Color(0x330fbab5), 'text': Color(0xFF0fbab5)}, // Primary
    {'background': Color(0x1A052744), 'text': Color(0xFF052744)}, // Secondary
    {'background': Color(0x26DE6EA0), 'text': Color(0xFFDE6EA0)}, // Logo pink
    {'background': Color(0x26FF9800), 'text': Color(0xFFE65100)}, // Orange
    {'background': Color(0x262196F3), 'text': Color(0xFF1976D2)}, // Blue
    {'background': Color(0x264CAF50), 'text': Color(0xFF388E3C)}, // Green
    {'background': Color(0x26F44336), 'text': Color(0xFFD32F2F)}, // Red
    {'background': Color(0x269C27B0), 'text': Color(0xFF7B1FA2)}, // Purple
  ];

  /// Generate colors based on name (for consistent colors per user)
  static Map<String, Color> getColorsFromName(String name) {
    if (name.isEmpty) return _colorPalette[0];

    // Use name hash to get consistent color
    int hash = name.hashCode.abs();
    int index = hash % _colorPalette.length;
    return _colorPalette[index];
  }

  /// Generate colors based on index (for lists)
  static Map<String, Color> getColorsFromIndex(int index) {
    int colorIndex = index % _colorPalette.length;
    return _colorPalette[colorIndex];
  }

  /// Get primary colors
  static Map<String, Color> getPrimaryColors() {
    return _colorPalette[0];
  }

  /// Get secondary colors
  static Map<String, Color> getSecondaryColors() {
    return _colorPalette[1];
  }

  /// Get logo pink colors
  static Map<String, Color> getPinkColors() {
    return _colorPalette[2];
  }
}
