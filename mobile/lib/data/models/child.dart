import 'json_utils.dart';

/// `model Child` — backend/prisma/schema.prisma
///
/// `gender` is a plain String column (not an enum), so the UI offers the values
/// the web app uses but never rejects an unexpected one coming back.
class Child {
  const Child({
    required this.id,
    required this.parentId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.bloodType,
    this.createdAt,
    this.parentFirstName,
    this.parentLastName,
  });

  final String id;
  final String parentId;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String gender;
  final String? bloodType;
  final DateTime? createdAt;

  /// Present when the backend includes `parent` (doctor/facility/admin lists).
  final String? parentFirstName;
  final String? parentLastName;

  factory Child.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? parent = Json.mapOrNull(json['parent']);
    return Child(
      id: Json.str(json['id']),
      parentId: Json.str(json['parentId']),
      firstName: Json.str(json['firstName']),
      lastName: Json.str(json['lastName']),
      dateOfBirth: Json.date(json['dateOfBirth']),
      gender: Json.str(json['gender']),
      bloodType: Json.strOrNull(json['bloodType']),
      createdAt: Json.dateOrNull(json['createdAt']),
      parentFirstName: parent == null
          ? null
          : Json.strOrNull(parent['firstName']),
      parentLastName: parent == null
          ? null
          : Json.strOrNull(parent['lastName']),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String? get parentName {
    final String name = '${parentFirstName ?? ''} ${parentLastName ?? ''}'
        .trim();
    return name.isEmpty ? null : name;
  }

  /// Whole months since birth — the same basis the growth service uses.
  int get ageInMonths {
    final DateTime now = DateTime.now();
    int months =
        (now.year - dateOfBirth.year) * 12 + (now.month - dateOfBirth.month);
    if (now.day < dateOfBirth.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  String get ageLabel {
    final int months = ageInMonths;
    if (months < 1) {
      final int days = DateTime.now().difference(dateOfBirth).inDays;
      return '$days day${days == 1 ? '' : 's'} old';
    }
    if (months < 24) return '$months month${months == 1 ? '' : 's'} old';
    final int years = months ~/ 12;
    final int rest = months % 12;
    if (rest == 0) return '$years year${years == 1 ? '' : 's'} old';
    return '$years yr $rest mo old';
  }
}
