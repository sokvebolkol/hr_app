import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../localization/language.dart';
import '../localization/language_logic.dart';

class DateSection extends StatefulWidget {
  const DateSection({super.key});

  @override
  State<DateSection> createState() => _DateSectionState();
}

class _DateSectionState extends State<DateSection> {
  Language language = Language();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    await initializeDateFormatting('km', null);
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildDateSection();
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isInitialized ? _getFormattedDate() : '',
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getFormattedDate() {
    if (language.code == 'KH') {
      // Khmer date format
      return "ថ្ងៃ${DateFormat('EEEE, d MMMM y', 'km').format(DateTime.now())}";
    } else {
      // English date format
      return DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    }
  }
}
