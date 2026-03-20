// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _iconController;
  late Animation<double>   _iconBounce;

  // ── Color palette ────────────────────────────────────────────────────────
  static const Color _navyDark  = Color(0xFF0D1B2A);
  static const Color _navy      = Color(0xFF1A3A5C);
  static const Color _navyLight = Color(0xFF1E4D7B);
  static const Color _gold      = Color(0xFFC9A84C);
  static const Color _white     = Color(0xFFFFFFFF);
  static const Color _bgLight   = Color(0xFFF4F6FA);

  // ── Onboarding pages data ────────────────────────────────────────────────
  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.shield_outlined,
      accentIcon: Icons.verified_user,
      title: 'Report Safely',
      subtitle: 'Your voice matters',
      description:
          'Submit crime reports anytime, anywhere — with photos, videos, '
          'audio and GPS location. Stay anonymous if you choose.',
      features: [
        _Feature(Icons.camera_alt_outlined,    'Photo & Video Evidence'),
        _Feature(Icons.location_on_outlined,   'Auto GPS Location'),
        _Feature(Icons.person_off_outlined,    'Anonymous Reporting'),
      ],
      gradientColors: [Color(0xFF0D1B2A), Color(0xFF1A3A5C), Color(0xFF1E4D7B)],
      accentColor: Color(0xFFC9A84C),
    ),
    _OnboardingPage(
      icon: Icons.track_changes_outlined,
      accentIcon: Icons.timeline,
      title: 'Track Your Cases',
      subtitle: 'Always stay informed',
      description:
          'Follow the progress of every report you submit. '
          'Get real-time notifications when police update your case status.',
      features: [
        _Feature(Icons.notifications_outlined, 'Instant Notifications'),
        _Feature(Icons.history_outlined,        'Full Case Timeline'),
        _Feature(Icons.check_circle_outline,    'Status Updates'),
      ],
      gradientColors: [Color(0xFF0F2744), Color(0xFF1A3A5C), Color(0xFF163354)],
      accentColor: Color(0xFF4CAF8C),
    ),
    _OnboardingPage(
      icon: Icons.campaign_outlined,
      accentIcon: Icons.people_outline,
      title: 'Stay Alert',
      subtitle: 'Community safety first',
      description:
          'View police announcements, wanted persons, missing people, '
          'and safety tips — helping keep Hawassa safe together.',
      features: [
        _Feature(Icons.warning_amber_outlined,     'Wanted Persons Alerts'),
        _Feature(Icons.person_search_outlined,     'Missing Person Reports'),
        _Feature(Icons.health_and_safety_outlined, 'Safety Tips & News'),
      ],
      gradientColors: [Color(0xFF0D1B2A), Color(0xFF1B3A5E), Color(0xFF0F2744)],
      accentColor: Color(0xFF5B9BD5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _iconBounce = CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ).drive(Tween(begin: 0.0, end: 8.0));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Page view ────────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], index);
            },
          ),

          // ── Bottom controls overlay ───────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    final size = MediaQuery.of(context).size;
    final isActive = index == _currentPage;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: page.gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: page.accentColor.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: -80,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            left: -50,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: page.accentColor.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skip button top right
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: _white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Icon area
                  AnimatedBuilder(
                    animation: _iconBounce,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, isActive ? -_iconBounce.value : 0),
                      child: Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: page.accentColor.withOpacity(0.1),
                            border: Border.all(
                              color: page.accentColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: page.accentColor.withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(page.icon,
                                size: 64,
                                color: page.accentColor.withOpacity(0.3)),
                              Icon(page.accentIcon,
                                size: 36,
                                color: page.accentColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Subtitle tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: page.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: page.accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      page.subtitle.toUpperCase(),
                      style: TextStyle(
                        color: page.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Title
                  Text(
                    page.title,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    page.description,
                    style: TextStyle(
                      color: _white.withOpacity(0.65),
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Feature list
                  ...page.features.map((f) => _buildFeatureItem(f, page.accentColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(_Feature feature, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon,
              size: 18, color: accentColor),
          ),
          const SizedBox(width: 14),
          Text(
            feature.label,
            style: TextStyle(
              color: _white.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.gradientColors.last.withOpacity(0),
            page.gradientColors.last,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dot indicators
          Row(
            children: List.generate(_pages.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 8),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? page.accentColor
                      : _white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Next / Get Started button
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isLast ? 160 : 56,
              height: 56,
              decoration: BoxDecoration(
                color: page.accentColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: page.accentColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: isLast
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: const TextStyle(
                              color: _navyDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              color: _navyDark, size: 18),
                        ],
                      )
                    : const Icon(Icons.arrow_forward_rounded,
                        color: _navyDark, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _OnboardingPage {
  final IconData   icon;
  final IconData   accentIcon;
  final String     title;
  final String     subtitle;
  final String     description;
  final List<_Feature> features;
  final List<Color> gradientColors;
  final Color      accentColor;

  const _OnboardingPage({
    required this.icon,
    required this.accentIcon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.gradientColors,
    required this.accentColor,
  });
}

class _Feature {
  final IconData icon;
  final String   label;
  const _Feature(this.icon, this.label);
}