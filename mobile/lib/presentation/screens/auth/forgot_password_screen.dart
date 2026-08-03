import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../providers/providers.dart';

/// Three-step reset that mirrors the web flow:
///   1. `POST /auth/forgot-password` — emails a 6-digit OTP (10 min validity)
///   2. enter the OTP
///   3. `POST /auth/reset-password` with `{ token: <otp>, newPassword }`
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _otp = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  final GlobalKey<FormState> _emailForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _otpForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordForm = GlobalKey<FormState>();

  int _step = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_emailForm.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      if (!mounted) return;
      setState(() => _step = 1);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirmCode() {
    if (!(_otpForm.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  Future<void> _reset() async {
    if (!(_passwordForm.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final AuthRepository repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(
        otp: _otp.text.trim(),
        newPassword: _password.text,
      );
      if (!mounted) return;
      setState(() => _step = 3);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.detailedMessage;
        // A bad/expired OTP sends the user back to the code step.
        if (error.statusCode == 400) _step = 1;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account recovery')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pageBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],
              switch (_step) {
                0 => _emailStep(context),
                1 => _otpStep(context),
                2 => _passwordStep(context),
                _ => _successStep(context),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String message,
  ) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _emailStep(BuildContext context) {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _stepHeader(
            context,
            Icons.mail_outline_rounded,
            AppColors.primary600,
            'Reset your password',
            "Enter the email linked to your account and we'll send a 6-digit verification code.",
          ),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Send verification code',
            icon: Icons.send_rounded,
            isLoading: _busy,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _otpStep(BuildContext context) {
    return Form(
      key: _otpForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _stepHeader(
            context,
            Icons.key_rounded,
            AppColors.warning,
            'Enter verification code',
            'We sent a 6-digit code to ${_email.text.trim()}. It expires in 10 minutes.',
          ),
          TextFormField(
            controller: _otp,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 10,
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              counterText: '',
              hintText: '000000',
            ),
            validator: Validators.otp,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Verify code',
            icon: Icons.arrow_forward_rounded,
            onPressed: _confirmCode,
          ),
          TextButton(
            onPressed: _busy ? null : _sendCode,
            child: const Text('Resend code'),
          ),
          TextButton(
            onPressed: () => setState(() {
              _step = 0;
              _otp.clear();
            }),
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }

  Widget _passwordStep(BuildContext context) {
    return Form(
      key: _passwordForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _stepHeader(
            context,
            Icons.shield_outlined,
            AppColors.teal,
            'Create new password',
            'Choose a password with at least 8 characters, a number and a symbol.',
          ),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New password',
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
            ),
            validator: Validators.strongPassword,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
            ),
            validator: (String? value) {
              if ((value ?? '').isEmpty) return 'Please confirm your password';
              if (value != _password.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Reset password',
            icon: Icons.check_rounded,
            isLoading: _busy,
            onPressed: _reset,
          ),
        ],
      ),
    );
  }

  Widget _successStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _stepHeader(
          context,
          Icons.check_circle_rounded,
          AppColors.success,
          'Password reset complete',
          'Your password has been updated. Sign in with your new credentials.',
        ),
        PrimaryButton(
          label: 'Go to sign in',
          icon: Icons.login_rounded,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
