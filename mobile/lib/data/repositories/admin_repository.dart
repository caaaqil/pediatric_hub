import '../../core/network/api_client.dart';
import '../models/telemetry.dart';

/// `backend/src/routes/admin.routes.js` and `user.routes.js` (ADMIN only).
class AdminRepository {
  const AdminRepository(this._api);

  final ApiClient _api;

  /// `GET /admin/telemetry`
  Future<AdminTelemetry> telemetry() async {
    final dynamic data = await _api.getData('/admin/telemetry');
    return AdminTelemetry.fromJson(asMap(data));
  }

  /// `GET /admin/users` — every non-deleted account, newest first.
  Future<List<ManagedUser>> users() async {
    final dynamic data = await _api.getData('/admin/users');
    return asMapList(data).map(ManagedUser.fromJson).toList();
  }

  /// `POST /admin/users/suspend` — `suspend: true` sets `isActive = false`.
  Future<void> setSuspended({
    required String userId,
    required bool suspend,
  }) async {
    await _api.postData(
      '/admin/users/suspend',
      body: <String, dynamic>{'userId': userId, 'suspend': suspend},
    );
  }

  /// `GET /admin/audits?limit=`
  Future<List<AuditLog>> audits({int limit = 100}) async {
    final dynamic data = await _api.getData(
      '/admin/audits',
      query: <String, dynamic>{'limit': '$limit'},
    );
    return asMapList(data).map(AuditLog.fromJson).toList();
  }

  /// `POST /users` — create an account directly (already email-verified).
  Future<void> createUser({
    required String email,
    required String password,
    required String role,
  }) async {
    await _api.postData(
      '/users',
      body: <String, dynamic>{
        'email': email,
        'password': password,
        'role': role,
      },
    );
  }

  /// `PUT /users/:id/role`
  Future<void> updateRole({
    required String userId,
    required String role,
  }) async {
    await _api.putData(
      '/users/$userId/role',
      body: <String, dynamic>{'role': role},
    );
  }

  /// `DELETE /users/:id` — soft delete (sets deletedAt and isActive = false).
  Future<void> deleteUser(String userId) => _api.deleteData('/users/$userId');
}
