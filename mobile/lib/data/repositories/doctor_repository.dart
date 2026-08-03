import '../../core/network/api_client.dart';
import '../models/doctor.dart';
import '../models/telemetry.dart';

/// `backend/src/routes/doctor.routes.js` (+ `GET /users/doctors`)
class DoctorRepository {
  const DoctorRepository(this._api);

  final ApiClient _api;

  /// `GET /doctors?page&limit&search` → `{ data, meta }`.
  ///
  /// Server-side `search` only matches **lastName** (`doctor.service.js`), so
  /// the browse screen filters names/specialisations locally on top of it.
  /// FACILITY callers are automatically scoped to their own staff.
  Future<Paginated<Doctor>> list({
    int page = 1,
    int limit = 50,
    String? search,
    String? facilityId,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'page': '$page',
      'limit': '$limit',
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (facilityId != null && facilityId.isNotEmpty) {
      query['facilityId'] = facilityId;
    }

    final dynamic data = await _api.getData('/doctors', query: query);
    return Paginated<Doctor>.fromJson(asMap(data), Doctor.fromJson);
  }

  /// `GET /doctors/:id` — includes the facility and the account email.
  Future<Doctor> byId(String id) async {
    final dynamic data = await _api.getData('/doctors/$id');
    return Doctor.fromJson(asMap(data));
  }

  /// `GET /users/doctors` (PARENT | ADMIN) — flat, unpaginated list used by the
  /// booking flow because it carries `facilityId` for service lookup.
  Future<List<Doctor>> bookable() async {
    final dynamic data = await _api.getData('/users/doctors');
    return asMapList(data).map(Doctor.fromJson).toList();
  }

  /// `POST /doctors` (ADMIN | FACILITY).
  ///
  /// Supplying `email` + `password` also creates the login (inactive until an
  /// admin flips verificationStatus to ACTIVE). FACILITY callers have their own
  /// facilityId forced server-side.
  Future<Doctor> create({
    required String firstName,
    required String lastName,
    required String specialization,
    String? email,
    String? password,
    String? licenseNumber,
    String? phoneNumber,
    String? facilityId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'specialization': specialization,
    };
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      body['licenseNumber'] = licenseNumber;
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      body['phoneNumber'] = phoneNumber;
    }
    if (facilityId != null && facilityId.isNotEmpty) {
      body['facilityId'] = facilityId;
    }

    final dynamic data = await _api.postData('/doctors', body: body);
    return Doctor.fromJson(asMap(data));
  }

  /// `PUT /doctors/:id` (DOCTOR | ADMIN | FACILITY).
  /// Setting `verificationStatus` to ACTIVE also activates the login.
  Future<Doctor> update({
    required String id,
    String? firstName,
    String? lastName,
    String? specialization,
    String? licenseNumber,
    String? phoneNumber,
    String? facilityId,
    String? verificationStatus,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (specialization != null) body['specialization'] = specialization;
    if (licenseNumber != null) body['licenseNumber'] = licenseNumber;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (facilityId != null) body['facilityId'] = facilityId;
    if (verificationStatus != null) {
      body['verificationStatus'] = verificationStatus;
    }

    final dynamic data = await _api.putData('/doctors/$id', body: body);
    return Doctor.fromJson(asMap(data));
  }

  /// `DELETE /doctors/:id` (ADMIN | FACILITY) — soft delete that also cancels
  /// the doctor's pending and confirmed appointments.
  Future<void> archive(String id) => _api.deleteData('/doctors/$id');
}
