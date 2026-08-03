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
import '../../../data/models/growth.dart';
import '../../../data/models/health_record.dart';
import '../../../data/models/vaccination.dart';
import '../../providers/providers.dart';

/// Clinical view of one child for DOCTOR / FACILITY / ADMIN.
///
/// Doctors can write consultation notes and medications, and check vaccine
/// doses off — the three write endpoints their role is granted.
class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(childDetailProvider(widget.childId));
    ref.invalidate(baselineProvider(widget.childId));
    ref.invalidate(consultationsProvider(widget.childId));
    ref.invalidate(childVaccinationsProvider(widget.childId));
    ref.invalidate(growthProvider(widget.childId));
    await ref.read(childDetailProvider(widget.childId).future);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Child> child = ref.watch(
      childDetailProvider(widget.childId),
    );
    final UserRole? role = ref.watch(currentRoleProvider);
    final bool isDoctor = role == UserRole.doctor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const <Widget>[
            Tab(text: 'Overview'),
            Tab(text: 'Notes'),
            Tab(text: 'Vaccines'),
          ],
        ),
      ),
      body: child.when(
        loading: () => const LoadingView(),
        error: (Object error, StackTrace _) => ErrorView(
          message: error is ApiException
              ? error.detailedMessage
              : error.toString(),
          onRetry: _refresh,
        ),
        data: (Child data) => TabBarView(
          controller: _tabs,
          children: <Widget>[
            _Overview(child: data, onRefresh: _refresh, canWrite: isDoctor),
            _Notes(
              childId: widget.childId,
              onRefresh: _refresh,
              canWrite: isDoctor,
            ),
            _Vaccines(
              childId: widget.childId,
              onRefresh: _refresh,
              canWrite:
                  role == UserRole.doctor ||
                  role == UserRole.facility ||
                  role == UserRole.admin,
            ),
          ],
        ),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({
    required this.child,
    required this.onRefresh,
    required this.canWrite,
  });

  final Child child;
  final Future<void> Function() onRefresh;
  final bool canWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ChildBaseline> baseline = ref.watch(
      baselineProvider(child.id),
    );
    final AsyncValue<GrowthData> growth = ref.watch(growthProvider(child.id));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pageBottom,
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    InitialsAvatar(
                      initials: child.firstName.isEmpty
                          ? '?'
                          : child.firstName.substring(0, 1).toUpperCase(),
                      size: 50,
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
                if (child.parentName != null)
                  DetailRow(
                    label: 'Parent',
                    value: child.parentName ?? '',
                    icon: Icons.family_restroom_rounded,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          baseline.when(
            loading: () => const SizedBox(height: 90, child: LoadingView()),
            error: (Object error, StackTrace _) => AppCard(
              child: Text(
                'Could not load baseline records.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            data: (ChildBaseline data) => Column(
              children: <Widget>[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const AppCardHeader(
                        title: 'Allergies',
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (data.allergies.isEmpty)
                        Text(
                          'None recorded.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...data.allergies.map(
                          (Allergy allergy) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    allergy.allergen,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                StatusBadge(
                                  label: allergy.severity,
                                  color: AppColors.warning,
                                  dense: true,
                                ),
                              ],
                            ),
                          ),
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
                        title: 'Medications',
                        icon: Icons.medication_outlined,
                        trailing: canWrite
                            ? IconButton(
                                tooltip: 'Prescribe',
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                onPressed: () async {
                                  final bool? saved =
                                      await showModalBottomSheet<bool>(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (BuildContext ctx) =>
                                            _MedicationSheet(childId: child.id),
                                      );
                                  if (saved == true) {
                                    ref.invalidate(baselineProvider(child.id));
                                    if (context.mounted) {
                                      Toast.success(
                                        context,
                                        'Medication logged',
                                      );
                                    }
                                  }
                                },
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (data.medications.isEmpty)
                        Text(
                          'None recorded.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...data.medications.map(
                          (Medication med) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    '${med.name} — ${med.dosage}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  Fmt.dateShort(med.startDate),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const AppCardHeader(
                        title: 'Illness history',
                        icon: Icons.sick_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (data.illnesses.isEmpty)
                        Text(
                          'None recorded.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...data.illnesses.map(
                          (IllnessHistory illness) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    illness.illnessName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  Fmt.dateShort(illness.diagnosisDate),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
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
                  title: 'Growth',
                  icon: Icons.monitor_weight_outlined,
                  trailing: TextButton(
                    onPressed: () => context.push(Routes.childGrowth(child.id)),
                    child: const Text('Open'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                growth.when(
                  loading: () =>
                      const SizedBox(height: 40, child: LoadingView()),
                  error: (Object error, StackTrace _) => Text(
                    'Could not load growth data.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  data: (GrowthData data) {
                    final GrowthRecord? latest = data.latest;
                    if (latest == null) {
                      return Text(
                        'No measurements recorded.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }
                    return Column(
                      children: <Widget>[
                        DetailRow(
                          label: 'Weight',
                          value: Fmt.metric(latest.weightKg, 'kg'),
                        ),
                        DetailRow(
                          label: 'Height',
                          value: Fmt.metric(latest.heightCm, 'cm'),
                        ),
                        DetailRow(
                          label: 'Measured',
                          value: Fmt.date(latest.measurementDate),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notes extends ConsumerWidget {
  const _Notes({
    required this.childId,
    required this.onRefresh,
    required this.canWrite,
  });

  final String childId;
  final Future<void> Function() onRefresh;
  final bool canWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ConsultationNote>> notes = ref.watch(
      consultationsProvider(childId),
    );

    return Scaffold(
      body: notes.when(
        loading: () => const LoadingView(),
        error: (Object error, StackTrace _) => ErrorView(
          message: error is ApiException
              ? error.detailedMessage
              : error.toString(),
          onRetry: onRefresh,
        ),
        data: (List<ConsultationNote> items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: const EmptyView(
                          title: 'No consultation notes',
                          message:
                              'Signed notes for this patient will be listed here.',
                          icon: Icons.description_outlined,
                        ),
                      ),
                    ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.pageBottom,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                final ConsultationNote note = items[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              note.doctorName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            Fmt.date(note.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.xl),
                      Text(
                        note.notes,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (note.treatmentPlan != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Treatment plan',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note.treatmentPlan ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () async {
                final bool? saved = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext ctx) =>
                      _ConsultationSheet(childId: childId),
                );
                if (saved == true) {
                  ref.invalidate(consultationsProvider(childId));
                  if (context.mounted) Toast.success(context, 'Note signed');
                }
              },
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('New note'),
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class _Vaccines extends ConsumerWidget {
  const _Vaccines({
    required this.childId,
    required this.onRefresh,
    required this.canWrite,
  });

  final String childId;
  final Future<void> Function() onRefresh;
  final bool canWrite;

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    Vaccination dose,
    VaccineStatus status,
  ) async {
    try {
      await ref
          .read(vaccinationRepositoryProvider)
          .updateStatus(vaccinationId: dose.id, status: status);
      ref.invalidate(childVaccinationsProvider(childId));
      if (context.mounted) Toast.success(context, 'Vaccine updated');
    } on ApiException catch (error) {
      if (context.mounted) Toast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Vaccination>> vaccines = ref.watch(
      childVaccinationsProvider(childId),
    );

    return vaccines.when(
      loading: () => const LoadingView(),
      error: (Object error, StackTrace _) => ErrorView(
        message: error is ApiException
            ? error.detailedMessage
            : error.toString(),
        onRetry: onRefresh,
      ),
      data: (List<Vaccination> items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const EmptyView(
                        title: 'No vaccine schedule',
                        message:
                            'The parent has not generated a schedule for this child yet.',
                        icon: Icons.vaccines_outlined,
                      ),
                    ),
                  ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pageBottom,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              final Vaccination dose = items[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(dose.status.icon, color: dose.status.color),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                dose.label,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                'Scheduled ${Fmt.date(dose.scheduledDate)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: dose.status.label,
                          color: dose.status.color,
                          dense: true,
                        ),
                      ],
                    ),
                    if (canWrite) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: VaccineStatus.values
                            .where((VaccineStatus s) => s != dose.status)
                            .map(
                              (VaccineStatus status) => ActionChip(
                                label: Text(status.label),
                                avatar: Icon(
                                  status.icon,
                                  size: 14,
                                  color: status.color,
                                ),
                                onPressed: () =>
                                    _setStatus(context, ref, dose, status),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// `POST /health-records/consultations` (DOCTOR only).
class _ConsultationSheet extends ConsumerStatefulWidget {
  const _ConsultationSheet({required this.childId});

  final String childId;

  @override
  ConsumerState<_ConsultationSheet> createState() => _ConsultationSheetState();
}

class _ConsultationSheetState extends ConsumerState<_ConsultationSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _plan = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    _plan.dispose();
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
          .addConsultation(
            childId: widget.childId,
            notes: _notes.text.trim(),
            treatmentPlan: _plan.text.trim(),
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
                'Consultation note',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextFormField(
                controller: _notes,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Clinical notes',
                  alignLabelWithHint: true,
                ),
                validator: (String? v) => Validators.required(v, 'Notes'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _plan,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Treatment plan (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Sign and save',
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

/// `POST /health-records/medications` (PARENT | DOCTOR | ADMIN).
class _MedicationSheet extends ConsumerStatefulWidget {
  const _MedicationSheet({required this.childId});

  final String childId;

  @override
  ConsumerState<_MedicationSheet> createState() => _MedicationSheetState();
}

class _MedicationSheetState extends ConsumerState<_MedicationSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _dosage = TextEditingController();

  DateTime _startDate = DateTime.now();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
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
          .addMedication(
            childId: widget.childId,
            name: _name.text.trim(),
            dosage: _dosage.text.trim(),
            startDate: _startDate,
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
                'Log medication',
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
                decoration: const InputDecoration(labelText: 'Medication name'),
                validator: (String? v) =>
                    Validators.required(v, 'Medication name'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _dosage,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g. 5ml twice daily',
                ),
                validator: (String? v) => Validators.required(v, 'Dosage'),
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () async {
                  final DateTime now = DateTime.now();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 1),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                borderRadius: AppRadius.smAll,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Start date'),
                  child: Text(Fmt.date(_startDate)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save medication',
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
