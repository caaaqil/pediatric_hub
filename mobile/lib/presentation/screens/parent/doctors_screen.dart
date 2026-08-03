import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/doctor.dart';
import '../../providers/providers.dart';

/// `GET /users/doctors` — browse and search the clinical directory.
///
/// The backend's `search` only matches lastName, so filtering happens locally
/// across name, specialisation and facility.
class DoctorsScreen extends ConsumerStatefulWidget {
  const DoctorsScreen({super.key});

  @override
  ConsumerState<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends ConsumerState<DoctorsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Doctor>> doctors = ref.watch(bookableDoctorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find a doctor')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _search,
              onChanged: (String value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or specialisation',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: AsyncView<List<Doctor>>(
              value: doctors,
              onRefresh: () => ref.refresh(bookableDoctorsProvider.future),
              isEmpty: (List<Doctor> items) => items.isEmpty,
              emptyIcon: Icons.medical_services_outlined,
              emptyTitle: 'No doctors available',
              emptyMessage: 'No clinicians are registered on the platform yet.',
              builder: (List<Doctor> items) {
                final List<Doctor> filtered = _query.isEmpty
                    ? items
                    : items
                          .where(
                            (Doctor d) =>
                                d.fullName.toLowerCase().contains(_query) ||
                                d.specialization.toLowerCase().contains(
                                  _query,
                                ) ||
                                (d.facilityName ?? '').toLowerCase().contains(
                                  _query,
                                ),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.pageBottom,
                    children: <Widget>[
                      AppCard(
                        child: Text(
                          'No doctors match "$_query".',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.pageBottom,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (BuildContext context, int index) =>
                      DoctorTile(doctor: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared doctor row — also used by the facility staff list.
class DoctorTile extends StatelessWidget {
  const DoctorTile({super.key, required this.doctor, this.onTap});

  final Doctor doctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap ?? () => context.push(Routes.doctorDetail(doctor.id)),
      child: Row(
        children: <Widget>[
          InitialsAvatar(initials: doctor.initials),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  doctor.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.specialization,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (doctor.facilityName != null)
                  Text(
                    doctor.facilityName ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (doctor.isVerified)
            const Icon(
              Icons.verified_rounded,
              size: 18,
              color: AppColors.success,
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
