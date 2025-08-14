import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/holiday_model.dart';
import '../services/global_service.dart';

class HolidayRepository {
  /// Fetches holidays based on the specified year.
  ///
  /// If [year] is provided, this function fetches holidays for that particular year.
  /// If [year] is null, it fetches holidays for all available years.
  ///
  /// Returns a list of [Holiday] objects.

  Future<List<HolidayModel>> fetchHolidays({int? year}) async {
    final baseUrl = ServerService().baseUrl;
    final url = Uri.parse('${baseUrl}holidays');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<HolidayModel> holidays =
          body.map((json) => HolidayModel.fromJson(json)).toList();
      return holidays;
    } else if (response.statusCode == 404) {
      throw Exception(
        year != null
            ? 'No holidays found for the year $year.'
            : 'No holidays found.',
      );
    } else {
      throw Exception(
        'Failed to load holidays. Status code: ${response.statusCode}',
      );
    }
  }
}
