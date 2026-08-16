import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({super.key});

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _masterController;

  late final Animation<double> _bgFade;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconMove;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleMove;
  late final Animation<double> _taglineFade;
  late final Animation<double> _pulseLine;

  static const _primaryNavy = Color(0xFF0B1F3A);
  static const _emergencyRed = Color(0xFFE31B23);
  static const _softRed = Color(0xFFFDEBEC);
  static const _background = Color(0xFFF8FAFC);
  static const _secondaryText = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 0 - 300ms: Background Fade (though scaffold handles base color)
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.15, curve: Curves.easeIn),
      ),
    );

    // 200 - 700ms: Icon Fade, Scale, Move
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.1, 0.35, curve: Curves.easeOut),
      ),
    );
    _iconScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.1, 0.35, curve: Curves.easeOutCubic),
      ),
    );
    _iconMove = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.1, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // 500 - 1000ms: Subtle Route/Pulse line animation
    _pulseLine = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.25, 0.5, curve: Curves.easeInOut),
      ),
    );

    // 800 - 1300ms: Title Fade & Move
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleMove = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 1100 - 1600ms: Tagline Fade
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
      ),
    );

    _masterController.forward();
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _background,
      body: AnimatedBuilder(
        animation: _masterController,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Subtle radial glow behind logo
              Positioned(
                top: screenHeight * 0.4 - 150,
                left: MediaQuery.of(context).size.width / 2 - 150,
                child: Opacity(
                  opacity: _bgFade.value * 0.4,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _softRed.withOpacity(0.5),
                          _background.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Main Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  Transform.translate(
                    offset: Offset(0, _iconMove.value),
                    child: Transform.scale(
                      scale: _iconScale.value,
                      child: Opacity(
                        opacity: _iconFade.value,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryNavy.withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/app-icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Route / Pulse Line Micro-Animation
                  SizedBox(
                    width: 80,
                    height: 4,
                    child: CustomPaint(
                      painter: _RoutePulsePainter(
                        progress: _pulseLine.value,
                        baseColor: _primaryNavy.withOpacity(0.1),
                        pulseColor: _emergencyRed,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Transform.translate(
                    offset: Offset(0, _titleMove.value),
                    child: Opacity(
                      opacity: _titleFade.value,
                      child: Text(
                        'Sajiloroute',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _primaryNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Opacity(
                    opacity: _taglineFade.value,
                    child: Text(
                      'AI-Powered Emergency Response',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _secondaryText,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Custom Loading Treatment at bottom
              Positioned(
                bottom: 40,
                left: 60,
                right: 60,
                child: Opacity(
                  opacity: _taglineFade.value,
                  child: const _SubtleLoadingIndicator(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoutePulsePainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  final Color pulseColor;

  _RoutePulsePainter({
    required this.progress,
    required this.baseColor,
    required this.pulseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pulsePaint = Paint()
      ..color = pulseColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw base line (subtle curve)
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
      size.width / 2,
      size.height / 2 - 10,
      size.width,
      size.height / 2,
    );
    canvas.drawPath(path, basePaint);

    // Draw pulse line over it based on progress
    if (progress > 0) {
      // We simulate drawing the path by calculating points or using a simpler approach.
      // For a premium feel, a straight line that masks the curved path works beautifully.
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, -20, size.width * progress, 40));
      canvas.drawPath(path, pulsePaint);
      
      // Draw a small dot at the leading edge
      if (progress < 1.0) {
        // Approximate Y position on the bezier
        final t = progress;
        final y = pow(1 - t, 2) * (size.height / 2) +
            2 * (1 - t) * t * (size.height / 2 - 10) +
            pow(t, 2) * (size.height / 2);
            
        canvas.drawCircle(
          Offset(size.width * progress, y.toDouble()),
          3.0,
          Paint()..color = pulseColor,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SubtleLoadingIndicator extends StatefulWidget {
  const _SubtleLoadingIndicator();

  @override
  State<_SubtleLoadingIndicator> createState() => _SubtleLoadingIndicatorState();
}

class _SubtleLoadingIndicatorState extends State<_SubtleLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LoadingLinePainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class _LoadingLinePainter extends CustomPainter {
  final double progress;

  _LoadingLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFF0B1F3A).withOpacity(0.05)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = const Color(0xFFE31B23).withOpacity(0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      bgPaint,
    );

    final pulseWidth = size.width * 0.3;
    final startX = (size.width + pulseWidth) * progress - pulseWidth;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawLine(
      Offset(startX, size.height / 2),
      Offset(startX + pulseWidth, size.height / 2),
      fgPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoadingLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
