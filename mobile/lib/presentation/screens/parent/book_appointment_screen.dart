import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../data/models/child.dart';
import '../../../data/models/doctor.dart';
import '../../../data/models/facility.dart';
import '../../../data/models/misc.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/dashboard/BookingFlow.jsx`.
///
/// The web flow is four steps — pay the consultation fee, choose a doctor,
/// choose a child, then pick a slot — with a booking summary beside the last
/// step. A phone has no room for a sidebar, so the summary sits underneath the
/// slot picker; everything else follows the web screen step for step.
class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key, this.presetDoctorId});

  final String? presetDoctorId;

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

/// `CONSULTATION_FEE` in BookingFlow.jsx.
const double _consultationFee = 0.01;

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  final TextEditingController _search = TextEditingController();

  int _step = 0;
  Doctor? _doctor;
  Child? _child;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _slot;
  String _searchTerm = '';

  bool _paying = false;
  String? _payError;
  Payment? _paid;
  String _paidNumber = '';

  bool _booking = false;
  String? _bookError;
  bool _success = false;

  bool _presetApplied = false;

  /// 09:00–16:00 on the half hour, with no 16:30 — the same grid as the web.
  static final List<String> _slots = <String>[
    for (int hour = 9; hour <= 16; hour++) ...<String>[
      '${hour.toString().padLeft(2, '0')}:00',
      if (hour != 16) '${hour.toString().padLeft(2, '0')}:30',
    ],
  ];

  List<String> get _morning =>
      _slots.where((String t) => int.parse(t.split(':').first) < 12).toList();
  List<String> get _afternoon =>
      _slots.where((String t) => int.parse(t.split(':').first) >= 12).toList();

  @override
  void dispose() {
    _phone.dispose();
    _reason.dispose();
    _search.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pay() async {
    final String cleaned = _phone.text.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) {
      setState(() => _payError = 'Please enter your EVC Plus phone number.');
      return;
    }
    // Same rule as the web form: 252XXXXXXXX or 0XXXXXXXX.
    if (!RegExp(r'^(252|0)\d{8,9}$').hasMatch(cleaned)) {
      setState(
        () => _payError =
            'Enter a valid Somali phone number (e.g. 2526XXXXXXXX or 06XXXXXXXX).',
      );
      return;
    }

    setState(() {
      _paying = true;
      _payError = null;
    });

    try {
      final PaymentResult result = await ref
          .read(supportRepositoryProvider)
          .pay(
            accountNo: cleaned,
            amount: _consultationFee,
            description: 'Pediatric Health Hub — Teleconsultation Fee',
          );
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _paid = result.payment;
          _paidNumber = cleaned;
          // A doctor arriving from their profile page skips straight to the
          // child step, exactly as the web flow does when one is preselected.
          _step = _doctor == null ? 1 : 2;
        });
      } else {
        setState(
          () => _payError =
              result.message ??
              'Payment was declined. Please check your EVC Plus balance and try again.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _payError = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _book() async {
    final Child? child = _child;
    final Doctor? doctor = _doctor;
    final String? slot = _slot;
    if (child == null || doctor == null || slot == null) {
      setState(() => _bookError = 'Please select a date and time slot.');
      return;
    }

    setState(() {
      _booking = true;
      _bookError = null;
    });

    final List<String> parts = slot.split(':');
    final DateTime scheduledAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      int.parse(parts.first),
      int.parse(parts.last),
    );

    try {
      await ref
          .read(appointmentRepositoryProvider)
          .book(
            childId: child.id,
            doctorId: doctor.id,
            scheduledAt: scheduledAt,
            reason: _reason.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(myScheduleProvider);
      setState(() => _success = true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _bookError = error.statusCode == 409
            ? 'This slot was just taken. Please choose another.'
            : 'Failed to book. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _reset() {
    setState(() {
      _success = false;
      _step = 0;
      _doctor = null;
      _child = null;
      _slot = null;
      _paid = null;
      _payError = null;
      _bookError = null;
      _paidNumber = '';
      _presetApplied = false;
      _phone.clear();
      _reason.clear();
      _search.clear();
      _searchTerm = '';
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_success) return _SuccessView(state: this);

    final AsyncValue<List<Doctor>> doctors = ref.watch(bookableDoctorsProvider);

    // Preselect the doctor a profile page sent us to, once the list arrives.
    final String? preset = widget.presetDoctorId;
    if (!_presetApplied && preset != null) {
      doctors.whenData((List<Doctor> list) {
        for (final Doctor d in list) {
          if (d.id == preset) {
            _presetApplied = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _doctor == null) setState(() => _doctor = d);
            });
            break;
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: <Widget>[
          _hero(doctors.valueOrNull?.length),
          const SizedBox(height: 16),
          _stepper(),
          const SizedBox(height: 16),
          if (_step == 0) _paymentStep(),
          if (_step == 1) _doctorStep(doctors),
          if (_step == 2) _childStep(),
          if (_step == 3) ...<Widget>[_timeStep(), const SizedBox(height: 16), _summary()],
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _hero(int? doctorCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Color(0xFF1E3A8A), AppColors.primary700],
        ),
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.videocam_rounded, size: 12, color: Color(0xFF7DD3FC)),
                SizedBox(width: 6),
                Text(
                  'TELECONSULTATION BOOKING',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Book an Appointment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect your child with a certified pediatrician in 4 easy '
            'steps. Secure, private, and professional.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _heroStat(doctorCount?.toString() ?? '—', 'DOCTORS'),
              const SizedBox(width: 10),
              _heroStat('24/7', 'ACCESS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step progress bar ─────────────────────────────────────────────────────

  Widget _stepper() {
    const List<(String, IconData)> steps = <(String, IconData)>[
      ('Payment', Icons.credit_card_rounded),
      ('Choose Doctor', Icons.medical_services_rounded),
      ('Select Child', Icons.child_care_rounded),
      ('Pick a Time', Icons.schedule_rounded),
    ];
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < steps.length; i++) ...<Widget>[
            SizedBox(
              width: 62,
              child: Column(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _step > i
                          ? _emerald500
                          : _step == i
                          ? AppColors.primary600
                          : palette.surfaceSoft,
                      border: _step < i
                          ? Border.all(color: palette.border, width: 2)
                          : null,
                    ),
                    child: Icon(
                      _step > i ? Icons.check_rounded : steps[i].$2,
                      size: 17,
                      color: _step >= i ? Colors.white : palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[i].$1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: _step == i
                          ? AppColors.primary600
                          : _step > i
                          ? _emerald600
                          : palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: _step > i ? _emerald500 : palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Step 0 — Payment ──────────────────────────────────────────────────────

  Widget _paymentStep() {
    final AppPalette palette = context.palette;

    return _Panel(
      title: 'Consultation Fee Payment',
      subtitle: 'Pay via EVC Plus (WaafiPay) to unlock appointment booking',
      icon: Icons.account_balance_wallet_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Fee summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.primary600.withValues(alpha: 0.07),
                  const Color(0xFF6366F1).withValues(alpha: 0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary600.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Teleconsultation Fee',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      '\$${_consultationFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _bullet('30-minute video consultation'),
                _bullet('Certified pediatric specialist'),
                _bullet('Digital prescription if needed'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _label(Icons.phone_rounded, 'EVC PLUS PHONE NUMBER'),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            // Rebuilds on every keystroke: the Pay button's enabled state is
            // derived from this field, so without it the button would stay
            // greyed out after the number is typed.
            onChanged: (_) => setState(() => _payError = null),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'e.g. 2526XXXXXXXX',
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Text('🇸🇴', style: TextStyle(fontSize: 16)),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 0),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your EVC Plus / Hormuud registered number',
            style: TextStyle(fontSize: 10, color: palette.textMuted),
          ),

          if (_payError != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_payError ?? ''),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _paying || _phone.text.trim().isEmpty ? null : _pay,
              icon: _paying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.credit_card_rounded, size: 18),
              label: Text(
                _paying
                    ? 'Processing — check your EVC Plus app...'
                    : 'Pay \$${_consultationFee.toStringAsFixed(2)} via EVC Plus',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (_paying) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'A payment prompt has been sent to your EVC Plus app. '
              'Please approve it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary600,
              ),
            ),
          ],

          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: _emerald500,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payment is securely processed by WaafiPay. Your phone '
                    'number is only used to charge your EVC Plus wallet.',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1 — Choose Doctor ────────────────────────────────────────────────

  Widget _doctorStep(AsyncValue<List<Doctor>> doctors) {
    final AppPalette palette = context.palette;

    return Column(
      children: <Widget>[
        if (_paid != null) _paidBanner(),
        _Panel(
          title: 'Available Specialists',
          subtitle: 'All doctors are certified pediatric specialists',
          child: Column(
            children: <Widget>[
              TextField(
                controller: _search,
                onChanged: (String v) => setState(() => _searchTerm = v),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search doctor or specialty...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchTerm.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () {
                            _search.clear();
                            setState(() => _searchTerm = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              doctors.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object e, StackTrace _) => _errorBox(
                  e is ApiException ? e.detailedMessage : e.toString(),
                ),
                data: (List<Doctor> list) {
                  final String q = _searchTerm.toLowerCase();
                  final List<Doctor> filtered = q.isEmpty
                      ? list
                      : list.where((Doctor d) {
                          return '${d.firstName} ${d.lastName}'
                                  .toLowerCase()
                                  .contains(q) ||
                              d.specialization.toLowerCase().contains(q);
                        }).toList();

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 46),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.medical_services_outlined,
                            size: 38,
                            color: palette.textMuted.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No doctors found',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: <Widget>[
                      for (int i = 0; i < filtered.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _doctorCard(filtered[i], i),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _doctorCard(Doctor d, int index) {
    final AppPalette palette = context.palette;
    final _Rating rating = _ratingFor(index);
    final _Specialty spec = _specialtyOf(d.specialization);

    return InkWell(
      onTap: () => setState(() {
        _doctor = d;
        _step = 2;
      }),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border, width: 2),
        ),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Avatar(
                  text: _initials(d.firstName, d.lastName),
                  gradient: _avatarGradient(d.id),
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            'Dr. ${d.firstName} ${d.lastName}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: palette.textPrimary,
                            ),
                          ),
                          if (d.verificationStatus == 'ACTIVE')
                            _Pill(
                              text: 'Verified',
                              icon: Icons.shield_rounded,
                              bg: _emerald50,
                              fg: _emerald700,
                              border: _emerald200,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _Pill(
                        text: d.specialization,
                        bg: spec.bg,
                        fg: spec.fg,
                        border: spec.border,
                      ),
                      if (d.facilityName != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.place_rounded,
                              size: 11,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                d.facilityName ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: palette.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          for (int s = 1; s <= 5; s++)
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: s <= rating.stars
                                  ? const Color(0xFFFBBF24)
                                  : palette.textMuted.withValues(alpha: 0.3),
                            ),
                          const SizedBox(width: 5),
                          Text(
                            rating.score,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(width: 5),
                          _Pill(
                            text: rating.label,
                            bg: rating.stars == 5
                                ? const Color(0xFFFEF3C7)
                                : palette.surfaceSoft,
                            fg: rating.stars == 5
                                ? const Color(0xFFB45309)
                                : palette.textSecondary,
                            border: Colors.transparent,
                            fontSize: 8.5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.primary600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _emerald500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Available for booking',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _emerald600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2 — Select Child ─────────────────────────────────────────────────

  Widget _childStep() {
    final AppPalette palette = context.palette;
    final Doctor? doctor = _doctor;
    final AsyncValue<List<Child>> children = ref.watch(myChildrenProvider);
    final String? facilityId = doctor?.facilityId;

    return _Panel(
      title: 'Select Child',
      subtitle: 'Who is this appointment for?',
      onBack: () => setState(() => _step = 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Doctor recap
          if (doctor != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary600.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  _Avatar(
                    text: _initials(doctor.firstName, doctor.lastName),
                    gradient: _avatarGradient(doctor.id),
                    size: 40,
                    radius: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Booking with',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary700,
                          ),
                        ),
                        Text(
                          'Dr. ${doctor.firstName} ${doctor.lastName}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Facility services
          if (facilityId != null) ...<Widget>[
            const SizedBox(height: 14),
            _facilityServices(facilityId, doctor?.facilityName),
          ],

          const SizedBox(height: 16),
          children.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, StackTrace _) =>
                _errorBox(e is ApiException ? e.detailedMessage : e.toString()),
            data: (List<Child> list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 46),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.child_care_outlined,
                        size: 38,
                        color: palette.textMuted.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No children registered',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Add a child profile first to book appointments.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: <Widget>[
                  for (final Child c in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _childCard(c),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _facilityServices(String facilityId, String? facilityName) {
    final AppPalette palette = context.palette;
    final AsyncValue<List<HealthService>> services = ref.watch(
      facilityServicesProvider(facilityId),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.monitor_heart_rounded, size: 14, color: _emerald600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SERVICES OFFERED BY '
                  '${(facilityName ?? 'this facility').toUpperCase()}',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          services.when(
            loading: () => Text(
              'Loading services…',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: palette.textMuted,
              ),
            ),
            error: (Object _, StackTrace _) => Text(
              'Services unavailable.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: palette.textMuted,
              ),
            ),
            data: (List<HealthService> list) {
              if (list.isEmpty) {
                return Text(
                  'No published services yet.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: palette.textMuted,
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final HealthService s in list)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _emerald50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _emerald200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.monitor_heart_rounded,
                            size: 11,
                            color: _emerald700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          if (s.price != null) ...<Widget>[
                            const SizedBox(width: 6),
                            Text(
                              '\$${(s.price ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _emerald600,
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
        ],
      ),
    );
  }

  Widget _childCard(Child c) {
    final AppPalette palette = context.palette;

    return InkWell(
      onTap: () => setState(() {
        _child = c;
        _step = 3;
      }),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border, width: 2),
        ),
        child: Row(
          children: <Widget>[
            _Avatar(
              text: _initials(c.firstName, c.lastName),
              gradient: const <Color>[Color(0xFFA78BFA), Color(0xFF9333EA)],
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${c.firstName} ${c.lastName}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        '🎂 ${DateFormat('M/d/yyyy').format(c.dateOfBirth)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                      _Pill(
                        text: _ageLabel(c.dateOfBirth),
                        bg: const Color(0xFFEDE9FE),
                        fg: const Color(0xFF6D28D9),
                        border: const Color(0xFFDDD6FE),
                      ),
                      Text(
                        '${c.gender.toUpperCase() == 'MALE' ? '♂' : '♀'} '
                        '${c.gender.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (c.bloodType != null) ...<Widget>[
                    const SizedBox(height: 5),
                    Text(
                      '🩸 ${c.bloodType ?? ''}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3 — Pick a Time ──────────────────────────────────────────────────

  Widget _timeStep() {
    final AppPalette palette = context.palette;

    return _Panel(
      title: 'Pick a Date & Time',
      subtitle: 'All slots are 30-minute sessions',
      onBack: () => setState(() => _step = 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_bookError != null) ...<Widget>[
            _errorBox(_bookError ?? ''),
            const SizedBox(height: 16),
          ],

          _label(Icons.calendar_month_rounded, 'SELECT DATE'),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded, size: 16),
                label: Text(DateFormat('MM/dd/yyyy').format(_date)),
                style: OutlinedButton.styleFrom(
                  // The theme's minimumSize is Size.fromHeight, i.e. infinitely
                  // wide. That is fine in a column but forces infinite width
                  // inside this row, so the width floor is dropped here.
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary600.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary600.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(_date),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 20),

          _label(Icons.schedule_rounded, 'AVAILABLE TIME SLOTS'),
          const SizedBox(height: 14),
          _slotGroup('☀️ MORNING', _morning),
          const SizedBox(height: 16),
          _slotGroup('🌤 AFTERNOON', _afternoon),

          const SizedBox(height: 20),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 20),

          Row(
            children: <Widget>[
              _label(Icons.description_rounded, 'REASON FOR VISIT'),
              const SizedBox(width: 6),
              Text(
                '(optional)',
                style: TextStyle(fontSize: 11, color: palette.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reason,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText:
                  'e.g. Routine checkup, fever since 2 days, vaccination visit...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotGroup(String heading, List<String> times) {
    final AppPalette palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          heading,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String t in times)
              GestureDetector(
                onTap: () => setState(() => _slot = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _slot == t ? AppColors.primary600 : palette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _slot == t
                          ? AppColors.primary600
                          : palette.border,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _fmtSlot(t),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _slot == t ? Colors.white : palette.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _slot = null;
      });
    }
  }

  // ── Booking summary ───────────────────────────────────────────────────────

  Widget _summary() {
    final AppPalette palette = context.palette;
    final Doctor? doctor = _doctor;
    final Child? child = _child;
    final String? facilityId = doctor?.facilityId;

    return _Panel(
      title: 'Booking Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (doctor != null)
            Row(
              children: <Widget>[
                _Avatar(
                  text: _initials(doctor.firstName, doctor.lastName),
                  gradient: _avatarGradient(doctor.id),
                  size: 42,
                  radius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'DOCTOR',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: palette.textMuted,
                        ),
                      ),
                      Text(
                        'Dr. ${doctor.firstName} ${doctor.lastName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _Pill(
                        text: doctor.specialization,
                        bg: _specialtyOf(doctor.specialization).bg,
                        fg: _specialtyOf(doctor.specialization).fg,
                        border: _specialtyOf(doctor.specialization).border,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 14),

          if (child != null)
            Row(
              children: <Widget>[
                _Avatar(
                  text: _initials(child.firstName, child.lastName),
                  gradient: const <Color>[Color(0xFFA78BFA), Color(0xFF9333EA)],
                  size: 42,
                  radius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'PATIENT',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: palette.textMuted,
                        ),
                      ),
                      Text(
                        '${child.firstName} ${child.lastName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        '${_ageLabel(child.dateOfBirth)} old',
                        style: TextStyle(
                          fontSize: 10,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 14),

          _summaryRow(
            Icons.calendar_month_rounded,
            'Date',
            DateFormat('EEEE, MMMM d').format(_date),
          ),
          _summaryRow(
            Icons.schedule_rounded,
            'Time',
            _slot == null ? 'Not selected' : _fmtSlot(_slot ?? ''),
            valueColor: _slot == null ? palette.textMuted : AppColors.primary600,
            italic: _slot == null,
          ),
          _summaryRow(Icons.videocam_rounded, 'Type', 'Video Call',
              valueColor: AppColors.teal),
          _summaryRow(
            Icons.credit_card_rounded,
            'Fee',
            '\$${_consultationFee.toStringAsFixed(2)} Paid',
            valueColor: _emerald600,
          ),

          if (facilityId != null) ...<Widget>[
            const SizedBox(height: 14),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: 14),
            _summaryServices(facilityId),
          ],

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Text(
              '⚠️ After booking, the doctor reviews and approves your request '
              'before the video call is unlocked.',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309),
              ),
            ),
          ),
          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: _slot == null || _booking ? null : _book,
            icon: _booking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 17),
            label: Text(_booking ? 'Booking...' : 'Confirm Appointment'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.lock_rounded,
                size: 11,
                color: palette.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'Secure & encrypted booking',
                style: TextStyle(fontSize: 10, color: palette.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryServices(String facilityId) {
    final AppPalette palette = context.palette;
    final AsyncValue<List<HealthService>> services = ref.watch(
      facilityServicesProvider(facilityId),
    );

    return services.maybeWhen(
      data: (List<HealthService> list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.monitor_heart_rounded,
                  size: 11,
                  color: _emerald600,
                ),
                const SizedBox(width: 6),
                Text(
                  'FACILITY SERVICES',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final HealthService s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        s.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    if (s.price != null)
                      Text(
                        '\$${(s.price ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _emerald600,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool italic = false,
  }) {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 12, color: palette.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: palette.textMuted,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                color: valueColor ?? palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Small shared pieces ───────────────────────────────────────────────────

  Widget _paidBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _emerald50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _emerald200),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, size: 15, color: _emerald600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payment confirmed — \$${_consultationFee.toStringAsFixed(2)} '
              'charged to $_paidNumber',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _emerald700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, size: 13, color: _emerald500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: context.palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.primary600),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: context.palette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success view ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.state});

  final _BookAppointmentScreenState state;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Doctor? doctor = state._doctor;
    final Child? child = state._child;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
        children: <Widget>[
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _emerald500,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _emerald500.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _emerald50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _emerald200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.bolt_rounded, size: 12, color: _emerald700),
                  SizedBox(width: 6),
                  Text(
                    'REQUEST SENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: _emerald700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Appointment Requested!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                const TextSpan(text: 'Your request has been sent to '),
                TextSpan(
                  text: 'Dr. ${doctor?.lastName ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Once the doctor approves, you'll see a Join Call button in the "
            'Tele-Consultation section.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.6,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: <Widget>[
                _row(
                  context,
                  'Doctor',
                  'Dr. ${doctor?.firstName ?? ''} ${doctor?.lastName ?? ''}',
                ),
                _row(
                  context,
                  'Patient',
                  '${child?.firstName ?? ''} ${child?.lastName ?? ''}',
                ),
                _row(
                  context,
                  'Date & Time',
                  '${DateFormat('EEEE, MMMM d').format(state._date)} · '
                      '${_fmtSlot(state._slot ?? '')}',
                ),
                _row(
                  context,
                  'Payment',
                  '\$${_consultationFee.toStringAsFixed(2)} Paid',
                  valueColor: _emerald600,
                ),
                _row(
                  context,
                  'Status',
                  'Pending Approval',
                  valueColor: const Color(0xFFD97706),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          ElevatedButton(
            onPressed: state._reset,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            child: const Text('Book Another Appointment'),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: valueColor ?? palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable bits ────────────────────────────────────────────────────────────

/// The white card every step sits in — header strip, optional Back button.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.sm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 17, color: AppColors.primary600),
                  const SizedBox(width: 9),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onBack != null)
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.chevron_left_rounded, size: 16),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary600,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

/// Gradient square with initials, matching the web avatars.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.text,
    required this.gradient,
    required this.size,
    this.radius = 16,
  });

  final String text;
  final List<Color> gradient;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.sm,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.bg,
    required this.fg,
    required this.border,
    this.icon,
    this.fontSize = 10,
  });

  final String text;
  final Color bg;
  final Color fg;
  final Color border;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 9, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers mirroring the web module's constants ─────────────────────────────

const Color _emerald50 = Color(0xFFECFDF5);
const Color _emerald200 = Color(0xFFA7F3D0);
const Color _emerald500 = Color(0xFF10B981);
const Color _emerald600 = Color(0xFF059669);
const Color _emerald700 = Color(0xFF047857);

/// `AVATAR_COLORS` — picked by the first character of the id, as on the web.
const List<List<Color>> _avatarColors = <List<Color>>[
  <Color>[Color(0xFF3B82F6), Color(0xFF4F46E5)],
  <Color>[Color(0xFF14B8A6), Color(0xFF059669)],
  <Color>[Color(0xFFA855F7), Color(0xFF7C3AED)],
  <Color>[Color(0xFFF43F5E), Color(0xFFDB2777)],
  <Color>[Color(0xFFF59E0B), Color(0xFFEA580C)],
  <Color>[Color(0xFF06B6D4), Color(0xFF0284C7)],
];

List<Color> _avatarGradient(String? id) {
  final int code = (id == null || id.isEmpty) ? 0 : id.codeUnitAt(0);
  return _avatarColors[code % _avatarColors.length];
}

String _initials(String? first, String? last) {
  final String a = (first == null || first.isEmpty) ? '' : first[0];
  final String b = (last == null || last.isEmpty) ? '' : last[0];
  return '$a$b'.toUpperCase();
}

/// `getAge` — years once past the first birthday, months before that.
String _ageLabel(DateTime dob) {
  final int days = DateTime.now().difference(dob).inDays;
  final int years = (days / 365.25).floor();
  final int months = (days / 30.44).floor();
  return years >= 1 ? '${years}yr' : '${months}mo';
}

/// `formatTime` — "09:00" becomes "9:00 AM".
String _fmtSlot(String value) {
  final List<String> parts = value.split(':');
  if (parts.length != 2) return value;
  final int hour = int.tryParse(parts.first) ?? 0;
  final int display = hour % 12 == 0 ? 12 : hour % 12;
  return '$display:${parts.last} ${hour >= 12 ? 'PM' : 'AM'}';
}

class _Rating {
  const _Rating(this.stars, this.score, this.label);
  final int stars;
  final String score;
  final String label;
}

/// `DOCTOR_RATINGS` — position in the list, not a stored score.
const List<_Rating> _ratings = <_Rating>[
  _Rating(5, '5.0', 'Top Rated'),
  _Rating(4, '4.2', 'Excellent'),
  _Rating(3, '3.5', 'Good'),
  _Rating(2, '2.8', 'Average'),
  _Rating(1, '1.9', 'New'),
];

_Rating _ratingFor(int index) =>
    _ratings[index < _ratings.length ? index : _ratings.length - 1];

class _Specialty {
  const _Specialty(this.bg, this.fg, this.border);
  final Color bg;
  final Color fg;
  final Color border;
}

/// `SPECIALTIES`
const Map<String, _Specialty> _specialties = <String, _Specialty>{
  'General Pediatrics': _Specialty(
    Color(0xFFDBEAFE),
    Color(0xFF1D4ED8),
    Color(0xFFBFDBFE),
  ),
  'Pediatrics (General)': _Specialty(
    Color(0xFFDBEAFE),
    Color(0xFF1D4ED8),
    Color(0xFFBFDBFE),
  ),
  'Neonatology': _Specialty(
    Color(0xFFF3E8FF),
    Color(0xFF7E22CE),
    Color(0xFFE9D5FF),
  ),
  'Cardiology': _Specialty(
    Color(0xFFFFE4E6),
    Color(0xFFBE123C),
    Color(0xFFFECDD3),
  ),
  'Neurology': _Specialty(
    Color(0xFFE0E7FF),
    Color(0xFF4338CA),
    Color(0xFFC7D2FE),
  ),
  'Nutrition': _Specialty(
    Color(0xFFDCFCE7),
    Color(0xFF15803D),
    Color(0xFFBBF7D0),
  ),
  'Dermatology': _Specialty(
    Color(0xFFFFEDD5),
    Color(0xFFC2410C),
    Color(0xFFFED7AA),
  ),
};

_Specialty _specialtyOf(String? name) =>
    _specialties[name] ??
    const _Specialty(Color(0xFFF1F5F9), Color(0xFF334155), Color(0xFFE2E8F0));
