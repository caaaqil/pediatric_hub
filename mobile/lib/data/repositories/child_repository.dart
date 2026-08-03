import '../../core/network/api_client.dart';
import '../models/child.dart';

/// `backend/src/routes/child.routes.js`
class ChildRepository {
  const ChildRepository(this._api);

  final ApiClient _api;

  /// `GET /children/my-children` (PARENT)
  Future<List<Child>> myChildren() async {
    final dynamic data = await _api.getData('/children/my-children');
    return asMapList(data).map(Child.fromJson).toList();
  }

  /// `GET /children` (DOCTOR | ADMIN | FACILITY).
  /// FACILITY callers are scoped server-side to children seen by their doctors.
  Future<List<Child>> allChildren() async {
    final dynamic data = await _api.getData('/children');
    return asMapList(data).map(Child.fromJson).toList();
  }

  /// `GET /children/:id` — includes medicalRecords, vaccinations, growthRecords.
  Future<Child> byId(String id) async {
    final dynamic data = await _api.getData('/children/$id');
    return Child.fromJson(asMap(data));
  }

  /// `POST /children` (PARENT | ADMIN)
  Future<Child> create({
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String gender,
    String? bloodType,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      // Zod requires a full ISO-8601 datetime, not a bare date.
      'dateOfBirth': dateOfBirth.toUtc().toIso8601String(),
      'gender': gender,
    };
    if (bloodType != null && bloodType.isNotEmpty) {
      body['bloodType'] = bloodType;
    }
    final dynamic data = await _api.postData('/children', body: body);
    return Child.fromJson(asMap(data));
  }

  /// `PUT /children/:id` (PARENT | ADMIN) — all fields optional.
  Future<Child> update({
    required String id,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (dateOfBirth != null) {
      body['dateOfBirth'] = dateOfBirth.toUtc().toIso8601String();
    }
    if (gender != null) body['gender'] = gender;
    if (bloodType != null) body['bloodType'] = bloodType;

    final dynamic data = await _api.putData('/children/$id', body: body);
    return Child.fromJson(asMap(data));
  }
}
