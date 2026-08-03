import 'appointment.dart';
import 'child.dart';
import 'doctor.dart';
import 'enums.dart';
import 'json_utils.dart';

/// `model FacilityProfile`.
class Facility {
  const Facility({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.facilityType,
    required this.isActive,
    this.email,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String address;
  final String phoneNumber;
  final FacilityType facilityType;
  final bool isActive;
  final String? email;
  final DateTime? createdAt;

  factory Facility.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? user = Json.mapOrNull(json['user']);
    return Facility(
      id: Json.str(json['id']),
      userId: Json.str(json['userId']),
      name: Json.str(json['name']),
      address: Json.str(json['address']),
      phoneNumber: Json.str(json['phoneNumber']),
      facilityType: FacilityType.fromJson(json['facilityType']),
      isActive: Json.boolean(json['isActive'], fallback: true),
      email: user == null ? null : Json.strOrNull(user['email']),
      createdAt: Json.dateOrNull(json['createdAt']),
    );
  }
}

/// `model HealthService` — services offered by a facility.
class HealthService {
  const HealthService({
    required this.id,
    required this.facilityId,
    required this.name,
    required this.isActive,
    this.description,
    this.price,
    this.createdAt,
  });

  final String id;
  final String facilityId;
  final String name;
  final bool isActive;
  final String? description;
  final double? price;
  final DateTime? createdAt;

  factory HealthService.fromJson(Map<String, dynamic> json) {
    return HealthService(
      id: Json.str(json['id']),
      facilityId: Json.str(json['facilityId']),
      name: Json.str(json['name']),
      isActive: Json.boolean(json['isActive'], fallback: true),
      description: Json.strOrNull(json['description']),
      price: Json.decimalOrNull(json['price']),
      createdAt: Json.dateOrNull(json['createdAt']),
    );
  }
}

/// `GET /facilities/my-scope` — the single call that powers the facility portal.
class FacilityScope {
  const FacilityScope({
    required this.facility,
    required this.doctorCount,
    required this.serviceCount,
    required this.appointmentCount,
    required this.patientCount,
    required this.doctors,
    required this.services,
    required this.appointments,
    required this.patients,
  });

  final Facility facility;
  final int doctorCount;
  final int serviceCount;
  final int appointmentCount;
  final int patientCount;
  final List<Doctor> doctors;
  final List<HealthService> services;
  final List<Appointment> appointments;
  final List<Child> patients;

  factory FacilityScope.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> counts =
        Json.mapOrNull(json['counts']) ?? <String, dynamic>{};
    return FacilityScope(
      facility: Facility.fromJson(
        Json.mapOrNull(json['facility']) ?? <String, dynamic>{},
      ),
      doctorCount: Json.integer(counts['doctors']),
      serviceCount: Json.integer(counts['services']),
      appointmentCount: Json.integer(counts['appointments']),
      patientCount: Json.integer(counts['patients']),
      doctors: Json.mapList(json['doctors']).map(Doctor.fromJson).toList(),
      services: Json.mapList(
        json['services'],
      ).map(HealthService.fromJson).toList(),
      appointments: Json.mapList(
        json['appointments'],
      ).map(Appointment.fromJson).toList(),
      patients: Json.mapList(json['patients']).map(Child.fromJson).toList(),
    );
  }
}
