// lib/screens/auth/forgot_password_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {

  final _emailController = TextEditingController();
  bool _isLoading  = false;
  bool _emailSent  = false;

  AnimationController? _entranceController;
  Animation<double>?   _fadeAnim;
  Animation<Offset>?   _slideAnim;

  // ── Police color palette ─────────────────────────────────────────────────
  static const Color _navyDark = Color(0xFF0D1B2A);
  static const Color _navy     = Color(0xFF1A3A5C);
  static const Color _navyMid  = Color(0xFF1E4D7B);
  static const Color _gold     = Color(0xFFC9A84C);
  static const Color _white    = Color(0xFFFFFFFF);
  static const Color _bgLight  = Color(0xFFF0F4F8);
  static const Color _inputBg  = Color(0xFFF5F8FC);
  static const Color _textDark = Color(0xFF1A3A5C);
  static const Color _textGrey = Color(0xFF7A90B0);
  static const Color _border   = Color(0xFFDDE6F0);

  @override
  void initState() {
    super.initState();
    final ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _entranceController = ctrl;
    _fadeAnim  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));
    ctrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _entranceController?.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: isError ? const Color(0xFFC0392B) : const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendResetCode() async {
    if (_emailController.text.isEmpty) {
      _showMessage('Please enter your email address');
      return;
    }
    if (!_emailController.text.contains('@')) {
      _showMessage('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/forgot-password', {
        'email': _emailController.text.trim(),
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() { _isLoading = false; _emailSent = true; });
        _showMessage('Reset code sent to your email', isError: false);
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 1200));
          Navigator.push(context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ResetPasswordScreen(
                email: _emailController.text.trim(),
                token: '',
              ),
              transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showMessage(data['message'] ?? 'Email not found. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Connection error. Check your internet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size  = MediaQuery.of(context).size;
    final fade  = _fadeAnim  ?? const AlwaysStoppedAnimation(1.0);
    final slide = _slideAnim ?? const AlwaysStoppedAnimation(Offset.zero);

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          // ── Navy gradient top ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: size.height * 0.42,
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
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _white.withOpacity(0.05), width: 1.5)),
            ),
          ),
          Positioned(
            top: 30, right: 30,
            child: Container(
              width: 65, height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _gold.withOpacity(0.2), width: 1)),
            ),
          ),
          Positioned(
            top: size.height * 0.07,
            left: size.width * 0.08,
            child: Container(width: 5, height: 5,
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.5),
                shape: BoxShape.circle)),
          ),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                  child: Row(children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _white, size: 20),
                    ),
                    const Expanded(
                      child: Text('Forgot Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _white, fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3)),
                    ),
                    const SizedBox(width: 48),
                  ]),
                ),

                const SizedBox(height: 16),

                // ── Icon area ─────────────────────────────────────────────
                FadeTransition(
                  opacity: fade,
                  child: Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _white.withOpacity(0.08),
                      border: Border.all(
                        color: _gold.withOpacity(0.45), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withOpacity(0.18),
                          blurRadius: 28, spreadRadius: 4),
                      ],
                    ),
                    child: Icon(
                      _emailSent
                        ? Icons.mark_email_read_outlined
                        : Icons.lock_reset_rounded,
                      size: 38,
                      color: _emailSent ? const Color(0xFF27AE60) : _gold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Card ──────────────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Container(
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
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                          child: _emailSent
                            ? _buildSuccessState()
                            : _buildFormState(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Form state ────────────────────────────────────────────────────────────
  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reset Password',
          style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800,
            color: _textDark, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        Text(
          'Enter your registered email address and we\'ll send you a reset code.',
          style: TextStyle(
            fontSize: 13, color: _textGrey, height: 1.5)),

        const SizedBox(height: 28),

        // Email label
        const Text('Email Address',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: _textDark, letterSpacing: 0.2)),
        const SizedBox(height: 10),

        // Email field
        Container(
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 1.5),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              color: _textDark, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: TextStyle(
                color: _textGrey.withOpacity(0.7), fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.email_outlined,
                  color: _navy.withOpacity(0.55), size: 20)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 4),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Info note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _navy.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _navy.withOpacity(0.1), width: 1)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                size: 15, color: _navy.withOpacity(0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A 6-digit verification code will be sent to your email.',
                  style: TextStyle(
                    fontSize: 12, color: _navy.withOpacity(0.7),
                    height: 1.5)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Send button
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: _white,
              disabledBackgroundColor: _navy.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SEND RESET CODE',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                    SizedBox(width: 8),
                    Icon(Icons.send_rounded, size: 17),
                  ],
                ),
          ),
        ),

        const SizedBox(height: 20),

        // Back to login
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Remember your password?  ',
              style: TextStyle(color: _textGrey, fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('Sign In',
                style: TextStyle(
                  color: _navy, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Success state ─────────────────────────────────────────────────────────
  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60).withOpacity(0.1),
            shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline_rounded,
            size: 32, color: Color(0xFF27AE60)),
        ),
        const SizedBox(height: 20),
        const Text('Email Sent!',
          style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 10),
        Text(
          'We\'ve sent a reset code to\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14, color: _textGrey, height: 1.6)),
        const SizedBox(height: 28),
        // Loading indicator
        const SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            backgroundColor: Color(0xFFDDE6F0),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
            minHeight: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text('Redirecting to verification...',
          style: TextStyle(fontSize: 12, color: _textGrey.withOpacity(0.7))),
        const SizedBox(height: 8),
      ],
    );
  }
}