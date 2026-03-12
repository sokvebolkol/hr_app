import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/global_service.dart';

/// Bottom sheet widget for environment switching
/// Accessible by tapping logo 7 times on login screen
class EnvironmentSwitcherBottomSheet extends StatefulWidget {
  const EnvironmentSwitcherBottomSheet({super.key});

  /// Show PIN dialog first, then environment switcher if PIN is correct
  static Future<void> show(BuildContext context) async {
    final pinCorrect = await _showPinDialog(context);
    if (pinCorrect && context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const EnvironmentSwitcherBottomSheet(),
      );
    }
  }

  /// Show PIN entry dialog
  static Future<bool> _showPinDialog(BuildContext context) async {
    final TextEditingController pinController = TextEditingController();
    const String correctPin = '7777';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.lock_outline, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                const Text('Enter PIN'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter PIN to access environment settings',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onSubmitted: (value) {
                    if (value == correctPin) {
                      Navigator.pop(context, true);
                    } else {
                      HapticFeedback.heavyImpact();
                      pinController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Incorrect PIN'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (pinController.text == correctPin) {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, true);
                  } else {
                    HapticFeedback.heavyImpact();
                    pinController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Incorrect PIN'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  @override
  State<EnvironmentSwitcherBottomSheet> createState() =>
      _EnvironmentSwitcherBottomSheetState();
}

class _EnvironmentSwitcherBottomSheetState
    extends State<EnvironmentSwitcherBottomSheet> {
  final ServerService _serverService = ServerService();
  bool _isChanging = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleEnvironmentChange(Environment env) async {
    if (env == _serverService.currentEnvironment) {
      Navigator.pop(context);
      return;
    }

    // Check if user is logged in
    final isLoggedIn = await _checkIfLoggedIn();

    final confirmed = await _showConfirmationDialog(env, isLoggedIn);
    if (!confirmed) {
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
            content: Text('Switched to ${_getEnvironmentName(env)}'),
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
            title: Row(
              children: [
                Icon(
                  _getEnvironmentIcon(env),
                  color: _getEnvironmentColor(env),
                ),
                const SizedBox(width: 12),
                const Text('Switch Environment?'),
              ],
            ),
            content: Text(
              'Switch to ${_getEnvironmentName(env)}?\n\n'
              '${isLoggedIn ? "⚠️ You will be logged out.\n\n" : ""}'
              'The app will restart.',
              style: const TextStyle(fontSize: 15),
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
                  foregroundColor: Colors.white,
                ),
                child: const Text('Switch'),
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
        return 'Local';
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
        return Icons.computer;
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

  Widget _buildEnvironmentOption(Environment env) {
    final isSelected = env == _serverService.currentEnvironment;
    final color = _getEnvironmentColor(env);

    return InkWell(
      onTap: _isChanging ? null : () => _handleEnvironmentChange(env),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getEnvironmentIcon(env), color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getEnvironmentName(env),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.black87,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
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
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child:
          _isChanging
              ? Container(
                height: 300,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Switching environment...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'App will restart',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.dns_outlined,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Switch Environment',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Select server environment',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Environment options
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        _buildEnvironmentOption(Environment.production),
                        const SizedBox(height: 12),
                        _buildEnvironmentOption(Environment.uat),
                        const SizedBox(height: 12),
                        _buildEnvironmentOption(Environment.development),

                        // Info message
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Switching will logout and restart the app',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
                ],
              ),
    );
  }
}
