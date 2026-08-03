import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_dimens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user.dart';
import '../../providers/providers.dart';

/// `POST /auth/register` — public on the backend for all four roles.
///
/// DOCTOR additionally accepts licenseNumber / specialization; FACILITY builds
/// its profile name from the two name fields and uses phone + address.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _license = TextEditingController();
  final TextEditingController _specialization = TextEditingController();

  UserRole _role = UserRole.parent;
  bool _obscure = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _address.dispose();
    _license.dispose();
    _specialization.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final RegistrationResult? result = await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _email.text.trim(),
          password: _password.text,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          role: _role.wire,
          phoneNumber: _phone.text.trim(),
          address: _address.text.trim(),
          licenseNumber: _role == UserRole.doctor ? _license.text.trim() : null,
          specialization: _role == UserRole.doctor
              ? _specialization.text.trim()
              : null,
        );

    if (!mounted || result == null) return;

    // The backend hands back the raw verification token instead of emailing it,
    // so offer the verification step straight away.
    final String? token = result.verificationToken;
    if (token != null && token.isNotEmpty) {
      context.push('${Routes.verifyEmail}?token=$token');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authControllerProvider);
    final ThemeData theme = Theme.of(context);
    final bool isDoctor = _role == UserRole.doctor;
    final bool isFacility = _role == UserRole.facility;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pageBottom,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Join Pediatric Health Hub',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Choose the portal that matches your role.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),

                if (auth.error != null) ...<Widget>[
                  ErrorBanner(message: auth.error ?? ''),
                  const SizedBox(height: AppSpacing.lg),
                ],

                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Account type',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  items: UserRole.values
                      .map(
                        (UserRole role) => DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(role.label),
                        ),
                      )
                      .toList(),
                  onChanged: (UserRole? value) {
                    if (value != null) setState(() => _role = value);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _firstName,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: isFacility
                              ? 'Facility name'
                              : 'First name',
                        ),
                        validator: (String? v) => Validators.required(
                          v,
                          isFacility ? 'Facility name' : 'First name',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _lastName,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: isFacility
                              ? 'Branch / suffix'
                              : 'Last name',
                        ),
                        validator: (String? v) => Validators.required(
                          v,
                          isFacility ? 'Branch' : 'Last name',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

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
                const SizedBox(height: AppSpacing.lg),

                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: '8+ chars with a letter, number and symbol',
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
                  validator: Validators.strongPassword,
                ),
                const SizedBox(height: AppSpacing.lg),

                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone number${isFacility ? '' : ' (optional)'}',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (String? v) => isFacility
                      ? Validators.required(v, 'Phone number')
                      : null,
                ),

                if (isFacility) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                    validator: (String? v) => Validators.required(v, 'Address'),
                  ),
                ],

                if (isDoctor) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _specialization,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Specialization',
                      hintText: 'e.g. Pediatric Pulmonology',
                      prefixIcon: Icon(
                        Icons.medical_services_outlined,
                        size: 20,
                      ),
                    ),
                    validator: (String? v) =>
                        Validators.required(v, 'Specialization'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _license,
                    decoration: const InputDecoration(
                      labelText: 'Licence number',
                      hintText: 'Must be unique',
                      prefixIcon: Icon(Icons.verified_outlined, size: 20),
                    ),
                    validator: (String? v) =>
                        Validators.required(v, 'Licence number'),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Create account',
                  icon: Icons.person_add_alt_1_rounded,
                  isLoading: auth.isBusy,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('I already have an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
