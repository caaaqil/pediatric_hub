import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/misc.dart';
import '../../../data/models/user.dart';
import '../../providers/providers.dart';
import '../../providers/theme_provider.dart';

class ShellTab {
  const ShellTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.child,
    required this.breadcrumb,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget child;

  /// Right-hand side of the blue toolbar breadcrumb, e.g. "Main Dashboard".
  final String breadcrumb;
}

/// One entry of the drawer navigation, mirroring the web sidebar links.
class SidebarLink {
  const SidebarLink(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

/// Portal chrome ported from the web `DashboardLayout`:
///
///  • a 68px header — avatar, name, "{ROLE} PORTAL", date chip and the
///    bordered square theme / settings / notifications / logout buttons
///  • a 48px primary-600 toolbar — quick icon links, page title, the
///    "Home › Page" breadcrumb and the "Secure Session Active" pulse
///  • a drawer holding the sidebar exactly as the web renders it
///  • plus the bottom tab bar for one-thumb navigation on a phone
class RoleShell extends ConsumerStatefulWidget {
  const RoleShell({
    super.key,
    required this.tabs,
    required this.portalName,
    required this.sidebarLinks,
    required this.quickLinks,
  });

  final List<ShellTab> tabs;
  final String portalName;
  final List<SidebarLink> sidebarLinks;

  /// The icon shortcuts pinned to the left of the blue toolbar.
  final List<SidebarLink> quickLinks;

  @override
  ConsumerState<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends ConsumerState<RoleShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppUser? user = ref.watch(currentUserProvider);
    final AppPalette palette = context.palette;
    final ShellTab tab = widget.tabs[_index];

    return Scaffold(
      drawer: _SidebarDrawer(
        portalName: widget.portalName,
        links: widget.sidebarLinks,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68 + 48),
        child: Column(
          children: <Widget>[
            _Header(user: user, portalName: widget.portalName),
            _BlueToolbar(
              title: tab.label,
              breadcrumb: tab.breadcrumb,
              quickLinks: widget.quickLinks,
            ),
          ],
        ),
      ),
      body: Container(
        color: palette.bg,
        child: IndexedStack(
          index: _index,
          children: widget.tabs.map((ShellTab t) => t.child).toList(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (int i) => setState(() => _index = i),
          items: widget.tabs
              .map(
                (ShellTab t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// The 68px header bar.
class _Header extends ConsumerWidget {
  const _Header({required this.user, required this.portalName});

  final AppUser? user;
  final String portalName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final ThemeData theme = Theme.of(context);
    final bool isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final int unread = ref
        .watch(notificationsProvider)
        .maybeWhen(
          data: (List<AppNotification> items) =>
              items.where((AppNotification n) => !n.isRead).length,
          orElse: () => 0,
        );

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
        boxShadow: AppShadows.sm,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            Builder(
              builder: (BuildContext ctx) => IconButton(
                tooltip: 'Menu',
                icon: Icon(Icons.menu_rounded, color: palette.textSecondary),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            InitialsAvatar(initials: user?.initials ?? '?', size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    user?.displayName ?? 'Authorized User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
                  ),
                  Text(
                    '${portalName.toUpperCase()} PORTAL',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            _SquareButton(
              icon: isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              tooltip: 'Toggle theme',
              onTap: () => ref.read(themeModeProvider.notifier).toggle(),
            ),
            const SizedBox(width: 6),
            _SquareButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              badge: unread,
              onTap: () => context.push(Routes.notifications),
            ),
            const SizedBox(width: 6),
            _SquareButton(
              icon: Icons.logout_rounded,
              tooltip: 'Log out',
              danger: true,
              onTap: () async {
                final bool ok = await confirmAction(
                  context,
                  title: 'Sign out',
                  message: 'You will need to sign in again to continue.',
                  confirmLabel: 'Sign out',
                );
                if (ok) {
                  await ref.read(authControllerProvider.notifier).logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The bordered square icon buttons from the web header.
class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: Border.all(color: palette.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: danger ? AppColors.danger : palette.textMuted,
              ),
              if (badge > 0)
                Positioned(
                  top: 7,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 48px primary-600 sub-navigation toolbar.
class _BlueToolbar extends StatelessWidget {
  const _BlueToolbar({
    required this.title,
    required this.breadcrumb,
    required this.quickLinks,
  });

  final String title;
  final String breadcrumb;
  final List<SidebarLink> quickLinks;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: isDark ? AppColors.primary700 : AppColors.primary600,
      child: Row(
        children: <Widget>[
          ...quickLinks.map(
            (SidebarLink link) => Tooltip(
              message: link.label,
              child: InkWell(
                onTap: () => context.push(link.route),
                borderRadius: AppRadius.smAll,
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(link.icon, size: 15, color: Colors.white),
                ),
              ),
            ),
          ),
          if (quickLinks.isNotEmpty)
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: isDark ? AppColors.primary600 : AppColors.primary500,
            ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Home › $breadcrumb',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primary200,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const _PulseDot(),
        ],
      ),
    );
  }
}

/// "Secure Session Active" indicator.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FadeTransition(
          opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(color: Colors.white54, blurRadius: 8),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'SECURE',
          style: TextStyle(
            color: AppColors.primary200,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

/// The web sidebar, rendered as a drawer.
class _SidebarDrawer extends ConsumerWidget {
  const _SidebarDrawer({required this.portalName, required this.links});

  final String portalName;
  final List<SidebarLink> links;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final ThemeData theme = Theme.of(context);
    final UserRole? role = ref.watch(currentRoleProvider);

    return Drawer(
      backgroundColor: palette.surface,
      width: 272,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sidebar header — logo block
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      borderRadius: AppRadius.smAll,
                      boxShadow: AppShadows.md,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Pediatric Hub',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${portalName.toUpperCase()} PORTAL',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                children: <Widget>[
                  _NavTile(
                    link: SidebarLink(
                      'Dashboard',
                      Icons.dashboard_outlined,
                      Routes.homeForRole(role?.wire ?? 'PARENT'),
                    ),
                    active: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 0, 8),
                    child: Text(
                      'CLINICAL FEATURES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  ...links.map((SidebarLink link) => _NavTile(link: link)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.link, this.active = false});

  final SidebarLink link;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: () {
            Navigator.of(context).pop();
            if (!active) context.push(link.route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? (isDark ? AppColors.primary950 : AppColors.primary50)
                  : Colors.transparent,
              borderRadius: AppRadius.smAll,
              border: active
                  ? Border.all(
                      color: isDark
                          ? AppColors.primary800
                          : AppColors.primary200,
                    )
                  : null,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  link.icon,
                  size: 18,
                  color: active
                      ? (isDark ? AppColors.primary300 : AppColors.primary700)
                      : palette.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    link.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? (isDark
                                ? AppColors.primary300
                                : AppColors.primary700)
                          : palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small date chip used on wider screens, matching the web header pill.
class HeaderDateChip extends StatelessWidget {
  const HeaderDateChip({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: palette.border),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        Fmt.date(DateTime.now()).toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: palette.textMuted,
        ),
      ),
    );
  }
}
