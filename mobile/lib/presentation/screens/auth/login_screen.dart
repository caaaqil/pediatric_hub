import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/api_endpoint.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/providers.dart';

/// `POST /auth/login` → stores the token pair and routes to the role home.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Lets the address be corrected on the device — a laptop's LAN IP changes
  /// whenever the router issues a new DHCP lease, and the APK would otherwise
  /// need rebuilding each time.
  Future<void> _editEndpoint() async {
    final TextEditingController controller = TextEditingController(
      text: ApiEndpoint.current,
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('API endpoint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Your laptop's address on this Wi-Fi. Find it with "
              '`hostname -I` (Linux), `ipconfig` (Windows) or '
              '`ipconfig getifaddr en0` (macOS).',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: '192.168.1.20',
                helperText: 'Port 3000 and /api/v1 are added automatically',
              ),
              onSubmitted: (String v) => Navigator.of(ctx).pop(v),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: const Text('Reset to default'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result == null) return; // cancelled

    await ApiEndpoint.save(result);
    if (!mounted) return;
    setState(() {}); // repaint the endpoint card
    Toast.success(context, 'Now using ${ApiEndpoint.current}');
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .login(email: _email.text.trim(), password: _password.text);
    // Routing is handled by the redirect in app_router.dart.
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authControllerProvider);
    final AppPalette palette = context.palette;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary600,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Pediatric Health Hub',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text('Welcome back', style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign in to access your secure clinical dashboard.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),

                if (auth.error != null) ...<Widget>[
                  ErrorBanner(message: auth.error ?? ''),
                  const SizedBox(height: AppSpacing.lg),
                ],

                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),

                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.password,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(Routes.forgotPassword),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                PrimaryButton(
                  label: 'Sign in',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: auth.isBusy,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Don't have an account?",
                      style: theme.textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => context.push(Routes.register),
                      child: const Text('Create one'),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceSoft,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.dns_outlined,
                            size: 14,
                            color: palette.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'API endpoint',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.textMuted,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _editEndpoint,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        ApiEndpoint.current,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (ApiEndpoint.isCustom)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Custom address saved on this device',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.teal,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
