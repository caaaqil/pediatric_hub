// Layout smoke tests for the screens ported from the web pages.
//
// A layout assertion (e.g. a Row with CrossAxisAlignment.stretch inside a
// ListView) blanks the whole screen at runtime without an obvious error, so
// every ported screen gets pumped here with stub data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pediatric_health_hub_mobile/config/theme/app_theme.dart';
import 'package:pediatric_health_hub_mobile/core/network/api_client.dart';
import 'package:pediatric_health_hub_mobile/core/storage/auth_storage.dart';
import 'package:pediatric_health_hub_mobile/data/repositories/support_repository.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/parent/book_appointment_screen.dart';
import 'package:pediatric_health_hub_mobile/data/models/child.dart';
import 'package:pediatric_health_hub_mobile/data/models/enums.dart';
import 'package:pediatric_health_hub_mobile/data/models/misc.dart';
import 'package:pediatric_health_hub_mobile/data/models/telemetry.dart';
import 'package:pediatric_health_hub_mobile/presentation/providers/providers.dart';
import 'package:pediatric_health_hub_mobile/data/models/doctor.dart';
import 'package:pediatric_health_hub_mobile/data/models/facility.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/admin/admin_doctors_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/admin/admin_facilities_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/admin/admin_payments_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/admin/admin_templates_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/admin/admin_users_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/parent/children_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/parent/vaccine_gateway_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/shared/education_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/shared/emergency_screen.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/shared/messages_screen.dart';

final List<ManagedUser> _users = <ManagedUser>[
  ManagedUser(
    id: '17b4d121-7aa0-4266-a0af-4620ddef17a1',
    email: 'admin@pediatric-hub.com',
    role: UserRole.admin,
    isActive: true,
    isEmailVerified: true,
    createdAt: DateTime(2026, 7, 30),
  ),
  ManagedUser(
    id: '27b4d121-7aa0-4266-a0af-4620ddef17a2',
    email: 'parent@pediatric-hub.com',
    role: UserRole.parent,
    isActive: false,
    isEmailVerified: true,
    createdAt: DateTime(2026, 7, 30),
  ),
];

final List<Child> _children = <Child>[
  Child(
    id: 'c1',
    parentId: 'p1',
    firstName: 'Amina',
    lastName: 'Hassan',
    dateOfBirth: DateTime(2024, 5, 1),
    gender: 'FEMALE',
    bloodType: 'O+',
    createdAt: DateTime(2026, 1, 1),
  ),
];

final List<ChatbotTemplate> _templates = <ChatbotTemplate>[
  ChatbotTemplate(
    id: 't1',
    triggerKeyword: 'fever, high temperature',
    response: 'Keep your child hydrated and monitor the temperature.',
    createdAt: DateTime(2026, 7, 30),
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const <Override>[],
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: AppTheme.dark(), home: screen),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('Admin command hub renders', (WidgetTester tester) async {
    await _pump(
      tester,
      const AdminCommandHubScreen(),
      overrides: <Override>[
        adminTelemetryProvider.overrideWith(
          (Ref ref) async => const AdminTelemetry(
            totalUsers: 4,
            totalDoctors: 1,
            totalAppointments: 0,
            activeTeleconsults: 0,
            totalChatbotSessions: 3,
          ),
        ),
        adminUsersProvider.overrideWith((Ref ref) async => _users),
        adminAuditsProvider.overrideWith((Ref ref) async => <AuditLog>[]),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('COMMAND HUB'), findsOneWidget);
  });

  testWidgets('Admin users renders', (WidgetTester tester) async {
    await _pump(
      tester,
      const AdminUsersScreen(),
      overrides: <Override>[
        adminUsersProvider.overrideWith((Ref ref) async => _users),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Users Management'), findsOneWidget);
  });

  testWidgets('Admin chatbot templates renders', (WidgetTester tester) async {
    await _pump(
      tester,
      const AdminTemplatesScreen(),
      overrides: <Override>[
        chatbotTemplatesProvider.overrideWith((Ref ref) async => _templates),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Manage Chatbot Templates'), findsOneWidget);
  });

  testWidgets('Children screen renders with data', (WidgetTester tester) async {
    await _pump(
      tester,
      const ChildrenScreen(),
      overrides: <Override>[
        myChildrenProvider.overrideWith((Ref ref) async => _children),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('My Registered Children'), findsOneWidget);
    expect(find.text('Amina Hassan'), findsOneWidget);
  });

  testWidgets('Admin doctor registry renders', (WidgetTester tester) async {
    await _pump(
      tester,
      const AdminDoctorsScreen(),
      overrides: <Override>[
        doctorRegistryProvider.overrideWith(
          (Ref ref) async => <Doctor>[
            Doctor(
              id: '5b8b4cc0-1111-2222-3333-444455556666',
              userId: 'u1',
              firstName: 'Sarah',
              lastName: 'Jenkins',
              specialization: 'Pediatric Pulmonology',
              licenseNumber: 'MD-123456789',
              verificationStatus: 'PENDING',
            ),
          ],
        ),
        facilitiesProvider.overrideWith((Ref ref) async => <Facility>[]),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Doctor Registry (DOC Register)'), findsOneWidget);
    expect(find.text('Dr. Sarah Jenkins'), findsOneWidget);
    expect(find.text('1 Pending'), findsOneWidget);
  });

  testWidgets('Admin facility registry renders', (WidgetTester tester) async {
    await _pump(
      tester,
      const AdminFacilitiesScreen(),
      overrides: <Override>[
        facilitiesProvider.overrideWith(
          (Ref ref) async => <Facility>[
            Facility(
              id: 'f1',
              userId: 'u2',
              name: 'Central Pediatric Clinic',
              address: '123 Health Ave, Medical District',
              phoneNumber: '+1-555-200-1234',
              facilityType: FacilityType.clinic,
              isActive: true,
            ),
          ],
        ),
        doctorRegistryProvider.overrideWith((Ref ref) async => <Doctor>[]),
      ],
    );
    expect(tester.takeException(), isNull);
    // The title appears in both the app bar and the hero banner.
    expect(find.text('Facility Registry'), findsWidgets);
    expect(find.text('Central Pediatric Clinic'), findsOneWidget);
    expect(find.text('Total Doctors'.toUpperCase()), findsOneWidget);
  });

  testWidgets('Admin payment history renders when empty', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AdminPaymentsScreen(),
      overrides: <Override>[
        paymentsProvider.overrideWith((Ref ref) async => <Payment>[]),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('All EVC Plus / WaafiPay transactions'), findsOneWidget);
    expect(find.text('No transactions found'), findsOneWidget);
  });

  testWidgets('Children screen renders when empty', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const ChildrenScreen(),
      overrides: <Override>[
        myChildrenProvider.overrideWith((Ref ref) async => <Child>[]),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('No Children Registered'), findsOneWidget);
  });

  testWidgets('Education screen renders the ported Somali articles', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const EducationScreen(),
      overrides: <Override>[
        articlesProvider.overrideWith(
          (Ref ref) async => <EducationalContent>[],
        ),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Maqaalada Muuqda'), findsOneWidget);
    expect(find.text('Hagaha Nafaqada'), findsOneWidget);
    expect(find.text('MAAREYNTA XUMMADDA'), findsWidgets);
  });

  testWidgets('Immunization gateway renders', (WidgetTester tester) async {
    await _pump(
      tester,
      const VaccineGatewayScreen(),
      overrides: <Override>[
        myChildrenProvider.overrideWith((Ref ref) async => _children),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Immunization Gateway'), findsOneWidget);
    expect(find.text('SELECT PATIENT PROFILE'), findsOneWidget);
    expect(find.text('OPEN IMMUNIZATION MATRIX'), findsOneWidget);
  });

  testWidgets('Emergency guidance renders the ported protocols', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const EmergencyScreen(),
      overrides: <Override>[
        emergencyContactsProvider.overrideWith(
          (Ref ref) async => <EmergencyContact>[],
        ),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('CALL AMBULANCE · 252-1'), findsOneWidget);
    expect(find.text('Immediate Action Protocols'), findsOneWidget);
    expect(find.text('Severe Difficulty Breathing'), findsOneWidget);
    expect(find.text('Nearest Approved Facilities'), findsOneWidget);
    expect(find.text('Banadir Health Center'), findsOneWidget);
  });

  testWidgets('Message doctor renders the contact list', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const MessagesScreen(),
      overrides: <Override>[
        currentRoleProvider.overrideWithValue(UserRole.parent),
        chatContactsProvider.overrideWith(
          (Ref ref) async => <ChatContact>[
            ChatContact(id: 'u9', name: 'Dr. Sarah Jenkins', role: 'DOCTOR'),
          ],
        ),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Message Your Doctor'), findsOneWidget);
    expect(find.text('Available Doctors'), findsOneWidget);
    expect(find.text('Dr. Sarah Jenkins'), findsOneWidget);
  });

  // Walks the four steps of the ported BookingFlow. Steps 1–3 are only
  // reachable once the fee is paid, so a stub repository stands in for
  // WaafiPay — otherwise the later layouts would never be exercised.
  testWidgets('Booking flow walks payment → doctor → child → time', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const BookAppointmentScreen(),
      overrides: <Override>[
        supportRepositoryProvider.overrideWithValue(_StubPayments()),
        bookableDoctorsProvider.overrideWith(
          (Ref ref) async => <Doctor>[
            Doctor(
              id: '5b8b4cc0-1111-2222-3333-444455556666',
              userId: 'u1',
              firstName: 'Sarah',
              lastName: 'Jenkins',
              specialization: 'Pediatric Pulmonology',
              licenseNumber: 'MD-123456789',
              verificationStatus: 'ACTIVE',
              facilityId: 'f1',
              facilityName: 'Banadir Clinic',
            ),
          ],
        ),
        myChildrenProvider.overrideWith((Ref ref) async => _children),
        facilityServicesProvider.overrideWith(
          (Ref ref, String facilityId) async => <HealthService>[
            HealthService(
              id: 's1',
              facilityId: facilityId,
              name: 'Growth Monitoring',
              isActive: true,
              price: 5,
            ),
          ],
        ),
      ],
    );

    // Step 0 — payment
    expect(tester.takeException(), isNull);
    expect(find.text('Consultation Fee Payment'), findsOneWidget);
    expect(find.text('Teleconsultation Fee'), findsOneWidget);
    expect(find.text(r'$0.01'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '252612345678');
    await tester.pump();
    await tester.tap(find.text(r'Pay $0.01 via EVC Plus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Step 1 — choose doctor
    expect(tester.takeException(), isNull);
    expect(find.text('Available Specialists'), findsOneWidget);
    expect(find.textContaining('Payment confirmed'), findsOneWidget);
    expect(find.text('Dr. Sarah Jenkins'), findsOneWidget);

    await tester.tap(find.text('Dr. Sarah Jenkins'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Step 2 — select child
    expect(tester.takeException(), isNull);
    // Twice: the stepper label and the panel heading.
    expect(find.text('Select Child'), findsNWidgets(2));
    expect(find.text('Booking with'), findsOneWidget);
    expect(find.text('Growth Monitoring'), findsOneWidget);
    expect(find.text('Amina Hassan'), findsOneWidget);

    await tester.tap(find.text('Amina Hassan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Step 3 — pick a time, with the summary underneath
    expect(tester.takeException(), isNull);
    expect(find.text('Pick a Date & Time'), findsOneWidget);
    expect(find.text('☀️ MORNING'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('Booking Summary'), findsOneWidget);
    expect(find.text('Not selected'), findsOneWidget);

    await tester.tap(find.text('10:30 AM'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Not selected'), findsNothing);
  });
}

/// Stands in for WaafiPay so the steps after payment can be reached. Only
/// `pay` is exercised; everything else keeps the real implementation, which
/// would fail on a network call the test never makes.
class _StubPayments extends SupportRepository {
  _StubPayments() : super(ApiClient(storage: AuthStorage()));

  @override
  Future<PaymentResult> pay({
    required String accountNo,
    required double amount,
    String? description,
    String? appointmentId,
  }) async {
    return PaymentResult(
      success: true,
      payment: Payment(
        id: 'pay-1',
        userId: 'u1',
        amount: amount,
        currency: 'USD',
        status: PaymentStatus.paid,
        accountNo: accountNo,
        referenceId: 'ref-1',
        invoiceId: 'inv-1',
        createdAt: DateTime(2026, 8, 9),
      ),
    );
  }
}
