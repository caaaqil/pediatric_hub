import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/child.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/dashboard/MyChildren.jsx` — the page header with
/// the teal "Register New Child" button, the gradient-banner child cards with
/// their Records / Growth / Vaccines tiles, and the primary-600 registration
/// modal.
class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  /// Same "N years, M mos" / "M months" wording the web computes.
  static String ageLabel(DateTime dob) {
    final DateTime now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) months -= 1;
    if (months < 0) {
      months += 12;
      years -= 1;
    }
    if (years > 0) {
      return '$years years${months > 0 ? ', $months mos' : ''}';
    }
    return '$months months';
  }

  Future<void> _register(BuildContext context, WidgetRef ref) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => const _RegisterChildSheet(),
    );
    if (saved == true) {
      ref.invalidate(myChildrenProvider);
      ref.invalidate(allChildVaccinationsProvider);
      ref.invalidate(dashboardTelemetryProvider);
      if (context.mounted) Toast.success(context, 'Child registered');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Child>> children = ref.watch(myChildrenProvider);
    final AppPalette palette = context.palette;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: const Text('My Registered Children'))
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myChildrenProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: <Widget>[
            // Page header with the bottom rule
            Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'My Registered Children',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage health profiles, log developmental growth points, '
                    'and review clinical histories.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _register(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Register New Child'),
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
            const SizedBox(height: 24),

            children.when(
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'SYNCHRONIZING CLINICAL DATA...',
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
                  return _EmptyState(onAdd: () => _register(context, ref));
                }
                return Column(
                  children: items
                      .map(
                        (Child child) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _ChildCard(child: child),
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

/// The dashed "No Children Registered" panel.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: palette.surfaceSoft.withValues(alpha: 0.5),
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: palette.border,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.sm,
            ),
            child: Icon(Icons.add_rounded, size: 24, color: palette.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            'No Children Registered',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                const TextSpan(text: 'Tap the '),
                TextSpan(
                  text: 'Register New Child',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(
                  text:
                      ' button above to securely map your first child to '
                      'your authorization identity.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Register New Child'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The child card: gradient banner, circular initial, name, age • blood, then
/// the three navigation tiles.
class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: palette.border),
          boxShadow: AppShadows.sm,
        ),
        child: Stack(
          children: <Widget>[
            // Gradient banner
            Container(
              height: 112,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    AppColors.primary600.withValues(alpha: 0.1),
                    AppColors.teal.withValues(alpha: 0.1),
                  ],
                ),
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                children: <Widget>[
                  // Circular avatar with the ring the web draws
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border, width: 2),
                      boxShadow: AppShadows.sm,
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary600,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        child.firstName.isEmpty
                            ? '?'
                            : child.firstName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    child.fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        ChildrenScreen.ageLabel(child.dateOfBirth),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: palette.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        'Blood: ${child.bloodType ?? 'Unrecorded'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.show_chart_rounded,
                          color: AppColors.primary600,
                          label: 'Records',
                          onTap: () =>
                              context.push(Routes.childDetail(child.id)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.stacked_line_chart_rounded,
                          color: AppColors.teal,
                          label: 'Growth',
                          onTap: () =>
                              context.push(Routes.childGrowth(child.id)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.vaccines_rounded,
                          color: AppColors.warning,
                          label: 'Vaccines',
                          onTap: () =>
                              context.push(Routes.childVaccines(child.id)),
                        ),
                      ),
                    ],
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.border),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Register Child Record" — the primary-600 modal from the web.
class _RegisterChildSheet extends ConsumerStatefulWidget {
  const _RegisterChildSheet();

  @override
  ConsumerState<_RegisterChildSheet> createState() =>
      _RegisterChildSheetState();
}

class _RegisterChildSheetState extends ConsumerState<_RegisterChildSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();

  // The web select offers MALE / FEMALE, stored verbatim in the String column.
  static const List<String> _genders = <String>['MALE', 'FEMALE'];
  static const List<String> _bloodTypes = <String>[
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  String _gender = 'MALE';
  String? _bloodType;
  DateTime? _dob;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final DateTime? dob = _dob;
    if (dob == null) {
      setState(() => _error = 'Date of birth is required');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(childRepositoryProvider)
          .create(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            dateOfBirth: dob,
            gender: _gender,
            bloodType: _bloodType,
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
                      'Register Child Record',
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _Label('First Name', palette: palette),
                              TextFormField(
                                controller: _firstName,
                                textCapitalization: TextCapitalization.words,
                                validator: (String? v) =>
                                    Validators.required(v, 'First name'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _Label('Last Name', palette: palette),
                              TextFormField(
                                controller: _lastName,
                                textCapitalization: TextCapitalization.words,
                                validator: (String? v) =>
                                    Validators.required(v, 'Last name'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Label('Date of Birth', palette: palette),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: AppRadius.smAll,
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Text(
                          _dob == null ? 'Select a date' : Fmt.date(_dob),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _dob == null
                                ? palette.textMuted
                                : palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _Label('Assigned Sex', palette: palette),
                              DropdownButtonFormField<String>(
                                initialValue: _gender,
                                items: _genders
                                    .map(
                                      (String g) => DropdownMenuItem<String>(
                                        value: g,
                                        child: Text(
                                          g == 'MALE' ? 'Male' : 'Female',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (String? v) {
                                  if (v != null) setState(() => _gender = v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _Label('Blood Group', palette: palette),
                              DropdownButtonFormField<String>(
                                initialValue: _bloodType,
                                items: <DropdownMenuItem<String>>[
                                  const DropdownMenuItem<String>(
                                    child: Text('—'),
                                  ),
                                  ..._bloodTypes.map(
                                    (String b) => DropdownMenuItem<String>(
                                      value: b,
                                      child: Text(b),
                                    ),
                                  ),
                                ],
                                onChanged: (String? v) =>
                                    setState(() => _bloodType = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Register Child',
                      isLoading: _busy,
                      onPressed: _submit,
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

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.palette});

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
