import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/facility.dart';
import '../../providers/providers.dart';
import '../shared/appointments_screen.dart';

/// FACILITY home — everything comes from the single `GET /facilities/my-scope`
/// call: profile, counts, staff, services, appointments and patients.
class FacilityDashboardScreen extends ConsumerWidget {
  const FacilityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FacilityScope> scope = ref.watch(facilityScopeProvider);

    return AsyncView<FacilityScope>(
      value: scope,
      onRefresh: () => ref.refresh(facilityScopeProvider.future),
      builder: (FacilityScope data) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pageBottom,
        children: <Widget>[
          BrandHeader(
            title: data.facility.name,
            subtitle:
                '${data.facility.facilityType.label} · ${data.facility.address}',
            trailing: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white70,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: 'Clinical staff',
                  value: '${data.doctorCount}',
                  icon: Icons.medical_services_rounded,
                  onTap: () => context.push(Routes.facilityStaff),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  label: 'Services',
                  value: '${data.serviceCount}',
                  icon: Icons.medical_information_rounded,
                  color: AppColors.teal,
                  onTap: () => context.push(Routes.facilityServices),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: 'Appointments',
                  value: '${data.appointmentCount}',
                  icon: Icons.event_note_rounded,
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  label: 'Patients seen',
                  value: '${data.patientCount}',
                  icon: Icons.groups_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Facility details'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DetailRow(
                  label: 'Type',
                  value: data.facility.facilityType.label,
                  icon: Icons.apartment_outlined,
                ),
                DetailRow(
                  label: 'Phone',
                  value: data.facility.phoneNumber,
                  icon: Icons.phone_outlined,
                ),
                DetailRow(
                  label: 'Address',
                  value: data.facility.address,
                  icon: Icons.location_on_outlined,
                ),
                DetailRow(
                  label: 'Status',
                  value: data.facility.isActive ? 'Active' : 'Inactive',
                  icon: Icons.verified_outlined,
                  valueColor: data.facility.isActive
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Pending appointments'),
          Builder(
            builder: (BuildContext context) {
              final List<Appointment> pending = data.appointments
                  .where(
                    (Appointment a) => a.status == AppointmentStatus.pending,
                  )
                  .take(5)
                  .toList();
              if (pending.isEmpty) {
                return AppCard(
                  child: Text(
                    'No requests waiting for a decision.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return Column(
                children: pending
                    .map(
                      (Appointment appointment) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppointmentTile(appointment: appointment),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Recent activity'),
          ...data.appointments
              .take(5)
              .map(
                (Appointment appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    onTap: () =>
                        context.push(Routes.appointmentDetail(appointment.id)),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${appointment.childName} → ${appointment.doctorName}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                Fmt.dateTime(appointment.scheduledAt),
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
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
