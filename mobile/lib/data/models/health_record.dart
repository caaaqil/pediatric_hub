import 'child.dart';
import 'json_utils.dart';

/// `model Allergy`
class Allergy {
  const Allergy({
    required this.id,
    required this.childId,
    required this.allergen,
    required this.severity,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String allergen;
  final String severity;
  final String? notes;
  final DateTime? createdAt;

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      id: Json.str(json['id']),
      childId: Json.str(json['childId']),
      allergen: Json.str(json['allergen']),
      severity: Json.str(json['severity']),
      notes: Json.strOrNull(json['notes']),
      createdAt: Json.dateOrNull(json['createdAt']),
    );
  }
}

/// `model Medication`
class Medication {
  const Medication({
    required this.id,
    required this.childId,
    required this.name,
    required this.dosage,
    required this.startDate,
    required this.active,
    this.endDate,
  });

  final String id;
  final String childId;
  final String name;
  final String dosage;
  final DateTime startDate;
  final bool active;
  final DateTime? endDate;

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: Json.str(json['id']),
      childId: Json.str(json['childId']),
      name: Json.str(json['name']),
      dosage: Json.str(json['dosage']),
      startDate: Json.date(json['startDate']),
      active: Json.boolean(json['active'], fallback: true),
      endDate: Json.dateOrNull(json['endDate']),
    );
  }
}

/// `model IllnessHistory`
class IllnessHistory {
  const IllnessHistory({
    required this.id,
    required this.childId,
    required this.illnessName,
    required this.diagnosisDate,
    this.recoveryDate,
    this.notes,
  });

  final String id;
  final String childId;
  final String illnessName;
  final DateTime diagnosisDate;
  final DateTime? recoveryDate;
  final String? notes;

  factory IllnessHistory.fromJson(Map<String, dynamic> json) {
    return IllnessHistory(
      id: Json.str(json['id']),
      childId: Json.str(json['childId']),
      illnessName: Json.str(json['illnessName']),
      diagnosisDate: Json.date(json['diagnosisDate']),
      recoveryDate: Json.dateOrNull(json['recoveryDate']),
      notes: Json.strOrNull(json['notes']),
    );
  }
}

/// `model ConsultationNote` — doctor-authored, read-only for parents.
class ConsultationNote {
  const ConsultationNote({
    required this.id,
    required this.childId,
    required this.doctorId,
    required this.notes,
    required this.createdAt,
    this.treatmentPlan,
    this.appointmentId,
    this.doctorFirstName,
    this.doctorLastName,
    this.doctorSpecialization,
  });

  final String id;
  final String childId;
  final String doctorId;
  final String notes;
  final DateTime createdAt;
  final String? treatmentPlan;
  final String? appointmentId;
  final String? doctorFirstName;
  final String? doctorLastName;
  final String? doctorSpecialization;

  factory ConsultationNote.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? doctor = Json.mapOrNull(json['doctor']);
    return ConsultationNote(
      id: Json.str(json['id']),
      childId: Json.str(json['childId']),
      doctorId: Json.str(json['doctorId']),
      notes: Json.str(json['notes']),
      createdAt: Json.date(json['createdAt']),
      treatmentPlan: Json.strOrNull(json['treatmentPlan']),
      appointmentId: Json.strOrNull(json['appointmentId']),
      doctorFirstName: doctor == null
          ? null
          : Json.strOrNull(doctor['firstName']),
      doctorLastName: doctor == null
          ? null
          : Json.strOrNull(doctor['lastName']),
      doctorSpecialization: doctor == null
          ? null
          : Json.strOrNull(doctor['specialization']),
    );
  }

  String get doctorName {
    final String name = '${doctorFirstName ?? ''} ${doctorLastName ?? ''}'
        .trim();
    return name.isEmpty ? 'Attending doctor' : 'Dr. $name';
  }
}

/// `GET /health-records/child/:childId/baseline` — the child row with its
/// allergies, medications and past illnesses included.
class ChildBaseline {
  const ChildBaseline({
    this.child,
    this.allergies = const <Allergy>[],
    this.medications = const <Medication>[],
    this.illnesses = const <IllnessHistory>[],
  });

  final Child? child;
  final List<Allergy> allergies;
  final List<Medication> medications;
  final List<IllnessHistory> illnesses;

  factory ChildBaseline.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return const ChildBaseline();
    return ChildBaseline(
      child: json['id'] == null ? null : Child.fromJson(json),
      allergies: Json.mapList(json['allergies']).map(Allergy.fromJson).toList(),
      medications: Json.mapList(
        json['medications'],
      ).map(Medication.fromJson).toList(),
      illnesses: Json.mapList(
        json['illnesses'],
      ).map(IllnessHistory.fromJson).toList(),
    );
  }

  bool get isEmpty =>
      allergies.isEmpty && medications.isEmpty && illnesses.isEmpty;
}

/// `model MedicalRecord` — the legacy generalised record, still readable at
/// `GET /medical-records/child/:childId`.
class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.childId,
    required this.diagnosis,
    required this.recordedAt,
    this.treatment,
    this.notes,
  });

  final String id;
  final String childId;
  final String diagnosis;
  final DateTime recordedAt;
  final String? treatment;
  final String? notes;

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: Json.str(json['id']),
      childId: Json.str(json['childId']),
      diagnosis: Json.str(json['diagnosis']),
      recordedAt: Json.date(json['recordedAt']),
      treatment: Json.strOrNull(json['treatment']),
      notes: Json.strOrNull(json['notes']),
    );
  }
}

/// `model ParentInfo` — guardian/emergency contacts attached to a child.
class ParentInfo {
  const ParentInfo({
    required this.id,
    required this.childId,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.relationship,
    this.healthStatus,
  });

  final String id;
  final String childId;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String relationship;
  final String? healthStatus;

  factory ParentInfo.fromJson(Map<String, dynamic> json) {
    return ParentInfo(
      id: Json.str(json['id']),
      childId: Json.str(json['childId']),
      fullName: Json.str(json['fullName']),
      phoneNumber: Json.str(json['phoneNumber']),
      address: Json.str(json['address']),
      relationship: Json.str(json['relationship'], fallback: 'OTHER'),
      healthStatus: Json.strOrNull(json['healthStatus']),
    );
  }
}
