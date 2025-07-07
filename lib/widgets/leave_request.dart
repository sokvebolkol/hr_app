import 'package:flutter/material.dart';

class LeaveRequestWidget extends StatelessWidget {
  const LeaveRequestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                // CircleAvatar(
                //   radius: 16,
                //   backgroundColor: Colors.grey[300],
                //   child: Icon(Icons.person, color: Colors.grey[700]),
                // ),
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/my-profile.png'),
                  backgroundColor: Colors.blueAccent,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Heng Souhouy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  'Total 1.0 day(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            const Divider(color: Colors.grey, thickness: 0.3),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 2,
                  child: Text(
                    '23-Jan-2025 → 23-Jan-2025',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Reason: Development Testing',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    _buildCircle(true),
                    _buildConnectingLine(),
                    _buildCircle(false),
                    _buildConnectingLine(),
                    _buildCircle(false),
                    const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'First Approver',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    Text(
                      'Second Approver',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'HR(Default)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(bool isActive) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.green : Colors.grey[400],
      ),
    );
  }

  Widget _buildConnectingLine() {
    return Expanded(child: Container(height: 2, color: Colors.grey[400]));
  }
}
