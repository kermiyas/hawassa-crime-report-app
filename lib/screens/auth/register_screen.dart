// lib/screens/auth/register_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _phoneController           = TextEditingController();
  final _addressController         = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dayController             = TextEditingController();
  final _monthController           = TextEditingController();
  final _yearController            = TextEditingController();

  bool    _isLoading               = false;
  bool    _obscurePassword         = true;
  bool    _obscureConfirmPassword  = true;
  bool    _agreeToTerms            = false;
  String  _selectedGender          = 'Male';
  File?   _profileImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      final appDir  = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setState(() => _profileImage = savedFile);
    }
  }

  Future<void> _uploadProfilePhoto(String token) async {
    try {
      final uri     = Uri.parse('${ApiConstants.baseUrl}/profile/photo');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept']        = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'profile_photo', _profileImage!.path));
      final streamed  = await request.send().timeout(const Duration(seconds: 30));
      await http.Response.fromStream(streamed);
    } catch (e) {
      debugPrint('Photo upload error: $e');
    }
  }

  Future<void> _register() async {
    final tr = context.read<LanguageProvider>().tr;

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage(tr.get('email_hint'));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage(tr.get('confirm_password'));
      return;
    }
    if (!_agreeToTerms) {
      _showMessage(tr.get('terms_privacy'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/register', {
        'full_name':             _nameController.text.trim(),
        'email':                 _emailController.text.trim(),
        'phone':                 _phoneController.text.trim(),
        'password':              _passwordController.text,
        'password_confirmation': _confirmPasswordController.text,
        'address':               _addressController.text.trim(),
        'gender':                _selectedGender,
        'birthday':
            '${_yearController.text}-${_monthController.text}-${_dayController.text}',
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (_profileImage != null) {
          await _uploadProfilePhoto(data['token']);
        }
        setState(() => _isLoading = false);
        _showMessage(tr.get('success'));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showMessage(data['message'] ?? tr.get('error'));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('${tr.get('error')}: $e');
    }
  }

  // ── Reusable widgets ────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: const Color(0xFF1A3A5C)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: const Color(0xFF1A3A5C)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF1A3A5C).withOpacity(0.7),
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String hint) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1A3A5C)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<LanguageProvider>().tr;

    return Scaffold(
      backgroundColor: const Color(0xFFD6E4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: Text(tr.get('register'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // ── Profile photo picker ──────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A3A5C), width: 2),
                      color: Colors.white,
                    ),
                    child: _profileImage != null
                        ? ClipOval(
                            child: Image.file(_profileImage!,
                                fit: BoxFit.cover, width: 90, height: 90))
                        : const Icon(Icons.person_outline,
                            size: 50, color: Color(0xFF1A3A5C)),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A3A5C), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Text(tr.get('change_photo'),
                style: const TextStyle(color: Color(0xFF1A3A5C), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),

            // ── Form fields ───────────────────────────────────────────────
            _buildTextField(
              controller: _nameController,
              hint: tr.get('full_name_hint'),
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              hint: tr.get('email_hint'),
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              hint: tr.get('phone_hint'),
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              hint: tr.get('address_hint'),
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),

            // ── Gender ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.people_outline, color: Color(0xFF1A3A5C)),
                const SizedBox(width: 12),
                Text('${tr.get('gender')} :',
                  style: const TextStyle(color: Color(0xFF1A3A5C), fontWeight: FontWeight.w500)),
                Row(children: [
                  Radio<String>(
                    value: 'Male',
                    groupValue: _selectedGender,
                    activeColor: const Color(0xFF1A3A5C),
                    onChanged: (v) => setState(() => _selectedGender = v!),
                  ),
                  Text(tr.get('male')),
                ]),
                Row(children: [
                  Radio<String>(
                    value: 'Female',
                    groupValue: _selectedGender,
                    activeColor: const Color(0xFF1A3A5C),
                    onChanged: (v) => setState(() => _selectedGender = v!),
                  ),
                  Text(tr.get('female')),
                ]),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Birthday ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, color: Color(0xFF1A3A5C)),
                const SizedBox(width: 12),
                Text('${tr.get('birthday')} :',
                  style: const TextStyle(color: Color(0xFF1A3A5C), fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(children: [
                    _buildDateField(_dayController, 'DD'),
                    const SizedBox(width: 8),
                    _buildDateField(_monthController, 'MM'),
                    const SizedBox(width: 8),
                    _buildDateField(_yearController, 'YYYY'),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Passwords ─────────────────────────────────────────────────
            _buildPasswordField(
              controller: _passwordController,
              hint: tr.get('password_hint'),
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _confirmPasswordController,
              hint: tr.get('confirm_password_hint'),
              icon: Icons.lock_reset_outlined,
              obscure: _obscureConfirmPassword,
              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            const SizedBox(height: 16),

            // ── Terms checkbox ────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  activeColor: const Color(0xFF1A3A5C),
                  onChanged: (v) => setState(() => _agreeToTerms = v!),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
  tr.get('agree_terms'),
  style: const TextStyle(color: Color(0xFF1A3A5C), fontSize: 13),
),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Register button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A5C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(tr.get('register'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}