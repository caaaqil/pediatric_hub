import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/misc.dart';
import '../../../data/static/emergency_content.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/dashboard/EmergencyGuidance.jsx` — the red
/// hero with the ambulance buttons, the Immediate Action Protocols, the
/// Nearest Approved Facilities list and the quick Emergency Contacts.
///
/// The protocols and facilities are hardcoded in the web component (not in the
/// `EmergencyContact` table), so they live in `data/static/emergency_content.dart`.
/// Rows an administrator adds through `POST /emergency` are appended below.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  static const Color danger = Color(0xFFDC2626);

  Future<void> _copy(BuildContext context, String number, String label) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (context.mounted) Toast.success(context, '$label — $number copied');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final AsyncValue<List<EmergencyContact>> published = ref.watch(
      emergencyContactsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Guidance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          // ── Red hero ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: danger,
              borderRadius: AppRadius.lgAll,
              boxShadow: AppShadows.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gpp_maybe_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Emergency Guidance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'If your child is experiencing a life-threatening emergency, '
                  'act immediately. Do not wait.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '🇸🇴 Hadduu caruurtu jiraan xaaladda degdegga, degdeg wac!',
                  style: TextStyle(
                    color: Color(0xFFFECACA),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _copy(context, '252-1', 'Ambulance'),
                    icon: const Icon(Icons.phone_rounded, size: 20),
                    label: const Text('CALL AMBULANCE · 252-1'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: danger,
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context, '252-1', 'Doctor on-call'),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                    label: const Text('Call Doctor On-Call'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Location sharing ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.navigation_rounded,
                      size: 18,
                      color: AppColors.primary600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Auto Location Sharing',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your exact GPS location with the doctor or ambulance '
                  'instantly.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '🇸🇴 Meeshaada si toos ah u dir dhakhtarka ama ambalaanka',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: palette.surfaceSoft,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_outlined,
                        size: 28,
                        color: palette.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Location sharing runs in the web app',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Mobile GPS needs the geolocator plugin and location '
                          'permissions — tell me if you want it enabled.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Immediate Action Protocols ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.monitor_heart_rounded,
                      size: 20,
                      color: danger,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Immediate Action Protocols',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...kEmergencyProtocols.map(
                  (EmergencyProtocol p) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${p.step}',
                            style: const TextStyle(
                              color: danger,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                p.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '🇸🇴 ${p.somali}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: danger,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.body,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Nearest Approved Facilities ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.apartment_rounded,
                      size: 18,
                      color: AppColors.primary600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nearest Approved Facilities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...kEmergencyFacilities.map(
                  (EmergencyFacility f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FacilityTile(facility: f, onCall: _copy),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick emergency contacts ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: danger.withValues(alpha: 0.08),
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: danger.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.phone_rounded, size: 16, color: danger),
                    const SizedBox(width: 8),
                    Text(
                      'Emergency Contacts',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: danger,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...kEmergencyNumbers.map(
                  (EmergencyNumber n) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _copy(context, n.number, n.label),
                      borderRadius: AppRadius.smAll,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: danger.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _numberColor(n.label),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  n.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  n.number,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.copy_rounded,
                              size: 15,
                              color: palette.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Anything an admin added through the API ─────────────────────
          published.maybeWhen(
            data: (List<EmergencyContact> items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 16),
                  Text(
                    'Added by administrators',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...items.map(
                    (EmergencyContact c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        tileColor: palette.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smAll,
                          side: BorderSide(color: palette.border),
                        ),
                        leading: const Icon(
                          Icons.local_hospital_rounded,
                          color: danger,
                        ),
                        title: Text(c.name),
                        subtitle: Text(
                          '${c.phoneNumber} · ${c.type}'
                          '${c.region == null ? '' : ' · ${c.region}'}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          onPressed: () =>
                              _copy(context, c.phoneNumber, c.name),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static Color _numberColor(String label) {
    if (label.startsWith('Police')) return AppColors.primary600;
    if (label.startsWith('Banadir')) return const Color(0xFF059669);
    return danger;
  }
}

class _FacilityTile extends StatefulWidget {
  const _FacilityTile({required this.facility, required this.onCall});

  final EmergencyFacility facility;
  final Future<void> Function(BuildContext, String, String) onCall;

  @override
  State<_FacilityTile> createState() => _FacilityTileState();
}

class _FacilityTileState extends State<_FacilityTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final EmergencyFacility f = widget.facility;
    final bool isHospital = f.type == 'Hospital';
    final Color accent = isHospital
        ? EmergencyScreen.danger
        : const Color(0xFF059669);

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHospital
                          ? Icons.local_hospital_rounded
                          : Icons.medical_services_rounded,
                      size: 16,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          f.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: <Widget>[
                            Text(
                              f.distance,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: palette.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              f.open,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: palette.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                f.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Divider(color: palette.border),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f.address,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onCall(context, f.phone, f.name),
                      icon: const Icon(Icons.phone_rounded, size: 15),
                      label: Text(f.phone),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(38),
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
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
}
