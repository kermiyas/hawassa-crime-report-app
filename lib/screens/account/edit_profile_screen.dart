// lib/screens/account/edit_profile_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController   = TextEditingController();

  final _oldPasswordController        = TextEditingController();
  final _newPasswordController        = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _showChangePassword = false;
  bool _obscureOld         = true;
  bool _obscureNew         = true;
  bool _obscureConfirm     = true;
  bool _isLoading          = false;
  bool _isFetchingProfile  = true;
  bool _isChangingPassword = false;

  File?   _newProfileImage;
  String? _existingPhotoUrl;

  @override
  void initState() { super.initState(); _loadProfile(); }

  @override
  void dispose() {
    _nameController.dispose(); _phoneController.dispose();
    _addressController.dispose(); _emailController.dispose();
    _oldPasswordController.dispose(); _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.getWithAuth('/profile');
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _nameController.text    = user['full_name'] ?? '';
          _phoneController.text   = user['phone'] ?? user['phone_number'] ?? '';
          _addressController.text = user['address'] ?? '';
          _emailController.text   = user['email'] ?? '';
          if (user['profile_photo'] != null && user['profile_photo'].toString().isNotEmpty) {
            _existingPhotoUrl = '${ApiConstants.storageUrl}/${user['profile_photo']}';
          }
        });
      }
    } catch (e) { debugPrint('Load profile error: $e'); }
    finally {
      if (mounted) setState(() => _isFetchingProfile = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final saved  = await File(picked.path).copy(
        '${appDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (mounted) setState(() => _newProfileImage = saved);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveChanges() async {
    final tr = context.read<LanguageProvider>().tr;
    setState(() => _isLoading = true);
    try {
      final body = <String, String>{};
      if (_nameController.text.trim().isNotEmpty)    body['full_name'] = _nameController.text.trim();
      if (_phoneController.text.trim().isNotEmpty)   body['phone']     = _phoneController.text.trim();
      if (_addressController.text.trim().isNotEmpty) body['address']   = _addressController.text.trim();
      if (_emailController.text.trim().isNotEmpty)   body['email']     = _emailController.text.trim();

      final response = await ApiService.postWithAuth('/profile/update', body);
      final data     = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (_newProfileImage != null) await _uploadPhoto();
        _showMessage(tr.isAmharic ? 'ፕሮፋይልዎ ተሻሽሏል!' : 'Profile updated successfully!');
        if (mounted) Navigator.pop(context, true);
      } else {
        _showMessage(data['message'] ?? (tr.isAmharic ? 'ማዘመን አልተሳካም' : 'Update failed'));
      }
    } catch (e) { _showMessage('Error: $e'); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _changePassword() async {
    final tr   = context.read<LanguageProvider>().tr;
    final isAm = tr.isAmharic;
    if (_oldPasswordController.text.isEmpty) {
      _showMessage(isAm ? 'የአሁኑ የይለፍ ቃልዎን ያስገቡ' : 'Please enter your current password'); return;
    }
    if (_newPasswordController.text.length < 8) {
      _showMessage(isAm ? 'አዲሱ የይለፍ ቃል ቢያንስ 8 ቁምፊ መሆን አለበት' : 'New password must be at least 8 characters'); return;
    }
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      _showMessage(isAm ? 'አዲሱ የይለፍ ቃሎች አይመሳሰሉም' : 'New passwords do not match'); return;
    }
    setState(() => _isChangingPassword = true);
    try {
      final response = await ApiService.postWithAuth('/profile/change-password', {
        'old_password':              _oldPasswordController.text,
        'new_password':              _newPasswordController.text,
        'new_password_confirmation': _confirmNewPasswordController.text,
      });
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage(isAm ? 'የይለፍ ቃሉ ተቀይሯል!' : 'Password changed successfully!');
        if (mounted) setState(() {
          _showChangePassword = false;
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmNewPasswordController.clear();
        });
      } else {
        _showMessage(data['message'] ?? (isAm ? 'የይለፍ ቃል መቀየር አልተሳካም' : 'Password change failed'));
      }
    } catch (e) { _showMessage('Error: $e'); }
    finally { if (mounted) setState(() => _isChangingPassword = false); }
  }

  Future<void> _uploadPhoto() async {
    try {
      final token   = await ApiService.getToken();
      final uri     = Uri.parse('${ApiConstants.baseUrl}/profile/photo');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept']        = 'application/json';
      request.files.add(await http.MultipartFile.fromPath('profile_photo', _newProfileImage!.path));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() {
          _existingPhotoUrl = '${ApiConstants.storageUrl}/${data['profile_photo']}';
          _newProfileImage  = null;
        });
      }
    } catch (e) { debugPrint('Photo upload error: $e'); }
  }

  Widget _sectionLabel(String text, AppTheme t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(
        color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
        fontWeight: FontWeight.w600, fontSize: 14)),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required AppTheme t,
    required Color fillColor,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText   = false,
    bool? obscureToggle,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(color: fillColor, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(color: t.primaryText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.secondaryText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(
                    (obscureToggle ?? true) ? Icons.visibility : Icons.visibility_off,
                    color: t.iconColor,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t    = context.watch<ThemeProvider>().theme;
    final tr   = context.watch<LanguageProvider>().tr;
    final isAm = tr.isAmharic;

    final profileFieldBg  = t.cardColor;
    final passwordFieldBg = t.scaffoldBg;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.appBarColor,
        foregroundColor: t.appBarFg,
        title: Text(tr.get('edit_profile'),
            style: TextStyle(color: t.appBarTextColor, fontSize: 18, fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: t.appBarFg),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isFetchingProfile
          ? Center(child: CircularProgressIndicator(
              color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Profile Photo ────────────────────────────────
                Center(child: Column(children: [
                  Stack(children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                            width: 2),
                      ),
                      child: ClipOval(
                        child: _newProfileImage != null
                            ? Image.file(_newProfileImage!, fit: BoxFit.cover)
                            : _existingPhotoUrl != null
                                ? Image.network(_existingPhotoUrl!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.person, size: 60, color: t.iconColor))
                                : Icon(Icons.person, size: 60, color: t.iconColor),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                            shape: BoxShape.circle,
                            border: Border.all(color: t.scaffoldBg, width: 2),
                          ),
                          child: Icon(Icons.image_outlined,
                              color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Text(
                      isAm ? 'ፎቶ ቀይር' : 'Change Photo',
                      style: TextStyle(
                          color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ])),
                const SizedBox(height: 32),

                // ── Profile Info Fields ──────────────────────────
                _sectionLabel(isAm ? 'ሙሉ ስም' : 'Full Name', t),
                _buildField(controller: _nameController,
                    hint: isAm ? 'ሙሉ ስምዎን ያስገቡ' : 'Enter your full name',
                    t: t, fillColor: profileFieldBg),
                const SizedBox(height: 16),

                _sectionLabel(isAm ? 'ኢሜይል አድራሻ' : 'Email Address', t),
                _buildField(controller: _emailController,
                    hint: isAm ? 'ኢሜይልዎን ያስገቡ' : 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    t: t, fillColor: profileFieldBg),
                const SizedBox(height: 16),

                _sectionLabel(isAm ? 'ስልክ ቁጥር' : 'Phone Number', t),
                _buildField(controller: _phoneController,
                    hint: isAm ? 'ስልክ ቁጥርዎን ያስገቡ' : 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                    t: t, fillColor: profileFieldBg),
                const SizedBox(height: 16),

                _sectionLabel(isAm ? 'አድራሻ' : 'Address', t),
                _buildField(controller: _addressController,
                    hint: isAm ? 'አድራሻዎን ያስገቡ' : 'Enter your address',
                    t: t, fillColor: profileFieldBg),
                const SizedBox(height: 24),

                // ── Save Changes Button ──────────────────────────
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                      foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white)
                        : Text(isAm ? 'ለውጦችን አስቀምጥ' : 'Save Changes',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Change Password Section ──────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: t.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(t.isNight ? 0.2 : 0.05),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _showChangePassword = !_showChangePassword),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                                color: t.scaffoldBg, borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.lock_outline, color: t.iconColor, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              isAm ? 'የይለፍ ቃል ቀይር' : 'Change Password',
                              style: TextStyle(
                                  color: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAm ? 'የመለያ የይለፍ ቃልዎን ያዘምኑ' : 'Update your account password',
                              style: TextStyle(color: t.secondaryText, fontSize: 12),
                            ),
                          ])),
                          Icon(_showChangePassword
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                              color: t.iconColor),
                        ]),
                      ),
                    ),

                    if (_showChangePassword) ...[
                      Divider(height: 1, color: t.dividerColor),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          _sectionLabel(isAm ? 'የአሁኑ የይለፍ ቃል' : 'Current Password', t),
                          _buildField(
                            controller: _oldPasswordController,
                            hint: isAm ? 'የአሁኑ የይለፍ ቃልዎን ያስገቡ' : 'Enter your current password',
                            obscureText: _obscureOld, obscureToggle: _obscureOld,
                            onToggle: () => setState(() => _obscureOld = !_obscureOld),
                            t: t, fillColor: passwordFieldBg,
                          ),
                          const SizedBox(height: 14),

                          _sectionLabel(isAm ? 'አዲስ የይለፍ ቃል' : 'New Password', t),
                          _buildField(
                            controller: _newPasswordController,
                            hint: isAm ? 'ቢያንስ 8 ቁምፊ' : 'Min 8 characters',
                            obscureText: _obscureNew, obscureToggle: _obscureNew,
                            onToggle: () => setState(() => _obscureNew = !_obscureNew),
                            t: t, fillColor: passwordFieldBg,
                          ),
                          const SizedBox(height: 14),

                          _sectionLabel(isAm ? 'አዲሱን የይለፍ ቃል አረጋግጥ' : 'Confirm New Password', t),
                          _buildField(
                            controller: _confirmNewPasswordController,
                            hint: isAm ? 'አዲሱን የይለፍ ቃል እንደገና ያስገቡ' : 'Re-enter new password',
                            obscureText: _obscureConfirm, obscureToggle: _obscureConfirm,
                            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            t: t, fillColor: passwordFieldBg,
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity, height: 48,
                            child: ElevatedButton(
                              onPressed: _isChangingPassword ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: t.isNight ? const Color(0xFFD5C38B) : const Color(0xFF486D99),
                                foregroundColor: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isChangingPassword
                                  ? SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          color: t.isNight ? const Color(0xFF1A3A5C) : Colors.white,
                                          strokeWidth: 2.5))
                                  : Text(
                                      isAm ? 'የይለፍ ቃል ለውጥ አረጋግጥ' : 'Confirm Password Change',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 32),
              ]),
            ),
    );
  }
}