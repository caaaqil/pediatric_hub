import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/misc.dart';
import '../models/telemetry.dart';

/// Dashboard telemetry, notifications, education, emergency contacts, payments
/// and direct messages — the endpoints shared across every role.
class SupportRepository {
  const SupportRepository(this._api);

  final ApiClient _api;

  /// `GET /dashboard/telemetry` — role-aware counters for the home screen.
  Future<DashboardTelemetry> telemetry() async {
    final dynamic data = await _api.getData('/dashboard/telemetry');
    return DashboardTelemetry.fromJson(asMap(data));
  }

  /// `GET /notifications` — the signed-in user's inbox, newest first.
  Future<List<AppNotification>> notifications() async {
    final dynamic data = await _api.getData('/notifications');
    return asMapList(data).map(AppNotification.fromJson).toList();
  }

  /// `PATCH /notifications/:id/read`
  Future<void> markNotificationRead(String id) async {
    await _api.patchData('/notifications/$id/read');
  }

  /// `GET /education` — published articles only.
  Future<List<EducationalContent>> articles() async {
    final dynamic data = await _api.getData('/education');
    return asMapList(data).map(EducationalContent.fromJson).toList();
  }

  /// `GET /emergency` — SOS contact directory.
  Future<List<EmergencyContact>> emergencyContacts() async {
    final dynamic data = await _api.getData('/emergency');
    return asMapList(data).map(EmergencyContact.fromJson).toList();
  }

  // ── Payments ──────────────────────────────────────────────────────────────
  //
  // These three endpoints bypass the standard response wrapper
  // (`payment.controller.js`), so they are read off the raw response.

  /// `GET /payments` → `{ data: [...] }`
  Future<List<Payment>> payments() async {
    final Response<dynamic> res = await _api.rawGet('/payments');
    final dynamic body = res.data;
    final dynamic list = body is Map ? body['data'] : body;
    return asMapList(list).map(Payment.fromJson).toList();
  }

  /// `POST /payments` → `{ success, data, message? }`, HTTP 402 when declined.
  ///
  /// `accountNo` is an EVC Plus wallet number (`252XXXXXXXX` / `06XXXXXXXX`).
  Future<PaymentResult> pay({
    required String accountNo,
    required double amount,
    String? description,
    String? appointmentId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'accountNo': accountNo,
      'amount': amount,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (appointmentId != null && appointmentId.isNotEmpty) {
      body['appointmentId'] = appointmentId;
    }

    final Response<dynamic> res = await _api.rawPost('/payments', body: body);
    final Map<String, dynamic> payload = asMap(res.data);
    final Map<String, dynamic> paymentJson = asMap(payload['data']);

    return PaymentResult(
      success: payload['success'] == true,
      payment: paymentJson.isEmpty ? null : Payment.fromJson(paymentJson),
      message: payload['message']?.toString(),
    );
  }

  // ── Direct messages ───────────────────────────────────────────────────────

  /// `GET /chat/contacts` — parents see every doctor; doctors see their parents.
  Future<List<ChatContact>> chatContacts() async {
    final dynamic data = await _api.getData('/chat/contacts');
    return asMapList(data).map(ChatContact.fromJson).toList();
  }

  /// `GET /chat/:targetUserId` — last 50 messages, oldest first.
  Future<List<DirectMessage>> messages(String targetUserId) async {
    final dynamic data = await _api.getData('/chat/$targetUserId');
    return asMapList(data).map(DirectMessage.fromJson).toList();
  }

  /// `POST /chat`
  Future<DirectMessage> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final dynamic data = await _api.postData(
      '/chat',
      body: <String, dynamic>{'receiverId': receiverId, 'content': content},
    );
    return DirectMessage.fromJson(asMap(data));
  }
}
