import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/child.dart';
import '../../../data/models/doctor.dart';
import '../../providers/providers.dart';

/// `POST /appointments` — child + doctor + slot.
///
/// The backend rejects a taken slot with 409, which is surfaced inline.
class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key, this.presetDoctorId});

  final String? presetDoctorId;

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final TextEditingController _reason = TextEditingController();

  Child? _child;
  Doctor? _doctor;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _slot;
  bool _busy = false;
  bool _presetApplied = false;
  String? _error;

  /// Same 09:00–16:00 half-hour grid the web booking flow offers.
  static final List<String> _slots = <String>[
    for (int hour = 9; hour <= 16; hour++) ...<String>[
      '${hour.toString().padLeft(2, '0')}:00',
      if (hour != 16) '${hour.toString().padLeft(2, '0')}:30',
    ],
  ];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _book() async {
    final Child? child = _child;
    final Doctor? doctor = _doctor;
    final String? slot = _slot;

    if (child == null) {
      setState(() => _error = 'Choose which child this appointment is for.');
      return;
    }
    if (doctor == null) {
      setState(() => _error = 'Choose a doctor.');
      return;
    }
    if (slot == null) {
      setState(() => _error = 'Choose a time slot.');
      return;
    }

    final List<String> parts = slot.split(':');
    final DateTime scheduledAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      int.tryParse(parts.first) ?? 9,
      parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(appointmentRepositoryProvider)
          .book(
            childId: child.id,
            doctorId: doctor.id,
            scheduledAt: scheduledAt,
            reason: _reason.text.trim(),
          );
      ref.invalidate(myScheduleProvider);
      ref.invalidate(dashboardTelemetryProvider);

      if (!mounted) return;
      Toast.success(context, 'Appointment requested');
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.isConflict
            ? 'That slot was just taken. Please choose another time.'
            : error.detailedMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Child>> children = ref.watch(myChildrenProvider);
    final AsyncValue<List<Doctor>> doctors = ref.watch(bookableDoctorsProvider);

    // Apply ?doctorId= coming from the doctor profile screen.
    final String? preset = widget.presetDoctorId;
    if (!_presetApplied && preset != null) {
      doctors.whenData((List<Doctor> items) {
        for (final Doctor d in items) {
          if (d.id == preset) {
            _presetApplied = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _doctor = d);
            });
            break;
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pageBottom,
          children: <Widget>[
            if (_error != null) ...<Widget>[
              ErrorBanner(message: _error ?? ''),
              const SizedBox(height: AppSpacing.lg),
            ],

            const SectionHeader(title: '1 · Which child?'),
            children.when(
              loading: () => const SizedBox(height: 72, child: LoadingView()),
              error: (Object error, StackTrace _) => AppCard(
                child: Text(
                  error is ApiException
                      ? error.detailedMessage
                      : 'Could not load your children.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              data: (List<Child> items) {
                if (items.isEmpty) {
                  return AppCard(
                    onTap: () => context.push(Routes.childNew),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppColors.primary600,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Register a child before booking.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: items.map((Child child) {
                    final bool selected = _child?.id == child.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        onTap: () => setState(() => _child = child),
                        borderColor: selected ? AppColors.primary600 : null,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: selected
                                  ? AppColors.primary600
                                  : context.palette.textMuted,
                              size: 20,
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
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(
                                    child.ageLabel,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: '2 · Which doctor?'),
            doctors.when(
              loading: () => const SizedBox(height: 72, child: LoadingView()),
              error: (Object error, StackTrace _) => AppCard(
                child: Text(
                  error is ApiException
                      ? error.detailedMessage
                      : 'Could not load doctors.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              data: (List<Doctor> items) {
                if (items.isEmpty) {
                  return AppCard(
                    child: Text(
                      'No doctors are registered yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return DropdownButtonFormField<Doctor>(
                  initialValue: _doctor,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Doctor',
                    prefixIcon: Icon(Icons.medical_services_outlined, size: 20),
                  ),
                  items: items
                      .map(
                        (Doctor doctor) => DropdownMenuItem<Doctor>(
                          value: doctor,
                          child: Text(
                            '${doctor.displayName} · ${doctor.specialization}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (Doctor? value) => setState(() => _doctor = value),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: '3 · When?'),
            InkWell(
              onTap: _pickDate,
              borderRadius: AppRadius.smAll,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                ),
                child: Text(Fmt.weekday(_date)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _slots.map((String slot) {
                return ChoiceChip(
                  label: Text(slot),
                  selected: _slot == slot,
                  onSelected: (_) => setState(() => _slot = slot),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: '4 · Reason (optional)'),
            TextField(
              controller: _reason,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the symptoms or purpose of the visit',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            PrimaryButton(
              label: 'Request appointment',
              icon: Icons.event_available_rounded,
              isLoading: _busy,
              onPressed: _book,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Requests start as PENDING until the doctor or facility confirms '
              'them. Payments are handled separately from the Payments screen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
