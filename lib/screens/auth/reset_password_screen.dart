// lib/screens/auth/reset_password_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {

  final _tokenController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // OTP code boxes
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading            = false;
  bool _obscurePassword      = true;
  bool _obscureConfirm       = true;
  bool _resetSuccess         = false;

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
  static const Color _green    = Color(0xFF27AE60);

  @override
  void initState() {
    super.initState();
    _tokenController.text = widget.token;
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
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
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
        backgroundColor: isError ? const Color(0xFFC0392B) : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getOtpCode() =>
      _otpControllers.map((c) => c.text).join();

  Future<void> _resetPassword() async {
    final otp = _getOtpCode();
    if (otp.length < 6) {
      _showMessage('Please enter the complete 6-digit code');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showMessage('Please enter your new password');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showMessage('Password must be at least 8 characters');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/reset-password', {
        'email':                 widget.email,
        'token':                 otp,
        'password':              _passwordController.text,
        'password_confirmation': _confirmPasswordController.text,
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() { _isLoading = false; _resetSuccess = true; });
        _showMessage('Password reset successfully!', isError: false);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pushAndRemoveUntil(context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showMessage(data['message'] ?? 'Invalid code. Please try again.');
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
              height: size.height * 0.40,
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
                      child: Text('Reset Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _white, fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3)),
                    ),
                    const SizedBox(width: 48),
                  ]),
                ),

                const SizedBox(height: 10),

                // ── Top icon ──────────────────────────────────────────────
                FadeTransition(
                  opacity: fade,
                  child: Container(
                    width: 82, height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _white.withOpacity(0.08),
                      border: Border.all(
                        color: _resetSuccess
                          ? _green.withOpacity(0.6)
                          : _gold.withOpacity(0.45),
                        width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: (_resetSuccess ? _green : _gold).withOpacity(0.18),
                          blurRadius: 24, spreadRadius: 4),
                      ],
                    ),
                    child: Icon(
                      _resetSuccess
                        ? Icons.check_circle_outline_rounded
                        : Icons.lock_open_rounded,
                      size: 36,
                      color: _resetSuccess ? _green : _gold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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
                          child: _resetSuccess
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
        const Text('New Password',
          style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800,
            color: _textDark, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: _textGrey, height: 1.5),
            children: [
              const TextSpan(text: 'Resetting password for\n'),
              TextSpan(
                text: widget.email,
                style: const TextStyle(
                  color: _navy, fontWeight: FontWeight.w700)),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── OTP code section ─────────────────────────────────────────────
        const Text('Verification Code',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: _textDark, letterSpacing: 0.2)),
        const SizedBox(height: 6),
        Text('Enter the 6-digit code sent to your email',
          style: TextStyle(fontSize: 12, color: _textGrey.withOpacity(0.8))),
        const SizedBox(height: 14),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ),

        const SizedBox(height: 24),

        // Divider
        Row(children: [
          Expanded(child: Divider(color: _border, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('New Password',
              style: TextStyle(
                fontSize: 12, color: _textGrey.withOpacity(0.7),
                fontWeight: FontWeight.w600))),
          Expanded(child: Divider(color: _border, height: 1)),
        ]),

        const SizedBox(height: 20),

        // New password
        const Text('New Password',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: _textDark, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        _buildPasswordField(
          controller: _passwordController,
          hint: 'Enter new password',
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),

        const SizedBox(height: 16),

        // Confirm password
        const Text('Confirm Password',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: _textDark, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        _buildPasswordField(
          controller: _confirmPasswordController,
          hint: 'Confirm new password',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          isConfirm: true,
        ),

        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.info_outline,
            size: 13, color: _textGrey.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text('Minimum 8 characters',
            style: TextStyle(
              fontSize: 12, color: _textGrey.withOpacity(0.7))),
        ]),

        const SizedBox(height: 28),

        // Reset button
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
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
                    Text('RESET PASSWORD',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                    SizedBox(width: 8),
                    Icon(Icons.lock_reset_rounded, size: 18),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  // ── OTP box ───────────────────────────────────────────────────────────────
  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 44, height: 52,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800, color: _textDark),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _inputBg,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 1.5)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _navy, width: 2)),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  // ── Password field ────────────────────────────────────────────────────────
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    bool isConfirm = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          color: _textDark, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: _textGrey.withOpacity(0.7), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              isConfirm
                ? Icons.lock_reset_outlined
                : Icons.lock_outline_rounded,
              color: _navy.withOpacity(0.5), size: 20)),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
              color: _navy.withOpacity(0.4), size: 20),
            onPressed: onToggle),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 4),
        ),
      ),
    );
  }

  // ── Success state ─────────────────────────────────────────────────────────
  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _green.withOpacity(0.1),
            shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline_rounded,
            size: 36, color: _green),
        ),
        const SizedBox(height: 20),
        const Text('Password Reset!',
          style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 10),
        Text(
          'Your password has been successfully reset.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13, color: _textGrey, height: 1.6)),
        const SizedBox(height: 28),
        const SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            backgroundColor: Color(0xFFDDE6F0),
            valueColor: AlwaysStoppedAnimation<Color>(_green),
            minHeight: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text('Redirecting to login...',
          style: TextStyle(
            fontSize: 12, color: _textGrey.withOpacity(0.7))),
        const SizedBox(height: 8),
      ],
    );
  }
}