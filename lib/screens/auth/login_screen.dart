// lib/screens/auth/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import 'register_screen.dart';
import '../home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading       = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final tr = context.read<LanguageProvider>().tr;
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage(tr.get('email_hint'));
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
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        _showMessage(data['message'] ?? tr.get('error'));
      }
    } catch (e) {
      _showMessage('Connection error. Check your internet.');
    }
    setState(() => _isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LanguageProvider>().tr;

    return Scaffold(
      backgroundColor: const Color(0xFFD6E4F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top curved section with logo ──────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 240,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A3A5C),
                    borderRadius: BorderRadius.only(
                      bottomLeft:  Radius.circular(80),
                      bottomRight: Radius.circular(80),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 300, height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD6E4F0),
                      borderRadius: BorderRadius.only(
                        topLeft:  Radius.circular(100),
                        topRight: Radius.circular(100),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  child: Container(
                    width: 130, height: 150,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(tr.get('welcome_back'),
                      style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                  ),
                  Center(
                    child: Text(tr.get('sign_in'),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF4A6A8A))),
                  ),
                  const SizedBox(height: 28),

                  // Email label
                  Text(tr.get('email'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
                  const SizedBox(height: 8),

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
                        prefixIcon: Icon(Icons.email_outlined,
                            color: const Color(0xFF1A3A5C).withOpacity(0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password label
                  Text(tr.get('password'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
                  const SizedBox(height: 8),

                  // Password field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: tr.get('password_hint'),
                        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.lock_outline,
                            color: const Color(0xFF1A3A5C).withOpacity(0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF1A3A5C).withOpacity(0.7),
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: Text(tr.get('forgot_password'),
                        style: const TextStyle(
                            color: Color(0xFF1A3A5C), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Sign In button
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3A5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(tr.get('sign_in').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skip Login button
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const HomeScreen())),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A3A5C)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${tr.get('skip_login')}',
                            style: TextStyle(
                                color: Color(0xFF1A3A5C),
                                fontWeight: FontWeight.w600, fontSize: 16)),
                          Icon(Icons.double_arrow, color: Color(0xFF1A3A5C)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tr.get('dont_have_account') + ' ',
                        style: const TextStyle(color: Color(0xFF4A6A8A))),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: Text(tr.get('register'),
                          style: const TextStyle(
                            color: Color(0xFF1A3A5C),
                            fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}