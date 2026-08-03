import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/doctor.dart';
import '../../../data/models/facility.dart';
import '../../providers/providers.dart';
import 'admin_widgets.dart';

/// Port of `frontend/src/pages/admin/AdminDoctors.jsx` — "Doctor Registry
/// (DOC Register)": the blue→indigo hero, the search field with the
/// Active / Pending / Rejected count pills, and the registry rows with their
/// Approve / Reject controls.
class AdminDoctorsScreen extends ConsumerStatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  ConsumerState<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends ConsumerState<AdminDoctorsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setStatus(Doctor doctor, String status) async {
    try {
      await ref
          .read(doctorRepositoryProvider)
          .update(id: doctor.id, verificationStatus: status);
      ref.invalidate(doctorRegistryProvider);
      ref.invalidate(bookableDoctorsProvider);
      if (mounted) {
        Toast.success(
          context,
          status == 'ACTIVE' ? 'Doctor approved' : 'Doctor rejected',
        );
      }
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    }
  }

  Future<void> _delete(Doctor doctor) async {
    final bool ok = await confirmAction(
      context,
      title: 'Archive doctor',
      message:
          'Archiving ${doctor.displayName} also cancels their pending and '
          'confirmed appointments.',
      confirmLabel: 'Archive',
    );
    if (!ok) return;
    try {
      await ref.read(doctorRepositoryProvider).archive(doctor.id);
      ref.invalidate(doctorRegistryProvider);
      if (mounted) Toast.success(context, 'Doctor archived');
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    }
  }

  Future<void> _openForm({Doctor? doctor}) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _DoctorFormSheet(doctor: doctor),
    );
    if (saved == true) {
      ref.invalidate(doctorRegistryProvider);
      ref.invalidate(bookableDoctorsProvider);
      if (mounted) {
        Toast.success(
          context,
          doctor == null ? 'Doctor registered' : 'Doctor updated',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Doctor>> doctors = ref.watch(doctorRegistryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Registry')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(doctorRegistryProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            AdminHero(
              icon: Icons.medical_services_rounded,
              iconColor: const Color(0xFF5EEAD4),
              title: 'Doctor Registry (DOC Register)',
              subtitle:
                  'Manage clinical profiles, licensure, specializations, '
                  'qualifications and verification status.',
              actionLabel: 'Register Doctor',
              actionForeground: const Color(0xFF1E40AF),
              gradient: const <Color>[Color(0xFF1E40AF), Color(0xFF312E81)],
              onAction: _openForm,
            ),
            const SizedBox(height: 16),

            AdminSearchField(
              hintText: 'Search by name or specialization...',
              controller: _search,
              onChanged: (String v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),

            doctors.maybeWhen(
              data: (List<Doctor> items) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  AdminCountPill(
                    icon: Icons.check_circle_rounded,
                    label: 'Active',
                    color: const Color(0xFF059669),
                    count: items
                        .where((Doctor d) => _statusOf(d) == 'ACTIVE')
                        .length,
                  ),
                  AdminCountPill(
                    icon: Icons.schedule_rounded,
                    label: 'Pending',
                    color: AppColors.warning,
                    count: items
                        .where((Doctor d) => _statusOf(d) == 'PENDING')
                        .length,
                  ),
                  AdminCountPill(
                    icon: Icons.cancel_rounded,
                    label: 'Rejected',
                    color: AppColors.danger,
                    count: items
                        .where((Doctor d) => _statusOf(d) == 'REJECTED')
                        .length,
                  ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            AdminTableCard(
              header: 'Doctor · Specialty · Facility · Verification',
              child: doctors.when(
                loading: () => const AdminTableMessage(
                  text: 'Syncing Medical Database...',
                ),
                error: (Object error, StackTrace _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorBanner(
                    message: error is ApiException
                        ? error.detailedMessage
                        : error.toString(),
                  ),
                ),
                data: (List<Doctor> items) {
                  final List<Doctor> shown = _query.isEmpty
                      ? items
                      : items
                            .where(
                              (Doctor d) =>
                                  d.fullName.toLowerCase().contains(_query) ||
                                  d.specialization.toLowerCase().contains(
                                    _query,
                                  ),
                            )
                            .toList();

                  if (shown.isEmpty) {
                    return const AdminTableMessage(text: 'No Profiles Found');
                  }

                  return Column(
                    children: <Widget>[
                      for (int i = 0; i < shown.length; i++)
                        AdminTableRow(
                          last: i == shown.length - 1,
                          child: _DoctorRow(
                            doctor: shown[i],
                            onApprove: () => _setStatus(shown[i], 'ACTIVE'),
                            onReject: () => _setStatus(shown[i], 'REJECTED'),
                            onEdit: () => _openForm(doctor: shown[i]),
                            onDelete: () => _delete(shown[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusOf(Doctor d) {
    final String s = d.verificationStatus.toUpperCase();
    return s.isEmpty ? 'PENDING' : s;
  }
}

class _DoctorRow extends StatelessWidget {
  const _DoctorRow({
    required this.doctor,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
  });

  final Doctor doctor;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String status = _AdminDoctorsScreenState._statusOf(doctor);

    final (Color color, IconData icon, String label) = switch (status) {
      'ACTIVE' => (
        const Color(0xFF059669),
        Icons.check_circle_rounded,
        'Active',
      ),
      'REJECTED' => (AppColors.danger, Icons.cancel_rounded, 'Rejected'),
      _ => (AppColors.warning, Icons.schedule_rounded, 'Pending'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Doctor identity
        Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary600,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary200.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                doctor.firstName.isEmpty
                    ? 'D'
                    : doctor.firstName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    doctor.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${doctor.id.length >= 8 ? doctor.id.substring(0, 8).toUpperCase() : doctor.id}...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Specialty chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            doctor.specialization.isEmpty ? 'General' : doctor.specialization,
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Facility / licence
        Text(
          doctor.facilityName ?? 'Unassigned',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontStyle: doctor.facilityName == null
                ? FontStyle.italic
                : FontStyle.normal,
            color: doctor.facilityName == null
                ? palette.textMuted
                : palette.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: <Widget>[
            Icon(
              Icons.description_outlined,
              size: 11,
              color: palette.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              doctor.licenseNumber,
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Verification + actions
        Row(
          children: <Widget>[
            AdminStatusChip(label: label, color: color, icon: icon),
            const Spacer(),
            AdminIconAction(
              icon: Icons.edit_rounded,
              color: AppColors.primary500,
              tooltip: 'Edit',
              onTap: onEdit,
            ),
            const SizedBox(width: 8),
            AdminIconAction(
              icon: Icons.delete_outline_rounded,
              color: AppColors.danger,
              tooltip: 'Archive',
              onTap: onDelete,
            ),
          ],
        ),
        if (status == 'PENDING') ...<Widget>[
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              AdminMiniButton(
                label: 'Approve',
                color: const Color(0xFF059669),
                onTap: onApprove,
              ),
              const SizedBox(width: 8),
              AdminMiniButton(
                label: 'Reject',
                color: AppColors.danger,
                onTap: onReject,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Register / edit doctor — `POST /doctors` and `PUT /doctors/:id`.
class _DoctorFormSheet extends ConsumerStatefulWidget {
  const _DoctorFormSheet({this.doctor});

  final Doctor? doctor;

  @override
  ConsumerState<_DoctorFormSheet> createState() => _DoctorFormSheetState();
}

class _DoctorFormSheetState extends ConsumerState<_DoctorFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _first = TextEditingController(
    text: widget.doctor?.firstName ?? '',
  );
  late final TextEditingController _last = TextEditingController(
    text: widget.doctor?.lastName ?? '',
  );
  late final TextEditingController _specialization = TextEditingController(
    text: widget.doctor?.specialization ?? '',
  );
  late final TextEditingController _license = TextEditingController(
    text: widget.doctor?.licenseNumber ?? '',
  );
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String? _facilityId;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.doctor != null;

  @override
  void initState() {
    super.initState();
    _facilityId = widget.doctor?.facilityId;
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _specialization.dispose();
    _license.dispose();
    _phone.dispose();
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
      final Doctor? existing = widget.doctor;
      if (existing == null) {
        await ref
            .read(doctorRepositoryProvider)
            .create(
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              specialization: _specialization.text.trim(),
              licenseNumber: _license.text.trim(),
              phoneNumber: _phone.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
              facilityId: _facilityId,
            );
      } else {
        await ref
            .read(doctorRepositoryProvider)
            .update(
              id: existing.id,
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              specialization: _specialization.text.trim(),
              licenseNumber: _license.text.trim(),
              phoneNumber: _phone.text.trim(),
              facilityId: _facilityId ?? '',
            );
      }
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
    final AsyncValue<List<Facility>> facilities = ref.watch(facilitiesProvider);

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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF1E40AF), Color(0xFF312E81)],
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Doctor' : 'Register Doctor',
                      style: const TextStyle(
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
                          child: TextFormField(
                            controller: _first,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                            ),
                            validator: (String? v) =>
                                Validators.required(v, 'First name'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _last,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                            ),
                            validator: (String? v) =>
                                Validators.required(v, 'Last name'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _specialization,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                        hintText: 'e.g. Pediatric Pulmonology',
                      ),
                      validator: (String? v) =>
                          Validators.required(v, 'Specialization'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _license,
                      decoration: const InputDecoration(
                        labelText: 'License Number',
                        helperText: 'Must be unique across the platform',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (optional)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    facilities.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (Object error, StackTrace _) =>
                          const SizedBox.shrink(),
                      data: (List<Facility> items) =>
                          DropdownButtonFormField<String>(
                            initialValue: _facilityId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Facility',
                            ),
                            items: <DropdownMenuItem<String>>[
                              const DropdownMenuItem<String>(
                                child: Text('Unassigned'),
                              ),
                              ...items.map(
                                (Facility f) => DropdownMenuItem<String>(
                                  value: f.id,
                                  child: Text(
                                    f.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (String? v) =>
                                setState(() => _facilityId = v),
                          ),
                    ),
                    if (!_isEdit) ...<Widget>[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Login Email (optional)',
                          helperText:
                              'Creates a login that stays inactive until approved',
                        ),
                        validator: (String? value) {
                          if ((value ?? '').trim().isEmpty) return null;
                          return Validators.email(value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Temporary Password',
                        ),
                        validator: (String? value) {
                          if (_email.text.trim().isEmpty) return null;
                          return Validators.strongPassword(value);
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isEdit ? 'Save Changes' : 'Register Doctor',
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
