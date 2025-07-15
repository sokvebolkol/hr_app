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

getDateTimeYMD(time) {
  DateTime dateTimeApproved = DateTime.parse(time);
  String dateTime = DateFormat("yyyy-MM-dd").format(dateTimeApproved);
  return dateTime;
}