import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

class SimpleFirebaseTest extends StatefulWidget {
  const SimpleFirebaseTest({super.key});

  @override
  State<SimpleFirebaseTest> createState() => _SimpleFirebaseTestState();
}

class _SimpleFirebaseTestState extends State<SimpleFirebaseTest> {
  String _status = '🔄 Testing Firebase...';
  String _token = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testFirebase();
  }

  Future<void> _testFirebase() async {
    try {
      // Test 1: Check if Firebase is initialized
      setState(() {
        _status = '🔄 Step 1: Checking Firebase initialization...';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (Firebase.apps.isEmpty) {
        setState(() {
          _status = '❌ Firebase is not initialized!';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status =
            '✅ Step 1: Firebase is initialized\n🔄 Step 2: Getting FCM token...';
      });

      // Test 2: Get FCM token
      final messaging = FirebaseMessaging.instance;

      // Request permission first
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        setState(() {
          _status = '❌ Notification permission denied!';
          _isLoading = false;
        });
        return;
      }

      final token = await messaging.getToken();

      setState(() {
        _token = token ?? 'Failed to get token';
        _status =
            token != null
                ? '✅ Step 1: Firebase initialized\n✅ Step 2: FCM token received\n🎉 Firebase is working perfectly!'
                : '❌ Failed to get FCM token';
        _isLoading = false;
      });

      // Test 3: Set up message listening
      if (token != null) {
        _setupMessageListening();
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  void _setupMessageListening() {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showMessageDialog('Foreground Message', message);
    });

    // Listen for background tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _showMessageDialog('Background Tap', message);
    });
  }

  void _showMessageDialog(String type, RemoteMessage message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('🔥 $type'),
            content: Text(
              'Title: ${message.notification?.title ?? 'No title'}\n'
              'Body: ${message.notification?.body ?? 'No body'}\n'
              'Data: ${message.data}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Firebase Status:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_status, style: const TextStyle(fontSize: 16)),
                  if (_isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Token Card
            const Text(
              'FCM Token:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    _token,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_token != 'Loading...' && !_token.contains('Failed'))
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _token));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Token copied to clipboard!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Test Instructions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. ✅ Check if status shows "Firebase is working perfectly!"\n'
                    '2. 📋 Copy the FCM token above\n'
                    '3. 🌐 Go to Firebase Console → Cloud Messaging\n'
                    '4. 📨 Click "Send your first message"\n'
                    '5. ✏️ Enter title: "Test" and message: "Hello!"\n'
                    '6. 🎯 Click "Send test message"\n'
                    '7. 📱 Paste your token and click "Test"\n'
                    '8. 🔔 You should receive a notification!',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Refresh Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _isLoading = true;
                            _status = '🔄 Testing Firebase...';
                            _token = 'Loading...';
                          });
                          _testFirebase();
                        },
                icon: const Icon(Icons.refresh),
                label: const Text('Test Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_isLoading) return Colors.yellow.shade100;
    if (_status.contains('❌')) return Colors.red.shade100;
    if (_status.contains('🎉')) return Colors.green.shade100;
    return Colors.grey.shade100;
  }
}
