import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_doctors_screen.dart';
import '../../presentation/screens/admin/admin_facilities_screen.dart';
import '../../presentation/screens/admin/admin_payments_screen.dart';
import '../../presentation/screens/admin/admin_templates_screen.dart';
import '../../presentation/screens/admin/admin_users_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/verify_email_screen.dart';
import '../../presentation/screens/doctor/patient_detail_screen.dart';
import '../../presentation/screens/doctor/patients_screen.dart';
import '../../presentation/screens/facility/facility_dashboard_screen.dart';
import '../../presentation/screens/facility/facility_services_screen.dart';
import '../../presentation/screens/facility/facility_staff_screen.dart';
import '../../presentation/screens/parent/book_appointment_screen.dart';
import '../../presentation/screens/parent/child_detail_screen.dart';
import '../../presentation/screens/parent/child_form_screen.dart';
import '../../presentation/screens/parent/children_screen.dart';
import '../../presentation/screens/parent/chatbot_screen.dart';
import '../../presentation/screens/parent/doctor_detail_screen.dart';
import '../../presentation/screens/parent/doctors_screen.dart';
import '../../presentation/screens/parent/growth_screen.dart';
import '../../presentation/screens/parent/health_records_screen.dart';
import '../../presentation/screens/parent/payments_screen.dart';
import '../../presentation/screens/parent/vaccine_gateway_screen.dart';
import '../../presentation/screens/parent/vaccine_tracker_screen.dart';
import '../../presentation/screens/shared/appointment_detail_screen.dart';
import '../../presentation/screens/shared/education_screen.dart';
import '../../presentation/screens/shared/emergency_screen.dart';
import '../../presentation/screens/shared/messages_screen.dart';
import '../../presentation/screens/shared/notifications_screen.dart';
import '../../presentation/screens/shared/teleconsult_screen.dart';
import '../../presentation/screens/shell/portal_shells.dart';
import '../../presentation/screens/splash_screen.dart';
import 'app_routes.dart';

/// Bridges Riverpod's [AuthState] to go_router's `refreshListenable`.
class _AuthRefreshNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// The app router with an auth guard and role-based redirects.
///
/// Rules:
///  • while the session is being restored → /splash
///  • signed out → the auth routes only
///  • signed in  → never the auth routes; a portal path belonging to another
///    role bounces to your own portal home
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final _AuthRefreshNotifier refresh = _AuthRefreshNotifier();
  ref.listen<AuthState>(authControllerProvider, (
    AuthState? previous,
    AuthState next,
  ) {
    if (previous?.status != next.status) refresh.bump();
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState auth = ref.read(authControllerProvider);
      final String location = state.matchedLocation;

      const Set<String> authRoutes = <String>{
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
      };

      // 1. Session still being restored.
      if (auth.status == AuthStatus.unknown) {
        return location == Routes.splash ? null : Routes.splash;
      }

      // 2. Signed out — allow only the auth routes.
      if (!auth.isAuthenticated) {
        if (authRoutes.contains(location) || location == Routes.verifyEmail) {
          return null;
        }
        return Routes.login;
      }

      // 3. Signed in — keep the user out of splash/auth screens.
      final String home = Routes.homeForRole(auth.role?.wire ?? 'PARENT');
      if (location == Routes.splash || authRoutes.contains(location)) {
        return home;
      }

      // 4. Portal isolation: a doctor cannot land on /parent/... and so on.
      const Map<String, UserRole> portalOwners = <String, UserRole>{
        Routes.parentHome: UserRole.parent,
        Routes.doctorHome: UserRole.doctor,
        Routes.facilityHome: UserRole.facility,
        Routes.adminHome: UserRole.admin,
      };

      for (final MapEntry<String, UserRole> entry in portalOwners.entries) {
        if (location.startsWith(entry.key) && auth.role != entry.value) {
          // Admins may inspect any portal's read screens; everyone else cannot.
          if (auth.role == UserRole.admin) continue;
          return home;
        }
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.verifyEmail,
        builder: (BuildContext context, GoRouterState state) =>
            VerifyEmailScreen(initialToken: state.uri.queryParameters['token']),
      ),

      // ── Parent portal ─────────────────────────────────────────────────────
      GoRoute(
        path: Routes.parentHome,
        builder: (BuildContext context, GoRouterState state) =>
            const ParentShell(),
        routes: <RouteBase>[
          GoRoute(
            path: 'children',
            builder: (BuildContext context, GoRouterState state) =>
                const ChildrenScreen(showAppBar: true),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (BuildContext context, GoRouterState state) =>
                    const ChildFormScreen(),
              ),
              GoRoute(
                path: ':childId',
                builder: (BuildContext context, GoRouterState state) =>
                    ChildDetailScreen(
                      childId: state.pathParameters['childId'] ?? '',
                    ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'edit',
                    builder: (BuildContext context, GoRouterState state) =>
                        ChildFormScreen(
                          childId: state.pathParameters['childId'],
                        ),
                  ),
                  GoRoute(
                    path: 'vaccines',
                    builder: (BuildContext context, GoRouterState state) =>
                        VaccineTrackerScreen(
                          childId: state.pathParameters['childId'] ?? '',
                        ),
                  ),
                  GoRoute(
                    path: 'records',
                    builder: (BuildContext context, GoRouterState state) =>
                        HealthRecordsScreen(
                          childId: state.pathParameters['childId'] ?? '',
                        ),
                  ),
                  GoRoute(
                    path: 'growth',
                    builder: (BuildContext context, GoRouterState state) =>
                        GrowthScreen(
                          childId: state.pathParameters['childId'] ?? '',
                        ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'doctors',
            builder: (BuildContext context, GoRouterState state) =>
                const DoctorsScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: ':doctorId',
                builder: (BuildContext context, GoRouterState state) =>
                    DoctorDetailScreen(
                      doctorId: state.pathParameters['doctorId'] ?? '',
                    ),
              ),
            ],
          ),
          GoRoute(
            path: 'book',
            builder: (BuildContext context, GoRouterState state) =>
                BookAppointmentScreen(
                  presetDoctorId: state.uri.queryParameters['doctorId'],
                ),
          ),
          GoRoute(
            path: 'vaccines',
            builder: (BuildContext context, GoRouterState state) =>
                const VaccineGatewayScreen(),
          ),
          GoRoute(
            path: 'chatbot',
            builder: (BuildContext context, GoRouterState state) =>
                const ChatbotScreen(showAppBar: true),
          ),
          GoRoute(
            path: 'payments',
            builder: (BuildContext context, GoRouterState state) =>
                const PaymentsScreen(),
          ),
        ],
      ),

      // ── Doctor portal ─────────────────────────────────────────────────────
      GoRoute(
        path: Routes.doctorHome,
        builder: (BuildContext context, GoRouterState state) =>
            const DoctorShell(),
        routes: <RouteBase>[
          GoRoute(
            path: 'patients',
            builder: (BuildContext context, GoRouterState state) =>
                const PatientsScreen(showAppBar: true),
            routes: <RouteBase>[
              GoRoute(
                path: ':childId',
                builder: (BuildContext context, GoRouterState state) =>
                    PatientDetailScreen(
                      childId: state.pathParameters['childId'] ?? '',
                    ),
              ),
            ],
          ),
        ],
      ),

      // ── Facility portal ───────────────────────────────────────────────────
      GoRoute(
        path: Routes.facilityHome,
        builder: (BuildContext context, GoRouterState state) =>
            const FacilityShell(),
        routes: <RouteBase>[
          GoRoute(
            path: 'staff',
            builder: (BuildContext context, GoRouterState state) =>
                const FacilityStaffScreen(showAppBar: true),
          ),
          GoRoute(
            path: 'services',
            builder: (BuildContext context, GoRouterState state) =>
                const FacilityServicesScreen(),
          ),
          GoRoute(
            path: 'admin',
            builder: (BuildContext context, GoRouterState state) =>
                const FacilityDashboardScreen(),
          ),
        ],
      ),

      // ── Admin portal ──────────────────────────────────────────────────────
      GoRoute(
        path: Routes.adminHome,
        builder: (BuildContext context, GoRouterState state) =>
            const AdminShell(),
        routes: <RouteBase>[
          GoRoute(
            path: 'users',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminUsersScreen(showAppBar: true),
          ),
          GoRoute(
            path: 'templates',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminTemplatesScreen(showAppBar: true),
          ),
          GoRoute(
            path: 'audits',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminCommandHubScreen(),
          ),
          GoRoute(
            path: 'doctors',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminDoctorsScreen(),
          ),
          GoRoute(
            path: 'facilities',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminFacilitiesScreen(),
          ),
          GoRoute(
            path: 'payments',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminPaymentsScreen(),
          ),
        ],
      ),

      // ── Shared across roles ───────────────────────────────────────────────
      GoRoute(
        path: '/appointments/:appointmentId',
        builder: (BuildContext context, GoRouterState state) =>
            AppointmentDetailScreen(
              appointmentId: state.pathParameters['appointmentId'] ?? '',
            ),
      ),
      GoRoute(
        path: Routes.teleconsult,
        builder: (BuildContext context, GoRouterState state) =>
            const TeleconsultScreen(),
      ),
      GoRoute(
        path: Routes.messages,
        builder: (BuildContext context, GoRouterState state) =>
            const MessagesScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (BuildContext context, GoRouterState state) =>
            const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.education,
        builder: (BuildContext context, GoRouterState state) =>
            const EducationScreen(),
      ),
      GoRoute(
        path: Routes.emergency,
        builder: (BuildContext context, GoRouterState state) =>
            const EmergencyScreen(),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.explore_off_rounded, size: 40),
              const SizedBox(height: 16),
              Text(
                'No screen matches ${state.uri}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
