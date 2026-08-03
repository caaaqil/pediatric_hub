import '../../core/network/api_client.dart';
import '../models/enums.dart';
import '../models/vaccination.dart';

/// `backend/src/routes/vaccination.routes.js`
class VaccinationRepository {
  const VaccinationRepository(this._api);

  final ApiClient _api;

  /// `GET /vaccinations/child/:childId` — ordered by scheduledDate ascending.
  Future<List<Vaccination>> forChild(String childId) async {
    final dynamic data = await _api.getData('/vaccinations/child/$childId');
    return asMapList(data).map(Vaccination.fromJson).toList();
  }

  /// `POST /vaccinations/child/:childId/generate` (PARENT | DOCTOR | ADMIN)
  ///
  /// Materialises any missing doses from the VaccineTemplate protocol and
  /// returns the child's full schedule.
  Future<List<Vaccination>> generateSchedule(String childId) async {
    final dynamic data = await _api.postData(
      '/vaccinations/child/$childId/generate',
    );
    return asMapList(data).map(Vaccination.fromJson).toList();
  }

  /// `PATCH /vaccinations/:id/status`
  ///
  /// DOCTOR/FACILITY/ADMIN may set any status; PARENT is restricted to
  /// COMPLETED on their own child by the controller. When COMPLETED is sent
  /// without a date the backend stamps `administeredDate` with now.
  Future<Vaccination> updateStatus({
    required String vaccinationId,
    required VaccineStatus status,
    DateTime? administeredDate,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{'status': status.wire};
    if (administeredDate != null) {
      body['administeredDate'] = administeredDate.toUtc().toIso8601String();
    }
    final dynamic data = await _api.patchData(
      '/vaccinations/$vaccinationId/status',
      body: body,
    );
    return Vaccination.fromJson(asMap(data));
  }

  /// `POST /vaccinations` (DOCTOR | FACILITY | ADMIN) — ad-hoc dose entry.
  /// The backend derives the status from how far past the scheduled date it is.
  Future<Vaccination> register({
    required String childId,
    required String vaccineName,
    required int doseNumber,
    required DateTime scheduledDate,
  }) async {
    final dynamic data = await _api.postData(
      '/vaccinations',
      body: <String, dynamic>{
        'childId': childId,
        'vaccineName': vaccineName,
        'doseNumber': doseNumber,
        'scheduledDate': scheduledDate.toUtc().toIso8601String(),
      },
    );
    return Vaccination.fromJson(asMap(data));
  }

  /// `GET /vaccinations/templates` — the national protocol rows.
  Future<List<VaccineTemplate>> templates() async {
    final dynamic data = await _api.getData('/vaccinations/templates');
    return asMapList(data).map(VaccineTemplate.fromJson).toList();
  }
}
