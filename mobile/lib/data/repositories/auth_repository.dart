import '../../core/network/api_client.dart';
import '../models/user.dart';

/// `backend/src/routes/auth.routes.js`
class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  /// `POST /auth/login` → `{ user, token, refreshToken }`
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final dynamic data = await _api.postData(
      '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );
    return AuthSession.fromJson(asMap(data));
  }

  /// `POST /auth/register` → `{ user, token, verificationToken }`
  ///
  /// `role` accepts PARENT | DOCTOR | FACILITY | ADMIN. DOCTOR additionally
  /// honours `licenseNumber` / `specialization`; FACILITY builds its profile
  /// name from `firstName + lastName` and uses `phoneNumber` / `address`.
  Future<RegistrationResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
    String? address,
    String? licenseNumber,
    String? specialization,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    };
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      body['phoneNumber'] = phoneNumber;
    }
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      body['licenseNumber'] = licenseNumber;
    }
    if (specialization != null && specialization.isNotEmpty) {
      body['specialization'] = specialization;
    }

    final dynamic data = await _api.postData('/auth/register', body: body);
    return RegistrationResult.fromJson(asMap(data));
  }

  /// `GET /auth/profile` → `{ user: { id, email, role, profile } }`
  Future<AppUser> profile() async {
    final dynamic data = await _api.getData('/auth/profile');
    final Map<String, dynamic> map = asMap(data);
    return AppUser.fromJson(asMap(map['user']));
  }

  /// `POST /auth/forgot-password` — emails a 6-digit OTP valid for 10 minutes.
  /// Always resolves, even for unknown addresses (enumeration guard).
  Future<void> forgotPassword(String email) async {
    await _api.postData(
      '/auth/forgot-password',
      body: <String, dynamic>{'email': email},
    );
  }

  /// `POST /auth/reset-password` — `token` is the 6-digit OTP from the email.
  Future<void> resetPassword({
    required String otp,
    required String newPassword,
  }) async {
    await _api.postData(
      '/auth/reset-password',
      body: <String, dynamic>{'token': otp, 'newPassword': newPassword},
    );
  }

  /// `POST /auth/verify-email` — `token` is the `verificationToken` handed back
  /// by registration.
  Future<void> verifyEmail(String token) async {
    await _api.postData(
      '/auth/verify-email',
      body: <String, dynamic>{'token': token},
    );
  }

  /// `PUT /parents/:id` — parent profile edit (id is the ParentProfile id).
  Future<void> updateParentProfile({
    required String parentProfileId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (address != null) body['address'] = address;
    await _api.putData('/parents/$parentProfileId', body: body);
  }
}
