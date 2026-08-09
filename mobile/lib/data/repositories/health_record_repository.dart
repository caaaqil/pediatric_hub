import '../../core/network/api_client.dart';
import '../models/growth.dart';
import '../models/health_record.dart';

/// `backend/src/routes/healthRecord.routes.js`, `growthRecord.routes.js`,
/// `parentInfo.routes.js` and `medicalRecord.routes.js`.
class HealthRecordRepository {
  const HealthRecordRepository(this._api);

  final ApiClient _api;

  /// `GET /health-records/child/:childId/baseline`
  Future<ChildBaseline> baseline(String childId) async {
    final dynamic data = await _api.getData(
      '/health-records/child/$childId/baseline',
    );
    return ChildBaseline.fromJson(asMap(data));
  }

  /// `GET /health-records/child/:childId/consultations`
  Future<List<ConsultationNote>> consultations(String childId) async {
    final dynamic data = await _api.getData(
      '/health-records/child/$childId/consultations',
    );
    return asMapList(data).map(ConsultationNote.fromJson).toList();
  }

  /// `POST /health-records/allergies` (PARENT | ADMIN)
  Future<Allergy> addAllergy({
    required String childId,
    required String allergen,
    required String severity,
    String? notes,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'childId': childId,
      'allergen': allergen,
      'severity': severity,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final dynamic data = await _api.postData(
      '/health-records/allergies',
      body: body,
    );
    return Allergy.fromJson(asMap(data));
  }

  /// `POST /health-records/medications` (PARENT | DOCTOR | ADMIN)
  Future<Medication> addMedication({
    required String childId,
    required String name,
    required String dosage,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'childId': childId,
      'name': name,
      'dosage': dosage,
      'startDate': startDate.toUtc().toIso8601String(),
    };
    if (endDate != null) body['endDate'] = endDate.toUtc().toIso8601String();

    final dynamic data = await _api.postData(
      '/health-records/medications',
      body: body,
    );
    return Medication.fromJson(asMap(data));
  }

  /// `POST /health-records/illnesses` (PARENT | ADMIN)
  Future<IllnessHistory> addIllness({
    required String childId,
    required String illnessName,
    required DateTime diagnosisDate,
    String? notes,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'childId': childId,
      'illnessName': illnessName,
      'diagnosisDate': diagnosisDate.toUtc().toIso8601String(),
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final dynamic data = await _api.postData(
      '/health-records/illnesses',
      body: body,
    );
    return IllnessHistory.fromJson(asMap(data));
  }

  /// `POST /health-records/consultations` (DOCTOR only) — the doctor id is
  /// resolved from the JWT, never sent by the client.
  Future<ConsultationNote> addConsultation({
    required String childId,
    required String notes,
    String? treatmentPlan,
    String? appointmentId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'childId': childId,
      'notes': notes,
    };
    if (treatmentPlan != null && treatmentPlan.isNotEmpty) {
      body['treatmentPlan'] = treatmentPlan;
    }
    if (appointmentId != null && appointmentId.isNotEmpty) {
      body['appointmentId'] = appointmentId;
    }

    final dynamic data = await _api.postData(
      '/health-records/consultations',
      body: body,
    );
    return ConsultationNote.fromJson(asMap(data));
  }

  /// `GET /medical-records/child/:childId` — the legacy record table.
  Future<List<MedicalRecord>> medicalRecords(String childId) async {
    final dynamic data = await _api.getData('/medical-records/child/$childId');
    return asMapList(data).map(MedicalRecord.fromJson).toList();
  }

  // ── Growth ────────────────────────────────────────────────────────────────

  /// `GET /growth/child/:childId` → `{ records, chartData }`
  Future<GrowthData> growth(String childId) async {
    final dynamic data = await _api.getData('/growth/child/$childId');
    return GrowthData.fromJson(asMap(data));
  }

  /// `POST /growth` (PARENT | DOCTOR) — at least one metric is required.
  Future<GrowthRecord> addGrowth({
    required String childId,
    required DateTime measurementDate,
    double? weightKg,
    double? heightCm,
    double? headCircumCm,
    String? milestoneNotes,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'childId': childId,
      'measurementDate': measurementDate.toUtc().toIso8601String(),
    };
    if (weightKg != null) body['weightKg'] = weightKg;
    if (heightCm != null) body['heightCm'] = heightCm;
    if (headCircumCm != null) body['headCircumCm'] = headCircumCm;
    if (milestoneNotes != null && milestoneNotes.isNotEmpty) {
      body['milestoneNotes'] = milestoneNotes;
    }

    final dynamic data = await _api.postData('/growth', body: body);
    return GrowthRecord.fromJson(asMap(data));
  }

  // ── Guardians (ParentInfo) ────────────────────────────────────────────────

  /// `GET /parent-info?childId=`
  Future<List<ParentInfo>> guardians(String childId) async {
    final dynamic data = await _api.getData(
      '/parent-info',
      query: <String, dynamic>{'childId': childId},
    );
    return asMapList(data).map(ParentInfo.fromJson).toList();
  }

  /// `POST /parent-info` (PARENT | ADMIN)
  Future<ParentInfo> addGuardian({
    required String childId,
    required String fullName,
    required String phoneNumber,
    required String address,
    required String relationship,
    String? healthStatus,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'childId': childId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'relationship': relationship,
    };
    if (healthStatus != null && healthStatus.isNotEmpty) {
      body['healthStatus'] = healthStatus;
    }

    final dynamic data = await _api.postData('/parent-info', body: body);
    return ParentInfo.fromJson(asMap(data));
  }

  /// `PUT /parent-info/:id` (PARENT | ADMIN)
  Future<ParentInfo> updateGuardian({
    required String id,
    required String fullName,
    required String phoneNumber,
    required String address,
    required String relationship,
    String? healthStatus,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'relationship': relationship,
      // Sent even when blank so clearing the field actually clears it.
      'healthStatus': (healthStatus == null || healthStatus.isEmpty)
          ? null
          : healthStatus,
    };

    final dynamic data = await _api.putData('/parent-info/$id', body: body);
    return ParentInfo.fromJson(asMap(data));
  }

  /// `DELETE /parent-info/:id` — soft delete.
  Future<void> removeGuardian(String id) => _api.deleteData('/parent-info/$id');
}
