import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../constants/constant.dart';

/// Shows the birthday overlay.
Future<void> showBirthdayScreen(
  BuildContext context, {
  required UserModel user,
  required UserProfile profile,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 600),
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, __) => _BirthdayScreen(user: user, profile: profile),
  );
}

// ---------------------------------------------------------------------------
// Internal birthday screen widget
// ---------------------------------------------------------------------------

class _BirthdayScreen extends StatefulWidget {
  final UserModel user;
  final UserProfile profile;
  const _BirthdayScreen({required this.user, required this.profile});

  @override
  State<_BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<_BirthdayScreen>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;
  late final AnimationController _bounceController;
  late final AnimationController _shimmerController;

  late final Animation<double> _cakeBounce;
  late final Animation<double> _shimmer;

  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    // Floating confetti
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Cake bounce
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cakeBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _bounceController.forward();

    // Shimmer for gradient title
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    // Generate particles
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle.random(_rng));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _bounceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String get _formattedDob {
    try {
      final raw = widget.user.dob ?? '';
      if (raw.isEmpty) return '';
      final date = DateTime.parse(raw.split(' ')[0]);
      return DateFormat('MMMM dd').format(date);
    } catch (_) {
      return '';
    }
  }

  String get _wish {
    final isF = (widget.user.gender ?? '').toLowerCase().startsWith('f');
    final pronoun = isF ? 'her' : 'his';
    return 'Wishing you a day as bright as $pronoun smile, '
        'filled with joy, love, and all the happiness '
        '${isF ? 'she' : 'he'} deserves! 🌟';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ─── Background gradient ───────────────────────────────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a0533),
                  Color(0xFF3d0d6b),
                  Color(0xFF6a1a9a),
                  Color(0xFF9b2cb8),
                ],
              ),
            ),
          ),

          // ─── Confetti particles ─────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) {
              return CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              );
            },
          ),

          // ─── Blurred glow circles ───────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFff6bc2).withOpacity(0.25),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7c3aed).withOpacity(0.3),
              ),
            ),
          ),

          // ─── Main content ───────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: Column(
                children: [
                  // Stars header
                  const Text(
                    '✨ ★  ✨ ★  ✨',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Profile avatar with glow ring ──────────────────────
                  ScaleTransition(
                    scale: _cakeBounce,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const SweepGradient(
                              colors: [
                                Color(0xFFffd700),
                                logoPink,
                                primary,
                                secondary,
                                Color(0xFFffd700),
                              ],
                            ),
                          ),
                        ),
                        // White gap
                        Container(
                          width: 130,
                          height: 130,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(child: _buildAvatar()),
                        ),
                        // Crown badge
                        // Positioned(
                        //   top: 0,
                        //   child: Container(
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 10,
                        //       vertical: 4,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       gradient: const LinearGradient(
                        //         colors: [Color(0xFFffd700), Color(0xFFffaa00)],
                        //       ),
                        //       borderRadius: BorderRadius.circular(20),
                        //       boxShadow: [
                        //         BoxShadow(
                        //           color: const Color(
                        //             0xFFffd700,
                        //           ).withOpacity(0.6),
                        //           blurRadius: 8,
                        //         ),
                        //       ],
                        //     ),
                        //     child: const Text(
                        //       '👑 Birthday Star',
                        //       style: TextStyle(
                        //         fontSize: 11,
                        //         fontWeight: FontWeight.bold,
                        //         color: Colors.white,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Shimmer "Happy Birthday" title ────────────────────
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) {
                      return ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: const [
                              Color(0xFFffd700),
                              Colors.white,
                              Color(0xFFff6bc2),
                              Color(0xFFffd700),
                            ],
                            stops: [
                              (_shimmer.value - 0.5).clamp(0.0, 1.0),
                              _shimmer.value.clamp(0.0, 1.0),
                              (_shimmer.value + 0.2).clamp(0.0, 1.0),
                              (_shimmer.value + 0.5).clamp(0.0, 1.0),
                            ],
                          ).createShader(rect);
                        },
                        child: const Text(
                          'Happy Birthday! 🎉',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),
                  // Name
                  Text(
                    widget.profile.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Cake card ─────────────────────────────────────────
                  ScaleTransition(
                    scale: _cakeBounce,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('🎂', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 8),
                          Text(
                            widget.profile.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_formattedDob.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFffd700),
                                    Color(0xFFffaa00),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '🎈 $_formattedDob',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Wish card ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFffd700).withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '💌 Birthday Wish',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFffd700),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _wish,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Close button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFffd700),
                        foregroundColor: const Color(0xFF1a0533),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFFffd700).withOpacity(0.5),
                      ),
                      child: const Text(
                        'Thank You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = widget.profile.profileImageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackAvatar(),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    final initials =
        widget.profile.fullName.isNotEmpty
            ? widget.profile.fullName[0].toUpperCase()
            : '?';
    return Container(
      color: primary,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti particle model & painter
// ---------------------------------------------------------------------------

class _Particle {
  final double x; // 0..1 horizontal start
  final double speed; // vertical fall speed
  final double size;
  final Color color;
  final double wobble; // horizontal wobble frequency
  final double wobbleAmt;
  final double startOffset; // phase offset so they don't all start at top

  const _Particle({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.wobble,
    required this.wobbleAmt,
    required this.startOffset,
  });

  factory _Particle.random(Random rng) {
    const colors = [
      Color(0xFFffd700),
      logoPink,
      secondary,
      primary,
      Color(0xFF2ed573),
      Colors.white,
    ];
    return _Particle(
      x: rng.nextDouble(),
      speed: 0.05 + rng.nextDouble() * 0.15,
      size: 4 + rng.nextDouble() * 8,
      color: colors[rng.nextInt(colors.length)],
      wobble: 1 + rng.nextDouble() * 3,
      wobbleAmt: rng.nextDouble() * 0.04,
      startOffset: rng.nextDouble(),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.startOffset) % 1.0;
      final dx = (p.x + sin(t * pi * 2 * p.wobble) * p.wobbleAmt) * size.width;
      final dy = t * size.height;

      final paint = Paint()..color = p.color.withOpacity(0.7);
      canvas.drawCircle(Offset(dx, dy), p.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
