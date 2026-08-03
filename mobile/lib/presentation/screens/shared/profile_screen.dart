import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/api_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user.dart';
import '../../providers/providers.dart';

/// Account screen for every role.
///
/// Editing maps to the role's own endpoint:
///  • PARENT   → `PUT /parents/:parentProfileId`
///  • DOCTOR   → `PUT /doctors/:doctorProfileId`
///  • FACILITY → `PUT /facilities/:facilityProfileId`
///  • ADMIN    → read-only (admins have no profile model on the backend)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(currentUserProvider);
    final AppPalette palette = context.palette;

    if (user == null) {
      return const Scaffold(body: LoadingView());
    }

    final UserProfile? profile = user.profile;
    final bool canEdit = user.role != UserRole.admin && profile != null;

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Profile')) : null,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(authControllerProvider.notifier).refreshProfile(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pageBottom,
          children: <Widget>[
            AppCard(
              child: Column(
                children: <Widget>[
                  InitialsAvatar(initials: user.initials, size: 64),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: <Widget>[
                      StatusBadge(
                        label: user.role.label,
                        color: AppColors.primary600,
                        icon: Icons.badge_rounded,
                      ),
                      StatusBadge(
                        label: user.isActive ? 'Active' : 'Suspended',
                        color: user.isActive
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      StatusBadge(
                        label: user.isEmailVerified ? 'Verified' : 'Unverified',
                        color: user.isEmailVerified
                            ? AppColors.teal
                            : AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppCardHeader(
                    title: 'Profile details',
                    icon: Icons.person_outline_rounded,
                    trailing: canEdit
                        ? TextButton(
                            onPressed: () async {
                              final bool? saved =
                                  await showModalBottomSheet<bool>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (BuildContext ctx) =>
                                        _EditProfileSheet(user: user),
                                  );
                              if (saved == true) {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .refreshProfile();
                                if (context.mounted) {
                                  Toast.success(context, 'Profile updated');
                                }
                              }
                            },
                            child: const Text('Edit'),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (profile == null)
                    Text(
                      user.role == UserRole.admin
                          ? 'Administrator accounts have no editable profile record.'
                          : 'No profile record is linked to this account.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else ...<Widget>[
                    if (user.role == UserRole.facility)
                      DetailRow(
                        label: 'Facility name',
                        value: profile.name ?? '—',
                        icon: Icons.local_hospital_outlined,
                      )
                    else
                      DetailRow(
                        label: 'Full name',
                        value: profile.fullName.isEmpty
                            ? '—'
                            : profile.fullName,
                        icon: Icons.person_outline_rounded,
                      ),
                    DetailRow(
                      label: 'Phone',
                      value: profile.phoneNumber ?? 'Not set',
                      icon: Icons.phone_outlined,
                    ),
                    if (user.role != UserRole.doctor)
                      DetailRow(
                        label: 'Address',
                        value: profile.address ?? 'Not set',
                        icon: Icons.location_on_outlined,
                      ),
                    if (user.role == UserRole.doctor) ...<Widget>[
                      DetailRow(
                        label: 'Specialisation',
                        value: profile.specialization ?? '—',
                        icon: Icons.medical_services_outlined,
                      ),
                      DetailRow(
                        label: 'Licence',
                        value: profile.licenseNumber ?? '—',
                        icon: Icons.verified_outlined,
                      ),
                      DetailRow(
                        label: 'Verification',
                        value: profile.verificationStatus ?? 'PENDING',
                        icon: Icons.fact_check_outlined,
                      ),
                    ],
                    if (user.role == UserRole.facility)
                      DetailRow(
                        label: 'Type',
                        value: profile.facilityType?.label ?? '—',
                        icon: Icons.apartment_outlined,
                      ),
                    DetailRow(
                      label: 'Member since',
                      value: Fmt.date(user.createdAt),
                      icon: Icons.event_note_outlined,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.notifications_none_rounded),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.notifications),
                  ),
                  Divider(height: 1, color: palette.border),
                  ListTile(
                    leading: const Icon(Icons.mark_email_read_outlined),
                    title: const Text('Verify email'),
                    subtitle: Text(
                      user.isEmailVerified
                          ? 'Your email is verified'
                          : 'Enter your verification token',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.verifyEmail),
                  ),
                  Divider(height: 1, color: palette.border),
                  ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('API endpoint'),
                    subtitle: Text(
                      ApiConfig.baseUrl,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final bool ok = await confirmAction(
                    context,
                    title: 'Sign out',
                    message: 'You will need to sign in again to continue.',
                    confirmLabel: 'Sign out',
                  );
                  if (ok) {
                    await ref.read(authControllerProvider.notifier).logout();
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.user});

  final AppUser user;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _specialization;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final UserProfile? profile = widget.user.profile;
    _first = TextEditingController(
      text: widget.user.role == UserRole.facility
          ? (profile?.name ?? '')
          : (profile?.firstName ?? ''),
    );
    _last = TextEditingController(text: profile?.lastName ?? '');
    _phone = TextEditingController(text: profile?.phoneNumber ?? '');
    _address = TextEditingController(text: profile?.address ?? '');
    _specialization = TextEditingController(
      text: profile?.specialization ?? '',
    );
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _address.dispose();
    _specialization.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String? profileId = widget.user.profile?.id;
    if (profileId == null) {
      setState(() => _error = 'No profile record is linked to this account.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      switch (widget.user.role) {
        case UserRole.parent:
          await ref
              .read(authRepositoryProvider)
              .updateParentProfile(
                parentProfileId: profileId,
                firstName: _first.text.trim(),
                lastName: _last.text.trim(),
                phoneNumber: _phone.text.trim(),
                address: _address.text.trim(),
              );
        case UserRole.doctor:
          await ref
              .read(doctorRepositoryProvider)
              .update(
                id: profileId,
                firstName: _first.text.trim(),
                lastName: _last.text.trim(),
                specialization: _specialization.text.trim(),
                phoneNumber: _phone.text.trim(),
              );
        case UserRole.facility:
          await ref
              .read(facilityRepositoryProvider)
              .update(
                id: profileId,
                name: _first.text.trim(),
                phoneNumber: _phone.text.trim(),
                address: _address.text.trim(),
              );
        case UserRole.admin:
          setState(() => _error = 'Administrator profiles cannot be edited.');
          return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserRole role = widget.user.role;
    final bool isFacility = role == UserRole.facility;
    final bool isDoctor = role == UserRole.doctor;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Edit profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextFormField(
                controller: _first,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: isFacility ? 'Facility name' : 'First name',
                ),
                validator: (String? v) => Validators.required(
                  v,
                  isFacility ? 'Facility name' : 'First name',
                ),
              ),
              if (!isFacility) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _last,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (String? v) => Validators.required(v, 'Last name'),
                ),
              ],
              if (isDoctor) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _specialization,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Specialisation',
                  ),
                  validator: (String? v) =>
                      Validators.required(v, 'Specialisation'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number${isFacility ? '' : ' (optional)'}',
                ),
                validator: (String? v) =>
                    isFacility ? Validators.required(v, 'Phone number') : null,
              ),
              if (!isDoctor) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(
                    labelText: 'Address${isFacility ? '' : ' (optional)'}',
                  ),
                  validator: (String? v) =>
                      isFacility ? Validators.required(v, 'Address') : null,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save changes',
                isLoading: _busy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
