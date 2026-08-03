import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_storage.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/chatbot_repository.dart';
import '../../data/repositories/child_repository.dart';
import '../../data/repositories/doctor_repository.dart';
import '../../data/repositories/facility_repository.dart';
import '../../data/repositories/health_record_repository.dart';
import '../../data/repositories/support_repository.dart';
import '../../data/repositories/vaccination_repository.dart';
import 'auth_provider.dart';

/// Token vault — single instance for the whole app.
final Provider<AuthStorage> authStorageProvider = Provider<AuthStorage>(
  (Ref ref) => AuthStorage(),
);

/// The configured Dio client. On an unrecoverable 401 it asks the auth
/// controller to tear the session down, which bounces the router to /login.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) {
  final AuthStorage storage = ref.watch(authStorageProvider);
  return ApiClient(
    storage: storage,
    onSessionExpired: () async {
      await ref.read(authControllerProvider.notifier).sessionExpired();
    },
  );
});

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (Ref ref) => AuthRepository(ref.watch(apiClientProvider)),
    );

final Provider<ChildRepository> childRepositoryProvider =
    Provider<ChildRepository>(
      (Ref ref) => ChildRepository(ref.watch(apiClientProvider)),
    );

final Provider<VaccinationRepository> vaccinationRepositoryProvider =
    Provider<VaccinationRepository>(
      (Ref ref) => VaccinationRepository(ref.watch(apiClientProvider)),
    );

final Provider<AppointmentRepository> appointmentRepositoryProvider =
    Provider<AppointmentRepository>(
      (Ref ref) => AppointmentRepository(ref.watch(apiClientProvider)),
    );

final Provider<DoctorRepository> doctorRepositoryProvider =
    Provider<DoctorRepository>(
      (Ref ref) => DoctorRepository(ref.watch(apiClientProvider)),
    );

final Provider<FacilityRepository> facilityRepositoryProvider =
    Provider<FacilityRepository>(
      (Ref ref) => FacilityRepository(ref.watch(apiClientProvider)),
    );

final Provider<HealthRecordRepository> healthRecordRepositoryProvider =
    Provider<HealthRecordRepository>(
      (Ref ref) => HealthRecordRepository(ref.watch(apiClientProvider)),
    );

final Provider<ChatbotRepository> chatbotRepositoryProvider =
    Provider<ChatbotRepository>(
      (Ref ref) => ChatbotRepository(ref.watch(apiClientProvider)),
    );

final Provider<AdminRepository> adminRepositoryProvider =
    Provider<AdminRepository>(
      (Ref ref) => AdminRepository(ref.watch(apiClientProvider)),
    );

final Provider<SupportRepository> supportRepositoryProvider =
    Provider<SupportRepository>(
      (Ref ref) => SupportRepository(ref.watch(apiClientProvider)),
    );
