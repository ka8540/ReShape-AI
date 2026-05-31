import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/firebase_bootstrap.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/design_system.dart';

enum _Mode { signIn, signUp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  String? _error;
  String? _notice;

  void switchMode(_Mode m) {
    if (_busy) return;
    setState(() {
      _mode = m;
      _error = null;
      _notice = null;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------- actions

  Future<void> _runAuth(Future<void> Function() body) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await body();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithEmail() => _runAuth(() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authServiceProvider).signInWithEmail(
      email: _email.text,
      password: _password.text,
    );
    // Router redirect handles routing to /home on auth success.
  });

  Future<void> _signUpWithEmail() => _runAuth(() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authServiceProvider).signUpWithEmail(
      email: _email.text,
      password: _password.text,
      displayName: _name.text,
    );
  });

  Future<void> _signInWithGoogle() => _runAuth(() async {
    final result = await ref.read(authServiceProvider).signInWithGoogle();
    if (result == null) {
      setState(() => _error = 'Google sign-in was cancelled.');
    }
  });

  Future<void> _forgotPassword() => _runAuth(() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter your email above to reset the password.');
      return;
    }
    await ref.read(authServiceProvider).sendPasswordReset(email);
    setState(() => _notice = 'Password reset email sent to $email.');
  });

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final fb = ref.watch(firebaseStatusProvider);
    return PageShell(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 24),
              if (fb.status == FirebaseStatus.ready)
                _AuthForm(state: this)
              else
                _FirebaseNotReady(status: fb),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const LogoMark(size: 44),
            const SizedBox(width: 12),
            Text(
              'ReShape AI',
              style: AppText.h2().copyWith(fontSize: 22),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Welcome', style: AppText.h1()),
        const SizedBox(height: 6),
        Text(
          'Sign in to load your projects and sync designs across devices.',
          style: AppText.body(),
        ),
      ],
    );
  }
}

class _FirebaseNotReady extends StatelessWidget {
  const _FirebaseNotReady({required this.status});

  final FirebaseBootstrapResult status;

  @override
  Widget build(BuildContext context) {
    final isDisabled = status.status == FirebaseStatus.disabled;
    final title = isDisabled
        ? 'Authentication disabled'
        : 'Firebase setup incomplete';
    final body = isDisabled
        ? 'This build was launched without --dart-define=ENABLE_FIREBASE=true. '
              'Stop the app and re-run with the flag enabled.'
        : 'Firebase failed to initialise. Add the GoogleService-Info.plist file '
              'to mobile/ios/Runner/ (or google-services.json to mobile/android/app/), '
              'register it in the Xcode/Android Studio project, then rebuild.';
    return RsCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warnTint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppText.h3())),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: AppText.sm()),
          if (status.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${status.error}',
                style: AppText.xs().copyWith(fontFamily: 'Courier'),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Quick setup:',
            style: AppText.sm(weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '1.  flutterfire configure   (creates lib/firebase_options.dart)\n'
            '2.  Drop GoogleService-Info.plist into mobile/ios/Runner/\n'
            '3.  Add the file to the Runner target in Xcode\n'
            '4.  flutter clean && flutter run',
            style: AppText.xs().copyWith(fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({required this.state});

  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: state._formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeSwitcher(
            current: state._mode,
            onChanged: state._busy ? null : state.switchMode,
          ),
          const SizedBox(height: 18),
          if (state._mode == _Mode.signUp) ...[
            _Field(
              controller: state._name,
              label: 'Display name',
              hint: 'How should we greet you?',
              autofillHints: const [AutofillHints.name],
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Enter a name';
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          _Field(
            controller: state._email,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: state._password,
            label: 'Password',
            hint: state._mode == _Mode.signUp
                ? 'Minimum 6 characters'
                : 'Your password',
            obscure: true,
            autofillHints: state._mode == _Mode.signUp
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              if (state._mode == _Mode.signUp && v.length < 6) {
                return 'Must be at least 6 characters';
              }
              return null;
            },
          ),
          if (state._mode == _Mode.signIn)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: state._busy ? null : state._forgotPassword,
                child: Text(
                  'Forgot password?',
                  style: AppText.xs(
                    color: AppColors.teal,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 6),
          if (state._error != null) ...[
            const SizedBox(height: 4),
            _MessageBanner(
              text: state._error!,
              color: AppColors.danger,
              icon: Icons.error_outline_rounded,
            ),
          ],
          if (state._notice != null) ...[
            const SizedBox(height: 4),
            _MessageBanner(
              text: state._notice!,
              color: AppColors.ok,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
          const SizedBox(height: 14),
          RsButton(
            label: state._busy
                ? 'Please wait…'
                : state._mode == _Mode.signIn
                ? 'Sign in'
                : 'Create account',
            icon: Icons.arrow_forward_rounded,
            onPressed: state._busy
                ? null
                : (state._mode == _Mode.signIn
                      ? state._signInWithEmail
                      : state._signUpWithEmail),
          ),
          const SizedBox(height: 14),
          const _OrDivider(),
          const SizedBox(height: 14),
          RsButton(
            label: 'Continue with Google',
            icon: Icons.login_rounded,
            variant: RsButtonVariant.soft,
            onPressed: state._busy ? null : state._signInWithGoogle,
          ),
          const SizedBox(height: 20),
          Text(
            'By continuing you agree to ReShape AI’s Terms and Privacy Policy.',
            style: AppText.xs(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.current, required this.onChanged});

  final _Mode current;
  final ValueChanged<_Mode>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SwitchButton(
              label: 'Sign in',
              selected: current == _Mode.signIn,
              onTap: onChanged == null ? null : () => onChanged!(_Mode.signIn),
            ),
          ),
          Expanded(
            child: _SwitchButton(
              label: 'Create account',
              selected: current == _Mode.signUp,
              onTap: onChanged == null ? null : () => onChanged!(_Mode.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  const _SwitchButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: selected ? AppShadows.sh : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppText.sm(
              color: selected ? AppColors.ink : AppColors.ink2,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.xs(weight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          validator: validator,
          textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
          style: AppText.body(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body(color: AppColors.ink3),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.r),
              borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('or', style: AppText.xs()),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppText.sm(color: color, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// --- helpers -----------------------------------------------------------

String? _validateEmail(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
    return 'Enter a valid email';
  }
  return null;
}

String _friendlyAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email looks malformed.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
      return 'No account found for that email.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email or password is incorrect.';
    case 'email-already-in-use':
      return 'An account already exists with that email.';
    case 'weak-password':
      return 'Password is too weak — use at least 6 characters.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'too-many-requests':
      return 'Too many attempts. Try again in a moment.';
    case 'operation-not-allowed':
      return 'This sign-in method is disabled in Firebase Console.';
    default:
      return e.message ?? 'Authentication failed (${e.code}).';
  }
}

