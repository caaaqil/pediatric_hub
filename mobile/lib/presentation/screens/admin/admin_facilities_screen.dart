import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/doctor.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/facility.dart';
import '../../providers/providers.dart';
import 'admin_widgets.dart';

/// Port of `frontend/src/pages/admin/AdminFacilities.jsx` — the emerald hero,
/// the four summary tiles, the search field and the facility rows with their
/// linked-doctor count.
class AdminFacilitiesScreen extends ConsumerStatefulWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  ConsumerState<AdminFacilitiesScreen> createState() =>
      _AdminFacilitiesScreenState();
}

class _AdminFacilitiesScreenState extends ConsumerState<AdminFacilitiesScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({Facility? facility}) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _FacilityFormSheet(facility: facility),
    );
    if (saved == true) {
      ref.invalidate(facilitiesProvider);
      if (mounted) {
        Toast.success(
          context,
          facility == null ? 'Facility added' : 'Facility updated',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Facility>> facilities = ref.watch(facilitiesProvider);
    final AsyncValue<List<Doctor>> doctors = ref.watch(doctorRegistryProvider);

    final List<Doctor> allDoctors = doctors.maybeWhen(
      data: (List<Doctor> d) => d,
      orElse: () => <Doctor>[],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Facility Registry')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(doctorRegistryProvider);
          ref.invalidate(facilitiesProvider);
          await ref.read(facilitiesProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            AdminHero(
              icon: Icons.apartment_rounded,
              iconColor: const Color(0xFF5EEAD4),
              title: 'Facility Registry',
              subtitle:
                  'Manage clinics, hospitals, health centers — link doctors '
                  'and monitor patient flow.',
              actionLabel: 'Add Facility',
              actionForeground: const Color(0xFF065F46),
              gradient: const <Color>[Color(0xFF065F46), Color(0xFF064E3B)],
              onAction: _openForm,
            ),
            const SizedBox(height: 16),

            facilities.maybeWhen(
              data: (List<Facility> items) {
                final int active = items
                    .where((Facility f) => f.isActive)
                    .length;
                final int inactive = items.length - active;
                return Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AdminSummaryTile(
                            label: 'Active Facilities',
                            value: '$active',
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminSummaryTile(
                            label: 'Inactive Facilities',
                            value: '$inactive',
                            color: context.palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AdminSummaryTile(
                            label: 'Pending Facilities',
                            // The schema has no pending state — only isActive —
                            // so this mirrors the web, which also always shows 0.
                            value: '0',
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminSummaryTile(
                            label: 'Total Doctors',
                            value: '${allDoctors.length}',
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            AdminSearchField(
              hintText: 'Search by facility name...',
              controller: _search,
              focusColor: const Color(0xFF059669),
              onChanged: (String v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 16),

            AdminTableCard(
              header: 'Facility · Type · Contact · Doctors · Status',
              child: facilities.when(
                loading: () => const AdminTableMessage(
                  text: 'Syncing Facility Database...',
                ),
                error: (Object error, StackTrace _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorBanner(
                    message: error is ApiException
                        ? error.detailedMessage
                        : error.toString(),
                  ),
                ),
                data: (List<Facility> items) {
                  final List<Facility> shown = _query.isEmpty
                      ? items
                      : items
                            .where(
                              (Facility f) =>
                                  f.name.toLowerCase().contains(_query),
                            )
                            .toList();

                  if (shown.isEmpty) {
                    return const AdminTableMessage(text: 'No Facilities Found');
                  }

                  return Column(
                    children: <Widget>[
                      for (int i = 0; i < shown.length; i++)
                        AdminTableRow(
                          last: i == shown.length - 1,
                          child: _FacilityRow(
                            facility: shown[i],
                            linkedDoctors: allDoctors
                                .where(
                                  (Doctor d) => d.facilityId == shown[i].id,
                                )
                                .length,
                            onEdit: () => _openForm(facility: shown[i]),
                            onDelete: () async {
                              final bool ok = await confirmAction(
                                context,
                                title: 'Archive facility',
                                message: 'Archive "${shown[i].name}"?',
                                confirmLabel: 'Archive',
                              );
                              if (!ok || !context.mounted) return;
                              try {
                                await ref
                                    .read(apiClientProvider)
                                    .deleteData('/facilities/${shown[i].id}');
                                ref.invalidate(facilitiesProvider);
                                if (context.mounted) {
                                  Toast.success(context, 'Facility archived');
                                }
                              } on ApiException catch (error) {
                                if (context.mounted) {
                                  Toast.error(context, error);
                                }
                              }
                            },
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
}

class _FacilityRow extends StatelessWidget {
  const _FacilityRow({
    required this.facility,
    required this.linkedDoctors,
    required this.onEdit,
    required this.onDelete,
  });

  final Facility facility;
  final int linkedDoctors;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isHospital = facility.facilityType == FacilityType.hospital;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                facility.name.isEmpty
                    ? 'F'
                    : facility.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    facility.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_outlined,
                        size: 10,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          facility.address.isEmpty
                              ? 'No address'
                              : facility.address.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            AdminStatusChip(
              label: facility.facilityType.label,
              color: isHospital
                  ? const Color(0xFF6366F1)
                  : AppColors.primary600,
            ),
            AdminStatusChip(
              label: facility.isActive ? 'Active' : 'Inactive',
              color: facility.isActive
                  ? const Color(0xFF059669)
                  : palette.textMuted,
              icon: facility.isActive
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Icon(Icons.phone_outlined, size: 12, color: palette.textMuted),
            const SizedBox(width: 6),
            Text(
              facility.phoneNumber.isEmpty ? 'N/A' : facility.phoneNumber,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Icon(
              Icons.mail_outline_rounded,
              size: 11,
              color: palette.textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                facility.email ?? 'N/A',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Text(
              '$linkedDoctors Doctor${linkedDoctors == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            AdminIconAction(
              icon: Icons.edit_rounded,
              color: const Color(0xFF059669),
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
      ],
    );
  }
}

/// `POST /facilities` and `PUT /facilities/:id`.
class _FacilityFormSheet extends ConsumerStatefulWidget {
  const _FacilityFormSheet({this.facility});

  final Facility? facility;

  @override
  ConsumerState<_FacilityFormSheet> createState() => _FacilityFormSheetState();
}

class _FacilityFormSheetState extends ConsumerState<_FacilityFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.facility?.name ?? '',
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.facility?.address ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.facility?.phoneNumber ?? '',
  );
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  late FacilityType _type =
      widget.facility?.facilityType ?? FacilityType.clinic;
  late bool _active = widget.facility?.isActive ?? true;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.facility != null;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
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
      final Facility? existing = widget.facility;
      if (existing == null) {
        final Map<String, dynamic> body = <String, dynamic>{
          'name': _name.text.trim(),
          'address': _address.text.trim(),
          'phoneNumber': _phone.text.trim(),
          'facilityType': _type.wire,
          'isActive': _active,
        };
        if (_email.text.trim().isNotEmpty) {
          body['email'] = _email.text.trim();
          body['password'] = _password.text;
        }
        await ref.read(apiClientProvider).postData('/facilities', body: body);
      } else {
        await ref
            .read(facilityRepositoryProvider)
            .update(
              id: existing.id,
              name: _name.text.trim(),
              address: _address.text.trim(),
              phoneNumber: _phone.text.trim(),
              facilityType: _type.wire,
              isActive: _active,
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
                  colors: <Color>[Color(0xFF0F766E), Color(0xFF047857)],
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.apartment_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Facility' : 'Add Facility',
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
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Facility Name',
                      ),
                      validator: (String? v) =>
                          Validators.required(v, 'Facility name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (String? v) =>
                          Validators.required(v, 'Address'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                      validator: (String? v) =>
                          Validators.required(v, 'Phone number'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<FacilityType>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: FacilityType.values
                          .map(
                            (FacilityType t) => DropdownMenuItem<FacilityType>(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: (FacilityType? v) {
                        if (v != null) setState(() => _type = v);
                      },
                    ),
                    if (!_isEdit) ...<Widget>[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Login Email (optional)',
                          helperText: 'Creates the facility portal account',
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
                    const SizedBox(height: 6),
                    SwitchListTile.adaptive(
                      value: _active,
                      onChanged: (bool v) => setState(() => _active = v),
                      title: const Text('Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: _isEdit ? 'Save Changes' : 'Add Facility',
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
