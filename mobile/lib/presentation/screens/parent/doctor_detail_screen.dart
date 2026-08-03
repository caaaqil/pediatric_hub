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
import '../../../data/models/doctor.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/facility.dart';
import '../../providers/providers.dart';

/// `GET /doctors/:id` plus the facility's active services when one is linked.
class DoctorDetailScreen extends ConsumerWidget {
  const DoctorDetailScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Doctor> doctor = ref.watch(doctorDetailProvider(doctorId));
    final UserRole? role = ref.watch(currentRoleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor profile')),
      body: doctor.when(
        loading: () => const LoadingView(),
        error: (Object error, StackTrace _) => ErrorView(
          message: error is ApiException
              ? error.detailedMessage
              : error.toString(),
          onRetry: () => ref.invalidate(doctorDetailProvider(doctorId)),
        ),
        data: (Doctor data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(doctorDetailProvider(doctorId));
            await ref.read(doctorDetailProvider(doctorId).future);
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
                        InitialsAvatar(initials: data.initials, size: 54),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                data.displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                data.specialization,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StatusBadge(
                      label: data.isVerified ? 'Verified' : 'Pending review',
                      color: data.isVerified
                          ? AppColors.success
                          : AppColors.warning,
                      icon: data.isVerified
                          ? Icons.verified_rounded
                          : Icons.hourglass_bottom_rounded,
                    ),
                    const Divider(height: AppSpacing.xxl),
                    DetailRow(
                      label: 'Licence',
                      value: data.licenseNumber,
                      icon: Icons.badge_outlined,
                    ),
                    DetailRow(
                      label: 'Email',
                      value: data.email ?? 'Not published',
                      icon: Icons.mail_outline_rounded,
                    ),
                    DetailRow(
                      label: 'Facility',
                      value: data.facilityName ?? 'Independent',
                      icon: Icons.local_hospital_outlined,
                    ),
                    if (data.facilityAddress != null)
                      DetailRow(
                        label: 'Address',
                        value: data.facilityAddress ?? '',
                        icon: Icons.location_on_outlined,
                      ),
                    if (data.facilityPhone != null)
                      DetailRow(
                        label: 'Facility phone',
                        value: data.facilityPhone ?? '',
                        icon: Icons.phone_outlined,
                      ),
                    DetailRow(
                      label: 'Joined',
                      value: Fmt.date(data.createdAt),
                      icon: Icons.event_note_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (data.facilityId != null)
                _FacilityServices(facilityId: data.facilityId ?? ''),

              if (role == UserRole.parent) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Book with ${data.displayName}',
                  icon: Icons.event_available_rounded,
                  onPressed: () => context.push(
                    '${Routes.bookAppointment}?doctorId=${data.id}',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityServices extends ConsumerWidget {
  const _FacilityServices({required this.facilityId});

  final String facilityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HealthService>> services = ref.watch(
      facilityServicesProvider(facilityId),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppCardHeader(
            title: 'Services at this facility',
            icon: Icons.medical_information_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          services.when(
            loading: () => const SizedBox(height: 48, child: LoadingView()),
            error: (Object error, StackTrace _) => Text(
              'Could not load services.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            data: (List<HealthService> items) {
              if (items.isEmpty) {
                return Text(
                  'No services published for this facility.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: items.map((HealthService service) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            service.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (service.price != null)
                          Text(
                            Fmt.money(service.price ?? 0),
                            style: Theme.of(context).textTheme.titleSmall,
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
