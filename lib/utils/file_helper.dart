import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  final _fileName = "counter.txt";

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<File> writeCounter(int counter) async {
    final file = await _localFile;
    return file.writeAsString('$counter');
  }

  Future<int> readCounter() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return int.parse(contents);
    } catch (e) {
      return 0;
    }
  }

// Dollar formatter function
  static String toDollarSyntax(double number) {
    return "\$ ${number.toStringAsFixed(2)}";
  }

// Convert Dollar to Riel
  static String toRielSyntax(double dollarAmount) {
    double exchangeRate = 4100.0; // Assume 1 dollar = 4100 riel
    double rielAmount = dollarAmount * exchangeRate;
    return "៛ ${rielAmount.toStringAsFixed(2)}";
  }

  // Phone number format
  static String formatPhoneNumber(String phoneNumber) {
    final formattedNumber = StringBuffer();
    if (phoneNumber.length >= 3) {
      formattedNumber.write(phoneNumber.substring(0, 3));
      formattedNumber.write('-');
    }
    if (phoneNumber.length >= 6) {
      formattedNumber.write(phoneNumber.substring(3, 6));
      formattedNumber.write('-');
    }
    formattedNumber.write(phoneNumber.substring(6));

    return formattedNumber.toString();
  }

  // Abbreviate Name
  static String abbreviateName(String fullName) {
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length < 2) {
      if (fullName.isNotEmpty) {
        return fullName[0].toUpperCase();
      } else {
        return '';
      }
    }

    String abbreviation = '';

    for (int i = 0; i < nameParts.length; i++) {
      String part = nameParts[i];
      if (part.isNotEmpty) {
        abbreviation += part[0].toUpperCase();
        if (abbreviation.length >= 2) {
          break;
        }
      }
    }

    return abbreviation;
  }

  /**
   * Get current date by format Day Date Month, Year for En
   */
  String getCurrentDayEn() {
    var now = DateTime.now();
    var formatter = DateFormat('EEEE d MMMM y');
    return formatter.format(now);
  }

  /**
   * Get current date by format Day Date Month, Year for Kh
   */
  String getCurrentDayKh() {
    initializeDateFormatting('km', null);
    var now = DateTime.now();
    var formatter = DateFormat('d MMMM y', 'km');
    return formatter.format(now);
  }
}
