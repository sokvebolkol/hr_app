import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/staff_listing_model.dart';
import '../services/global_service.dart';

class StaffListingRepository {
  final ServerService _serverService = ServerService();

  Future<StaffListingResponse> getStaffListing({
    String? status,
    String? branchId,
    String? departmentId,
    int page = 1,
    String? date,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Build query parameters
      Map<String, String> queryParams = {'page': page.toString()};

      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }
      if (branchId != null) {
        queryParams['branch_id'] = branchId;
      }
      if (departmentId != null) {
        queryParams['department_id'] = departmentId;
      }
      if (date != null) {
        queryParams['date'] = date;
      }

      final uri = Uri.parse(
        '${_serverService.baseUrl}ceo/staff-listing',
      ).replace(queryParameters: queryParams);

      print('Staff Listing Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Staff Listing Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data is! Map<String, dynamic>) {
            throw Exception('Invalid response format: Expected JSON object');
          }

          return StaffListingResponse.fromJson(data);
        } catch (e) {
          print('JSON Parsing Error: $e');
          print('Raw Response: ${response.body}');
          throw Exception('Failed to parse response: $e');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ?? 'Failed to load staff listing',
          );
        } catch (parseError) {
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error in getStaffListing: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Please check your internet connection');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout: Please try again');
      } else {
        throw Exception('Error loading staff listing: $e');
      }
    }
  }
}
