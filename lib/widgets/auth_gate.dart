// lib/widgets/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

/// Shows a bottom-sheet prompt asking the guest to sign in or register.
/// Wrap any tap handler with [AuthGate.require] to gate it behind auth.
class AuthGate {
  static const Color _navy = Color(0xFF1A3A5C);
  static const Color _gold = Color(0xFFC9A84C);

  /// Returns `true` if the user is authenticated and the action should proceed.
  /// Returns `false` and shows the sign-in sheet if the user is a guest.
  static bool require(
    BuildContext context, {
    String? featureName, // e.g. "submit a report"
  }) {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) return true;
    _showSheet(context, featureName: featureName);
    return false;
  }

  static void _showSheet(BuildContext context, {String? featureName}) {
    final t = context.read<ThemeProvider>().theme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AuthSheet(t: t, featureName: featureName),
    );
  }
}

class _AuthSheet extends StatelessWidget {
  final AppTheme t;
  final String?  featureName;

  const _AuthSheet({required this.t, this.featureName});

  static const Color _navy    = Color(0xFF1A3A5C);
  static const Color _navyDk  = Color(0xFF0D1B2A);
  static const Color _gold    = Color(0xFFC9A84C);
  static const Color _white   = Colors.white;

  @override
  Widget build(BuildContext context) {
    final bg    = t.isNight ? const Color(0xFF0F2440) : _white;
    final textC = t.isNight ? _white : _navy;

    final action = featureName != null
        ? 'To $featureName, please sign in or create an account.'
        : 'Sign in or create an account to access this feature.';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: textC.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withOpacity(0.12),
              border: Border.all(color: _gold.withOpacity(0.35), width: 2),
            ),
            child: const Icon(Icons.lock_rounded,
                size: 28, color: _gold),
          ),
          const SizedBox(height: 18),

          // Title
          Text('Sign In Required',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textC)),
          const SizedBox(height: 8),

          // Subtitle
          Text(action,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: textC.withOpacity(0.6))),
          const SizedBox(height: 28),

          // Sign In button
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: _white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('SIGN IN',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Create account button
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterScreen()));
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: _navy.withOpacity(0.3), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                foregroundColor: _navy,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_rounded,
                      size: 18,
                      color: t.isNight
                          ? _white.withOpacity(0.8)
                          : _navy),
                  const SizedBox(width: 8),
                  Text('CREATE ACCOUNT',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: t.isNight
                              ? _white.withOpacity(0.8)
                              : _navy)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later',
                style: TextStyle(
                    fontSize: 13,
                    color: textC.withOpacity(0.45),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}