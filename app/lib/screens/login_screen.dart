import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_controller.dart';

const Color _accent = Color(0xFF0F62FE);
const Color _danger = Color(0xFFDA1E28);

/// Pocket-minimal auth screen: sign-in / sign-up / guest.
/// No rounded corners, no emoji, hairline dividers, generous whitespace.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSignUp = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();

  String _role = 'deaf_user';
  String _lang = 'en';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authProvider.notifier);
      if (_isSignUp) {
        await auth.register(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
          role: _role,
          preferredLang: _lang,
        );
      } else {
        await auth.login(email: _email.text.trim(), password: _password.text);
      }
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _guest() {
    ref.read(authProvider.notifier).continueAsGuest();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.dividerColor;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Wordmark
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          color: theme.colorScheme.primary,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.sign_language,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SignBridge',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Text(
                      _isSignUp ? 'Create your account' : 'Welcome back',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? 'A few details and you are in.'
                          : 'Sign in to continue translating.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_isSignUp) ...[
                      _Field(
                        controller: _name,
                        label: 'Full name',
                        hint: 'Roswald Dcosta',
                        validator: (v) =>
                            (v == null || v.trim().length < 2)
                            ? 'Enter your full name'
                            : null,
                      ),
                      _DividerGap(divider: divider),
                    ],
                    _Field(
                      controller: _email,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter your email';
                        final re = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$',
                        );
                        if (!re.hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    _DividerGap(divider: divider),
                    _Field(
                      controller: _password,
                      label: 'Password',
                      hint: 'At least 6 characters',
                      obscure: _obscure,
                      autofillHints: const [AutofillHints.password],
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6)
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    if (_isSignUp) ...[
                      _DividerGap(divider: divider),
                      _Field(
                        controller: _confirm,
                        label: 'Confirm password',
                        hint: 'Repeat your password',
                        obscure: true,
                        validator: (v) =>
                            (v == null || v != _password.text)
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'I AM',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'deaf_user', label: Text('Deaf')),
                          ButtonSegment(
                            value: 'hearing_peer',
                            label: Text('Hearing'),
                          ),
                          ButtonSegment(
                            value: 'interpreter',
                            label: Text('Interpreter'),
                          ),
                        ],
                        selected: {_role},
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          side: WidgetStatePropertyAll(
                            BorderSide(color: divider),
                          ),
                        ),
                        onSelectionChanged: (value) =>
                            setState(() => _role = value.first),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PREFERRED LANGUAGE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('English')),
                          ButtonSegment(value: 'hi', label: Text('Hindi')),
                        ],
                        selected: {_lang},
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          side: WidgetStatePropertyAll(
                            BorderSide(color: divider),
                          ),
                        ),
                        onSelectionChanged: (value) =>
                            setState(() => _lang = value.first),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _danger),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 18,
                              color: _danger,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Create account' : 'Sign in',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                            }),
                      style: TextButton.styleFrom(
                        foregroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : 'New to SignBridge? Create an account',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Divider(height: 1, color: divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(height: 1, color: divider)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy ? null : _guest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(color: divider),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Continue as guest'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square text field with a floating label and hairline border.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints = const {},
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String> autofillHints;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: suffix,
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _accent, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _danger, width: 1.4),
        ),
      ),
    );
  }
}

class _DividerGap extends StatelessWidget {
  const _DividerGap({required this.divider});
  final Color divider;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Divider(height: 1, color: divider),
  );
}
