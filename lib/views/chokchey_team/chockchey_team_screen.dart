import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../constants/constant.dart';

class ChockcheyTeamScreen extends StatefulWidget {
  const ChockcheyTeamScreen({super.key});

  @override
  State<ChockcheyTeamScreen> createState() => _ChockcheyTeamScreenState();
}

class _ChockcheyTeamScreenState extends State<ChockcheyTeamScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildFeatureItem(IconData icon, String text, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: secondary.withOpacity(0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
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
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        title: const Text(
          'Chokchey Team',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [secondary, secondary.withOpacity(0.8)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FontAwesomeIcons.users, size: 36, color: secondary),
                        const SizedBox(height: 14),
                        Text(
                          'About Chokchey Team',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: secondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "This module will help you stay informed about your company's team structure, memos, and announcements. Exciting features are coming soon!",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondary,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Animated Icon
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [secondary, secondary.withOpacity(0.7)],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: secondary.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.users, // FontAwesome Team icon
                                size: 46,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Main Title
                    Text(
                      'Coming Soon!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: secondary,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Chokchey Team & Structure',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          FaIcon(FontAwesomeIcons.infoCircle, color: secondary, size: 22),
                          const SizedBox(height: 10),
                          Text(
                            "We're working hard to bring you an amazing memo and announcements feature. Stay tuned for updates!",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Feature List
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: secondary.withOpacity(0.23)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming Features:',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(FontAwesomeIcons.bullhorn, 'Company-wide announcements'),
                          _buildFeatureItem(FontAwesomeIcons.clipboardList, 'Internal memos and updates'),
                          _buildFeatureItem(FontAwesomeIcons.bell, 'Real-time notifications'),
                          _buildFeatureItem(FontAwesomeIcons.userGroup, 'Department-specific messages'),
                          _buildFeatureItem(FontAwesomeIcons.sitemap, 'Team structure overview'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}