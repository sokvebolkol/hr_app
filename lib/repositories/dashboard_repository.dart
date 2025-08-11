import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_model.dart';
import '../models/user_model.dart';
import '../services/global_service.dart';

class DashboardRepository {
  final ServerService _serverService = ServerService();

  // Get dashboard data from API
  Future<DashboardData> getDashboardData() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final userId = pref.getString("userId");
      final token = pref.getString("token");

      if (userId == null) {
        throw Exception('User ID not found in local storage');
      }

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}home/$userId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Check if the response is successful
        if (responseData['success'] != true) {
          throw Exception('API returned unsuccessful response');
        }

        // Extract the data object
        final data = responseData['data'];
        if (data == null) {
          throw Exception('Data object is null in API response');
        }

        // Safely parse user data
        final userData = data['user'];
        if (userData == null) {
          throw Exception('User data is null in API response');
        }

        // Safely parse leaves data
        final leavesData = data['leaves'];
        List<LeaveModel> leaves = [];
        if (leavesData != null && leavesData is List) {
          leaves =
              leavesData
                  .where((e) => e != null) // Filter out null items
                  .map((e) {
                    try {
                      return LeaveModel.fromJson(e as Map<String, dynamic>);
                    } catch (error) {
                      print('Error parsing leave item: $e, Error: $error');
                      return null;
                    }
                  })
                  .where((e) => e != null) // Filter out failed parsing attempts
                  .cast<LeaveModel>()
                  .toList();
        }

        // Safely parse leave balance data
        final leaveBalancesData = data['leaveBalances'];
        LeaveBalanceModel? leaveBalance;

        if (leaveBalancesData != null &&
            leaveBalancesData is List &&
            leaveBalancesData.isNotEmpty &&
            leaveBalancesData[0] != null) {
          try {
            leaveBalance = LeaveBalanceModel.fromJson(
              leaveBalancesData[0] as Map<String, dynamic>,
            );
          } catch (error) {
            print(
              'Error parsing leave balance: ${leaveBalancesData[0]}, Error: $error',
            );
            // Create a default leave balance if parsing fails
            leaveBalance = _createDefaultLeaveBalance();
          }
        } else {
          // Create a default leave balance if data is missing
          leaveBalance = _createDefaultLeaveBalance();
        }

        return DashboardData(
          user: UserModel.fromJson(userData as Map<String, dynamic>),
          leaves: leaves,
          leaveBalance: leaveBalance,
        );
      } else {
        throw Exception(
          'Failed to fetch dashboard data: ${response.statusCode}. Response: ${response.body}',
        );
      }
    } catch (e) {
      print('Dashboard Repository Error: $e');
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // Create a default leave balance when data is missing or invalid
  LeaveBalanceModel _createDefaultLeaveBalance() {
    // You'll need to update this based on your actual LeaveBalanceModel constructor
    // Looking at your API response, it should probably be something like:
    return LeaveBalanceModel(
      id: 0,
      orgId: '',
      employeeId: '',
      year: DateTime.now().year,
      annualLeaveForwardBalance: '0',
      annualLeaveEntitlement: '0',
      annualLeaveUsed: '0',
      annualLeaveBalance: '0',
      sickLeaveEntitlement: '0',
      sickLeaveUsed: '0',
      sickLeaveBalance: '0',
      specialLeaveEntitlement: '0',
      specialLeaveUsed: '0',
      specialLeaveBalance: '0',
      maternityLeaveEntitlement: '0',
      maternityLeaveUsed: '0',
      maternityLeaveBalance: '0',
      unpaidLeaveUsed: '0',
      approvedLeaveRequest: '0',
      pendingLeaveRequest: '0',
      rejectedLeaveRequest: '0',
      remark: '',
    );
  }

  // Get user ID from local storage
  Future<String?> getUserId() async {
    try {
      final pref = await SharedPreferences.getInstance();
      return pref.getString("userId");
    } catch (e) {
      throw Exception('Error getting user ID: $e');
    }
  }

  // Logout user (clear local data)
  Future<void> logout() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.clear();
  }
}

class DashboardData {
  final UserModel user;
  final List<LeaveModel> leaves;
  final LeaveBalanceModel leaveBalance;

  DashboardData({
    required this.user,
    required this.leaves,
    required this.leaveBalance,
  });
}
