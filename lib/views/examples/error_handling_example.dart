import 'package:flutter/material.dart';
import '../services/error_display_service.dart';
import '../utils/network_checker.dart';

/// Example screen showing best practices for error handling
///
/// This demonstrates:
/// 1. How to handle errors from repositories
/// 2. How to show appropriate error dialogs
/// 3. How to implement retry logic
/// 4. How to check connection before heavy operations
class ExampleErrorHandlingScreen extends StatefulWidget {
  const ExampleErrorHandlingScreen({super.key});

  @override
  State<ExampleErrorHandlingScreen> createState() =>
      _ExampleErrorHandlingScreenState();
}

class _ExampleErrorHandlingScreenState
    extends State<ExampleErrorHandlingScreen> {
  bool _isLoading = false;
  String? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Example: Load data with proper error handling
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // In real code, call your repository:
      // final data = await yourRepository.getData();

      if (!mounted) return;
      setState(() {
        _data = 'Data loaded successfully';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show error with retry option
      await ErrorDisplayService.showError(
        context,
        error: error,
        onRetry: _loadData, // Retry same operation
        onDismiss: () {
          // Optional: Navigate back or show offline UI
        },
      );
    }
  }

  /// Example: Check connection before uploading/downloading
  Future<void> _uploadFile() async {
    if (!mounted) return;

    // Check connection first
    final hasConnection = await NetworkChecker.hasConnection();
    if (!hasConnection) {
      if (!mounted) return;
      await ErrorDisplayService.showNetworkError(context, onRetry: _uploadFile);
      return;
    }

    // Proceed with upload
    setState(() => _isLoading = true);

    try {
      // Your upload logic here
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show success
      await ErrorDisplayService.showSuccess(
        context,
        title: 'Upload Successful',
        message: 'Your file has been uploaded successfully.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      await ErrorDisplayService.showError(
        context,
        error: error,
        onRetry: _uploadFile,
      );
    }
  }

  /// Example: Confirm before delete with error handling
  Future<void> _deleteItem() async {
    if (!mounted) return;

    // Show confirmation
    final confirmed = await ErrorDisplayService.showConfirmation(
      context,
      title: 'Delete Item',
      message:
          'Are you sure you want to delete this item? This cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      type: DialogType.warning,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      // Your delete logic here
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() => _isLoading = false);

      await ErrorDisplayService.showSuccess(
        context,
        title: 'Deleted',
        message: 'Item has been deleted successfully.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      await ErrorDisplayService.showError(
        context,
        error: error,
        customTitle: 'Delete Failed',
        onRetry: _deleteItem,
      );
    }
  }

  /// Example: Listen to connectivity changes
  void _listenToConnectivity() {
    NetworkChecker.onConnectivityChanged.listen((result) {
      // Handle connectivity changes
      if (result.contains(ConnectivityResult.none)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Internet connection lost'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Internet connection restored'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Handling Example')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_data ?? 'No data'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Load Data'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _uploadFile,
                      child: const Text('Upload File'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _deleteItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete Item'),
                    ),
                  ],
                ),
              ),
    );
  }
}
