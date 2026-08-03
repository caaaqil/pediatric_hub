import '../../core/network/api_client.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/enums.dart';

/// `backend/src/routes/appointment.routes.js` and
/// `backend/src/routes/teleconsultation.routes.js`
class AppointmentRepository {
  const AppointmentRepository(this._api);

  final ApiClient _api;

  /// `GET /appointments/my-schedule` → `{ appointments: [...] }`
  ///
  /// The backend picks the right scope from the JWT role: parents get their
  /// children's, doctors their own, facilities their staff's, admins all.
  Future<List<Appointment>> mySchedule() async {
    final dynamic data = await _api.getData('/appointments/my-schedule');
    final Map<String, dynamic> map = asMap(data);
    return asMapList(map['appointments']).map(Appointment.fromJson).toList();
  }

  /// `GET /appointments/:id`
  Future<Appointment> byId(String id) async {
    final dynamic data = await _api.getData('/appointments/$id');
    return Appointment.fromJson(asMap(data));
  }

  /// `POST /appointments` (PARENT | ADMIN) — 409 when the slot is taken.
  Future<Appointment> book({
    required String childId,
    required String doctorId,
    required DateTime scheduledAt,
    String? reason,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'childId': childId,
      'doctorId': doctorId,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
    };
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;

    final dynamic data = await _api.postData('/appointments', body: body);
    return Appointment.fromJson(asMap(data));
  }

  /// `PATCH /appointments/:id/status`
  ///
  /// DOCTOR/FACILITY/ADMIN may set any status; PARENT is restricted to
  /// CANCELLED on their own child's appointment by the controller.
  Future<Appointment> updateStatus({
    required String id,
    required AppointmentStatus status,
    String? notes,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{'status': status.wire};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final dynamic data = await _api.patchData(
      '/appointments/$id/status',
      body: body,
    );
    return Appointment.fromJson(asMap(data));
  }

  /// `GET /appointments/availability/:doctorId?date=` — the weekday windows a
  /// doctor has configured (not concrete free slots).
  Future<List<DoctorAvailability>> availability({
    required String doctorId,
    required DateTime date,
  }) async {
    final dynamic data = await _api.getData(
      '/appointments/availability/$doctorId',
      query: <String, dynamic>{'date': date.toIso8601String()},
    );
    return asMapList(data).map(DoctorAvailability.fromJson).toList();
  }

  // ── Teleconsultation rooms ────────────────────────────────────────────────

  /// `POST /teleconsultations/generate` — creates/refreshes the room and
  /// auto-confirms a PENDING appointment.
  Future<Teleconsultation> openRoom(String appointmentId) async {
    final dynamic data = await _api.postData(
      '/teleconsultations/generate',
      body: <String, dynamic>{'appointmentId': appointmentId},
    );
    return Teleconsultation.fromJson(asMap(data));
  }

  /// `GET /teleconsultations/:appointmentId` — 403 when the room has not been
  /// started or has already ended.
  Future<Teleconsultation> room(String appointmentId) async {
    final dynamic data = await _api.getData(
      '/teleconsultations/$appointmentId',
    );
    return Teleconsultation.fromJson(asMap(data));
  }

  /// `PATCH /teleconsultations/:appointmentId/end` (DOCTOR | ADMIN) — also
  /// marks the appointment COMPLETED.
  Future<void> endRoom({required String appointmentId, String? notes}) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    await _api.patchData('/teleconsultations/$appointmentId/end', body: body);
  }
}
