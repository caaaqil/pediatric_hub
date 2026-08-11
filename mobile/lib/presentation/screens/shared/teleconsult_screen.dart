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

/// Teleconsultation room status.
///
/// `POST /teleconsultations/generate` opens (and auto-confirms) a room;
/// `PATCH /teleconsultations/:appointmentId/end` closes it and completes the
/// appointment. Once a room is live, "Join video call" opens
/// `VideoCallScreen`, which joins the same Socket.IO room the web client uses —
/// so a parent on a phone and a doctor in a browser meet in one call.
class TeleconsultScreen extends ConsumerStatefulWidget {
  const TeleconsultScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  ConsumerState<TeleconsultScreen> createState() => _TeleconsultScreenState();
}

class _TeleconsultScreenState extends ConsumerState<TeleconsultScreen> {
  String? _busyId;

  Future<void> _openRoom(Appointment appointment) async {
    setState(() => _busyId = appointment.id);
    try {
      await ref.read(appointmentRepositoryProvider).openRoom(appointment.id);
      ref.invalidate(myScheduleProvider);
      if (mounted) Toast.success(context, 'Room opened');
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _endRoom(Appointment appointment) async {
    final bool ok = await confirmAction(
      context,
      title: 'End consultation',
      message:
          'Ending the room also marks this appointment as completed. Continue?',
      confirmLabel: 'End room',
    );
    if (!ok) return;

    setState(() => _busyId = appointment.id);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .endRoom(appointmentId: appointment.id);
      ref.invalidate(myScheduleProvider);
      ref.invalidate(dashboardTelemetryProvider);
      if (mounted) Toast.success(context, 'Consultation closed');
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Appointment>> schedule = ref.watch(
      myScheduleProvider,
    );
    final UserRole? role = ref.watch(currentRoleProvider);
    final bool canEnd = role == UserRole.doctor || role == UserRole.admin;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Teleconsultation'))
          : null,
      body: AsyncView<List<Appointment>>(
        value: schedule,
        onRefresh: () => ref.refresh(myScheduleProvider.future),
        isEmpty: (List<Appointment> items) =>
            items.where((Appointment a) => a.status.isOpen).isEmpty,
        emptyIcon: Icons.videocam_off_outlined,
        emptyTitle: 'No active consultations',
        emptyMessage:
            'Rooms can be opened for appointments that are pending, confirmed '
            'or rescheduled.',
        builder: (List<Appointment> items) {
          final List<Appointment> eligible = items
              .where((Appointment a) => a.status.isOpen)
              .toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pageBottom,
            children: <Widget>[
              AppCard(
                background: context.palette.surfaceSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.primary600,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Open a room here, then join the video call from the '
                        'web app. Mobile shows room status only.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...eligible.map((Appointment appointment) {
                final Teleconsultation? room = appointment.teleconsultation;
                final bool busy = _busyId == appointment.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    onTap: () =>
                        context.push(Routes.appointmentDetail(appointment.id)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                role == UserRole.parent
                                    ? appointment.doctorName
                                    : appointment.childName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            StatusBadge(
                              label: room == null
                                  ? 'No room'
                                  : room.isLive
                                  ? 'Live'
                                  : 'Closed',
                              color: room == null
                                  ? AppColors.lightTextMuted
                                  : room.isLive
                                  ? AppColors.success
                                  : AppColors.warning,
                              dense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DetailRow(
                          label: 'Scheduled',
                          value: Fmt.dateTime(appointment.scheduledAt),
                          icon: Icons.schedule_rounded,
                        ),
                        if (room != null)
                          DetailRow(
                            label: 'Room id',
                            value: room.roomUrl ?? '—',
                            icon: Icons.meeting_room_outlined,
                          ),
                        if (room != null && room.isLive) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => context.push(
                                Routes.videoCall(appointment.id),
                              ),
                              icon: const Icon(
                                Icons.videocam_rounded,
                                size: 17,
                              ),
                              label: const Text('Join video call'),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => _openRoom(appointment),
                                icon: const Icon(
                                  Icons.video_call_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  room == null ? 'Open room' : 'Reopen',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(
                                    AppSizes.buttonMd,
                                  ),
                                ),
                              ),
                            ),
                            if (canEnd &&
                                room != null &&
                                room.isLive) ...<Widget>[
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => _endRoom(appointment),
                                  icon: const Icon(
                                    Icons.call_end_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('End'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(
                                      AppSizes.buttonMd,
                                    ),
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
