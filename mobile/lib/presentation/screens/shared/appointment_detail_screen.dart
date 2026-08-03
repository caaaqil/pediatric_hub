import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/enums.dart';
import '../../providers/providers.dart';

/// `GET /appointments/:id`, with role-appropriate actions:
///  • PARENT  → cancel (`PATCH /appointments/:id/status` restricted to CANCELLED)
///  • DOCTOR / FACILITY / ADMIN → any status transition
///  • all     → open the teleconsultation room
class AppointmentDetailScreen extends ConsumerStatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  bool _busy = false;

  Future<void> _updateStatus(AppointmentStatus status) async {
    final bool ok = await confirmAction(
      context,
      title: '${status.label} appointment',
      message: 'Set this appointment to ${status.label.toLowerCase()}?',
      confirmLabel: status.label,
      destructive: status == AppointmentStatus.cancelled,
    );
    if (!ok) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateStatus(id: widget.appointmentId, status: status);
      ref.invalidate(appointmentDetailProvider(widget.appointmentId));
      ref.invalidate(myScheduleProvider);
      ref.invalidate(dashboardTelemetryProvider);
      if (mounted) Toast.success(context, 'Appointment updated');
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRoom() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .openRoom(widget.appointmentId);
      ref.invalidate(appointmentDetailProvider(widget.appointmentId));
      ref.invalidate(myScheduleProvider);
      if (mounted) {
        Toast.success(context, 'Teleconsultation room is open');
        context.push(Routes.teleconsult);
      }
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Appointment> appointment = ref.watch(
      appointmentDetailProvider(widget.appointmentId),
    );
    final UserRole? role = ref.watch(currentRoleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: appointment.when(
        loading: () => const LoadingView(),
        error: (Object error, StackTrace _) => ErrorView(
          message: error is ApiException
              ? error.detailedMessage
              : error.toString(),
          onRetry: () =>
              ref.invalidate(appointmentDetailProvider(widget.appointmentId)),
        ),
        data: (Appointment data) {
          final bool canManage =
              role == UserRole.doctor ||
              role == UserRole.facility ||
              role == UserRole.admin;
          final bool canCancel = role == UserRole.parent && data.status.isOpen;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(appointmentDetailProvider(widget.appointmentId));
              await ref.read(
                appointmentDetailProvider(widget.appointmentId).future,
              );
            },
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
                          Expanded(
                            child: Text(
                              Fmt.weekday(data.scheduledAt),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          StatusBadge(
                            label: data.status.label,
                            color: data.status.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Fmt.time(data.scheduledAt)} · ${Fmt.relative(data.scheduledAt)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Divider(height: AppSpacing.xxl),
                      DetailRow(
                        label: 'Patient',
                        value: data.childName,
                        icon: Icons.child_care_rounded,
                      ),
                      DetailRow(
                        label: 'Doctor',
                        value: data.doctorName,
                        icon: Icons.medical_services_outlined,
                      ),
                      if (data.doctor?.specialization != null)
                        DetailRow(
                          label: 'Specialisation',
                          value: data.doctor?.specialization ?? '',
                          icon: Icons.workspace_premium_outlined,
                        ),
                      DetailRow(
                        label: 'Reason',
                        value: data.reason ?? 'Not provided',
                        icon: Icons.notes_rounded,
                      ),
                      if (data.notes != null)
                        DetailRow(
                          label: 'Notes',
                          value: data.notes ?? '',
                          icon: Icons.sticky_note_2_outlined,
                        ),
                      DetailRow(
                        label: 'Booked',
                        value: Fmt.dateTime(data.createdAt),
                        icon: Icons.event_note_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                _TeleconsultCard(
                  appointment: data,
                  busy: _busy,
                  onOpenRoom: data.status.isOpen ? _openRoom : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                if (canCancel) ...<Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _updateStatus(AppointmentStatus.cancelled),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Cancel appointment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                ],

                if (canManage) ...<Widget>[
                  const SectionHeader(title: 'Update status'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: AppointmentStatus.values
                        .where((AppointmentStatus s) => s != data.status)
                        .map(
                          (AppointmentStatus status) => ActionChip(
                            avatar: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: status.color,
                            ),
                            label: Text(status.label),
                            onPressed: _busy
                                ? null
                                : () => _updateStatus(status),
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
  }
}

class _TeleconsultCard extends StatelessWidget {
  const _TeleconsultCard({
    required this.appointment,
    required this.busy,
    this.onOpenRoom,
  });

  final Appointment appointment;
  final bool busy;
  final VoidCallback? onOpenRoom;

  @override
  Widget build(BuildContext context) {
    final Teleconsultation? room = appointment.teleconsultation;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppCardHeader(
            title: 'Teleconsultation',
            subtitle: 'Room status from the backend',
            icon: Icons.videocam_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          if (room == null)
            Text(
              'No room has been opened for this appointment yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...<Widget>[
            DetailRow(
              label: 'Room',
              value: room.roomUrl ?? '—',
              icon: Icons.meeting_room_outlined,
            ),
            DetailRow(
              label: 'Started',
              value: Fmt.dateTime(room.startedAt),
              icon: Icons.play_circle_outline_rounded,
            ),
            DetailRow(
              label: 'Ended',
              value: room.endedAt == null
                  ? 'Still open'
                  : Fmt.dateTime(room.endedAt),
              icon: Icons.stop_circle_outlined,
              valueColor: room.isLive ? AppColors.success : null,
            ),
          ],
          if (onOpenRoom != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onOpenRoom,
                icon: const Icon(Icons.video_call_outlined, size: 18),
                label: Text(room == null ? 'Open room' : 'Refresh room'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Opening a room also confirms a pending appointment. Video '
              'calling itself runs in the web app.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
