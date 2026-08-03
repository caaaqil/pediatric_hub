import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/doctor.dart';
import '../../providers/providers.dart';

/// Staff management for FACILITY (and ADMIN) — `GET/POST/PUT/DELETE /doctors`.
///
/// The backend forces a facility's own `facilityId` on create and update, and
/// refuses edits to doctors belonging to another facility.
class FacilityStaffScreen extends ConsumerWidget {
  const FacilityStaffScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Doctor? doctor,
  }) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _DoctorSheet(doctor: doctor),
    );
    if (saved == true) {
      ref.invalidate(doctorRegistryProvider);
      ref.invalidate(facilityScopeProvider);
      if (context.mounted) {
        Toast.success(
          context,
          doctor == null ? 'Doctor added' : 'Doctor updated',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Doctor>> doctors = ref.watch(doctorRegistryProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Clinical staff')) : null,
      body: AsyncView<List<Doctor>>(
        value: doctors,
        onRefresh: () => ref.refresh(doctorRegistryProvider.future),
        isEmpty: (List<Doctor> items) => items.isEmpty,
        emptyIcon: Icons.medical_services_outlined,
        emptyTitle: 'No doctors registered',
        emptyMessage: 'Add clinicians so parents can book with your facility.',
        emptyActionLabel: 'Add doctor',
        onEmptyAction: () => _openForm(context, ref),
        builder: (List<Doctor> items) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pageBottom,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (BuildContext context, int index) {
            final Doctor doctor = items[index];
            return AppCard(
              onTap: () => context.push(Routes.doctorDetail(doctor.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      InitialsAvatar(initials: doctor.initials),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              doctor.displayName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              doctor.specialization,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (doctor.email != null)
                              Text(
                                doctor.email ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: doctor.verificationStatus,
                        color: doctor.isVerified
                            ? AppColors.success
                            : AppColors.warning,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openForm(context, ref, doctor: doctor),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppSizes.buttonMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final bool ok = await confirmAction(
                              context,
                              title: 'Archive doctor',
                              message:
                                  'Archiving ${doctor.displayName} also cancels their pending and confirmed appointments.',
                              confirmLabel: 'Archive',
                            );
                            if (!ok || !context.mounted) return;
                            try {
                              await ref
                                  .read(doctorRepositoryProvider)
                                  .archive(doctor.id);
                              ref.invalidate(doctorRegistryProvider);
                              ref.invalidate(facilityScopeProvider);
                              if (context.mounted) {
                                Toast.success(context, 'Doctor archived');
                              }
                            } on ApiException catch (error) {
                              if (context.mounted) Toast.error(context, error);
                            }
                          },
                          icon: const Icon(Icons.archive_outlined, size: 16),
                          label: const Text('Archive'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppSizes.buttonMd,
                            ),
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add doctor'),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// `POST /doctors` / `PUT /doctors/:id`.
class _DoctorSheet extends ConsumerStatefulWidget {
  const _DoctorSheet({this.doctor});

  final Doctor? doctor;

  @override
  ConsumerState<_DoctorSheet> createState() => _DoctorSheetState();
}

class _DoctorSheetState extends ConsumerState<_DoctorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _first = TextEditingController(
    text: widget.doctor?.firstName ?? '',
  );
  late final TextEditingController _last = TextEditingController(
    text: widget.doctor?.lastName ?? '',
  );
  late final TextEditingController _specialization = TextEditingController(
    text: widget.doctor?.specialization ?? '',
  );
  late final TextEditingController _license = TextEditingController(
    text: widget.doctor?.licenseNumber ?? '',
  );
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  static const List<String> _statuses = <String>['PENDING', 'ACTIVE'];
  late String _status =
      _statuses.contains(widget.doctor?.verificationStatus.toUpperCase())
      ? (widget.doctor?.verificationStatus.toUpperCase() ?? 'PENDING')
      : 'PENDING';

  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.doctor != null;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _specialization.dispose();
    _license.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final Doctor? existing = widget.doctor;
      if (existing == null) {
        await ref
            .read(doctorRepositoryProvider)
            .create(
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              specialization: _specialization.text.trim(),
              licenseNumber: _license.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
            );
      } else {
        await ref
            .read(doctorRepositoryProvider)
            .update(
              id: existing.id,
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              specialization: _specialization.text.trim(),
              licenseNumber: _license.text.trim(),
              verificationStatus: _status,
            );
        ref.invalidate(doctorDetailProvider(existing.id));
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
                _isEdit ? 'Edit doctor' : 'Add doctor',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                      ),
                      validator: (String? v) =>
                          Validators.required(v, 'First name'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _last,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Last name'),
                      validator: (String? v) =>
                          Validators.required(v, 'Last name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _specialization,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Specialisation'),
                validator: (String? v) =>
                    Validators.required(v, 'Specialisation'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _license,
                decoration: const InputDecoration(
                  labelText: 'Licence number',
                  helperText: 'Must be unique across the platform',
                ),
              ),
              if (!_isEdit) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Login email (optional)',
                    helperText: 'Creates a login that starts deactivated',
                  ),
                  validator: (String? value) {
                    if ((value ?? '').trim().isEmpty) return null;
                    return Validators.email(value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password',
                  ),
                  validator: (String? value) {
                    if (_email.text.trim().isEmpty) return null;
                    return Validators.strongPassword(value);
                  },
                ),
              ],
              if (_isEdit) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Verification status',
                    helperText: 'ACTIVE also enables the doctor\'s login',
                  ),
                  items: _statuses
                      .map(
                        (String s) =>
                            DropdownMenuItem<String>(value: s, child: Text(s)),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _isEdit ? 'Save changes' : 'Add doctor',
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
