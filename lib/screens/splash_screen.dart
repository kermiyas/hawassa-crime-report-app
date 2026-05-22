// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ───────────────────────────────────────────────
  late AnimationController _shieldController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;

  late Animation<double>   _shieldScale;
  late Animation<double>   _shieldOpacity;
  late Animation<double>   _shieldRotate;
  late Animation<double>   _textOpacity;
  late Animation<Offset>   _titleSlide;
  late Animation<Offset>   _subtitleSlide;
  late Animation<double>   _pulseAnim;
  late Animation<double>   _bgAnim;

  // ── Color palette ────────────────────────────────────────────────────────
  static const Color _navyDark   = Color(0xFF0D1B2A);
  static const Color _navy       = Color(0xFF1A3A5C);
  static const Color _navyLight  = Color(0xFF1E4D7B);
  static const Color _gold       = Color(0xFFC9A84C);
  static const Color _goldLight  = Color(0xFFE8C96A);
  static const Color _white      = Color(0xFFFFFFFF);
  static const Color _white70    = Color(0xB3FFFFFF);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Shield entrance — scale + rotate + fade
    _shieldController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
    _shieldScale = CurvedAnimation(
        parent: _shieldController, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _shieldOpacity = CurvedAnimation(
        parent: _shieldController, curve: const Interval(0.0, 0.5))
        .drive(Tween(begin: 0.0, end: 1.0));
    _shieldRotate = CurvedAnimation(
        parent: _shieldController, curve: Curves.easeOutBack)
        .drive(Tween(begin: -0.15, end: 0.0));

    // Text fade + slide
    _textController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _textOpacity = CurvedAnimation(
        parent: _textController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _titleSlide = CurvedAnimation(
        parent: _textController, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.4), end: Offset.zero));
    _subtitleSlide = CurvedAnimation(
        parent: _textController, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.6), end: Offset.zero));

    // Pulse ring around shield
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: false);
    _pulseAnim = CurvedAnimation(
        parent: _pulseController, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    // Background gradient shift
    _backgroundController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000));
    _bgAnim = CurvedAnimation(
        parent: _backgroundController, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.0, end: 1.0));
  }

  Future<void> _startSequence() async {
    // Start bg immediately
    _backgroundController.forward();

    // Shield after 200ms
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _shieldController.forward();

    // Text after shield is mostly done
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) _textController.forward();

    // Navigate after everything is shown
    await Future.delayed(const Duration(milliseconds: 2400));
    if (mounted) _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            seenOnboarding ? const HomeScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _shieldController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _shieldController,
          _textController,
          _pulseController,
          _backgroundController,
        ]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(_navyDark, _navy, _bgAnim.value)!,
                  Color.lerp(_navy, _navyLight, _bgAnim.value)!,
                  Color.lerp(_navyLight, const Color(0xFF0F2744), _bgAnim.value)!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // ── Decorative background circles ──────────────────────────
                Positioned(
                  top: -size.height * 0.12,
                  right: -size.width * 0.2,
                  child: Container(
                    width: size.width * 0.7,
                    height: size.width * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _gold.withOpacity(0.08),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -size.height * 0.08,
                  left: -size.width * 0.15,
                  child: Container(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // Top-left small accent
                Positioned(
                  top: size.height * 0.08,
                  left: size.width * 0.06,
                  child: Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: size.height * 0.15,
                  right: size.width * 0.1,
                  child: Container(
                    width: 4, height: 4,
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: size.height * 0.2,
                  right: size.width * 0.08,
                  child: Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // ── Main content ───────────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pulse ring + shield
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
                            Opacity(
                              opacity: (1.0 - _pulseAnim.value).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 0.6 + (_pulseAnim.value * 0.8),
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _gold.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Second pulse ring (offset)
                            Opacity(
                              opacity: ((0.7 - _pulseAnim.value).clamp(0.0, 1.0)),
                              child: Transform.scale(
                                scale: 0.5 + (_pulseAnim.value * 0.6),
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _gold.withOpacity(0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Shield logo
                            Transform.scale(
                              scale: _shieldScale.value,
                              child: Transform.rotate(
                                angle: _shieldRotate.value,
                                child: Opacity(
                                  opacity: _shieldOpacity.value,
                                  child: _buildShieldLogo(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // App name
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _textOpacity,
                          child: Column(
                            children: [
                              Text(
                                'HAWASSA',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _gold,
                                  letterSpacing: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Crime Report',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: _white,
                                  letterSpacing: 1.2,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Divider line
                      FadeTransition(
                        opacity: _textOpacity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40, height: 1,
                              color: _gold.withOpacity(0.5),
                            ),
                            Container(
                              width: 8, height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: _gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 40, height: 1,
                              color: _gold.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tagline
                      SlideTransition(
                        position: _subtitleSlide,
                        child: FadeTransition(
                          opacity: _textOpacity,
                          child: Text(
                            'Safety for Everyone',
                            style: TextStyle(
                              fontSize: 14,
                              color: _white70,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom loading indicator ───────────────────────────────
                Positioned(
                  bottom: 60,
                  left: 0, right: 0,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 120,
                          child: LinearProgressIndicator(
                            backgroundColor: _white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(_gold),
                            minHeight: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hawassa Police Department',
                          style: TextStyle(
                            fontSize: 11,
                            color: _white.withOpacity(0.4),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShieldLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _navy.withOpacity(0.3),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 90,
          height: 90,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackShield(),
        ),
      ),
    );
  }

  Widget _buildFallbackShield() {
    return CustomPaint(
      size: const Size(90, 90),
      painter: _ShieldPainter(
        shieldColor: _navy,
        borderColor: _gold,
        starColor: _gold,
      ),
    );
  }
}

// ── Custom shield painter as fallback ────────────────────────────────────────
class _ShieldPainter extends CustomPainter {
  final Color shieldColor;
  final Color borderColor;
  final Color starColor;

  const _ShieldPainter({
    required this.shieldColor,
    required this.borderColor,
    required this.starColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPaint = Paint()
      ..color = shieldColor
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Shield path
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.2)
      ..lineTo(w, h * 0.55)
      ..quadraticBezierTo(w, h * 0.85, w * 0.5, h)
      ..quadraticBezierTo(0, h * 0.85, 0, h * 0.55)
      ..lineTo(0, h * 0.2)
      ..close();

    canvas.drawPath(path, shieldPaint);
    canvas.drawPath(path, borderPaint);

    // Star in center
    _drawStar(canvas, Offset(w * 0.5, h * 0.48), w * 0.22,
        Paint()..color = starColor);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const int points = 5;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (i * 3.14159 / points) - 3.14159 / 2;
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double angle) => _mathCos(angle);
  double _sin(double angle) => _mathSin(angle);

  double _mathCos(double x) {
    // Simple approximation for small values
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 6; i++) {
      term *= -x * x / (2 * i * (2 * i - 1));
      result += term;
    }
    return result;
  }

  double _mathSin(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i <= 6; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}