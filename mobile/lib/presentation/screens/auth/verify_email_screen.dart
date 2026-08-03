import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/providers.dart';

/// `POST /auth/verify-email` — the backend does not email this token; it is
/// returned by `POST /auth/register` as `verificationToken`, so registration
/// forwards it here pre-filled.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _token = TextEditingController(
    text: widget.initialToken ?? '',
  );

  bool _busy = false;
  bool _verified = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyEmail(_token.text.trim());
      if (!mounted) return;
      setState(() => _verified = true);
      await ref.read(authControllerProvider.notifier).refreshProfile();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = context.palette;
    final bool signedIn = ref.watch(authControllerProvider).isAuthenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pageBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (_verified ? AppColors.success : AppColors.primary600)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _verified
                      ? Icons.verified_rounded
                      : Icons.mark_email_read_outlined,
                  color: _verified ? AppColors.success : AppColors.primary600,
                  size: 26,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _verified ? 'Email verified' : 'Confirm your email',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _verified
                    ? 'Your account is now marked as verified.'
                    : 'Paste the verification token issued when your account was created.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (!_verified) ...<Widget>[
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _token,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Verification token',
                      prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                    ),
                    validator: (String? v) =>
                        Validators.required(v, 'Verification token'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Verify email',
                  icon: Icons.check_rounded,
                  isLoading: _busy,
                  onPressed: _verify,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  background: palette.surfaceSoft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Verification is optional — sign-in works without it. '
                          'The backend returns this token from registration '
                          'rather than sending it by email.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_verified) ...<Widget>[
                PrimaryButton(
                  label: signedIn ? 'Continue' : 'Go to sign in',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.pop(),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
