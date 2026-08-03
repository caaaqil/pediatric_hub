// Live end-to-end test: real Riverpod providers → Dio → the running backend →
// MySQL. Nothing is stubbed except the two storage plugins, which need platform
// channels that do not exist in the test VM.
//
// Requires the backend to be running and seeded:
//
//   cd backend && node prisma/seed.js && npm run dev
//
// Run it with the base URL pointed at your host:
//
//   flutter test test/live_backend_test.dart \
//     --dart-define=API_BASE_URL=http://localhost:3000/api/v1
//
// Every test self-skips when the backend is unreachable, so a plain
// `flutter test` on a machine with no server still passes.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pediatric_health_hub_mobile/config/api_config.dart';
import 'package:pediatric_health_hub_mobile/data/models/appointment.dart';
import 'package:pediatric_health_hub_mobile/data/models/child.dart';
import 'package:pediatric_health_hub_mobile/data/models/doctor.dart';
import 'package:pediatric_health_hub_mobile/data/models/enums.dart';
import 'package:pediatric_health_hub_mobile/data/models/misc.dart';
import 'package:pediatric_health_hub_mobile/data/models/telemetry.dart';
import 'package:pediatric_health_hub_mobile/data/models/vaccination.dart';
import 'package:pediatric_health_hub_mobile/presentation/providers/providers.dart';

/// In-memory stand-in for the Keystore/Keychain channel.
void _mockSecureStorage() {
  final Map<String, String> store = <String, String>{};
  const MethodChannel channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
        final Map<Object?, Object?> args =
            (call.arguments as Map<Object?, Object?>?) ?? <Object?, Object?>{};
        final String key = args['key']?.toString() ?? '';
        switch (call.method) {
          case 'write':
            store[key] = args['value']?.toString() ?? '';
            return null;
          case 'read':
            return store[key];
          case 'delete':
            store.remove(key);
            return null;
          case 'deleteAll':
            store.clear();
            return null;
          case 'readAll':
            return store;
          case 'containsKey':
            return store.containsKey(key);
          default:
            return null;
        }
      });
}

Future<bool> _backendUp() async {
  try {
    final Response<dynamic> res = await Dio().get<dynamic>(
      '${ApiConfig.baseUrl.replaceFirst('/api/v1', '')}/api/health',
      options: Options(receiveTimeout: const Duration(seconds: 5)),
    );
    return res.statusCode == 200;
  } on DioException {
    return false;
  }
}

Future<ProviderContainer> _signIn(String email, String password) async {
  final ProviderContainer container = ProviderContainer();
  final bool ok = await container
      .read(authControllerProvider.notifier)
      .login(email: email, password: password);
  expect(
    ok,
    isTrue,
    reason:
        'login failed for $email: '
        '${container.read(authControllerProvider).error}',
  );
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool up;

  setUpAll(() async {
    // flutter_test installs an HttpOverrides that fails every real request.
    // Clearing it lets Dio actually reach the backend.
    HttpOverrides.global = null;
    _mockSecureStorage();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    up = await _backendUp();
    if (!up) {
      // ignore: avoid_print
      print('Backend not reachable at ${ApiConfig.baseUrl} — skipping.');
    }
  });

  group('PARENT', () {
    test('signs in and the JWT reaches every parent endpoint', () async {
      if (!up) return;
      final ProviderContainer c = await _signIn(
        'parent@pediatric-hub.com',
        'parent123',
      );
      addTearDown(c.dispose);

      final AuthState auth = c.read(authControllerProvider);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.role, UserRole.parent);
      // Login attaches the ParentProfile, which Profile → Edit needs.
      expect(auth.user?.profile?.id, isNotEmpty);

      // The interceptor must be attaching the bearer token on these.
      final List<Child> children = await c
          .read(childRepositoryProvider)
          .myChildren();
      final List<Appointment> schedule = await c
          .read(appointmentRepositoryProvider)
          .mySchedule();
      final DashboardTelemetry telemetry = await c
          .read(supportRepositoryProvider)
          .telemetry();
      final List<AppNotification> notes = await c
          .read(supportRepositoryProvider)
          .notifications();
      final List<Doctor> doctors = await c
          .read(doctorRepositoryProvider)
          .bookable();

      expect(children, isA<List<Child>>());
      expect(schedule, isA<List<Appointment>>());
      expect(telemetry.title1, isNotEmpty);
      expect(notes, isA<List<AppNotification>>());
      expect(doctors, isNotEmpty, reason: 'seed.js creates one doctor');
    });

    test(
      'books an appointment and cancels it (parent-cancel endpoint)',
      () async {
        if (!up) return;
        final ProviderContainer c = await _signIn(
          'parent@pediatric-hub.com',
          'parent123',
        );
        addTearDown(c.dispose);

        final Child child = await c
            .read(childRepositoryProvider)
            .create(
              firstName: 'ZZTest',
              lastName: 'Harness',
              dateOfBirth: DateTime(2024, 5, 1),
              gender: 'Female',
              bloodType: 'O+',
            );
        expect(child.id, isNotEmpty);
        expect(child.fullName, 'ZZTest Harness');

        final List<Doctor> doctors = await c
            .read(doctorRepositoryProvider)
            .bookable();
        final Appointment booked = await c
            .read(appointmentRepositoryProvider)
            .book(
              childId: child.id,
              doctorId: doctors.first.id,
              scheduledAt: DateTime.now().add(const Duration(days: 9)),
              reason: 'automated harness',
            );
        expect(booked.status, AppointmentStatus.pending);

        // This is the backend change: PARENT may set CANCELLED on their own
        // child's appointment.
        final Appointment cancelled = await c
            .read(appointmentRepositoryProvider)
            .updateStatus(id: booked.id, status: AppointmentStatus.cancelled);
        expect(cancelled.status, AppointmentStatus.cancelled);

        // ignore: avoid_print
        print('CLEANUP childId=${child.id} appointmentId=${booked.id}');
      },
    );
  });

  group('DOCTOR / FACILITY', () {
    test('doctor sees the roster and schedule', () async {
      if (!up) return;
      final ProviderContainer c = await _signIn(
        'doctor@pediatric-hub.com',
        'doctor123',
      );
      addTearDown(c.dispose);

      expect(c.read(authControllerProvider).user?.role, UserRole.doctor);
      expect(
        await c.read(childRepositoryProvider).allChildren(),
        isA<List<Child>>(),
      );
      expect(
        await c.read(appointmentRepositoryProvider).mySchedule(),
        isA<List<Appointment>>(),
      );
      expect(
        (await c.read(supportRepositoryProvider).telemetry()).title1,
        isNotEmpty,
      );
    });

    test('facility loads its whole scope in one call', () async {
      if (!up) return;
      final ProviderContainer c = await _signIn(
        'facility@pediatric-hub.com',
        'facility123',
      );
      addTearDown(c.dispose);

      final dynamic scope = await c.read(facilityRepositoryProvider).myScope();
      expect(scope.facility.name, isNotEmpty);
      expect(scope.doctorCount, isA<int>());
    });
  });

  group('ADMIN', () {
    test('telemetry, users and audits decode', () async {
      if (!up) return;
      final ProviderContainer c = await _signIn(
        'admin@pediatric-hub.com',
        'admin123',
      );
      addTearDown(c.dispose);

      final AdminTelemetry t = await c
          .read(adminRepositoryProvider)
          .telemetry();
      final List<ManagedUser> users = await c
          .read(adminRepositoryProvider)
          .users();

      expect(t.totalUsers, greaterThan(0));
      expect(users, isNotEmpty);
      expect(
        await c.read(adminRepositoryProvider).audits(limit: 5),
        isA<List<AuditLog>>(),
      );
    });

    test('chatbot templates list / create / delete (new endpoints)', () async {
      if (!up) return;
      final ProviderContainer c = await _signIn(
        'admin@pediatric-hub.com',
        'admin123',
      );
      addTearDown(c.dispose);

      // GET /chatbot/templates — added for this app.
      final List<ChatbotTemplate> before = await c
          .read(chatbotRepositoryProvider)
          .templates();
      expect(before, isNotEmpty, reason: 'seed.js upserts six templates');

      final ChatbotTemplate created = await c
          .read(chatbotRepositoryProvider)
          .saveTemplate(
            triggerKeyword: 'zz-harness-keyword',
            response: 'Automated harness response, safe to delete.',
          );
      expect(created.id, isNotEmpty);

      // DELETE /chatbot/templates/:id — also added for this app.
      await c.read(chatbotRepositoryProvider).deleteTemplate(created.id);
      final List<ChatbotTemplate> after = await c
          .read(chatbotRepositoryProvider)
          .templates();
      expect(after.where((ChatbotTemplate t) => t.id == created.id), isEmpty);
    });

    test('admin registers a dose that the parent then completes', () async {
      if (!up) return;

      // The mocked keystore is a single map, so only one session can be signed
      // in at a time — exactly like a real device. Sign in sequentially rather
      // than holding two containers open, or the second login's token would be
      // sent for the first container's requests.

      // 1. As the parent: pick one of their children.
      ProviderContainer parent = await _signIn(
        'parent@pediatric-hub.com',
        'parent123',
      );
      final List<Child> children = await parent
          .read(childRepositoryProvider)
          .myChildren();
      parent.dispose();
      if (children.isEmpty) return; // nothing to attach a dose to

      // 2. As an admin: register an ad-hoc dose (DOCTOR/FACILITY/ADMIN only).
      final ProviderContainer admin = await _signIn(
        'admin@pediatric-hub.com',
        'admin123',
      );
      final Vaccination dose = await admin
          .read(vaccinationRepositoryProvider)
          .register(
            childId: children.first.id,
            vaccineName: 'ZZ Harness Vaccine',
            doseNumber: 1,
            scheduledDate: DateTime.now(),
          );
      admin.dispose();
      expect(dose.id, isNotEmpty);
      expect(dose.status, isNot(VaccineStatus.completed));

      // 3. Back as the parent — the backend change under test: PARENT may set
      //    COMPLETED on their own child's dose.
      parent = await _signIn('parent@pediatric-hub.com', 'parent123');
      addTearDown(parent.dispose);
      final Vaccination done = await parent
          .read(vaccinationRepositoryProvider)
          .updateStatus(
            vaccinationId: dose.id,
            status: VaccineStatus.completed,
          );
      expect(done.status, VaccineStatus.completed);
      expect(done.administeredDate, isNotNull);

      // ignore: avoid_print
      print('CLEANUP vaccinationId=${dose.id}');
    });
  });
}
