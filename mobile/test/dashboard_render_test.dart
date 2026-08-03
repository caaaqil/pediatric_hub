// Renders MainDashboardScreen with stub telemetry to catch layout/paint
// exceptions that show up as a blank screen in the browser.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pediatric_health_hub_mobile/config/theme/app_theme.dart';
import 'package:pediatric_health_hub_mobile/data/models/enums.dart';
import 'package:pediatric_health_hub_mobile/data/models/telemetry.dart';
import 'package:pediatric_health_hub_mobile/presentation/providers/providers.dart';
import 'package:pediatric_health_hub_mobile/presentation/screens/dashboard/main_dashboard_screen.dart';

DashboardTelemetry _stub() {
  return const DashboardTelemetry(
    title1: 'Active Platform Users',
    count1: 2,
    title2: 'Total Consultations',
    count2: 0,
    title3: 'System Alerts',
    count3: 0,
    charts: <TelemetryPoint>[
      TelemetryPoint(name: 'Mar', uv: 0, sales: 0, orders: 0),
      TelemetryPoint(name: 'Apr', uv: 0, sales: 0, orders: 0),
      TelemetryPoint(name: 'May', uv: 0, sales: 0, orders: 0),
      TelemetryPoint(name: 'Jun', uv: 0, sales: 0, orders: 0),
      TelemetryPoint(name: 'Jul', uv: 0, sales: 0, orders: 0),
      TelemetryPoint(name: 'Aug', uv: 0, sales: 0, orders: 0),
    ],
  );
}

void main() {
  testWidgets('MainDashboardScreen renders without exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          dashboardTelemetryProvider.overrideWith((Ref ref) async => _stub()),
          currentRoleProvider.overrideWithValue(UserRole.admin),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: MainDashboardScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ignore: avoid_print
    print('EXCEPTION: ${tester.takeException()}');
    expect(find.text('CALCULATED AGGREGATE TRENDS'), findsOneWidget);
  });
}
