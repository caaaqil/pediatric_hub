import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/telemetry.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/admin/AdminDashboard.jsx` — the "COMMAND HUB"
/// page with its three tabs (Global Telemetry / Identity Mapping / Security
/// Audit Matrix). The web renders the tabs as a left rail; on a phone they
/// become a horizontal row of the same buttons.
class AdminCommandHubScreen extends ConsumerStatefulWidget {
  const AdminCommandHubScreen({super.key});

  @override
  ConsumerState<AdminCommandHubScreen> createState() =>
      _AdminCommandHubScreenState();
}

enum _HubTab { overview, users, audits }

class _AdminCommandHubScreenState extends ConsumerState<AdminCommandHubScreen> {
  _HubTab _tab = _HubTab.overview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Control Center')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          const _CommandHubBanner(),
          const SizedBox(height: 16),
          _TabButton(
            label: 'Global Telemetry',
            icon: Icons.show_chart_rounded,
            active: _tab == _HubTab.overview,
            onTap: () => setState(() => _tab = _HubTab.overview),
          ),
          const SizedBox(height: 8),
          _TabButton(
            label: 'Identity Mapping',
            icon: Icons.groups_rounded,
            active: _tab == _HubTab.users,
            onTap: () => setState(() => _tab = _HubTab.users),
          ),
          const SizedBox(height: 8),
          _TabButton(
            label: 'Security Audit Matrix',
            icon: Icons.gpp_maybe_rounded,
            active: _tab == _HubTab.audits,
            danger: true,
            onTap: () => setState(() => _tab = _HubTab.audits),
          ),
          const SizedBox(height: 20),
          switch (_tab) {
            _HubTab.overview => const _OverviewTab(),
            _HubTab.users => const _IdentityTab(),
            _HubTab.audits => const _AuditTab(),
          },
        ],
      ),
    );
  }
}

/// The dark "COMMAND HUB / Real-Time Uplink" panel.
class _CommandHubBanner extends StatelessWidget {
  const _CommandHubBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'COMMAND HUB',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF34D399),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Color(0xFF34D399), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'REAL-TIME UPLINK',
                style: TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color accent = danger ? AppColors.danger : AppColors.primary600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: active ? accent : palette.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: active ? accent : palette.border),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: active
                    ? Colors.white
                    : (danger ? AppColors.danger : palette.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab 1 — System Telemetry cards with the coloured top borders.
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AdminTelemetry> telemetry = ref.watch(
      adminTelemetryProvider,
    );
    final AppPalette palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'System Telemetry',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time aggregate data pulling from primary indexing engines globally.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sync Indexes',
                onPressed: () => ref.invalidate(adminTelemetryProvider),
                icon: Icon(Icons.refresh_rounded, color: palette.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        telemetry.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'AGGREGATING DB VECTORS...',
                style: TextStyle(
                  color: AppColors.primary500,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),
          error: (Object error, StackTrace _) => ErrorBanner(
            message: error is ApiException
                ? error.detailedMessage
                : error.toString(),
          ),
          data: (AdminTelemetry t) => Column(
            children: <Widget>[
              _TelemetryCard(
                label: 'Total Unified Users',
                value: t.totalUsers,
                icon: Icons.groups_rounded,
                accent: AppColors.primary500,
              ),
              const SizedBox(height: 16),
              _TelemetryCard(
                label: 'Verified Providers',
                value: t.totalDoctors,
                icon: Icons.check_circle_rounded,
                accent: const Color(0xFF10B981),
              ),
              const SizedBox(height: 16),
              _TelemetryCard(
                label: 'Active WebRTC Links',
                value: t.activeTeleconsults,
                icon: Icons.videocam_rounded,
                accent: const Color(0xFFA855F7),
              ),
              const SizedBox(height: 16),
              _TelemetryCard(
                label: 'Chatbot Sessions',
                value: t.totalChatbotSessions,
                icon: Icons.smart_toy_rounded,
                accent: AppColors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: <Widget>[
          // The web uses a 4px coloured top border on these cards.
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(icon, color: accent, size: 30),
                    const SizedBox(width: 16),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 2 — "Identity Indexing Array".
class _IdentityTab extends ConsumerWidget {
  const _IdentityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ManagedUser>> users = ref.watch(adminUsersProvider);
    final AppPalette palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary600,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            child: Text(
              'Identity Indexing Array',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          users.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'LOADING IDENTITIES...',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
            error: (Object error, StackTrace _) => Padding(
              padding: const EdgeInsets.all(16),
              child: ErrorBanner(
                message: error is ApiException
                    ? error.detailedMessage
                    : error.toString(),
              ),
            ),
            data: (List<ManagedUser> items) => Column(
              children: items.map((ManagedUser u) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: palette.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        u.id,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        u.email,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              u.role.wire,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            u.isActive
                                ? Icons.check_circle_rounded
                                : Icons.stop_circle_rounded,
                            size: 14,
                            color: u.isActive
                                ? const Color(0xFF059669)
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            u.isActive ? 'ACTIVE' : 'SUSPENDED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: u.isActive
                                  ? const Color(0xFF059669)
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      if (u.role.wire != 'ADMIN') ...<Widget>[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(adminRepositoryProvider)
                                    .setSuspended(
                                      userId: u.id,
                                      suspend: u.isActive,
                                    );
                                ref.invalidate(adminUsersProvider);
                                ref.invalidate(adminTelemetryProvider);
                              } on ApiException catch (error) {
                                if (context.mounted) {
                                  Toast.error(context, error);
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                AppSizes.buttonMd,
                              ),
                              foregroundColor: u.isActive
                                  ? AppColors.danger
                                  : const Color(0xFF059669),
                              side: BorderSide(
                                color: u.isActive
                                    ? AppColors.danger
                                    : const Color(0xFF059669),
                              ),
                            ),
                            child: Text(
                              u.isActive ? 'Revoke Access' : 'Restore Login',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab 3 — the audit trail.
class _AuditTab extends ConsumerWidget {
  const _AuditTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AuditLog>> audits = ref.watch(adminAuditsProvider);

    return audits.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: LoadingView(),
      ),
      error: (Object error, StackTrace _) => ErrorBanner(
        message: error is ApiException
            ? error.detailedMessage
            : error.toString(),
      ),
      data: (List<AuditLog> items) {
        if (items.isEmpty) {
          return const EmptyView(
            title: 'No audit entries',
            message: 'Actions taken on the platform will be recorded here.',
            icon: Icons.receipt_long_outlined,
          );
        }
        return Column(
          children: items
              .map(
                (AuditLog log) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AuditTile(log: log),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Shared audit row.
class AuditTile extends StatelessWidget {
  const AuditTile({super.key, required this.log});

  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary600.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 16,
              color: AppColors.primary600,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  Fmt.humanize(log.action),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${log.entity} · ${log.userEmail ?? 'system'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            Fmt.relative(log.createdAt),
            style: TextStyle(fontSize: 11, color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}
