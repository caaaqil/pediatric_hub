import 'enums.dart';
import 'json_utils.dart';

/// One bar of the six-month series returned by `GET /dashboard/telemetry`.
class TelemetryPoint {
  const TelemetryPoint({
    required this.name,
    required this.uv,
    required this.sales,
    required this.orders,
  });

  final String name;
  final int uv;
  final int sales;
  final int orders;

  factory TelemetryPoint.fromJson(Map<String, dynamic> json) {
    return TelemetryPoint(
      name: Json.str(json['name']),
      uv: Json.integer(json['uv']),
      sales: Json.integer(json['sales']),
      orders: Json.integer(json['orders']),
    );
  }
}

/// `GET /dashboard/telemetry` — role-aware headline counters.
///
/// The backend labels the three tiles per role, so the UI just renders whatever
/// titles it is given rather than hard-coding them.
class DashboardTelemetry {
  const DashboardTelemetry({
    required this.title1,
    required this.count1,
    required this.title2,
    required this.count2,
    required this.title3,
    required this.count3,
    this.charts = const <TelemetryPoint>[],
  });

  final String title1;
  final int count1;
  final String title2;
  final int count2;
  final String title3;
  final int count3;
  final List<TelemetryPoint> charts;

  factory DashboardTelemetry.fromJson(Map<String, dynamic> json) {
    return DashboardTelemetry(
      title1: Json.str(json['title1'], fallback: '—'),
      count1: Json.integer(json['count1']),
      title2: Json.str(json['title2'], fallback: '—'),
      count2: Json.integer(json['count2']),
      title3: Json.str(json['title3'], fallback: '—'),
      count3: Json.integer(json['count3']),
      charts: Json.mapList(
        json['charts'],
      ).map(TelemetryPoint.fromJson).toList(),
    );
  }
}

/// `model AuditLog` with the `user { email, role }` include.
class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.entity,
    required this.createdAt,
    this.entityId,
    this.details,
    this.ipAddress,
    this.userEmail,
    this.userRole,
  });

  final String id;
  final String action;
  final String entity;
  final DateTime createdAt;
  final String? entityId;
  final String? details;
  final String? ipAddress;
  final String? userEmail;
  final UserRole? userRole;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? user = Json.mapOrNull(json['user']);
    return AuditLog(
      id: Json.str(json['id']),
      action: Json.str(json['action']),
      entity: Json.str(json['entity']),
      createdAt: Json.date(json['createdAt']),
      entityId: Json.strOrNull(json['entityId']),
      details: Json.strOrNull(json['details']),
      ipAddress: Json.strOrNull(json['ipAddress']),
      userEmail: user == null ? null : Json.strOrNull(user['email']),
      userRole: user == null ? null : UserRole.tryParse(user['role']),
    );
  }
}

/// `GET /admin/telemetry` — platform-wide counters plus the last 8 audits.
class AdminTelemetry {
  const AdminTelemetry({
    required this.totalUsers,
    required this.totalDoctors,
    required this.totalAppointments,
    required this.activeTeleconsults,
    required this.totalChatbotSessions,
    this.recentAudits = const <AuditLog>[],
  });

  final int totalUsers;
  final int totalDoctors;
  final int totalAppointments;
  final int activeTeleconsults;
  final int totalChatbotSessions;
  final List<AuditLog> recentAudits;

  factory AdminTelemetry.fromJson(Map<String, dynamic> json) {
    return AdminTelemetry(
      totalUsers: Json.integer(json['totalUsers']),
      totalDoctors: Json.integer(json['totalDoctors']),
      totalAppointments: Json.integer(json['totalAppointments']),
      activeTeleconsults: Json.integer(json['activeTeleconsults']),
      totalChatbotSessions: Json.integer(json['totalChatbotSessions']),
      recentAudits: Json.mapList(
        json['recentAudits'],
      ).map(AuditLog.fromJson).toList(),
    );
  }
}

/// A row of `GET /admin/users`.
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    required this.isEmailVerified,
    this.createdAt,
  });

  final String id;
  final String email;
  final UserRole role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? createdAt;

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: Json.str(json['id']),
      email: Json.str(json['email']),
      role: UserRole.tryParse(json['role']) ?? UserRole.parent,
      isActive: Json.boolean(json['isActive'], fallback: true),
      isEmailVerified: Json.boolean(json['isEmailVerified']),
      createdAt: Json.dateOrNull(json['createdAt']),
    );
  }
}

/// `{ data, meta }` envelope used by the paginated list endpoints.
class Paginated<T> {
  const Paginated({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.limit = 10,
    this.totalPages = 1,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final Map<String, dynamic> meta =
        Json.mapOrNull(json['meta']) ?? <String, dynamic>{};
    return Paginated<T>(
      items: Json.mapList(json['data']).map(parse).toList(),
      total: Json.integer(meta['total']),
      page: Json.integer(meta['page'], fallback: 1),
      limit: Json.integer(meta['limit'], fallback: 10),
      totalPages: Json.integer(meta['totalPages'], fallback: 1),
    );
  }
}
