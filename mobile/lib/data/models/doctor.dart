import 'json_utils.dart';

/// `model DoctorProfile`.
///
/// Comes back from three endpoints with slightly different includes:
///  • `GET /doctors`          → `{ user: { email }, facility: { id, name } }`
///  • `GET /doctors/:id`      → `{ user: { email }, facility: {...full} }`
///  • `GET /users/doctors`    → `{ user: { email, isActive } }`
class Doctor {
  const Doctor({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.specialization,
    required this.licenseNumber,
    required this.verificationStatus,
    this.facilityId,
    this.facilityName,
    this.facilityAddress,
    this.facilityPhone,
    this.email,
    this.userIsActive,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String specialization;
  final String licenseNumber;

  /// Free-form String on the schema; the web admin sets "PENDING" / "ACTIVE".
  final String verificationStatus;

  final String? facilityId;
  final String? facilityName;
  final String? facilityAddress;
  final String? facilityPhone;
  final String? email;
  final bool? userIsActive;
  final DateTime? createdAt;

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? user = Json.mapOrNull(json['user']);
    final Map<String, dynamic>? facility = Json.mapOrNull(json['facility']);
    return Doctor(
      id: Json.str(json['id']),
      userId: Json.str(json['userId']),
      firstName: Json.str(json['firstName']),
      lastName: Json.str(json['lastName']),
      specialization: Json.str(json['specialization']),
      licenseNumber: Json.str(json['licenseNumber']),
      verificationStatus: Json.str(
        json['verificationStatus'],
        fallback: 'PENDING',
      ),
      facilityId:
          Json.strOrNull(json['facilityId']) ??
          (facility == null ? null : Json.strOrNull(facility['id'])),
      facilityName: facility == null ? null : Json.strOrNull(facility['name']),
      facilityAddress: facility == null
          ? null
          : Json.strOrNull(facility['address']),
      facilityPhone: facility == null
          ? null
          : Json.strOrNull(facility['phoneNumber']),
      email: user == null ? null : Json.strOrNull(user['email']),
      userIsActive: user == null || user['isActive'] == null
          ? null
          : Json.boolean(user['isActive']),
      createdAt: Json.dateOrNull(json['createdAt']),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String get displayName => 'Dr. $fullName';

  bool get isVerified => verificationStatus.toUpperCase() == 'ACTIVE';

  String get initials {
    final String f = firstName.isNotEmpty ? firstName.substring(0, 1) : '';
    final String l = lastName.isNotEmpty ? lastName.substring(0, 1) : '';
    final String joined = (f + l).toUpperCase();
    return joined.isEmpty ? 'DR' : joined;
  }
}

/// `model DoctorAvailability` — returned by `GET /appointments/availability/:doctorId`.
class DoctorAvailability {
  const DoctorAvailability({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  final String id;
  final String doctorId;

  /// 0 = Sunday … 6 = Saturday
  final int dayOfWeek;

  /// "HH:MM"
  final String startTime;
  final String endTime;
  final bool isActive;

  factory DoctorAvailability.fromJson(Map<String, dynamic> json) {
    return DoctorAvailability(
      id: Json.str(json['id']),
      doctorId: Json.str(json['doctorId']),
      dayOfWeek: Json.integer(json['dayOfWeek']),
      startTime: Json.str(json['startTime']),
      endTime: Json.str(json['endTime']),
      isActive: Json.boolean(json['isActive'], fallback: true),
    );
  }

  static const List<String> dayNames = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String get dayName =>
      dayOfWeek >= 0 && dayOfWeek < dayNames.length ? dayNames[dayOfWeek] : '—';
}
