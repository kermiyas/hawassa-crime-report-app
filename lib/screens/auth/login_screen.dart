// lib/screens/auth/login_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading       = false;
  bool _obscurePassword = true;

  late AnimationController _entranceController;
  late Animation<double>   _logoFade;
  late Animation<Offset>   _logoSlide;
  late Animation<double>   _cardFade;
  late Animation<Offset>   _cardSlide;

  // ── Police color palette ─────────────────────────────────────────────────
  static const Color _navyDark  = Color(0xFF0D1B2A);
  static const Color _navy      = Color(0xFF1A3A5C);
  static const Color _navyMid   = Color(0xFF1E4D7B);
  static const Color _gold      = Color(0xFFC9A84C);
  static const Color _white     = Color(0xFFFFFFFF);
  static const Color _bgLight   = Color(0xFFF0F4F8);
  static const Color _inputBg   = Color(0xFFF5F8FC);
  static const Color _textDark  = Color(0xFF1A3A5C);
  static const Color _textGrey  = Color(0xFF7A90B0);
  static const Color _border    = Color(0xFFDDE6F0);

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _logoFade = CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn))
        .drive(Tween(begin: 0.0, end: 1.0));

    _logoSlide = CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic))
        .drive(Tween(begin: const Offset(0, -0.3), end: Offset.zero));

    _cardFade = CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn))
        .drive(Tween(begin: 0.0, end: 1.0));

    _cardSlide = CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic))
        .drive(Tween(begin: const Offset(0, 0.2), end: Offset.zero));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage(
          context.read<LanguageProvider>().tr.get('login_empty_fields'),
          isError: true);
      return;
    }
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showMessage('Please enter a valid email address', isError: true);
      return;
    }
    if (_passwordController.text.length < 6) {
      _showMessage('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/login', {
        'email':    _emailController.text.trim(),
        'password': _passwordController.text,
      });
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await ApiService.saveToken(data['token']);
        if (mounted) await context.read<AuthProvider>().setAuthenticated();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomeScreen(initialIndex: 2),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
            (route) => false,
          );
        }
      } else {
        final tr = context.read<LanguageProvider>().tr;
        _showMessage(
            data['message'] ?? tr.get('invalid_credentials'),
            isError: true);
      }
    } on SocketException {
      if (mounted) {
        _showMessage(
            context.read<LanguageProvider>().tr.get('network_error'),
            isError: true);
      }
    } on TimeoutException {
      if (mounted) {
        _showMessage(
            context.read<LanguageProvider>().tr.get('network_error'),
            isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
            context.read<LanguageProvider>().tr.get('network_error'),
            isError: true);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _browseAsGuest() async {
    await context.read<AuthProvider>().setGuest();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(initialIndex: 0),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor:
        isError ? const Color(0xFFC0392B) : const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr   = context.watch<LanguageProvider>().tr;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          // ── Navy gradient top section ──────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: size.height * 0.48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_navyDark, _navy, _navyMid],
                ),
              ),
            ),
          ),

          // ── Decorative circles ─────────────────────────────────────────
          Positioned(
              top: -50, right: -50,
              child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _white.withOpacity(0.05), width: 1.5)))),
          Positioned(
              top: 30, right: 30,
              child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _gold.withOpacity(0.2), width: 1)))),
          Positioned(
              top: size.height * 0.3, left: -40,
              child: Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _white.withOpacity(0.04), width: 1)))),
          Positioned(
              top: size.height * 0.07, left: size.width * 0.08,
              child: Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                      color: _gold.withOpacity(0.5),
                      shape: BoxShape.circle))),
          Positioned(
              top: size.height * 0.13, right: size.width * 0.1,
              child: Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                      color: _white.withOpacity(0.25),
                      shape: BoxShape.circle))),

          // ── Scrollable content ─────────────────────────────────────────
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 28),

                // ── Logo + app name ───────────────────────────────────────
                SlideTransition(
                  position: _logoSlide,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Column(
                      children: [
                        Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _white.withOpacity(0.07),
                            border: Border.all(
                                color: _gold.withOpacity(0.45), width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: _gold.withOpacity(0.18),
                                  blurRadius: 28,
                                  spreadRadius: 4),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset('assets/logo.png',
                                  fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('HAWASSA',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _gold,
                                letterSpacing: 5)),
                        const SizedBox(height: 3),
                        const Text('Crime Report',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _white,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 28,
                                height: 1,
                                color: _gold.withOpacity(0.35)),
                            Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                decoration: const BoxDecoration(
                                    color: _gold,
                                    shape: BoxShape.circle)),
                            Container(
                                width: 28,
                                height: 1,
                                color: _gold.withOpacity(0.35)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ── Login card ────────────────────────────────────────────
                SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: Container(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                              color: _navy.withOpacity(0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 16)),
                          BoxShadow(
                              color: _navy.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Padding(
                        padding:
                        const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr.get('welcome_back'),
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                    letterSpacing: 0.3)),
                            const SizedBox(height: 4),
                            Text(tr.get('sign_in_subtitle'),
                                style: const TextStyle(
                                    fontSize: 13, color: _textGrey)),
                            const SizedBox(height: 26),

                            _buildLabel(tr.get('email')),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _emailController,
                              hint: tr.get('email_hint'),
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 18),

                            _buildLabel(tr.get('password')),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _passwordController,
                              hint: tr.get('password_hint'),
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const ForgotPasswordScreen())),
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 8)),
                                child: Text(tr.get('forgot_password'),
                                    style: const TextStyle(
                                        color: _navy,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Sign In button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _navy,
                                  foregroundColor: _white,
                                  disabledBackgroundColor:
                                  _navy.withOpacity(0.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5))
                                    : Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        tr
                                            .get('sign_in')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                            FontWeight.w800,
                                            letterSpacing: 2)),
                                    const SizedBox(width: 8),
                                    const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Browse without login
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: _browseAsGuest,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: _navy.withOpacity(0.25),
                                      width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14)),
                                  foregroundColor: _navy,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(tr.get('skip_login'),
                                        style: TextStyle(
                                            color:
                                            _navy.withOpacity(0.7),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Icon(
                                        Icons
                                            .arrow_forward_ios_rounded,
                                        size: 12,
                                        color: _navy.withOpacity(0.4)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text(tr.get('dont_have_account'),
                                    style: const TextStyle(
                                        color: _textGrey,
                                        fontSize: 14)),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                          const RegisterScreen())),
                                  child: Text(tr.get('register'),
                                      style: const TextStyle(
                                          color: _navy,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                FadeTransition(
                  opacity: _cardFade,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 12,
                          color: _textGrey.withOpacity(0.5)),
                      const SizedBox(width: 5),
                      Text('Hawassa Police Department',
                          style: TextStyle(
                              fontSize: 11,
                              color: _textGrey.withOpacity(0.5),
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textDark,
            letterSpacing: 0.2));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: _textGrey.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400),
          prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(icon,
                  color: _navy.withOpacity(0.55), size: 20)),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _navy.withOpacity(0.45),
                size: 20),
            onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 4),
        ),
      ),
    );
  }
}