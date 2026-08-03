import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/vaccination.dart';
import '../../providers/providers.dart';

/// `GET /vaccinations/child/:childId` with the four real statuses
/// (UPCOMING / DUE / COMPLETED / MISSED).
///
/// Parents can generate the schedule from the national protocol and check a
/// dose off as COMPLETED; the backend restricts them to exactly that.
class VaccineTrackerScreen extends ConsumerStatefulWidget {
  const VaccineTrackerScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<VaccineTrackerScreen> createState() =>
      _VaccineTrackerScreenState();
}

class _VaccineTrackerScreenState extends ConsumerState<VaccineTrackerScreen> {
  VaccineStatus? _filter;
  bool _generating = false;

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      await ref
          .read(vaccinationRepositoryProvider)
          .generateSchedule(widget.childId);
      ref.invalidate(childVaccinationsProvider(widget.childId));
      ref.invalidate(allChildVaccinationsProvider);
      if (mounted) Toast.success(context, 'Schedule synced');
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _markCompleted(Vaccination dose) async {
    final bool ok = await confirmAction(
      context,
      title: 'Mark as completed',
      message:
          '${dose.label} will be recorded as administered today. Continue?',
      confirmLabel: 'Mark completed',
      destructive: false,
    );
    if (!ok) return;

    try {
      await ref
          .read(vaccinationRepositoryProvider)
          .updateStatus(
            vaccinationId: dose.id,
            status: VaccineStatus.completed,
          );
      ref.invalidate(childVaccinationsProvider(widget.childId));
      ref.invalidate(allChildVaccinationsProvider);
      if (mounted) Toast.success(context, 'Dose recorded');
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Vaccination>> vaccines = ref.watch(
      childVaccinationsProvider(widget.childId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine tracker'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sync schedule from protocol',
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: AsyncView<List<Vaccination>>(
        value: vaccines,
        onRefresh: () =>
            ref.refresh(childVaccinationsProvider(widget.childId).future),
        isEmpty: (List<Vaccination> items) => items.isEmpty,
        emptyIcon: Icons.vaccines_outlined,
        emptyTitle: 'No doses scheduled',
        emptyMessage:
            'Generate the schedule from the national vaccine protocol to get '
            'started.',
        emptyActionLabel: 'Generate schedule',
        onEmptyAction: _generate,
        builder: (List<Vaccination> items) {
          final List<Vaccination> filtered = _filter == null
              ? items
              : items.where((Vaccination v) => v.status == _filter).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pageBottom,
            children: <Widget>[
              _StatusFilters(
                items: items,
                selected: _filter,
                onSelect: (VaccineStatus? status) =>
                    setState(() => _filter = status),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                AppCard(
                  child: Text(
                    'No doses with this status.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...filtered.map(
                  (Vaccination dose) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _DoseCard(
                      dose: dose,
                      onMarkCompleted: dose.status == VaccineStatus.completed
                          ? null
                          : () => _markCompleted(dose),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<Vaccination> items;
  final VaccineStatus? selected;
  final ValueChanged<VaccineStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          FilterChip(
            label: Text('All ${items.length}'),
            selected: selected == null,
            onSelected: (_) => onSelect(null),
          ),
          ...VaccineStatus.values.map((VaccineStatus status) {
            final int count = items
                .where((Vaccination v) => v.status == status)
                .length;
            return Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: FilterChip(
                avatar: Icon(status.icon, size: 15, color: status.color),
                label: Text('${status.label} $count'),
                selected: selected == status,
                onSelected: (_) => onSelect(selected == status ? null : status),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({required this.dose, this.onMarkCompleted});

  final Vaccination dose;
  final VoidCallback? onMarkCompleted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dose.status.color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(dose.status.icon, color: dose.status.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      dose.vaccineName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Dose ${dose.doseNumber}',
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
          const SizedBox(height: AppSpacing.md),
          DetailRow(
            label: 'Scheduled',
            value:
                '${Fmt.date(dose.scheduledDate)} · ${Fmt.relative(dose.scheduledDate)}',
            icon: Icons.event_rounded,
          ),
          if (dose.administeredDate != null)
            DetailRow(
              label: 'Administered',
              value: Fmt.date(dose.administeredDate),
              icon: Icons.check_circle_outline_rounded,
              valueColor: AppColors.success,
            ),
          if (dose.batchNumber != null)
            DetailRow(
              label: 'Batch',
              value: dose.batchNumber ?? '—',
              icon: Icons.qr_code_rounded,
            ),
          if (dose.notes != null)
            DetailRow(
              label: 'Notes',
              value: dose.notes ?? '—',
              icon: Icons.sticky_note_2_outlined,
            ),
          if (onMarkCompleted != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onMarkCompleted,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Mark as completed'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.buttonMd),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
