// lib/screens/auth/forgot_password_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendResetCode() async {
    final tr = context.read<LanguageProvider>().tr;

    if (_emailController.text.isEmpty) {
      _showMessage(tr.get('email_hint'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/forgot-password', {
        'email': _emailController.text.trim(),
      });

      final data = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _showMessage(tr.get('send_reset_code'));
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(
                email: _emailController.text.trim(),
                token: '',
              ),
            ),
          );
        }
      } else {
        _showMessage(data['message'] ?? tr.get('error'));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('${tr.get('error')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LanguageProvider>().tr;

    return Scaffold(
      backgroundColor: const Color(0xFFD6E4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: Text(tr.get('forgot_password')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.lock_reset, size: 70, color: Color(0xFF1A3A5C)),
            const SizedBox(height: 20),
            Text(
              tr.get('reset_password'),
              style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
            ),
            const SizedBox(height: 8),
            Text(
              tr.get('send_reset_code'),
              style: const TextStyle(color: Color(0xFF4A6A8A)),
            ),
            const SizedBox(height: 32),

            // Email field
            Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: tr.get('email_hint'),
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1A3A5C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Send button
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A5C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(tr.get('send_reset_code'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}