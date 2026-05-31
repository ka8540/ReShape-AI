import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../state/auth_state.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/design_system.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(authServiceProvider).signInWithGoogle();
      if (result != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LogoMark(size: 48),
            const SizedBox(height: 24),
            Text('Welcome to ReSpace', style: AppText.h1()),
            const SizedBox(height: 8),
            Text(
              'Sign in to save your projects and sync across devices.',
              style: AppText.body(),
            ),
            const Spacer(),
            if (_error != null) ...[
              Text(_error!, style: AppText.sm(color: AppColors.danger)),
              const SizedBox(height: 12),
            ],
            RsButton(
              label: _busy ? 'Signing in…' : 'Continue with Google',
              icon: Icons.login_rounded,
              onPressed: _busy ? null : _signInWithGoogle,
            ),
            const SizedBox(height: 8),
            RsButton(
              label: 'Continue as guest',
              variant: RsButtonVariant.quiet,
              onPressed: _busy
                  ? null
                  : () {
                      ref.read(appAuthControllerProvider.notifier).continueAsGuest();
                      context.go('/home');
                    },
            ),
          ],
        ),
      ),
    );
  }
}
