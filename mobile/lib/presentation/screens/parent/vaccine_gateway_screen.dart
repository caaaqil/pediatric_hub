import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/child.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/dashboard/GlobalVaccineTracker.jsx` — the amber
/// "Immunization Gateway" banner and the patient picker that opens each child's
/// immunization matrix.
class VaccineGatewayScreen extends ConsumerWidget {
  const VaccineGatewayScreen({super.key});

  static const Color amber = Color(0xFFFFB020);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Child>> children = ref.watch(myChildrenProvider);
    final AppPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Vaccinations')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myChildrenProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            // Amber gateway banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[amber, Color(0xFFF59E0B)],
                ),
                borderRadius: AppRadius.lgAll,
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vaccines_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Immunization Gateway',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a patient below to view, manage, and synchronize '
                    'their formal vaccination schedules.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'SELECT PATIENT PROFILE',
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 16),

            children.when(
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'LOADING GATEWAY PROFILES...',
                    style: TextStyle(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              error: (Object error, StackTrace _) => ErrorView(
                message: error is ApiException
                    ? error.detailedMessage
                    : error.toString(),
                onRetry: () => ref.invalidate(myChildrenProvider),
              ),
              data: (List<Child> items) {
                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 44,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft.withValues(alpha: 0.5),
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: palette.border, width: 2),
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'No Children Registered',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: palette.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please return to Child Health Records to register '
                          'your first child before generating a vaccine map.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: palette.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: items
                      .map(
                        (Child child) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PatientCard(child: child),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return InkWell(
      onTap: () => context.push(Routes.childVaccines(child.id)),
      borderRadius: AppRadius.mdAll,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: palette.border),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: VaccineGatewayScreen.amber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                child.firstName.isEmpty
                    ? '?'
                    : child.firstName.substring(0, 1).toLowerCase(),
                style: const TextStyle(
                  color: VaccineGatewayScreen.amber,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    child.fullName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.show_chart_rounded,
                        size: 10,
                        color: Color(0xFFAEB1C4),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'OPEN IMMUNIZATION MATRIX',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                          color: Color(0xFFAEB1C4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
