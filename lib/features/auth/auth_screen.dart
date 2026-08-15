import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/colors.dart';
import '../../core/providers/providers.dart';

/// Sign in / sign up screen.
/// For v1 (local-only), creates a stable local user ID.
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
    setState(() {
      _loading = true;
      _error = null;
    });
    // Simulate async auth — in production, call a real auth provider.
    await Future.delayed(const Duration(milliseconds: 800));
    // Use email as a stable local user ID for v1.
    await ref.read(authProvider.notifier).signIn(email);
    if (!mounted) return;
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
      backgroundColor: KholoColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Back
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
              ),
              const SizedBox(height: 32),
              // Header
              Text(
                _isSignUp ? 'Create your\nprivate space' : 'Welcome back',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: KholoColors.ink,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Your health information is private and stays on your device.'
                    : 'Sign in to continue your KHOLO journey.',
                style: tt.bodyMedium?.copyWith(color: KholoColors.inkMuted, height: 1.5),
              ),
              const SizedBox(height: 40),

              // Email
              const _FieldLabel('Email address'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: KholoColors.inkSubtle),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              const _FieldLabel('Password'),
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
                  hintText: _isSignUp ? 'Create a password' : 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: KholoColors.inkSubtle),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: KholoColors.inkSubtle,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
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
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignUp ? 'Create account' : 'Sign in'),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _isSignUp = !_isSignUp;
                    _error = null;
                  }),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'New to KHOLO? Create account',
                    style: tt.bodyMedium?.copyWith(color: KholoColors.plum),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Privacy note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KholoColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KholoColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: KholoColors.plum, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No health information is requested until after you sign in. Your data is private and scoped to your account.',
                        style: tt.bodySmall?.copyWith(
                            color: KholoColors.inkMuted, height: 1.5),
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
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: KholoColors.inkMuted,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
    );
  }
}
