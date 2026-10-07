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

/**
 * font size label
 */

// Legacy constants (deprecated - use async functions above)
final leaveTypes = [
  {"label": "Annual Leave", "value": 700001},
  {"label": "Sick Leave", "value": 700002},
  {"label": "Unpaid Leave", "value": 700003},
  {"label": "Maternity Leave", "value": 700004},
  {"label": "Special Leave", "value": 700005},
];

// Convert time format to AM or PM
String convertToAmPm(String time24) {
  DateTime dateTime = DateFormat("HH:mm:ss").parse(time24);
  String time12 = DateFormat.jm().format(dateTime);
  return time12;
}

const annualLeave = '700001';
const sickLeave = '700002';
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

// Secondary avatar colors
final secondaryAvatarBackground = secondary.withOpacity(0.1);

/**
 * Avatar Color Generator - Returns different colors based on name or index
 */
