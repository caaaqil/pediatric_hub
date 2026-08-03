import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/child.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/health_record.dart';
import '../../../data/models/vaccination.dart';
import '../../providers/providers.dart';

/// One child's profile: identity, vaccine summary, guardians and shortcuts into
/// the vaccine tracker, health records and growth log.
class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Child> child = ref.watch(childDetailProvider(childId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child profile'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit',
            onPressed: () => context.push(Routes.childEdit(childId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: child.when(
        loading: () => const LoadingView(),
        error: (Object error, StackTrace _) => ErrorView(
          message: error is ApiException
              ? error.detailedMessage
              : error.toString(),
          onRetry: () => ref.invalidate(childDetailProvider(childId)),
        ),
        data: (Child data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(childDetailProvider(childId));
            ref.invalidate(childVaccinationsProvider(childId));
            ref.invalidate(guardiansProvider(childId));
            await ref.read(childDetailProvider(childId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pageBottom,
            children: <Widget>[
              _Identity(child: data),
              const SizedBox(height: AppSpacing.lg),
              _VaccineSummary(childId: childId),
              const SizedBox(height: AppSpacing.lg),
              _Shortcuts(childId: childId),
              const SizedBox(height: AppSpacing.lg),
              _Guardians(childId: childId),
            ],
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              InitialsAvatar(
                initials: child.firstName.isEmpty
                    ? '?'
                    : child.firstName.substring(0, 1).toUpperCase(),
                size: 52,
                color: AppColors.teal,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      child.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      child.ageLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xxl),
          DetailRow(
            label: 'Date of birth',
            value: Fmt.date(child.dateOfBirth),
            icon: Icons.cake_outlined,
          ),
          DetailRow(
            label: 'Gender',
            value: child.gender.isEmpty ? '—' : child.gender,
            icon: Icons.wc_rounded,
          ),
          DetailRow(
            label: 'Blood type',
            value: child.bloodType ?? 'Not recorded',
            icon: Icons.bloodtype_outlined,
          ),
          DetailRow(
            label: 'Registered',
            value: Fmt.date(child.createdAt),
            icon: Icons.event_note_outlined,
          ),
        ],
      ),
    );
  }
}

class _VaccineSummary extends ConsumerWidget {
  const _VaccineSummary({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Vaccination>> vaccines = ref.watch(
      childVaccinationsProvider(childId),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppCardHeader(
            title: 'Vaccination status',
            icon: Icons.vaccines_rounded,
            trailing: TextButton(
              onPressed: () => context.push(Routes.childVaccines(childId)),
              child: const Text('Open'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          vaccines.when(
            loading: () => const SizedBox(height: 56, child: LoadingView()),
            error: (Object error, StackTrace _) => Text(
              'Could not load the vaccine schedule.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            data: (List<Vaccination> items) {
              if (items.isEmpty) {
                return Text(
                  'No schedule generated yet — open the tracker to build it '
                  'from the national protocol.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: VaccineStatus.values.map((VaccineStatus status) {
                  final int count = items
                      .where((Vaccination v) => v.status == status)
                      .length;
                  return StatusBadge(
                    label: '${status.label}  $count',
                    color: status.color,
                    icon: status.icon,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppCard(
          onTap: () => context.push(Routes.childRecords(childId)),
          child: const _ShortcutRow(
            icon: Icons.folder_shared_outlined,
            title: 'Health records',
            subtitle: 'Allergies, medications, illnesses and consultations',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: () => context.push(Routes.childGrowth(childId)),
          child: const _ShortcutRow(
            icon: Icons.monitor_weight_outlined,
            title: 'Growth log',
            subtitle: 'Weight, height and head circumference over time',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: () => context.push(Routes.childVaccines(childId)),
          child: const _ShortcutRow(
            icon: Icons.vaccines_outlined,
            title: 'Vaccine tracker',
            subtitle: 'Every scheduled dose and its status',
          ),
        ),
      ],
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary600.withValues(alpha: 0.1),
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary600),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }
}

class _Guardians extends ConsumerWidget {
  const _Guardians({required this.childId});

  final String childId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _GuardianSheet(childId: childId),
    );
    if (saved == true) ref.invalidate(guardiansProvider(childId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ParentInfo>> guardians = ref.watch(
      guardiansProvider(childId),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppCardHeader(
            title: 'Guardians & emergency contacts',
            icon: Icons.contacts_outlined,
            trailing: IconButton(
              tooltip: 'Add guardian',
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          guardians.when(
            loading: () => const SizedBox(height: 56, child: LoadingView()),
            error: (Object error, StackTrace _) => Text(
              error is ApiException
                  ? error.detailedMessage
                  : 'Could not load guardians.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            data: (List<ParentInfo> items) {
              if (items.isEmpty) {
                return Text(
                  'No guardian recorded yet. Add someone who can be reached in '
                  'an emergency.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: items.map((ParentInfo info) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                info.fullName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${Relationship.fromJson(info.relationship).label} · ${info.phoneNumber}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppColors.danger,
                          ),
                          onPressed: () async {
                            final bool ok = await confirmAction(
                              context,
                              title: 'Remove guardian',
                              message:
                                  'Remove ${info.fullName} from this child?',
                              confirmLabel: 'Remove',
                            );
                            if (!ok || !context.mounted) return;
                            try {
                              await ref
                                  .read(healthRecordRepositoryProvider)
                                  .removeGuardian(info.id);
                              ref.invalidate(guardiansProvider(childId));
                              if (context.mounted) {
                                Toast.success(context, 'Guardian removed');
                              }
                            } on ApiException catch (error) {
                              if (context.mounted) Toast.error(context, error);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// `POST /parent-info`
class _GuardianSheet extends ConsumerStatefulWidget {
  const _GuardianSheet({required this.childId});

  final String childId;

  @override
  ConsumerState<_GuardianSheet> createState() => _GuardianSheetState();
}

class _GuardianSheetState extends ConsumerState<_GuardianSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _health = TextEditingController();

  Relationship _relationship = Relationship.mother;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _health.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(healthRecordRepositoryProvider)
          .addGuardian(
            childId: widget.childId,
            fullName: _name.text.trim(),
            phoneNumber: _phone.text.trim(),
            address: _address.text.trim(),
            relationship: _relationship.wire,
            healthStatus: _health.text.trim(),
          );
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
                'Add guardian',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: Validators.guardianName,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
                validator: Validators.guardianPhone,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: Validators.guardianAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<Relationship>(
                initialValue: _relationship,
                decoration: const InputDecoration(labelText: 'Relationship'),
                items: Relationship.values
                    .map(
                      (Relationship r) => DropdownMenuItem<Relationship>(
                        value: r,
                        child: Text(r.label),
                      ),
                    )
                    .toList(),
                onChanged: (Relationship? value) {
                  if (value != null) setState(() => _relationship = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _health,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Health notes (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save guardian',
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
