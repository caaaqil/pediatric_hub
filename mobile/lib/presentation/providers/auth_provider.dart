import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/storage/auth_storage.dart';
import '../../data/models/enums.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import 'core_providers.dart';

enum AuthStatus {
  /// Splash is still restoring a persisted session.
  unknown,
  authenticated,
  unauthenticated,
}

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isBusy = false,
    this.error,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool isBusy;
  final String? error;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  UserRole? get role => user?.role;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isBusy,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Owns the session: restore, login, register, logout.
class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required AuthStorage storage,
  }) : _repository = repository,
       _storage = storage,
       super(const AuthState());

  final AuthRepository _repository;
  final AuthStorage _storage;

  /// Called once from the splash screen: rehydrate from storage, then confirm
  /// the token is still good against `GET /auth/profile`.
  Future<void> bootstrap() async {
    final String? token = await _storage.readAccessToken();
    final Map<String, dynamic>? cachedUser = await _storage.readUser();

    if (token == null || token.isEmpty || cachedUser == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    // Paint immediately from cache so the app is usable offline-first…
    state = AuthState(
      status: AuthStatus.authenticated,
      user: AppUser.fromJson(cachedUser),
    );

    // …then verify. A 401 that survives the refresh interceptor logs us out.
    try {
      final AppUser fresh = await _repository.profile();
      final AppUser merged =
          state.user?.copyWith(profile: fresh.profile) ?? fresh;
      state = state.copyWith(user: merged);
      await _storage.writeUser(merged.toJson());
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _clearSession();
      }
      // Any other failure (server down, no network) keeps the cached session.
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final AuthSession session = await _repository.login(
        email: email,
        password: password,
      );
      await _storage.writeAccessToken(session.token);
      await _storage.writeRefreshToken(session.refreshToken);
      await _storage.writeUser(session.user.toJson());

      state = AuthState(status: AuthStatus.authenticated, user: session.user);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isBusy: false, error: error.detailedMessage);
      return false;
    }
  }

  /// Registers and signs the new account straight in — `POST /auth/register`
  /// already returns a usable access token.
  Future<RegistrationResult?> register({
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
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final RegistrationResult result = await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
        phoneNumber: phoneNumber,
        address: address,
        licenseNumber: licenseNumber,
        specialization: specialization,
      );

      await _storage.writeAccessToken(result.token);
      await _storage.writeUser(result.user.toJson());

      // The register payload carries no profile; fetch it so headers/avatars
      // have a name to show.
      AppUser user = result.user;
      try {
        user = await _repository.profile();
        await _storage.writeUser(user.toJson());
      } on ApiException {
        // Non-fatal: the cached register payload is enough to route on.
      }

      state = AuthState(status: AuthStatus.authenticated, user: user);
      return result;
    } on ApiException catch (error) {
      state = state.copyWith(isBusy: false, error: error.detailedMessage);
      return null;
    }
  }

  /// Re-reads `GET /auth/profile` after a profile edit.
  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;
    try {
      final AppUser fresh = await _repository.profile();
      final AppUser merged =
          state.user?.copyWith(profile: fresh.profile) ?? fresh;
      state = state.copyWith(user: merged);
      await _storage.writeUser(merged.toJson());
    } on ApiException {
      // Keep whatever we already have.
    }
  }

  Future<void> logout() => _clearSession();

  /// Invoked by the Dio interceptor when a 401 could not be refreshed.
  Future<void> sessionExpired() async {
    if (state.status == AuthStatus.unauthenticated) return;
    await _clearSession(message: 'Your session expired. Please sign in again.');
  }

  Future<void> _clearSession({String? message}) async {
    await _storage.clear();
    state = AuthState(status: AuthStatus.unauthenticated, error: message);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((Ref ref) {
      return AuthController(
        repository: ref.watch(authRepositoryProvider),
        storage: ref.watch(authStorageProvider),
      );
    });

/// Convenience: the signed-in user, or null.
final Provider<AppUser?> currentUserProvider = Provider<AppUser?>(
  (Ref ref) => ref.watch(authControllerProvider).user,
);

/// Convenience: the signed-in user's role, or null.
final Provider<UserRole?> currentRoleProvider = Provider<UserRole?>(
  (Ref ref) => ref.watch(authControllerProvider).user?.role,
);
