import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/health_record.dart';
import '../../../data/repositories/health_record_repository.dart';
import '../../providers/providers.dart';

/// `GET /health-records/child/:childId/baseline` + `.../consultations`.
///
/// Parents can add allergies, medications and past illnesses; consultation
/// notes are doctor-authored and read-only here.
class HealthRecordsScreen extends ConsumerStatefulWidget {
  const HealthRecordsScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<HealthRecordsScreen> createState() =>
      _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends ConsumerState<HealthRecordsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(baselineProvider(widget.childId));
    ref.invalidate(consultationsProvider(widget.childId));
    await ref.read(baselineProvider(widget.childId).future);
  }

  Future<void> _addRecord(_RecordKind kind) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) =>
          _RecordSheet(childId: widget.childId, kind: kind),
    );
    if (saved == true) {
      ref.invalidate(baselineProvider(widget.childId));
      if (mounted) Toast.success(context, 'Record added');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ChildBaseline> baseline = ref.watch(
      baselineProvider(widget.childId),
    );
    final AsyncValue<List<ConsultationNote>> consultations = ref.watch(
      consultationsProvider(widget.childId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health records'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const <Widget>[
            Tab(text: 'Allergies'),
            Tab(text: 'Medications'),
            Tab(text: 'Illnesses'),
            Tab(text: 'Consultations'),
          ],
        ),
      ),
      body: baseline.when(
        loading: () => const LoadingView(),
        error: (Object error, StackTrace _) => ErrorView(
          message: error is ApiException
              ? error.detailedMessage
              : error.toString(),
          onRetry: _refresh,
        ),
        data: (ChildBaseline data) => TabBarView(
          controller: _tabs,
          children: <Widget>[
            _AllergyTab(items: data.allergies, onRefresh: _refresh),
            _MedicationTab(items: data.medications, onRefresh: _refresh),
            _IllnessTab(items: data.illnesses, onRefresh: _refresh),
            _ConsultationTab(value: consultations, onRefresh: _refresh),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (BuildContext context, Widget? _) {
          if (_tabs.index == 3) {
            // Consultation notes are written by doctors only
            // (`POST /health-records/consultations` is DOCTOR-gated).
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _addRecord(_RecordKind.values[_tabs.index]),
            icon: const Icon(Icons.add_rounded),
            label: Text(_RecordKind.values[_tabs.index].actionLabel),
            backgroundColor: AppColors.primary600,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }
}

enum _RecordKind {
  allergy('Add allergy', 'Allergy'),
  medication('Add medication', 'Medication'),
  illness('Add illness', 'Past illness');

  const _RecordKind(this.actionLabel, this.title);

  final String actionLabel;
  final String title;
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({
    required this.title,
    required this.message,
    required this.icon,
    required this.onRefresh,
  });

  final String title;
  final String message;
  final IconData icon;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: EmptyView(title: title, message: message, icon: icon),
            ),
          );
        },
      ),
    );
  }
}

class _AllergyTab extends StatelessWidget {
  const _AllergyTab({required this.items, required this.onRefresh});

  final List<Allergy> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyList(
        title: 'No allergies recorded',
        message: 'Add any known allergies so clinicians can see them.',
        icon: Icons.warning_amber_rounded,
        onRefresh: onRefresh,
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
          final Allergy allergy = items[index];
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        allergy.allergen,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    StatusBadge(
                      label: allergy.severity,
                      color: AppColors.warning,
                      dense: true,
                    ),
                  ],
                ),
                if (allergy.notes != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    allergy.notes ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MedicationTab extends StatelessWidget {
  const _MedicationTab({required this.items, required this.onRefresh});

  final List<Medication> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyList(
        title: 'No medications logged',
        message: 'Track current and past medication courses here.',
        icon: Icons.medication_outlined,
        onRefresh: onRefresh,
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
          final Medication med = items[index];
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        med.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    StatusBadge(
                      label: med.active ? 'Active' : 'Ended',
                      color: med.active
                          ? AppColors.success
                          : AppColors.lightTextMuted,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                DetailRow(label: 'Dosage', value: med.dosage),
                DetailRow(label: 'Started', value: Fmt.date(med.startDate)),
                if (med.endDate != null)
                  DetailRow(label: 'Ends', value: Fmt.date(med.endDate)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IllnessTab extends StatelessWidget {
  const _IllnessTab({required this.items, required this.onRefresh});

  final List<IllnessHistory> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyList(
        title: 'No illness history',
        message: 'Record past illnesses to build a fuller medical picture.',
        icon: Icons.sick_outlined,
        onRefresh: onRefresh,
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
          final IllnessHistory illness = items[index];
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  illness.illnessName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                DetailRow(
                  label: 'Diagnosed',
                  value: Fmt.date(illness.diagnosisDate),
                ),
                if (illness.recoveryDate != null)
                  DetailRow(
                    label: 'Recovered',
                    value: Fmt.date(illness.recoveryDate),
                  ),
                if (illness.notes != null)
                  DetailRow(label: 'Notes', value: illness.notes ?? ''),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConsultationTab extends StatelessWidget {
  const _ConsultationTab({required this.value, required this.onRefresh});

  final AsyncValue<List<ConsultationNote>> value;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const LoadingView(),
      error: (Object error, StackTrace _) => ErrorView(
        message: error is ApiException
            ? error.detailedMessage
            : error.toString(),
        onRetry: onRefresh,
      ),
      data: (List<ConsultationNote> items) {
        if (items.isEmpty) {
          return _EmptyList(
            title: 'No consultation notes',
            message: 'Notes written by doctors after a visit appear here.',
            icon: Icons.description_outlined,
            onRefresh: onRefresh,
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
                    if (note.doctorSpecialization != null)
                      Text(
                        note.doctorSpecialization ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}

/// Bottom sheet that posts to the three parent-writable record endpoints.
class _RecordSheet extends ConsumerStatefulWidget {
  const _RecordSheet({required this.childId, required this.kind});

  final String childId;
  final _RecordKind kind;

  @override
  ConsumerState<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<_RecordSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _primary = TextEditingController();
  final TextEditingController _secondary = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  static const List<String> _severities = <String>[
    'Mild',
    'Moderate',
    'Severe',
  ];
  String _severity = 'Mild';
  DateTime _date = DateTime.now();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final HealthRecordRepository repo = ref.read(
        healthRecordRepositoryProvider,
      );
      switch (widget.kind) {
        case _RecordKind.allergy:
          await repo.addAllergy(
            childId: widget.childId,
            allergen: _primary.text.trim(),
            severity: _severity,
            notes: _notes.text.trim(),
          );
        case _RecordKind.medication:
          await repo.addMedication(
            childId: widget.childId,
            name: _primary.text.trim(),
            dosage: _secondary.text.trim(),
            startDate: _date,
          );
        case _RecordKind.illness:
          await repo.addIllness(
            childId: widget.childId,
            illnessName: _primary.text.trim(),
            diagnosisDate: _date,
            notes: _notes.text.trim(),
          );
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
    final bool isAllergy = widget.kind == _RecordKind.allergy;
    final bool isMedication = widget.kind == _RecordKind.medication;
    final bool isIllness = widget.kind == _RecordKind.illness;

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
                widget.kind.actionLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextFormField(
                controller: _primary,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: isAllergy
                      ? 'Allergen'
                      : isMedication
                      ? 'Medication name'
                      : 'Illness name',
                ),
                validator: (String? v) => Validators.required(
                  v,
                  isAllergy
                      ? 'Allergen'
                      : isMedication
                      ? 'Medication name'
                      : 'Illness name',
                ),
              ),
              if (isAllergy) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _severity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: _severities
                      .map(
                        (String s) =>
                            DropdownMenuItem<String>(value: s, child: Text(s)),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _severity = value);
                  },
                ),
              ],
              if (isMedication) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _secondary,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g. 5ml twice daily',
                  ),
                  validator: (String? v) => Validators.required(v, 'Dosage'),
                ),
              ],
              if (isMedication || isIllness) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: AppRadius.smAll,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: isMedication ? 'Start date' : 'Diagnosis date',
                    ),
                    child: Text(Fmt.date(_date)),
                  ),
                ),
              ],
              if (isAllergy || isIllness) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save record',
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
