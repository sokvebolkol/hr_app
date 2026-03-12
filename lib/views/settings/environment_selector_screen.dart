import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/global_service.dart';

class EnvironmentSelectorScreen extends StatefulWidget {
  const EnvironmentSelectorScreen({super.key});

  @override
  State<EnvironmentSelectorScreen> createState() =>
      _EnvironmentSelectorScreenState();
}

class _EnvironmentSelectorScreenState extends State<EnvironmentSelectorScreen> {
  final ServerService _serverService = ServerService();
  Environment? _selectedEnvironment;
  bool _isChanging = false;

  @override
  void initState() {
    super.initState();
    _selectedEnvironment = _serverService.currentEnvironment;
  }

  Future<void> _handleEnvironmentChange(Environment env) async {
    if (env == _serverService.currentEnvironment) {
      return;
    }

    // Check if user is logged in
    final isLoggedIn = await _checkIfLoggedIn();

    final confirmed = await _showConfirmationDialog(env, isLoggedIn);
    if (!confirmed) {
      setState(() {
        _selectedEnvironment = _serverService.currentEnvironment;
      });
      return;
    }

    setState(() {
      _isChanging = true;
    });

    try {
      // Switch environment first
      await _serverService.switchToEnvironment(env);

      // Clear user session data (logout)
      await _serverService.clearUserSession();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Environment changed to ${_getEnvironmentName(env)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Wait a bit then restart the app
        await Future.delayed(const Duration(seconds: 2));

        // Restart the app to apply changes and go to login
        Restart.restartApp();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() {
        _isChanging = false;
        _selectedEnvironment = _serverService.currentEnvironment;
      });
    }
  }

  Future<bool> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<bool> _showConfirmationDialog(Environment env, bool isLoggedIn) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Environment'),
            content: Text(
              'Are you sure you want to switch to ${_getEnvironmentName(env)}?\n\n'
              '${isLoggedIn ? "⚠️ You will be logged out.\n\n" : ""}'
              'The app will restart to apply changes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getEnvironmentColor(env),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  String _getEnvironmentName(Environment env) {
    switch (env) {
      case Environment.production:
        return 'Production';
      case Environment.uat:
        return 'UAT';
      case Environment.development:
        return 'Development';
    }
  }

  Color _getEnvironmentColor(Environment env) {
    switch (env) {
      case Environment.production:
        return Colors.green;
      case Environment.uat:
        return Colors.orange;
      case Environment.development:
        return Colors.blue;
    }
  }

  IconData _getEnvironmentIcon(Environment env) {
    switch (env) {
      case Environment.production:
        return Icons.cloud_done;
      case Environment.uat:
        return Icons.science;
      case Environment.development:
        return Icons.code;
    }
  }

  String _getEnvironmentUrl(Environment env) {
    switch (env) {
      case Environment.production:
        return ServerService.prodUrl;
      case Environment.uat:
        return ServerService.uatUrl;
      case Environment.development:
        return ServerService.devUrl;
    }
  }

  Widget _buildEnvironmentCard(Environment env) {
    final isSelected = _selectedEnvironment == env;
    final isCurrent = _serverService.currentEnvironment == env;
    final color = _getEnvironmentColor(env);

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap:
            _isChanging
                ? null
                : () {
                  setState(() {
                    _selectedEnvironment = env;
                  });
                  _handleEnvironmentChange(env);
                },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEnvironmentIcon(env),
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getEnvironmentName(env),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? color : Colors.black87,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getEnvironmentUrl(env),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected && !isCurrent)
                    Icon(Icons.check_circle, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment Settings'),
        backgroundColor: _getEnvironmentColor(
          _serverService.currentEnvironment,
        ),
      ),
      body:
          _isChanging
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Changing environment...'),
                    SizedBox(height: 8),
                    Text(
                      'App will restart',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Environment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _serverService.baseUrlName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _serverService.baseUrl,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Environment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildEnvironmentCard(Environment.production),
                  const SizedBox(height: 12),
                  _buildEnvironmentCard(Environment.uat),
                  const SizedBox(height: 12),
                  _buildEnvironmentCard(Environment.development),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Note: Changing the environment will restart the app. '
                              'Make sure to save any unsaved work before proceeding.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
