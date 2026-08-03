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
import '../../../data/models/child.dart';
import '../../providers/providers.dart';

/// `GET /children` — the patient roster for DOCTOR, FACILITY and ADMIN.
/// Facility callers are scoped server-side to children their doctors have seen.
class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Child>> patients = ref.watch(allChildrenProvider);

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Patients')) : null,
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
                hintText: 'Search patients',
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
            child: AsyncView<List<Child>>(
              value: patients,
              onRefresh: () => ref.refresh(allChildrenProvider.future),
              isEmpty: (List<Child> items) => items.isEmpty,
              emptyIcon: Icons.groups_outlined,
              emptyTitle: 'No patients yet',
              emptyMessage:
                  'Children registered on the platform will appear here.',
              builder: (List<Child> items) {
                final List<Child> filtered = _query.isEmpty
                    ? items
                    : items
                          .where(
                            (Child c) =>
                                c.fullName.toLowerCase().contains(_query) ||
                                (c.parentName ?? '').toLowerCase().contains(
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
                          'No patients match "$_query".',
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
                  itemBuilder: (BuildContext context, int index) {
                    final Child child = filtered[index];
                    return AppCard(
                      onTap: () => context.push(Routes.patientDetail(child.id)),
                      child: Row(
                        children: <Widget>[
                          InitialsAvatar(
                            initials: child.firstName.isEmpty
                                ? '?'
                                : child.firstName.substring(0, 1).toUpperCase(),
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  child.fullName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${child.ageLabel} · ${child.gender}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (child.parentName != null)
                                  Text(
                                    'Parent: ${child.parentName}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                Text(
                                  'Born ${Fmt.date(child.dateOfBirth)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
