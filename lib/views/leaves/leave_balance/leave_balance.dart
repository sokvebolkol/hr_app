import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../../constants/constant.dart';
import '../../../localization/language.dart';
import '../../../localization/language_logic.dart';
import '../../../widgets/leave_balance_item.dart';
import '../../../viewmodels/leave_balance_viewmodel.dart';

class LeaveBalanceDetailScreen extends StatefulWidget {
  const LeaveBalanceDetailScreen({super.key});

  @override
  State<LeaveBalanceDetailScreen> createState() =>
      _LeaveBalanceDetailScreenState();
}

class _LeaveBalanceDetailScreenState extends State<LeaveBalanceDetailScreen> {
  late LeaveBalanceViewModel _viewModel;
  Language language = Language();

  @override
  void initState() {
    super.initState();
    _viewModel = LeaveBalanceViewModel();

    // Fetch initial data
    _viewModel.fetchLeaveBalance();
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
      });
    }
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext modalContext) {
        return ChangeNotifierProvider.value(
          value: _viewModel,
          child: Consumer<LeaveBalanceViewModel>(
            builder: (context, viewModel, child) {
              final years =
                  viewModel.availableYears
                      .map((year) => year.toString())
                      .toList();

              return Container(
                height: 300,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        language.selectYear,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const DividerItem(),
                    Expanded(
                      child: CupertinoPicker(
                        backgroundColor: Colors.white,
                        itemExtent: 40.0,
                        scrollController: FixedExtentScrollController(
                          initialItem: years.indexOf(
                            viewModel.selectedYear.toString(),
                          ),
                        ),
                        onSelectedItemChanged: (int index) {
                          final selectedYear = int.parse(years[index]);
                          viewModel.changeYear(selectedYear);
                        },
                        children:
                            years.map((year) {
                              return Center(
                                child: Text(
                                  year,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(modalContext),
                          child: const Text('Done'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(237, 255, 255, 255),
        appBar: AppBar(
          backgroundColor: primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            language.leaveBalance,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Consumer<LeaveBalanceViewModel>(
              builder: (context, viewModel, child) {
                return InkWell(
                  onTap: _showYearPicker,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          viewModel.selectedYear.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<LeaveBalanceViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return _buildLoadingContent();
            }

            if (viewModel.errorMessage != null) {
              return _buildErrorContent(viewModel);
            }

            return _buildContent(viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitFadingCircle(color: primary),
          SizedBox(height: 16),
          Text(
            language.loadingLeaveBalance,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(LeaveBalanceViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            language.errorLoadingLeaveBalance,
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LeaveBalanceViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(viewModel),
            const SizedBox(height: 20),
            _buildLeaveBalanceDetails(viewModel),
            const SizedBox(height: 20),
            _buildLeaveRequestStats(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(LeaveBalanceViewModel viewModel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.annualLeaveSummary,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    language.used,
                    viewModel.annualLeaveUsed,
                    Colors.red[400]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    language.balance,
                    viewModel.annualLeaveBalance,
                    Colors.green[400]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    language.entitlement,
                    viewModel.annualLeaveEntitlement,
                    Colors.blue[400]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLeaveBalanceDetails(LeaveBalanceViewModel viewModel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.leaveBalanceDetails,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            LeaveBalanceItem(
              icon: Icons.beach_access,
              title: language.annualLeave,
              remainingDays: double.tryParse(viewModel.annualLeaveBalance) ?? 0,
              totalDays: double.tryParse(viewModel.annualLeaveEntitlement) ?? 0,
              color: Colors.blue[600]!,
              barColor: Colors.blue[400]!,
            ),
            const DividerItem(),
            LeaveBalanceItem(
              icon: Icons.local_hospital,
              title: language.sickLeave,
              remainingDays: double.tryParse(viewModel.sickLeaveBalance) ?? 0,
              totalDays: double.tryParse(viewModel.sickLeaveEntitlement) ?? 0,
              color: Colors.red[600]!,
              barColor: Colors.red[400]!,
            ),
            const DividerItem(),
            LeaveBalanceItem(
              icon: Icons.star,
              title: language.specialLeave,
              remainingDays:
                  double.tryParse(viewModel.specialLeaveBalance) ?? 0,
              totalDays:
                  double.tryParse(viewModel.specialLeaveEntitlement) ?? 0,
              color: Colors.orange[600]!,
              barColor: Colors.orange[400]!,
            ),
            const DividerItem(),
            LeaveBalanceItem(
              icon: Icons.child_care,
              title: language.maternityLeave,
              remainingDays:
                  double.tryParse(viewModel.maternityLeaveBalance) ?? 0,
              totalDays:
                  double.tryParse(viewModel.maternityLeaveEntitlement) ?? 0,
              color: Colors.pink[600]!,
              barColor: Colors.pink[400]!,
            ),
            const DividerItem(),
            LeaveBalanceItem(
              icon: Icons.money_off,
              title: language.unpaidLeave,
              label: language.daysUsed,
              remainingDays: double.tryParse(viewModel.unpaidLeaveUsed) ?? 0,
              totalDays: 0,
              color: Colors.grey[600]!,
              barColor: const Color.fromARGB(255, 39, 31, 31),
              isNoUsedItem: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveRequestStats(LeaveBalanceViewModel viewModel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.leaveRequestStatistics,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    language.approved,
                    viewModel.approvedLeaveRequest,
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    language.pending,
                    viewModel.pendingLeaveRequest,
                    Colors.orange,
                    Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    language.rejected,
                    viewModel.rejectedLeaveRequest,
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
