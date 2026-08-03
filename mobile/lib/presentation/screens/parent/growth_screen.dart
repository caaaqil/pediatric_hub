import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/growth.dart';
import '../../providers/providers.dart';

/// `GET /growth/child/:childId` and `POST /growth`.
class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key, required this.childId});

  final String childId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _GrowthSheet(childId: childId),
    );
    if (saved == true) {
      ref.invalidate(growthProvider(childId));
      if (context.mounted) Toast.success(context, 'Measurement recorded');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GrowthData> growth = ref.watch(growthProvider(childId));

    return Scaffold(
      appBar: AppBar(title: const Text('Growth log')),
      body: AsyncView<GrowthData>(
        value: growth,
        onRefresh: () => ref.refresh(growthProvider(childId).future),
        isEmpty: (GrowthData data) => data.isEmpty,
        emptyIcon: Icons.monitor_weight_outlined,
        emptyTitle: 'No measurements yet',
        emptyMessage:
            'Log weight, height or head circumference to start tracking growth.',
        emptyActionLabel: 'Add measurement',
        onEmptyAction: () => _add(context, ref),
        builder: (GrowthData data) {
          final List<GrowthRecord> records = data.records.reversed.toList(
            growable: false,
          );
          final GrowthRecord? latest = data.latest;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pageBottom,
            children: <Widget>[
              if (latest != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const AppCardHeader(
                        title: 'Latest measurement',
                        icon: Icons.insights_rounded,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _Metric(
                              label: 'Weight',
                              value: Fmt.metric(latest.weightKg, 'kg'),
                              color: AppColors.primary600,
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'Height',
                              value: Fmt.metric(latest.heightCm, 'cm'),
                              color: AppColors.teal,
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'Head',
                              value: Fmt.metric(latest.headCircumCm, 'cm'),
                              color: AppColors.violet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Recorded ${Fmt.date(latest.measurementDate)} by ${latest.recorderRole.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (data.chartData.isNotEmpty) ...<Widget>[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const AppCardHeader(
                        title: 'Weight trend',
                        subtitle: 'Kilograms by measurement',
                        icon: Icons.show_chart_rounded,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      MiniBarChart(
                        labels: data.chartData
                            .map((GrowthPoint p) => Fmt.dateShort(p.date))
                            .toList(),
                        values: data.chartData
                            .map((GrowthPoint p) => (p.weight ?? 0).round())
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SectionHeader(title: 'History'),
              ...records.map(
                (GrowthRecord record) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                Fmt.date(record.measurementDate),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            StatusBadge(
                              label: record.recorderRole,
                              color: record.recorderRole == 'DOCTOR'
                                  ? AppColors.primary600
                                  : AppColors.teal,
                              dense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DetailRow(
                          label: 'Weight',
                          value: Fmt.metric(record.weightKg, 'kg'),
                        ),
                        DetailRow(
                          label: 'Height',
                          value: Fmt.metric(record.heightCm, 'cm'),
                        ),
                        DetailRow(
                          label: 'Head circ.',
                          value: Fmt.metric(record.headCircumCm, 'cm'),
                        ),
                        if (record.milestoneNotes != null)
                          DetailRow(
                            label: 'Milestones',
                            value: record.milestoneNotes ?? '',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add measurement'),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// `POST /growth` — the backend requires at least one metric or a milestone.
class _GrowthSheet extends ConsumerStatefulWidget {
  const _GrowthSheet({required this.childId});

  final String childId;

  @override
  ConsumerState<_GrowthSheet> createState() => _GrowthSheetState();
}

class _GrowthSheetState extends ConsumerState<_GrowthSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _head = TextEditingController();
  final TextEditingController _milestones = TextEditingController();

  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _head.dispose();
    _milestones.dispose();
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

    final double? weight = double.tryParse(_weight.text.trim());
    final double? height = double.tryParse(_height.text.trim());
    final double? head = double.tryParse(_head.text.trim());
    final String milestones = _milestones.text.trim();

    if (weight == null &&
        height == null &&
        head == null &&
        milestones.isEmpty) {
      setState(
        () => _error = 'Enter at least one measurement or a milestone note.',
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(healthRecordRepositoryProvider)
          .addGrowth(
            childId: widget.childId,
            measurementDate: _date,
            weightKg: weight,
            heightCm: height,
            headCircumCm: head,
            milestoneNotes: milestones,
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
                'Add measurement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],
              InkWell(
                onTap: _pickDate,
                borderRadius: AppRadius.smAll,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Measurement date',
                  ),
                  child: Text(Fmt.date(_date)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  suffixText: 'kg',
                ),
                validator: (String? v) =>
                    Validators.optionalPositive(v, 'weight'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _height,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  suffixText: 'cm',
                ),
                validator: (String? v) =>
                    Validators.optionalPositive(v, 'height'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _head,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Head circumference (cm)',
                  suffixText: 'cm',
                ),
                validator: (String? v) =>
                    Validators.optionalPositive(v, 'head circumference'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _milestones,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Milestone notes (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save measurement',
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
