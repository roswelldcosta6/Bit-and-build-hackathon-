import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_controller.dart';

/// Landing palette (matched to the official logo / landing screen).
const Color _green = Color(0xFF4E9B8F);
const Color _navy = Color(0xFF1B263B);
const Color _inkText = Color(0xFF1E293B);
const Color _subText = Color(0xFF64748B);
const Color _pageBg = Color(0xFFFBFBFA);
const Color _hairline = Color(0xFFE5E7EB);
const Color _danger = Color(0xFFDA1E28);

/// Auth screen (sign in / sign up / guest) matching the landing page theme.
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
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _guest() {
    ref.read(authProvider.notifier).continueAsGuest();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back to landing
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => context.go('/landing'),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _inkText,
                        ),
                      ),
                    ),

                    // Logo emblem + wordmark (same asset as the landing page)
                    const SizedBox(height: 4),
                    Center(
                      child: Image.asset(
                        'assets/images/logo_emblem.png',
                        width: 96,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.sign_language_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'SignBridge',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: _navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _isSignUp
                            ? 'Create your account'
                            : 'Welcome back',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _subText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Card with the fields (landing-style rounded card)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _hairline, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            const SizedBox(height: 14),
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
                          const SizedBox(height: 14),
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
                                color: _subText,
                              ),
                              tooltip: _obscure
                                  ? 'Show password'
                                  : 'Hide password',
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6)
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                          if (_isSignUp) ...[
                            const SizedBox(height: 14),
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
                            const SizedBox(height: 16),
                            const Text(
                              'I AM',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.2,
                                color: _subText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ChoiceChips(
                              values: const {
                                'deaf_user': 'Deaf',
                                'hearing_peer': 'Hearing',
                                'interpreter': 'Interpreter',
                              },
                              selected: _role,
                              onSelected: (v) => setState(() => _role = v),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'PREFERRED LANGUAGE',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.2,
                                color: _subText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ChoiceChips(
                              values: const {'en': 'English', 'hi': 'Hindi'},
                              selected: _lang,
                              onSelected: (v) => setState(() => _lang = v),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _danger.withValues(alpha: .4),
                          ),
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
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _danger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),
                    // Primary action — navy like the landing Get Started button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                            }),
                      style: TextButton.styleFrom(
                        foregroundColor: _green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : 'New to SignBridge? Create an account',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(height: 1, color: _hairline),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _subText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(height: 1, color: _hairline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _busy ? null : _guest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _navy,
                          side: const BorderSide(color: _hairline, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Continue as guest',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'Bilingual • India-First Design • Offline Capable',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

/// Pill choice chips in the landing green.
class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final Map<String, String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: values.entries.map((entry) {
      final isSel = entry.key == selected;
      return ChoiceChip(
        label: Text(entry.value),
        selected: isSel,
        onSelected: (_) => onSelected(entry.key),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isSel ? Colors.white : _subText,
        ),
        selectedColor: _green,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSel ? _green : _hairline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        visualDensity: VisualDensity.compact,
      );
    }).toList(),
  );
}

/// Rounded text field in the landing style.
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
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: const TextStyle(
        fontSize: 14,
        color: _inkText,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: _subText),
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 1.4),
        ),
      ),
    );
  }
}
