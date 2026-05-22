// lib/screens/account/edit_profile_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

// ── Colors ─────────────────────────────────────────────────────────────────
const _kNavy      = Color(0xFF0D1B2A);
const _kNavyMid   = Color(0xFF1A3A5C);
const _kGold      = Color(0xFFC9A84C);
const _kGoldLight = Color(0xFFE8D5A3);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
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
      if (mounted) {
        setState(() => _isFetchingProfile = false);
        _animController.forward();
      }
    }
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final saved  = await File(picked.path).copy(
          '${appDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (mounted) setState(() => _newProfileImage = saved);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    final t = context.read<ThemeProvider>().theme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _saveChanges() async {
    final tr = context.read<LanguageProvider>().tr;
    HapticFeedback.lightImpact();
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
        _showMessage(data['message'] ?? (tr.isAmharic ? 'ማዘመን አልተሳካም' : 'Update failed'),
            isError: true);
      }
    } catch (e) { _showMessage('Error: $e', isError: true); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _changePassword() async {
    final tr   = context.read<LanguageProvider>().tr;
    final isAm = tr.isAmharic;
    if (_oldPasswordController.text.isEmpty) {
      _showMessage(isAm ? 'የአሁኑ የይለፍ ቃልዎን ያስገቡ' : 'Please enter your current password',
          isError: true); return;
    }
    if (_newPasswordController.text.length < 8) {
      _showMessage(isAm ? 'አዲሱ የይለፍ ቃል ቢያንስ 8 ቁምፊ መሆን አለበት'
          : 'New password must be at least 8 characters', isError: true); return;
    }
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      _showMessage(isAm ? 'አዲሱ የይለፍ ቃሎች አይመሳሰሉም' : 'New passwords do not match',
          isError: true); return;
    }
    HapticFeedback.lightImpact();
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
        _showMessage(data['message'] ?? (isAm ? 'የይለፍ ቃል መቀየር አልተሳካም' : 'Password change failed'),
            isError: true);
      }
    } catch (e) { _showMessage('Error: $e', isError: true); }
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

  @override
  Widget build(BuildContext context) {
    final t    = context.watch<ThemeProvider>().theme;
    final tr   = context.watch<LanguageProvider>().tr;
    final isAm = tr.isAmharic;
    final accent = t.isNight ? _kGold : _kNavyMid;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: Column(children: [
        // ── Gradient Header ────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: t.isNight
                  ? [const Color(0xFF1A2F4A), _kNavy]
                  : [_kNavy, _kNavyMid],
            ),
            boxShadow: [
              BoxShadow(color: _kNavy.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isAm ? 'ፕሮፋይል አስተካክል' : 'Edit Profile',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 0.3)),
                    Text(isAm ? 'የእርስዎን መረጃ ያዘምኑ' : 'Update your personal information',
                        style: TextStyle(fontSize: 12,
                            color: Colors.white.withOpacity(0.7))),
                  ]),
                ),
                // Save icon button in header
                GestureDetector(
                  onTap: _isLoading ? null : _saveChanges,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kGold,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: _kGold.withOpacity(0.4), blurRadius: 8)],
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                color: _kNavy))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.check_rounded, color: _kNavy, size: 16),
                            const SizedBox(width: 4),
                            Text(isAm ? 'አስቀምጥ' : 'Save',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                                    color: _kNavy)),
                          ]),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Body ───────────────────────────────────────────────────────
        Expanded(
          child: _isFetchingProfile
              ? Center(child: CircularProgressIndicator(
                  color: t.isNight ? _kGold : _kNavyMid, strokeWidth: 2.5))
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        // ── Avatar ─────────────────────────────────────
                        Center(child: _buildAvatar(t)),
                        const SizedBox(height: 28),

                        // ── Personal Info Card ─────────────────────────
                        _buildSectionCard(
                          icon: Icons.person_rounded,
                          title: isAm ? 'ግላዊ መረጃ' : 'Personal Information',
                          t: t, accent: accent,
                          child: Column(children: [
                            _buildField(
                              controller: _nameController,
                              label: isAm ? 'ሙሉ ስም' : 'Full Name',
                              hint: isAm ? 'ሙሉ ስምዎን ያስገቡ' : 'Enter your full name',
                              icon: Icons.person_outline_rounded,
                              t: t, accent: accent,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _emailController,
                              label: isAm ? 'ኢሜይል' : 'Email Address',
                              hint: isAm ? 'ኢሜይልዎን ያስገቡ' : 'Enter your email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              t: t, accent: accent,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _phoneController,
                              label: isAm ? 'ስልክ ቁጥር' : 'Phone Number',
                              hint: isAm ? 'ስልክ ቁጥርዎን ያስገቡ' : 'Enter your phone number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              t: t, accent: accent,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _addressController,
                              label: isAm ? 'አድራሻ' : 'Address',
                              hint: isAm ? 'አድራሻዎን ያስገቡ' : 'Enter your address',
                              icon: Icons.location_on_outlined,
                              t: t, accent: accent,
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // ── Save Button ────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveChanges,
                            icon: _isLoading
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(Icons.save_rounded, size: 20),
                            label: Text(isAm ? 'ለውጦችን አስቀምጥ' : 'Save Changes',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3)),
                            style: ElevatedButton.styleFrom(
backgroundColor: t.isNight ? _kGold : _kNavyMid,
                              foregroundColor: t.isNight ? _kNavy : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Change Password Card ───────────────────────
                        _buildPasswordSection(t, tr, isAm, accent),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _buildAvatar(AppTheme t) {
    final accent = t.isNight ? _kGold : _kNavyMid;
    return Stack(clipBehavior: Clip.none, children: [
      // Outer glow ring
      Container(
        width: 110, height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.3), accent.withOpacity(0.05)],
          ),
        ),
      ),
      // Avatar
      Positioned(
        top: 5, left: 5,
        child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 2.5),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.3), blurRadius: 12, spreadRadius: 1),
            ],
          ),
          child: ClipOval(
            child: _newProfileImage != null
                ? Image.file(_newProfileImage!, fit: BoxFit.cover)
                : _existingPhotoUrl != null
                    ? Image.network(_existingPhotoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: accent.withOpacity(0.1),
                                child: Icon(Icons.person_rounded, size: 50,
                                    color: accent.withOpacity(0.5))))
                    : Container(
                        color: accent.withOpacity(0.1),
                        child: Icon(Icons.person_rounded, size: 50,
                            color: accent.withOpacity(0.5))),
          ),
        ),
      ),
      // Camera button
      Positioned(
        bottom: 2, right: 2,
        child: GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: t.isNight ? [_kGold, const Color(0xFFE8C96A)] : [_kNavy, _kNavyMid]),
              shape: BoxShape.circle,
              border: Border.all(color: t.scaffoldBg, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
            ),
            child: Icon(Icons.camera_alt_rounded,
                color: t.isNight ? _kNavy : Colors.white, size: 16),
          ),
        ),
      ),
    ]);
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required AppTheme t,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(bottom: BorderSide(color: t.dividerColor)),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accent, size: 17),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent,
                    letterSpacing: 0.2)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ]),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required AppTheme t,
    required Color accent,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText   = false,
    bool? obscureToggle,
    VoidCallback? onToggle,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 13, color: accent),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: accent, letterSpacing: 0.2)),
      ]),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: t.isNight ? const Color(0xFF0D1B2A) : const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.dividerColor),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(fontSize: 14, color: t.primaryText, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: t.secondaryText, fontWeight: FontWeight.w400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            suffixIcon: onToggle != null
                ? IconButton(
                    icon: Icon(
                      (obscureToggle ?? true) ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: t.secondaryText, size: 20,
                    ),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
      ),
    ]);
  }

  Widget _buildPasswordSection(AppTheme t, dynamic tr, bool isAm, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10,
            offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        // Toggle header
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showChangePassword = !_showChangePassword);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(0.2)),
                ),
                child: Icon(Icons.lock_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isAm ? 'የይለፍ ቃል ቀይር' : 'Change Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: accent)),
                Text(isAm ? 'የመለያ የይለፍ ቃልዎን ያዘምኑ' : 'Update your account password',
                    style: TextStyle(fontSize: 12, color: t.secondaryText)),
              ])),
              AnimatedRotation(
                turns: _showChangePassword ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: accent, size: 20),
                ),
              ),
            ]),
          ),
        ),

        // Expanded password fields
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(children: [
            Divider(height: 1, color: t.dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildField(
                  controller: _oldPasswordController,
                  label: isAm ? 'የአሁኑ የይለፍ ቃል' : 'Current Password',
                  hint: isAm ? 'የአሁኑ የይለፍ ቃልዎን ያስገቡ' : 'Enter current password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscureOld, obscureToggle: _obscureOld,
                  onToggle: () => setState(() => _obscureOld = !_obscureOld),
                  t: t, accent: accent,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _newPasswordController,
                  label: isAm ? 'አዲስ የይለፍ ቃል' : 'New Password',
                  hint: isAm ? 'ቢያንስ 8 ቁምፊ' : 'Min 8 characters',
                  icon: Icons.lock_reset_rounded,
                  obscureText: _obscureNew, obscureToggle: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  t: t, accent: accent,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _confirmNewPasswordController,
                  label: isAm ? 'አዲሱን የይለፍ ቃል አረጋግጥ' : 'Confirm New Password',
                  hint: isAm ? 'አዲሱን የይለፍ ቃል እንደገና ያስገቡ' : 'Re-enter new password',
                  icon: Icons.verified_user_outlined,
                  obscureText: _obscureConfirm, obscureToggle: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  t: t, accent: accent,
                ),
                const SizedBox(height: 18),

                // Strength hints
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withOpacity(0.15)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      isAm
                          ? 'ጠንካራ የይለፍ ቃል ቢያንስ 8 ቁምፊ፣ ቁጥሮች እና ልዩ ቁምፊዎችን ያካትታል'
                          : 'A strong password has at least 8 characters, numbers and special characters',
                      style: TextStyle(fontSize: 11, color: accent, height: 1.5),
                    )),
                  ]),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isChangingPassword ? null : _changePassword,
                    icon: _isChangingPassword
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.lock_rounded, size: 18),
                    label: Text(
                      isAm ? 'የይለፍ ቃል ለውጥ አረጋግጥ' : 'Confirm Password Change',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.isNight ? _kGold : _kNavyMid,
                      foregroundColor: t.isNight ? _kNavy : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ]),
            ),
          ]),
          crossFadeState: _showChangePassword
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ]),
    );
  }
}