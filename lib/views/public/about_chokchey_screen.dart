import 'package:flutter/material.dart';
import '../../constants/constant.dart';

class AboutChokcheyScreen extends StatefulWidget {
  const AboutChokcheyScreen({super.key});

  @override
  State<AboutChokcheyScreen> createState() => _AboutChokcheyScreenState();
}

class _AboutChokcheyScreenState extends State<AboutChokcheyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhilosophyItem(String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        title: const Text(
          'About CHOKCHEY',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primary.withOpacity(0.05), Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section with Logo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo_256x256.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'CHOKCHEY',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Trusted Financial Partner',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Main Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // About Us Section
                      const Text(
                        'Who We Are',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ChokChey Finance Plc. was established on July 11th 2015. Micro Finance License obtained from National Bank of Cambodia in April, 2016.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The registered head office is located at #9-11, St. Veng sreng, Sangkat Steung Meanchey, Khan Meanchey, Phnom Penh, Kingdom of Cambodia.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Mission & Vision Cards
                      _buildInfoCard(
                        icon: Icons.visibility,
                        title: 'Our Vision',
                        description:
                            'We pursue to be a world class finance company, Beating the Banks in terms of profitability, Brand Recognition (Trust, Convenience and Speed) and Workforce Satisfaction.',
                        color: secondary,
                      ),
                      _buildInfoCard(
                        icon: Icons.flag,
                        title: 'Our Mission',
                        description:
                            'To gain lifetime loyalty from low-moderate income families, through lending and providing financial services to foster their sustainable business growth, and implanting our "winning habit culture" to their daily lives & business.',
                        color: primary,
                      ),
                      _buildInfoCard(
                        icon: Icons.groups,
                        title: 'Our Culture',
                        description:
                            'We are the best people powerhouse, thinking big and global in pursuit of world class company through our eternal winning habit and learning the positive changes. We all work for common growth and enjoy our lives. We are ChokChey Finance.',
                        color: logoPink,
                      ),
                      const SizedBox(height: 32),
                      // Philosophy
                      const Text(
                        'Our Philosophy',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: secondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPhilosophyItem('People, People and People'),
                            _buildPhilosophyItem('Honesty is the Best Policy'),
                            _buildPhilosophyItem('Open Opportunities'),
                            _buildPhilosophyItem(
                              'Performance-driven Compensation',
                            ),
                            _buildPhilosophyItem('Fairness', isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Contact Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildContactItem(
                              Icons.phone,
                              'Hotline',
                              '+855 (0) 23 922 126',
                            ),
                            _buildContactItem(
                              Icons.email,
                              'Email',
                              'info@chokchey.com.kh',
                            ),
                            _buildContactItem(
                              Icons.language,
                              'Website',
                              'www.chokchey.com.kh',
                            ),
                            _buildContactItem(
                              Icons.location_on,
                              'Head Office',
                              'Booyoung Town | Building, 1st Floor, Unit No 125 & 2nd Floor, Unit No 210 & 211, Russian Federation Blvd, Phum Borey Kamakar, Sangkat Tuek Thla, Khan Saensokh, Phnom Penh',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
