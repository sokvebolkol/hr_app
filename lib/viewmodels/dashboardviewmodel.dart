import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/leave_balance_model.dart';
import '../models/leave_model.dart';
import '../models/user_model.dart';
import '../services/global_service.dart';

class DashboardViewModel extends ChangeNotifier {
  UserModel? user;
  List<LeaveModel> leaves = [];
  LeaveBalanceModel? leaveBalance;
  bool isLoading = false;
  String? error;

  Future<void> fetchDashboard(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${ServerService().baseUrl}home/$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // debugPrint(data);
        user = UserModel.fromJson(data['user']);
        leaves =
            (data['leaves'] as List)
                .map((e) => LeaveModel.fromJson(e))
                .toList();
        leaveBalance = LeaveBalanceModel.fromJson(data['leaveBalances'][0]);
      } else {
        error = "Failed to load dashboard";
      }
    } catch (e) {
      error = "Network error";
    }
    isLoading = false;
    notifyListeners();
  }
}
