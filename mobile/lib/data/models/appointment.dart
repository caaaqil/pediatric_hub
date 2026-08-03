import 'child.dart';
import 'doctor.dart';
import 'enums.dart';
import 'json_utils.dart';

/// `model Teleconsultation` — one optional room per appointment.
class Teleconsultation {
  const Teleconsultation({
    required this.id,
    required this.appointmentId,
    this.roomUrl,
    this.startedAt,
    this.endedAt,
    this.notes,
  });

  final String id;
  final String appointmentId;

  /// The backend stores `webrtc-room:<appointmentId>` — an identifier, not a URL.
  final String? roomUrl;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? notes;

  factory Teleconsultation.fromJson(Map<String, dynamic> json) {
    return Teleconsultation(
      id: Json.str(json['id']),
      appointmentId: Json.str(json['appointmentId']),
      roomUrl: Json.strOrNull(json['roomUrl']),
      startedAt: Json.dateOrNull(json['startedAt']),
      endedAt: Json.dateOrNull(json['endedAt']),
      notes: Json.strOrNull(json['notes']),
    );
  }

  bool get isLive => startedAt != null && endedAt == null;
}

/// `model Appointment`.
///
/// `GET /appointments/my-schedule` and `GET /appointments/:id` both include
/// `child`, `doctor` and `teleconsultation`.
class Appointment {
  const Appointment({
    required this.id,
    required this.childId,
    required this.doctorId,
    required this.scheduledAt,
    required this.status,
    this.reason,
    this.notes,
    this.child,
    this.doctor,
    this.teleconsultation,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String doctorId;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
  final Child? child;
  final Doctor? doctor;
  final Teleconsultation? teleconsultation;
  final DateTime? createdAt;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? childJson = Json.mapOrNull(json['child']);
    final Map<String, dynamic>? doctorJson = Json.mapOrNull(json['doctor']);
    final Map<String, dynamic>? teleJson = Json.mapOrNull(
      json['teleconsultation'],
    );
    return Appointment(
      id: Json.str(json['id']),
      childId: Json.str(json['childId']),
      doctorId: Json.str(json['doctorId']),
      scheduledAt: Json.date(json['scheduledAt']),
      status: AppointmentStatus.fromJson(json['status']),
      reason: Json.strOrNull(json['reason']),
      notes: Json.strOrNull(json['notes']),
      child: childJson == null ? null : Child.fromJson(childJson),
      doctor: doctorJson == null ? null : Doctor.fromJson(doctorJson),
      teleconsultation: teleJson == null
          ? null
          : Teleconsultation.fromJson(teleJson),
      createdAt: Json.dateOrNull(json['createdAt']),
    );
  }

  String get childName => child?.fullName ?? 'Patient';

  String get doctorName => doctor?.displayName ?? 'Doctor';

  bool get isUpcoming => status.isOpen && scheduledAt.isAfter(DateTime.now());

  bool get isToday {
    final DateTime now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }
}
