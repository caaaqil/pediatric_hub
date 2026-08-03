import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/telemetry.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/admin/ManageUsers.jsx` — the slate gradient
/// hero, the search bar, the identity rows and the "Add User" modal.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => const _CreateUserSheet(),
    );
    if (saved == true) {
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminTelemetryProvider);
      if (mounted) Toast.success(context, 'User created');
    }
  }

  Future<void> _changeRole(ManagedUser user) async {
    final UserRole? picked = await showModalBottomSheet<UserRole>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Change role for ${user.email}',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ...UserRole.values.map(
              (UserRole role) => ListTile(
                leading: Icon(
                  role == user.role
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                title: Text(role.label),
                onTap: () => Navigator.of(ctx).pop(role),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );

    if (picked == null || picked == user.role) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateRole(userId: user.id, role: picked.wire);
      ref.invalidate(adminUsersProvider);
      if (mounted) Toast.success(context, 'Role updated to ${picked.label}');
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    }
  }

  Future<void> _deleteUser(ManagedUser user) async {
    final bool ok = await confirmAction(
      context,
      title: 'Delete user',
      message:
          '${user.email} will be soft-deleted and permanently signed out. Continue?',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    try {
      await ref.read(adminRepositoryProvider).deleteUser(user.id);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminTelemetryProvider);
      if (mounted) Toast.success(context, 'User deleted');
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ManagedUser>> users = ref.watch(adminUsersProvider);
    final AppPalette palette = context.palette;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Users Management'))
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminUsersProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            // Slate gradient hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: AppRadius.lgAll,
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.groups_rounded,
                        color: AppColors.teal,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Users Management',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Monitor system telemetry and authorization statuses for all '
                    'Parents, Doctors, and Administrators within the Pediatric '
                    'Health Hub architecture.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createUser,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(AppSizes.buttonMd),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search + identity list card
            Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: palette.border),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft,
                      border: Border(bottom: BorderSide(color: palette.border)),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.md),
                      ),
                    ),
                    child: TextField(
                      controller: _search,
                      onChanged: (String v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Search by email...',
                        prefixIcon: Icon(Icons.search_rounded, size: 18),
                      ),
                    ),
                  ),
                  users.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'SYNCHRONIZING IAM DATABASE...',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            fontSize: 12,
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
                    data: (List<ManagedUser> items) {
                      final List<ManagedUser> shown = _query.isEmpty
                          ? items
                          : items
                                .where(
                                  (ManagedUser u) =>
                                      u.email.toLowerCase().contains(_query),
                                )
                                .toList();

                      if (shown.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(color: palette.surfaceSoft),
                          child: Center(
                            child: Text(
                              'NO IDENTITIES FOUND',
                              style: TextStyle(
                                color: palette.textMuted,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: shown
                            .map(
                              (ManagedUser u) => _IdentityRow(
                                user: u,
                                onEdit: () => _changeRole(u),
                                onDelete: () => _deleteUser(u),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  final ManagedUser user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final Color roleBg = switch (user.role) {
      UserRole.admin => AppColors.primary600.withValues(alpha: 0.1),
      UserRole.doctor => AppColors.teal.withValues(alpha: 0.1),
      _ => palette.surfaceSoft,
    };
    final Color roleFg = switch (user.role) {
      UserRole.admin => AppColors.primary600,
      UserRole.doctor => AppColors.teal,
      _ => palette.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(user.email, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            'SSO Linked • Database ID: ${user.id.length >= 8 ? user.id.substring(0, 8) : user.id}...',
            style: TextStyle(fontSize: 11, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user.role.wire,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: roleFg,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: user.isActive
                      ? const Color(0xFF10B981)
                      : AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user.isActive ? 'Active' : 'Suspended',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: user.isActive
                      ? const Color(0xFF10B981)
                      : AppColors.danger,
                ),
              ),
              const Spacer(),
              _IconAction(
                icon: Icons.edit_rounded,
                color: AppColors.primary500,
                onTap: onEdit,
                tooltip: 'Change role',
              ),
              const SizedBox(width: 8),
              _IconAction(
                icon: Icons.delete_outline_rounded,
                color: AppColors.danger,
                onTap: onDelete,
                tooltip: 'Delete user',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

/// `POST /users` — modal with the primary-600 header bar from the web.
class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet();

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  UserRole _role = UserRole.parent;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .createUser(
            email: _email.text.trim(),
            password: _password.text,
            role: _role.wire,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.primary600,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Add User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_error != null) ...<Widget>[
                      ErrorBanner(message: _error ?? ''),
                      const SizedBox(height: 16),
                    ],
                    _FieldLabel('Email Address', palette: palette),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Password', palette: palette),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        helperText: '8+ chars with a letter, number and symbol',
                      ),
                      validator: Validators.strongPassword,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('System Role', palette: palette),
                    DropdownButtonFormField<UserRole>(
                      initialValue: _role,
                      items: UserRole.values
                          .map(
                            (UserRole r) => DropdownMenuItem<UserRole>(
                              value: r,
                              child: Text(r.label),
                            ),
                          )
                          .toList(),
                      onChanged: (UserRole? v) {
                        if (v != null) setState(() => _role = v);
                      },
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Create User',
                      isLoading: _busy,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.palette});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: palette.textMuted,
        ),
      ),
    );
  }
}
