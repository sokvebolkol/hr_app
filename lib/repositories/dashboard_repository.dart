import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_version.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_model.dart';
import '../models/user_model.dart';
import '../services/global_service.dart';
import '../services/http_service.dart';
import '../utils/exceptions.dart';
import '../utils/error_handler.dart';

class DashboardRepository {
  final ServerService _serverService = ServerService();

  // Get dashboard data from API
  Future<DashboardData> getDashboardData() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final userId = pref.getString("userId");
      final token = pref.getString("token");

      if (userId == null || token == null) {
        throw UnauthorizedException(
          message: 'Session expired. Please login again.',
        );
      }

      final response = await HttpService.get(
        url: '${_serverService.baseUrl}home/$userId',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      // Check if the response is successful
      if (responseData['success'] != true) {
        throw ServerException(message: 'Failed to fetch dashboard data');
      }

      // Extract the data object
      final data = responseData['data'];
      if (data == null) {
        throw DataParseException(message: 'Invalid response from server');
      }

      // Safely parse user data
      final userData = data['user'];
      if (userData == null) {
        throw DataParseException(message: 'User data not found in response');
      }

      // Safely parse leaves data
      final leavesData = data['leaves'];
      List<LeaveModel> leaves = [];
      if (leavesData != null && leavesData is List) {
        leaves =
            leavesData
                .where((e) => e != null)
                .map((e) {
                  try {
                    return LeaveModel.fromJson(e as Map<String, dynamic>);
                  } catch (error) {
                    ErrorHandler.logError(error, StackTrace.current);
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
          ErrorHandler.logError(error, StackTrace.current);
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
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      rethrow; // Rethrow to let ViewModel handle it
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
  final AppVersion? appVersion;

  DashboardData({
    required this.user,
    required this.leaves,
    required this.leaveBalance,
    this.appVersion,
  });
}
