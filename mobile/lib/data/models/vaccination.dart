import 'enums.dart';
import 'json_utils.dart';

/// `model Vaccination` — one dose instance for one child.
class Vaccination {
  const Vaccination({
    required this.id,
    required this.childId,
    required this.vaccineName,
    required this.doseNumber,
    required this.scheduledDate,
    required this.status,
    this.administeredDate,
    this.batchNumber,
    this.notes,
  });

  final String id;
  final String childId;
  final String vaccineName;
  final int doseNumber;
  final DateTime scheduledDate;
  final VaccineStatus status;
  final DateTime? administeredDate;
  final String? batchNumber;
  final String? notes;

  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      id: Json.str(json['id']),
      childId: Json.str(json['childId']),
      vaccineName: Json.str(json['vaccineName']),
      doseNumber: Json.integer(json['doseNumber'], fallback: 1),
      scheduledDate: Json.date(json['scheduledDate']),
      status: VaccineStatus.fromJson(json['status']),
      administeredDate: Json.dateOrNull(json['administeredDate']),
      batchNumber: Json.strOrNull(json['batchNumber']),
      notes: Json.strOrNull(json['notes']),
    );
  }

  String get label => '$vaccineName — Dose $doseNumber';
}

/// `model VaccineTemplate` — the national protocol rows an admin maintains.
class VaccineTemplate {
  const VaccineTemplate({
    required this.id,
    required this.vaccineName,
    required this.doseNumber,
    required this.daysAfterBirth,
    required this.isMandatory,
    this.description,
  });

  final String id;
  final String vaccineName;
  final int doseNumber;
  final int daysAfterBirth;
  final bool isMandatory;
  final String? description;

  factory VaccineTemplate.fromJson(Map<String, dynamic> json) {
    return VaccineTemplate(
      id: Json.str(json['id']),
      vaccineName: Json.str(json['vaccineName']),
      doseNumber: Json.integer(json['doseNumber'], fallback: 1),
      daysAfterBirth: Json.integer(json['daysAfterBirth']),
      isMandatory: Json.boolean(json['isMandatory'], fallback: true),
      description: Json.strOrNull(json['description']),
    );
  }

  String get ageLabel {
    if (daysAfterBirth == 0) return 'At birth';
    if (daysAfterBirth < 30) {
      final int weeks = daysAfterBirth ~/ 7;
      return weeks <= 0 ? '$daysAfterBirth days' : '$weeks weeks';
    }
    final int months = daysAfterBirth ~/ 30;
    return '$months month${months == 1 ? '' : 's'}';
  }
}
