import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/enums.dart';
import '../../providers/providers.dart';

/// `GET /appointments/my-schedule` — one screen for all four roles, since the
/// backend scopes the result from the JWT.
///
/// Actions differ by role: parents may cancel; doctors, facilities and admins
/// may move an appointment through its full status set.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  bool _upcomingOnly = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Appointment>> schedule = ref.watch(
      myScheduleProvider,
    );
    final UserRole? role = ref.watch(currentRoleProvider);
    final bool isParent = role == UserRole.parent;

    final Widget body = AsyncView<List<Appointment>>(
      value: schedule,
      onRefresh: () => ref.refresh(myScheduleProvider.future),
      isEmpty: (List<Appointment> items) => items.isEmpty,
      emptyIcon: Icons.event_busy_rounded,
      emptyTitle: 'No appointments',
      emptyMessage: isParent
          ? 'Book a consultation with a doctor to get started.'
          : 'Nothing has been scheduled yet.',
      emptyActionLabel: isParent ? 'Book appointment' : null,
      onEmptyAction: isParent
          ? () => context.push(Routes.bookAppointment)
          : null,
      builder: (List<Appointment> items) {
        final List<Appointment> visible = _upcomingOnly
            ? items.where((Appointment a) => a.isUpcoming).toList()
            : items;

        final List<Appointment> today = visible
            .where((Appointment a) => a.isToday)
            .toList();

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pageBottom,
          children: <Widget>[
            Row(
              children: <Widget>[
                FilterChip(
                  label: Text('All ${items.length}'),
                  selected: !_upcomingOnly,
                  onSelected: (_) => setState(() => _upcomingOnly = false),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilterChip(
                  label: Text(
                    'Upcoming ${items.where((Appointment a) => a.isUpcoming).length}',
                  ),
                  selected: _upcomingOnly,
                  onSelected: (_) => setState(() => _upcomingOnly = true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (today.isNotEmpty) ...<Widget>[
              const SectionHeader(title: 'Today'),
              ...today.map(
                (Appointment appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppointmentTile(appointment: appointment),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            SectionHeader(
              title: _upcomingOnly ? 'Upcoming' : 'All appointments',
            ),
            if (visible.isEmpty)
              AppCard(
                child: Text(
                  'Nothing to show with this filter.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ...visible.map(
                (Appointment appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppointmentTile(appointment: appointment),
                ),
              ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Appointments'))
          : null,
      body: body,
      floatingActionButton: isParent
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.bookAppointment),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book'),
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

/// Compact appointment row shared by the list and the dashboards.
class AppointmentTile extends ConsumerWidget {
  const AppointmentTile({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserRole? role = ref.watch(currentRoleProvider);
    final bool canDecide =
        role == UserRole.doctor ||
        role == UserRole.facility ||
        role == UserRole.admin;
    final bool isPending = appointment.status == AppointmentStatus.pending;

    return AppCard(
      onTap: () => context.push(Routes.appointmentDetail(appointment.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: appointment.status.color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smAll,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      Fmt.time(appointment.scheduledAt),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: appointment.status.color,
                      ),
                    ),
                    Text(
                      Fmt.dateShort(appointment.scheduledAt),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: appointment.status.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      role == UserRole.parent
                          ? appointment.doctorName
                          : appointment.childName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role == UserRole.parent
                          ? 'For ${appointment.childName}'
                          : 'With ${appointment.doctorName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: appointment.status.label,
                color: appointment.status.color,
                dense: true,
              ),
            ],
          ),
          if (appointment.reason != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              appointment.reason ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (canDecide && isPending) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _setStatus(context, ref, AppointmentStatus.confirmed),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppSizes.buttonMd),
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _setStatus(context, ref, AppointmentStatus.cancelled),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppSizes.buttonMd),
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    AppointmentStatus status,
  ) async {
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateStatus(id: appointment.id, status: status);
      ref.invalidate(myScheduleProvider);
      ref.invalidate(appointmentDetailProvider(appointment.id));
      ref.invalidate(dashboardTelemetryProvider);
      if (context.mounted) {
        Toast.success(context, 'Appointment ${status.label.toLowerCase()}');
      }
    } on ApiException catch (error) {
      if (context.mounted) Toast.error(context, error);
    }
  }
}
