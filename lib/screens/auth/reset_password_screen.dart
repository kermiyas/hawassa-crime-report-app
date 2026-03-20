// lib/screens/auth/reset_password_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
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

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading       = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tokenController.text = '';
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _resetPassword() async {
    final tr = context.read<LanguageProvider>().tr;

    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showMessage(tr.get('password_hint'));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage(tr.get('confirm_password'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/reset-password', {
        'email':                 widget.email,
        'token':                 _tokenController.text.trim(),
        'password':              _passwordController.text,
        'password_confirmation': _confirmPasswordController.text,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showMessage(tr.get('success'));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        _showMessage(data['message'] ?? tr.get('error'));
      }
    } catch (e) {
      _showMessage('${tr.get('error')}: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LanguageProvider>().tr;

    return Scaffold(
      backgroundColor: const Color(0xFFD6E4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: Text(tr.get('reset_password')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_open, size: 70, color: Color(0xFF1A3A5C)),
            const SizedBox(height: 20),
            Text(
              tr.get('new_password'),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
            ),
            const SizedBox(height: 4),
            Text(
              '${tr.get('resetting_for')} ${widget.email}',
              style: const TextStyle(color: Color(0xFF4A6A8A)),
            ),
            const SizedBox(height: 32),

            // Reset code field
            Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  hintText: tr.get('reset_code'),
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.pin, color: Color(0xFF1A3A5C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // New password field
            Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: tr.get('new_password'),
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A3A5C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF1A3A5C),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm password field
            Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: tr.get('confirm_password_hint'),
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.lock_reset_outlined, color: Color(0xFF1A3A5C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reset button
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A5C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(tr.get('reset_password'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}