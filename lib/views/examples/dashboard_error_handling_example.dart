import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboardviewmodel.dart';
import '../../utils/error_handler.dart';

/// Example: How to use the error handling with modal dialogs in your UI widgets

class DashboardViewExample extends StatefulWidget {
  const DashboardViewExample({super.key});

  @override
  State<DashboardViewExample> createState() => _DashboardViewExampleState();
}

class _DashboardViewExampleState extends State<DashboardViewExample> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final viewModel = context.read<DashboardViewModel>();
    await viewModel.fetchDashboard();

    // Show error modal if any
    if (mounted && viewModel.errorMessage != null) {
      ErrorHandler.showErrorDialog(
        context,
        message: viewModel.errorMessage!,
        onRetry: _loadData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          // Show loading indicator
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error state with retry button
          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show success state with data
          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Welcome, ${viewModel.username}'),
                const SizedBox(height: 16),
                Text('Available Leave: ${viewModel.availableLeave}'),
                Text('Used Leave: ${viewModel.usedLeave}'),
                const SizedBox(height: 16),
                const Text(
                  'Recent Leaves:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ...viewModel.sortedLeaves.map(
                  (leave) => ListTile(
                    title: Text(leave.ltype),
                    subtitle: Text('${leave.frdat} - ${leave.todat}'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Example: Simple approach - Just show loading and data, modal handles errors
class DashboardViewSimpleExample extends StatefulWidget {
  const DashboardViewSimpleExample({super.key});

  @override
  State<DashboardViewSimpleExample> createState() =>
      _DashboardViewSimpleExampleState();
}

class _DashboardViewSimpleExampleState
    extends State<DashboardViewSimpleExample> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final viewModel = context.read<DashboardViewModel>();
    await viewModel.fetchDashboard();

    // Automatically show error modal - clean and simple!
    if (mounted && viewModel.errorMessage != null) {
      ErrorHandler.showErrorDialog(
        context,
        message: viewModel.errorMessage!,
        onRetry: _loadData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Just show the data - errors are handled by modal
          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (viewModel.user != null) ...[
                  Text('Welcome, ${viewModel.username}'),
                  const SizedBox(height: 16),
                  Text('Available Leave: ${viewModel.availableLeave}'),
                  Text('Used Leave: ${viewModel.usedLeave}'),
                ] else ...[
                  const Center(child: Text('Pull down to refresh')),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
