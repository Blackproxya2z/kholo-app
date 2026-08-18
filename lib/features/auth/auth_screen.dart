import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/kholo_animated_loader.dart';

/// ─── LUXURY AUTHENTICATION EXPERIENCE ───────────────────────────────────────
///
/// Features:
/// 1. Calm, private authentication portal.
/// 2. Email & password sign in / account registration.
/// 3. Haptic feedback on interactions.
/// 4. Full Dark & Light luxury theme tokens.
/// ────────────────────────────────────────────────────────────────────────────
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
    });

    KholoAnimatedLoader.show(
      context,
      message: _isSignUp
          ? 'Creating your private space...'
          : 'Signing in to KHOLO...',
    );

    // Simulate async auth — in production, call a real auth provider.
    await Future.delayed(const Duration(milliseconds: 900));
    // Use email as a stable local user ID for v1.
    await ref.read(authProvider.notifier).signIn(email);
    if (!mounted) return;
    KholoAnimatedLoader.hide(context);
    setState(() => _loading = false);

    // Route to onboarding if profile incomplete, else to app.
    final profile = ref.read(healthProfileProvider);
    if (!profile.onboardingComplete) {
      context.go('/onboarding');
    } else {
      context.go('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.kCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Back
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.go('/');
                },
                icon: Icon(Icons.arrow_back_rounded,
                    size: 18,
                    color: context.isDark
                        ? KholoColors.magenta
                        : KholoColors.wine),
                label: Text(
                  'Back',
                  style: TextStyle(
                    color: context.isDark
                        ? KholoColors.magenta
                        : KholoColors.wine,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Header
              Text(
                _isSignUp ? 'Create your\nprivate space' : 'Welcome back',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: context.kInk,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Your health information is private and stays on your device.'
                    : 'Sign in to continue your KHOLO journey.',
                style: tt.bodyMedium
                    ?.copyWith(color: context.kInkMuted, height: 1.5),
              ),
              const SizedBox(height: 40),

              // Email
              _FieldLabel('Email address', color: context.kInkMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  filled: true,
                  fillColor: context.kCard,
                  prefixIcon: Icon(Icons.mail_outline_rounded,
                      color: context.kInkSubtle),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              _FieldLabel('Password', color: context.kInkMuted),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: _isSignUp
                    ? [AutofillHints.newPassword]
                    : [AutofillHints.password],
                decoration: InputDecoration(
                  hintText:
                      _isSignUp ? 'Create a password' : 'Enter your password',
                  filled: true,
                  fillColor: context.kCard,
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      color: context.kInkSubtle),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: context.kInkSubtle,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    tooltip:
                        _obscurePassword ? 'Show password' : 'Hide password',
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: tt.bodySmall?.copyWith(color: KholoColors.error),
                  ),
                ),

              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDark
                        ? KholoColors.magenta
                        : KholoColors.wine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isSignUp ? 'Create account' : 'Sign in',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle
              Center(
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _error = null;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'New to KHOLO? Create account',
                    style: tt.bodyMedium?.copyWith(
                      color: context.isDark
                          ? KholoColors.magenta
                          : KholoColors.wine,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Privacy note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.kDivider),
                  boxShadow: [
                    BoxShadow(
                      color: KholoColors.wine.withValues(
                          alpha: context.isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: context.isDark
                          ? KholoColors.magenta
                          : KholoColors.plum,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No health information is requested until after you sign in. Your data is private and scoped to your account.',
                        style: tt.bodySmall?.copyWith(
                            color: context.kInkMuted, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontSize: 12,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
