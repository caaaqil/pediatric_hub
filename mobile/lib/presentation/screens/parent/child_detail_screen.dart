import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/child.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/health_record.dart';
import '../../../data/models/vaccination.dart';
import '../../../data/repositories/health_record_repository.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/dashboard/ChildProfile.jsx` — the page a parent
/// lands on from Child Health Records.
///
/// Same sections in the same order: the gradient banner with the Vaccines and
/// Growth buttons, Child's Information, Vaccination Summary, Parent
/// Information, the Allergies / Medications / Past Illnesses trio, Appointment
/// History and Doctor's Notes. The web lays the middle sections out in two and
/// three columns; on a phone they stack.
class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Child> child = ref.watch(childDetailProvider(childId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Health Records'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit',
            onPressed: () => context.push(Routes.childEdit(childId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: child.when(
        loading: () => const LoadingView(),
        error: (Object error, StackTrace _) => ErrorView(
          message: error is ApiException
              ? error.detailedMessage
              : 'Failed to load medical records. Check your permissions.',
          onRetry: () => ref.invalidate(childDetailProvider(childId)),
        ),
        data: (Child data) => RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(childDetailProvider(childId))
              ..invalidate(childVaccinationsProvider(childId))
              ..invalidate(guardiansProvider(childId))
              ..invalidate(baselineProvider(childId))
              ..invalidate(consultationsProvider(childId))
              ..invalidate(myScheduleProvider);
            await ref.read(childDetailProvider(childId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: <Widget>[
              _Banner(child: data, childId: childId),
              const SizedBox(height: 16),
              _ChildInformation(child: data),
              const SizedBox(height: 16),
              _VaccinationSummary(childId: childId),
              const SizedBox(height: 16),
              _ParentInformation(childId: childId),
              const SizedBox(height: 16),
              _Baseline(childId: childId),
              const SizedBox(height: 16),
              _AppointmentHistory(childId: childId),
              const SizedBox(height: 16),
              _DoctorNotes(childId: childId),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Banner ───────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({required this.child, required this.childId});

  final Child child;
  final String childId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[AppColors.primary600, Color(0xFF4338CA)],
        ),
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF3730A3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 4,
                  ),
                ),
                child: Text(
                  child.firstName.isEmpty
                      ? 'C'
                      : child.firstName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${child.firstName} ${child.lastName}'.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              _bannerPill(
                Icons.child_care_rounded,
                'Age: ${_calcAge(child.dateOfBirth)}',
              ),
              _bannerPill(Icons.person_rounded, child.gender.toUpperCase()),
              if (child.bloodType != null)
                _bannerPill(null, child.bloodType ?? '', red: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _bannerButton(
                  context,
                  Icons.vaccines_rounded,
                  'Vaccines',
                  () => context.push(Routes.childVaccines(childId)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bannerButton(
                  context,
                  Icons.show_chart_rounded,
                  'Growth',
                  () => context.push(Routes.childGrowth(childId)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerPill(IconData? icon, String text, {bool red = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: red
            ? const Color(0xFFF87171).withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      ),
    );
  }
}

// ── Child's Information ──────────────────────────────────────────────────────

class _ChildInformation extends StatelessWidget {
  const _ChildInformation({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> fields = <(String, String)>[
      ('Full Name', '${child.firstName} ${child.lastName}'.trim()),
      ('Date of Birth', Fmt.date(child.dateOfBirth)),
      ('Age', _calcAge(child.dateOfBirth)),
      ('Gender', child.gender.toUpperCase()),
      ('Blood Type', child.bloodType ?? 'N/A'),
      // The child payload carries no parent phone; the web falls back to N/A
      // for exactly the same reason.
      ("Parent's Phone", 'N/A'),
    ];

    return _Panel(
      title: "Child's Information",
      icon: Icons.child_care_rounded,
      iconColor: AppColors.primary500,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < fields.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              // IntrinsicHeight gives the pair a shared, finite height. A bare
              // CrossAxisAlignment.stretch would ask for infinite height inside
              // the ListView and drop the whole page.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(child: _field(context, fields[i])),
                    const SizedBox(width: 10),
                    Expanded(
                      child: i + 1 < fields.length
                          ? _field(context, fields[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, (String, String) entry) {
    final AppPalette palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            entry.$1.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.$2.isEmpty ? 'N/A' : entry.$2,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vaccination Summary ──────────────────────────────────────────────────────

class _VaccinationSummary extends ConsumerWidget {
  const _VaccinationSummary({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<List<Vaccination>> doses = ref.watch(
      childVaccinationsProvider(childId),
    );

    return _Panel(
      title: 'Vaccination Summary',
      icon: Icons.vaccines_rounded,
      iconColor: const Color(0xFFA855F7),
      child: doses.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (Object e, StackTrace _) => Text(
          e is ApiException ? e.detailedMessage : 'Could not load vaccines.',
          style: TextStyle(fontSize: 12, color: palette.textMuted),
        ),
        data: (List<Vaccination> list) {
          final List<Vaccination> given = list
              .where((Vaccination v) => v.status == VaccineStatus.completed)
              .toList();
          final List<Vaccination> pending = list
              .where(
                (Vaccination v) =>
                    v.status == VaccineStatus.upcoming ||
                    v.status == VaccineStatus.due,
              )
              .toList();
          final int missed = list
              .where((Vaccination v) => v.status == VaccineStatus.missed)
              .length;

          return Column(
            children: <Widget>[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _tile(
                        context,
                        given.length,
                        'Given',
                        const Color(0xFF059669),
                        const Color(0xFFECFDF5),
                        const Color(0xFFA7F3D0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _tile(
                        context,
                        pending.length,
                        'Remaining',
                        const Color(0xFF2563EB),
                        const Color(0xFFEFF6FF),
                        const Color(0xFFBFDBFE),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _tile(
                        context,
                        missed,
                        'Missed',
                        const Color(0xFFDC2626),
                        const Color(0xFFFEF2F2),
                        const Color(0xFFFECACA),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final Vaccination v in pending.take(2))
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          v.vaccineName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          Fmt.date(v.scheduledDate),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: () => context.push(Routes.childVaccines(childId)),
                child: const Text(
                  'View Full Vaccine Schedule →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    int count,
    String label,
    Color fg,
    Color bg,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              color: fg.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Parent Information ───────────────────────────────────────────────────────

/// `RELATIONSHIP_OPTIONS` in ChildProfile.jsx — the wire values the backend
/// validator accepts, with the labels the web shows.
const List<(String, String)> _relationships = <(String, String)>[
  ('FATHER', 'Father'),
  ('MOTHER', 'Mother'),
  ('UNCLE', 'Uncle'),
  ('AUNT', 'Aunt'),
  ('MATERNAL_UNCLE', 'Maternal Uncle'),
  ('MATERNAL_AUNT', 'Maternal Aunt'),
  ('GUARDIAN', 'Guardian'),
  ('OTHER', 'Other'),
];

String _relationshipLabel(String wire) {
  for (final (String value, String label) in _relationships) {
    if (value == wire) return label;
  }
  return wire;
}

class _ParentInformation extends ConsumerWidget {
  const _ParentInformation({required this.childId});

  final String childId;

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    ParentInfo? editing,
  }) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext _) =>
          _ParentForm(childId: childId, editing: editing),
    );
    if (saved == true) ref.invalidate(guardiansProvider(childId));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ParentInfo parent,
  ) async {
    final bool ok = await confirmAction(
      context,
      title: 'Delete this parent record?',
      message: '${parent.fullName} will be removed from this child.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    try {
      await ref.read(healthRecordRepositoryProvider).removeGuardian(parent.id);
      ref.invalidate(guardiansProvider(childId));
    } on ApiException catch (error) {
      if (context.mounted) Toast.error(context, error.detailedMessage);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<List<ParentInfo>> parents = ref.watch(
      guardiansProvider(childId),
    );

    return _Panel(
      title: 'Parent Information',
      icon: Icons.people_alt_rounded,
      iconColor: const Color(0xFF059669),
      action: FilledButton.icon(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_rounded, size: 15),
        label: const Text('Add Parent'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      child: parents.when(
        loading: () => Text(
          'Loading parent records...',
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: palette.textSecondary,
          ),
        ),
        error: (Object e, StackTrace _) => Text(
          e is ApiException ? e.detailedMessage : 'Could not load parents.',
          style: TextStyle(fontSize: 12, color: palette.textMuted),
        ),
        data: (List<ParentInfo> list) {
          if (list.isEmpty) {
            return Text(
              'No parent information linked yet.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: palette.textSecondary,
              ),
            );
          }
          return Column(
            children: <Widget>[
              for (final ParentInfo p in list)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  p.fullName,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _relationshipLabel(
                                      p.relationship,
                                    ).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                _openForm(context, ref, editing: p),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Color(0xFF059669),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _delete(context, ref, p),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _line(context, Icons.phone_rounded, p.phoneNumber),
                      _line(context, Icons.place_rounded, p.address),
                      if (p.healthStatus != null &&
                          (p.healthStatus ?? '').isNotEmpty) ...<Widget>[
                        Divider(height: 18, color: palette.border),
                        _line(
                          context,
                          Icons.monitor_heart_rounded,
                          p.healthStatus ?? '',
                          iconColor: const Color(0xFFEF4444),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(
    BuildContext context,
    IconData icon,
    String text, {
    Color? iconColor,
  }) {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 12, color: iconColor ?? palette.textSecondary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Add / Edit Parent Information" modal, as a sheet so the keyboard has
/// somewhere to go on a phone.
class _ParentForm extends ConsumerStatefulWidget {
  const _ParentForm({required this.childId, this.editing});

  final String childId;
  final ParentInfo? editing;

  @override
  ConsumerState<_ParentForm> createState() => _ParentFormState();
}

class _ParentFormState extends ConsumerState<_ParentForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _health;
  late String _relationship;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ParentInfo? editing = widget.editing;
    _fullName = TextEditingController(text: editing?.fullName ?? '');
    _phone = TextEditingController(text: editing?.phoneNumber ?? '');
    _address = TextEditingController(text: editing?.address ?? '');
    _health = TextEditingController(text: editing?.healthStatus ?? '');
    _relationship = editing?.relationship ?? 'FATHER';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _address.dispose();
    _health.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final HealthRecordRepository repo = ref.read(
        healthRecordRepositoryProvider,
      );
      final ParentInfo? editing = widget.editing;
      if (editing == null) {
        await repo.addGuardian(
          childId: widget.childId,
          fullName: _fullName.text.trim(),
          phoneNumber: _phone.text.trim(),
          address: _address.text.trim(),
          relationship: _relationship,
          healthStatus: _health.text.trim(),
        );
      } else {
        await repo.updateGuardian(
          id: editing.id,
          fullName: _fullName.text.trim(),
          phoneNumber: _phone.text.trim(),
          address: _address.text.trim(),
          relationship: _relationship,
          healthStatus: _health.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool editing = widget.editing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Emerald header, as on the web modal.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF059669), Color(0xFF0F766E)],
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.people_alt_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      editing
                          ? 'Edit Parent Information'
                          : 'Add Parent Information',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _field(
                        'PARENT FULL NAME *',
                        _fullName,
                        hint: 'e.g. Cabdiraxmaan Maxamed',
                        validator: (String? v) =>
                            (v == null || v.trim().length < 2)
                            ? 'At least 2 characters'
                            : null,
                      ),
                      _field(
                        'PHONE NUMBER *',
                        _phone,
                        hint: '+252 612 345 678',
                        keyboard: TextInputType.phone,
                        validator: (String? v) =>
                            (v == null || v.trim().length < 5)
                            ? 'At least 5 characters'
                            : null,
                      ),
                      _field(
                        'ADDRESS / RESIDENTIAL LOCATION *',
                        _address,
                        hint: 'Mogadishu, Hodan District',
                        validator: (String? v) =>
                            (v == null || v.trim().length < 2)
                            ? 'At least 2 characters'
                            : null,
                      ),
                      _field(
                        'HEALTH STATUS (OPTIONAL)',
                        _health,
                        hint: 'Any known medical condition or illness',
                        maxLines: 2,
                      ),
                      Text(
                        'RELATIONSHIP TO CHILD *',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _relationship,
                        items: <DropdownMenuItem<String>>[
                          for (final (String value, String label)
                              in _relationships)
                            DropdownMenuItem<String>(
                              value: value,
                              child: Text(label),
                            ),
                        ],
                        onChanged: (String? v) =>
                            setState(() => _relationship = v ?? 'FATHER'),
                      ),
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: 14),
                        ErrorBanner(message: _error ?? ''),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                minimumSize: const Size(0, 48),
                              ),
                              child: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      editing ? 'Save Changes' : 'Save Parent',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboard,
            validator: validator,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

// ── Allergies / Medications / Past Illnesses ─────────────────────────────────

class _Baseline extends ConsumerWidget {
  const _Baseline({required this.childId});

  final String childId;

  Future<void> _add(BuildContext context, WidgetRef ref, String type) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext _) => _RecordForm(childId: childId, type: type),
    );
    if (saved == true) ref.invalidate(baselineProvider(childId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<ChildBaseline> baseline = ref.watch(
      baselineProvider(childId),
    );

    return baseline.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => ErrorBanner(
        message: e is ApiException ? e.detailedMessage : e.toString(),
      ),
      data: (ChildBaseline data) => Column(
        children: <Widget>[
          _Panel(
            title: 'Allergies',
            icon: Icons.gpp_maybe_rounded,
            iconColor: AppColors.danger,
            action: IconButton(
              onPressed: () => _add(context, ref, 'allergy'),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.danger,
              ),
            ),
            child: data.allergies.isEmpty
                ? _empty(context, 'No known allergies')
                : Column(
                    children: <Widget>[
                      for (final Allergy a in data.allergies)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  Text(
                                    a.allergen,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  _severityPill(a.severity),
                                ],
                              ),
                              if (a.notes != null &&
                                  (a.notes ?? '').isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(
                                  a.notes ?? '',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Medications',
            icon: Icons.medication_rounded,
            iconColor: AppColors.primary500,
            action: IconButton(
              onPressed: () => _add(context, ref, 'medication'),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.primary500,
              ),
            ),
            child: data.medications.isEmpty
                ? _empty(context, 'No active medications')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final Medication m in data.medications)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                m.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                              Text(
                                m.dosage,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _Panel(
            title: 'Past Illnesses',
            icon: Icons.monitor_heart_rounded,
            iconColor: AppColors.warning,
            action: IconButton(
              onPressed: () => _add(context, ref, 'illness'),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.warning,
              ),
            ),
            child: data.illnesses.isEmpty
                ? _empty(context, 'Clean history')
                : Column(
                    children: <Widget>[
                      for (final IllnessHistory i in data.illnesses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      i.illnessName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Fmt.date(i.diagnosisDate),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              if (i.notes != null &&
                                  (i.notes ?? '').isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(
                                  i.notes ?? '',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontStyle: FontStyle.italic,
      color: context.palette.textSecondary,
    ),
  );

  Widget _severityPill(String severity) {
    late final Color bg;
    late final Color fg;
    switch (severity) {
      case 'Severe':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
      case 'Moderate':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
      default:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: fg,
        ),
      ),
    );
  }
}

/// "Add allergy" / "Add medication" / "Add illness" — the web's second modal.
class _RecordForm extends ConsumerStatefulWidget {
  const _RecordForm({required this.childId, required this.type});

  final String childId;
  final String type;

  @override
  ConsumerState<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends ConsumerState<_RecordForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _a = TextEditingController();
  final TextEditingController _b = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  String _severity = 'Mild';
  DateTime _date = DateTime.now();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final HealthRecordRepository repo = ref.read(
        healthRecordRepositoryProvider,
      );
      switch (widget.type) {
        case 'allergy':
          await repo.addAllergy(
            childId: widget.childId,
            allergen: _a.text.trim(),
            severity: _severity,
            notes: _notes.text.trim(),
          );
        case 'medication':
          await repo.addMedication(
            childId: widget.childId,
            name: _a.text.trim(),
            dosage: _b.text.trim(),
            startDate: DateTime.now(),
          );
        case 'illness':
          await repo.addIllness(
            childId: widget.childId,
            illnessName: _a.text.trim(),
            diagnosisDate: _date,
            notes: _notes.text.trim(),
          );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isAllergy = widget.type == 'allergy';
    final bool isMedication = widget.type == 'medication';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Add ${widget.type}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _a,
                      decoration: InputDecoration(
                        labelText: isAllergy
                            ? 'Allergen'
                            : isMedication
                            ? 'Medication Name'
                            : 'Illness Name',
                      ),
                      validator: (String? v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    if (isAllergy)
                      DropdownButtonFormField<String>(
                        initialValue: _severity,
                        decoration: const InputDecoration(
                          labelText: 'Severity',
                        ),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: 'Mild',
                            child: Text('Mild'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Moderate',
                            child: Text('Moderate'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Severe',
                            child: Text('Severe'),
                          ),
                        ],
                        onChanged: (String? v) =>
                            setState(() => _severity = v ?? 'Mild'),
                      ),
                    if (isMedication)
                      TextFormField(
                        controller: _b,
                        decoration: const InputDecoration(
                          labelText: 'Dosage Details',
                          hintText: 'e.g. 5ml twice daily',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    if (widget.type == 'illness')
                      OutlinedButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        icon: const Icon(Icons.event_rounded, size: 16),
                        label: Text('Date Diagnosed — ${Fmt.date(_date)}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    if (!isMedication) ...<Widget>[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                        ),
                      ),
                    ],
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 14),
                      ErrorBanner(message: _error ?? ''),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            child: const Text('Discard'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Submit'),
                          ),
                        ),
                      ],
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

// ── Appointment History ──────────────────────────────────────────────────────

class _AppointmentHistory extends ConsumerWidget {
  const _AppointmentHistory({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<List<Appointment>> schedule = ref.watch(
      myScheduleProvider,
    );

    return _Panel(
      title: 'Appointment History',
      icon: Icons.place_rounded,
      iconColor: const Color(0xFFF59E0B),
      accent: const Color(0xFFF59E0B),
      child: schedule.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (Object e, StackTrace _) => Text(
          e is ApiException ? e.detailedMessage : 'Could not load history.',
          style: TextStyle(fontSize: 12, color: palette.textMuted),
        ),
        data: (List<Appointment> all) {
          final List<Appointment> mine = all
              .where((Appointment a) => a.childId == childId)
              .take(5)
              .toList();
          if (mine.isEmpty) {
            return Text(
              'No past appointments recorded.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: palette.textSecondary,
              ),
            );
          }
          return Column(
            children: <Widget>[
              for (final Appointment a in mine)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 17,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Dr. ${a.doctor?.firstName ?? ''} '
                                      '${a.doctor?.lastName ?? ''}'
                                  .trim(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (a.reason == null || (a.reason ?? '').isEmpty)
                                  ? 'General Consultation'
                                  : a.reason ?? '',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            Fmt.date(a.scheduledAt),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _statusPill(a.status),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusPill(AppointmentStatus status) {
    late final Color bg;
    late final Color fg;
    switch (status) {
      case AppointmentStatus.completed:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
      case AppointmentStatus.confirmed:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.wire,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.9,
          color: fg,
        ),
      ),
    );
  }
}

// ── Doctor's Notes ───────────────────────────────────────────────────────────

class _DoctorNotes extends ConsumerWidget {
  const _DoctorNotes({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<List<ConsultationNote>> notes = ref.watch(
      consultationsProvider(childId),
    );

    return _Panel(
      title: "Doctor's Notes & Prescriptions",
      icon: Icons.description_rounded,
      iconColor: AppColors.primary600,
      accent: AppColors.primary600,
      child: notes.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (Object e, StackTrace _) => Text(
          e is ApiException ? e.detailedMessage : 'Could not load notes.',
          style: TextStyle(fontSize: 12, color: palette.textMuted),
        ),
        data: (List<ConsultationNote> list) {
          if (list.isEmpty) {
            return Text(
              'No formal doctor notes recorded yet.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: palette.textSecondary,
              ),
            );
          }
          return Column(
            children: <Widget>[
              for (final ConsultationNote n in list)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          InitialsAvatar(
                            initials:
                                (n.doctorLastName == null ||
                                    (n.doctorLastName ?? '').isEmpty)
                                ? 'D'
                                : (n.doctorLastName ?? '')
                                      .substring(0, 1)
                                      .toUpperCase(),
                            size: 38,
                            color: AppColors.primary600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dr. ${n.doctorLastName ?? ''}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            Fmt.dateTime(n.createdAt),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 20, color: palette.border),
                      Text(
                        n.notes,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (n.treatmentPlan != null &&
                          (n.treatmentPlan ?? '').isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.medication_rounded,
                              size: 12,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'TREATMENT PROTOCOL',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                color: AppColors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            n.treatmentPlan ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Shared card shell ────────────────────────────────────────────────────────

/// The web's Card: tinted header strip with an icon, optional action on the
/// right, and optionally a coloured left edge (`border-l-4`).
class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
    this.action,
    this.accent,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final Widget? action;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    // The web marks two of these cards with `border-l-4`. Flutter refuses to
    // paint a border of uneven widths together with a corner radius, so the
    // accent is the parent's background showing through a 4px left inset.
    return Container(
      decoration: BoxDecoration(
        color: accent ?? palette.surface,
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.sm,
      ),
      padding: EdgeInsets.only(left: accent == null ? 0 : 4),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.border),
          borderRadius: accent == null
              ? AppRadius.mdAll
              : const BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.md),
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(
                      icon,
                      size: 18,
                      color: iconColor ?? palette.textPrimary,
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  if (action != null) action ?? const SizedBox.shrink(),
                  if (action == null) const SizedBox(width: 8),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }
}

/// `calcAge` in ChildProfile.jsx — whole years once past the first birthday,
/// otherwise "N month(s)".
String _calcAge(DateTime? dob) {
  if (dob == null) return 'N/A';
  final DateTime now = DateTime.now();
  final int years = now.year - dob.year;
  final int months = now.month - dob.month;
  if (years == 0) return '${months < 0 ? 0 : months} month(s)';
  return '$years year${years != 1 ? 's' : ''}';
}
