// lib/screens/auth/register_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import 'login_screen.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {

  final _firstNameController       = TextEditingController();
  final _lastNameController        = TextEditingController();
  final _emailController           = TextEditingController();
  final _phoneController           = TextEditingController();
  final _addressController         = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dayController             = TextEditingController();
  final _monthController           = TextEditingController();
  final _yearController            = TextEditingController();

  bool   _isLoading              = false;
  bool   _obscurePassword        = true;
  bool   _obscureConfirmPassword = true;
  bool   _agreeToTerms           = false;
  String _selectedGender         = 'Male';
  File?  _profileImage;

  late AnimationController _entranceController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

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
    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final appDir  = await getApplicationDocumentsDirectory();
      final fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved =
      await File(picked.path).copy('${appDir.path}/$fileName');
      setState(() => _profileImage = saved);
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
      final streamed =
      await request.send().timeout(const Duration(seconds: 30));
      await http.Response.fromStream(streamed);
    } catch (e) {
      debugPrint('Photo upload error: $e');
    }
  }

  Future<void> _register() async {
    // ── Validation ──────────────────────────────────────────────────────
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty) {
      _showMessage('Please enter your first and last name');
      return;
    }
    if (_emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill in all required fields');
      return;
    }
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showMessage('Please enter a valid email address');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showMessage('Password must be at least 8 characters');
      return;
    }
    if (!_agreeToTerms) {
      _showMessage('Please agree to the Terms & Privacy Policy');
      return;
    }
    // Birthday validation (optional field — only validate if any part filled)
    if (_dayController.text.isNotEmpty ||
        _monthController.text.isNotEmpty ||
        _yearController.text.isNotEmpty) {
      final day   = int.tryParse(_dayController.text);
      final month = int.tryParse(_monthController.text);
      final year  = int.tryParse(_yearController.text);
      if (day == null || month == null || year == null ||
          day < 1 || day > 31 ||
          month < 1 || month > 12 ||
          year < 1900 || year > DateTime.now().year) {
        _showMessage('Please enter a valid date of birth');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      final response = await ApiService.post('/register', {
        'full_name':             fullName,
        'email':                 _emailController.text.trim(),
        'phone':                 _phoneController.text.trim(),
        'password':              _passwordController.text,
        'password_confirmation': _confirmPasswordController.text,
        'address':               _addressController.text.trim(),
        'gender':                _selectedGender,
        'birthday': (_dayController.text.isEmpty ||
            _monthController.text.isEmpty ||
            _yearController.text.isEmpty)
            ? null
            : '${_yearController.text}-'
            '${_monthController.text.padLeft(2, '0')}-'
            '${_dayController.text.padLeft(2, '0')}',
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (_profileImage != null) {
          await _uploadProfilePhoto(data['token']);
        }
        if (mounted) {
          _showMessage('Account created successfully!', isError: false);
          await Future.delayed(const Duration(milliseconds: 800));
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      } else {
        _showMessage(data['message'] ?? 'Registration failed. Try again.');
      }
    } catch (e) {
      _showMessage('Connection error. Check your internet.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          // ── Navy gradient top bar ────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 130,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_navyDark, _navy, _navyMid],
                ),
              ),
            ),
          ),

          // ── Decorative circles ───────────────────────────────────────
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _white.withOpacity(0.06), width: 1.5)),
            ),
          ),
          Positioned(
            top: 20, right: 20,
            child: Container(
              width: 55, height: 55,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _gold.withOpacity(0.25), width: 1)),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Custom app bar ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _white,
                            size: 20),
                      ),
                      const Expanded(
                        child: Text('Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: _white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ── Scrollable form ────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        child: Column(
                          children: [

                            // ── Profile photo ────────────────────────
                            _buildPhotoSection(),
                            const SizedBox(height: 24),

                            // ── Personal info card ───────────────────
                            _buildSectionCard(
                              title: 'Personal Information',
                              icon: Icons.person_outline_rounded,
                              children: [
                                _buildField(
                                  controller: _firstNameController,
                                  hint: 'First Name',
                                  icon: Icons.badge_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _lastNameController,
                                  hint: 'Last Name',
                                  icon: Icons.badge_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _emailController,
                                  hint: 'Email Address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _phoneController,
                                  hint: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _addressController,
                                  hint: 'Address (optional)',
                                  icon: Icons.location_on_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Gender & Birthday card ───────────────
                            _buildSectionCard(
                              title: 'Additional Details',
                              icon: Icons.info_outline_rounded,
                              children: [
                                _buildLabel('Gender'),
                                const SizedBox(height: 10),
                                Row(children: [
                                  _buildGenderOption(
                                      'Male', Icons.male_rounded),
                                  const SizedBox(width: 12),
                                  _buildGenderOption(
                                      'Female', Icons.female_rounded),
                                ]),
                                const SizedBox(height: 16),
                                _buildLabel('Date of Birth'),
                                const SizedBox(height: 10),
                                Row(children: [
                                  _buildDateBox(_dayController, 'DD',
                                      maxLength: 2,
                                      minValue: 1,
                                      maxValue: 31),
                                  const SizedBox(width: 8),
                                  _buildDateBox(_monthController, 'MM',
                                      maxLength: 2,
                                      minValue: 1,
                                      maxValue: 12),
                                  const SizedBox(width: 8),
                                  _buildDateBox(_yearController, 'YYYY',
                                      maxLength: 4,
                                      minValue: 1900,
                                      maxValue: DateTime.now().year,
                                      flex: 2),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Password card ────────────────────────
                            _buildSectionCard(
                              title: 'Security',
                              icon: Icons.security_rounded,
                              children: [
                                _buildPasswordField(
                                  controller: _passwordController,
                                  hint: 'Create Password',
                                  obscure: _obscurePassword,
                                  onToggle: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                                ),
                                const SizedBox(height: 12),
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  hint: 'Confirm Password',
                                  obscure: _obscureConfirmPassword,
                                  onToggle: () => setState(() =>
                                  _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                                ),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Icon(Icons.info_outline,
                                      size: 13,
                                      color: _textGrey.withOpacity(0.7)),
                                  const SizedBox(width: 6),
                                  Text('Minimum 8 characters',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color:
                                          _textGrey.withOpacity(0.7))),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Terms checkbox ───────────────────────
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: _agreeToTerms
                                        ? _navy.withOpacity(0.3)
                                        : _border,
                                    width: 1.5),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24, height: 24,
                                    child: Checkbox(
                                      value: _agreeToTerms,
                                      activeColor: _navy,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(5)),
                                      side: BorderSide(
                                          color: _navy.withOpacity(0.4),
                                          width: 1.5),
                                      onChanged: (v) => setState(
                                              () => _agreeToTerms = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                            color: _textGrey,
                                            fontSize: 13,
                                            height: 1.5),
                                        children: const [
                                          TextSpan(
                                              text: 'I agree to the '),
                                          TextSpan(
                                              text: 'Terms & Conditions',
                                              style: TextStyle(
                                                  color: _navy,
                                                  fontWeight:
                                                  FontWeight.w700)),
                                          TextSpan(text: ' and '),
                                          TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                  color: _navy,
                                                  fontWeight:
                                                  FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Register button ──────────────────────
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed:
                                _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _navy,
                                  foregroundColor: _white,
                                  disabledBackgroundColor:
                                  _navy.withOpacity(0.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5))
                                    : const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text('CREATE ACCOUNT',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                            FontWeight.w800,
                                            letterSpacing: 1.5)),
                                    SizedBox(width: 8),
                                    Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Login link ───────────────────────────
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text('Already have an account?  ',
                                    style: TextStyle(
                                        color: _textGrey, fontSize: 14)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text('Sign In',
                                      style: TextStyle(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo section ─────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Column(children: [
        Stack(children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _white,
              border:
              Border.all(color: _gold.withOpacity(0.5), width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: _navy.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
            child: _profileImage != null
                ? ClipOval(
                child: Image.file(_profileImage!,
                    fit: BoxFit.cover, width: 100, height: 100))
                : Icon(Icons.person_rounded,
                size: 52, color: _navy.withOpacity(0.3)),
          ),
          Positioned(
            bottom: 2, right: 2,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _navy,
                shape: BoxShape.circle,
                border: Border.all(color: _white, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: _navy.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 15, color: _white),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Upload Photo',
            style: TextStyle(
                color: _navy.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        Text('Tap to select from gallery',
            style: TextStyle(
                color: _textGrey.withOpacity(0.7), fontSize: 11)),
      ]),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _navy.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: _navy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 17, color: _navy),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: 0.2)),
            ]),
            const SizedBox(height: 4),
            Divider(color: _border, height: 20),
            ...children,
          ],
        ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
            color: _textDark, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: _textGrey.withOpacity(0.7), fontSize: 14),
          prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child:
              Icon(icon, color: _navy.withOpacity(0.5), size: 19)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
            color: _textDark, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: _textGrey.withOpacity(0.7), fontSize: 14),
          prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.lock_outline_rounded,
                  color: _navy.withOpacity(0.5), size: 19)),
          suffixIcon: IconButton(
              icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _navy.withOpacity(0.4),
                  size: 19),
              onPressed: onToggle),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, IconData icon) {
    final selected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: selected ? _navy : _inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? _navy : _border, width: 1.5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? _white : _navy.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                      selected ? _white : _navy.withOpacity(0.6))),
            ],
          ),
        ),
      ),
    );
  }

  // ── Date box — no inner Expanded, flex controlled by caller ──────────────
  Widget _buildDateBox(
      TextEditingController controller,
      String hint, {
        required int maxLength,
        required int maxValue,
        required int minValue,
        int flex = 1,
      }) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          color: _inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 1.5),
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: maxLength,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RangeInputFormatter(min: minValue, max: maxValue),
          ],
          style: const TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: TextStyle(
                color: _textGrey.withOpacity(0.6), fontSize: 12),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

// ── Range input formatter ─────────────────────────────────────────────────
class _RangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;
  _RangeInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final val = int.tryParse(newValue.text);
    if (val == null) return oldValue;
    if (val > max) return oldValue;
    return newValue;
  }
}