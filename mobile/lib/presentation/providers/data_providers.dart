import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/appointment.dart';
import '../../data/models/child.dart';
import '../../data/models/doctor.dart';
import '../../data/models/facility.dart';
import '../../data/models/growth.dart';
import '../../data/models/health_record.dart';
import '../../data/models/misc.dart';
import '../../data/models/telemetry.dart';
import '../../data/models/vaccination.dart';
import 'core_providers.dart';

/// Every list screen reads one of these and refreshes it with
/// `ref.refresh(<provider>.future)` from a `RefreshIndicator`.

// ── Shared ───────────────────────────────────────────────────────────────────

final AutoDisposeFutureProvider<DashboardTelemetry> dashboardTelemetryProvider =
    FutureProvider.autoDispose<DashboardTelemetry>((Ref ref) {
      return ref.watch(supportRepositoryProvider).telemetry();
    });

final AutoDisposeFutureProvider<List<AppNotification>> notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((Ref ref) {
      return ref.watch(supportRepositoryProvider).notifications();
    });

final AutoDisposeFutureProvider<List<EducationalContent>> articlesProvider =
    FutureProvider.autoDispose<List<EducationalContent>>((Ref ref) {
      return ref.watch(supportRepositoryProvider).articles();
    });

final AutoDisposeFutureProvider<List<EmergencyContact>>
emergencyContactsProvider = FutureProvider.autoDispose<List<EmergencyContact>>((
  Ref ref,
) {
  return ref.watch(supportRepositoryProvider).emergencyContacts();
});

final AutoDisposeFutureProvider<List<Payment>> paymentsProvider =
    FutureProvider.autoDispose<List<Payment>>((Ref ref) {
      return ref.watch(supportRepositoryProvider).payments();
    });

// ── Children ─────────────────────────────────────────────────────────────────

final AutoDisposeFutureProvider<List<Child>> myChildrenProvider =
    FutureProvider.autoDispose<List<Child>>((Ref ref) {
      return ref.watch(childRepositoryProvider).myChildren();
    });

/// DOCTOR / FACILITY / ADMIN patient roster.
final AutoDisposeFutureProvider<List<Child>> allChildrenProvider =
    FutureProvider.autoDispose<List<Child>>((Ref ref) {
      return ref.watch(childRepositoryProvider).allChildren();
    });

final AutoDisposeFutureProviderFamily<Child, String> childDetailProvider =
    FutureProvider.autoDispose.family<Child, String>((Ref ref, String childId) {
      return ref.watch(childRepositoryProvider).byId(childId);
    });

// ── Vaccinations ─────────────────────────────────────────────────────────────

final AutoDisposeFutureProviderFamily<List<Vaccination>, String>
childVaccinationsProvider = FutureProvider.autoDispose
    .family<List<Vaccination>, String>((Ref ref, String childId) {
      return ref.watch(vaccinationRepositoryProvider).forChild(childId);
    });

final AutoDisposeFutureProvider<List<VaccineTemplate>>
vaccineTemplatesProvider = FutureProvider.autoDispose<List<VaccineTemplate>>((
  Ref ref,
) {
  return ref.watch(vaccinationRepositoryProvider).templates();
});

/// A dose paired with the child it belongs to.
class ChildVaccination {
  const ChildVaccination({required this.child, required this.vaccination});

  final Child child;
  final Vaccination vaccination;
}

/// Every dose across all of the parent's children, oldest scheduled first.
///
/// There is no "all my children's vaccines" endpoint, so this fans out over
/// `GET /vaccinations/child/:childId` once per child.
final AutoDisposeFutureProvider<List<ChildVaccination>>
allChildVaccinationsProvider =
    FutureProvider.autoDispose<List<ChildVaccination>>((Ref ref) async {
      final List<Child> children = await ref.watch(myChildrenProvider.future);
      final List<ChildVaccination> rows = <ChildVaccination>[];

      for (final Child child in children) {
        final List<Vaccination> doses = await ref
            .watch(vaccinationRepositoryProvider)
            .forChild(child.id);
        rows.addAll(
          doses.map(
            (Vaccination v) => ChildVaccination(child: child, vaccination: v),
          ),
        );
      }

      rows.sort(
        (ChildVaccination a, ChildVaccination b) =>
            a.vaccination.scheduledDate.compareTo(b.vaccination.scheduledDate),
      );
      return rows;
    });

// ── Appointments ─────────────────────────────────────────────────────────────

final AutoDisposeFutureProvider<List<Appointment>> myScheduleProvider =
    FutureProvider.autoDispose<List<Appointment>>((Ref ref) {
      return ref.watch(appointmentRepositoryProvider).mySchedule();
    });

final AutoDisposeFutureProviderFamily<Appointment, String>
appointmentDetailProvider = FutureProvider.autoDispose
    .family<Appointment, String>((Ref ref, String id) {
      return ref.watch(appointmentRepositoryProvider).byId(id);
    });

// ── Doctors ──────────────────────────────────────────────────────────────────

/// `GET /users/doctors` — the list parents book from (carries facilityId).
final AutoDisposeFutureProvider<List<Doctor>> bookableDoctorsProvider =
    FutureProvider.autoDispose<List<Doctor>>((Ref ref) {
      return ref.watch(doctorRepositoryProvider).bookable();
    });

/// `GET /doctors` — paginated registry; FACILITY sees only its own staff.
final AutoDisposeFutureProvider<List<Doctor>> doctorRegistryProvider =
    FutureProvider.autoDispose<List<Doctor>>((Ref ref) async {
      final Paginated<Doctor> page = await ref
          .watch(doctorRepositoryProvider)
          .list(limit: 100);
      return page.items;
    });

final AutoDisposeFutureProviderFamily<Doctor, String> doctorDetailProvider =
    FutureProvider.autoDispose.family<Doctor, String>((Ref ref, String id) {
      return ref.watch(doctorRepositoryProvider).byId(id);
    });

final AutoDisposeFutureProvider<List<Facility>> facilitiesProvider =
    FutureProvider.autoDispose<List<Facility>>((Ref ref) async {
      final Paginated<Facility> page = await ref
          .watch(facilityRepositoryProvider)
          .list(limit: 100);
      return page.items;
    });

// ── Facility portal ──────────────────────────────────────────────────────────

final AutoDisposeFutureProvider<FacilityScope> facilityScopeProvider =
    FutureProvider.autoDispose<FacilityScope>((Ref ref) {
      return ref.watch(facilityRepositoryProvider).myScope();
    });

final AutoDisposeFutureProvider<List<HealthService>> myHealthServicesProvider =
    FutureProvider.autoDispose<List<HealthService>>((Ref ref) {
      return ref.watch(facilityRepositoryProvider).myServices();
    });

final AutoDisposeFutureProviderFamily<List<HealthService>, String>
facilityServicesProvider = FutureProvider.autoDispose
    .family<List<HealthService>, String>((Ref ref, String facilityId) {
      return ref
          .watch(facilityRepositoryProvider)
          .servicesOfFacility(facilityId);
    });

// ── Health records ───────────────────────────────────────────────────────────

final AutoDisposeFutureProviderFamily<ChildBaseline, String> baselineProvider =
    FutureProvider.autoDispose.family<ChildBaseline, String>((
      Ref ref,
      String childId,
    ) {
      return ref.watch(healthRecordRepositoryProvider).baseline(childId);
    });

final AutoDisposeFutureProviderFamily<List<ConsultationNote>, String>
consultationsProvider = FutureProvider.autoDispose
    .family<List<ConsultationNote>, String>((Ref ref, String childId) {
      return ref.watch(healthRecordRepositoryProvider).consultations(childId);
    });

final AutoDisposeFutureProviderFamily<GrowthData, String> growthProvider =
    FutureProvider.autoDispose.family<GrowthData, String>((
      Ref ref,
      String childId,
    ) {
      return ref.watch(healthRecordRepositoryProvider).growth(childId);
    });

final AutoDisposeFutureProviderFamily<List<ParentInfo>, String>
guardiansProvider = FutureProvider.autoDispose.family<List<ParentInfo>, String>(
  (Ref ref, String childId) {
    return ref.watch(healthRecordRepositoryProvider).guardians(childId);
  },
);

// ── Admin ────────────────────────────────────────────────────────────────────

final AutoDisposeFutureProvider<AdminTelemetry> adminTelemetryProvider =
    FutureProvider.autoDispose<AdminTelemetry>((Ref ref) {
      return ref.watch(adminRepositoryProvider).telemetry();
    });

final AutoDisposeFutureProvider<List<ManagedUser>> adminUsersProvider =
    FutureProvider.autoDispose<List<ManagedUser>>((Ref ref) {
      return ref.watch(adminRepositoryProvider).users();
    });

final AutoDisposeFutureProvider<List<AuditLog>> adminAuditsProvider =
    FutureProvider.autoDispose<List<AuditLog>>((Ref ref) {
      return ref.watch(adminRepositoryProvider).audits(limit: 100);
    });

final AutoDisposeFutureProvider<List<ChatbotTemplate>>
chatbotTemplatesProvider = FutureProvider.autoDispose<List<ChatbotTemplate>>((
  Ref ref,
) {
  return ref.watch(chatbotRepositoryProvider).templates();
});

// ── Chatbot history ──────────────────────────────────────────────────────────

final AutoDisposeFutureProvider<List<ChatbotSession>> chatbotSessionsProvider =
    FutureProvider.autoDispose<List<ChatbotSession>>((Ref ref) {
      return ref.watch(chatbotRepositoryProvider).sessions();
    });
