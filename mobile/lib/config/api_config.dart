import 'package:flutter/foundation.dart';

/// Central API configuration.
///
/// The backend (`backend/src/server.js`) listens on PORT (default 3000) and all
/// routes are mounted under `/api/v1` (see `backend/src/app.js`).
///
/// ---------------------------------------------------------------------------
/// WHICH BASE URL DO I USE?
/// ---------------------------------------------------------------------------
/// | Target                     | Base URL                                   |
/// |----------------------------|--------------------------------------------|
/// | Android emulator           | http://10.0.2.2:3000/api/v1   (the default)|
/// | iOS simulator / desktop    | http://localhost:3000/api/v1               |
/// | Physical phone (same Wi-Fi)| `http://YOUR_LAN_IP:3000/api/v1`           |
///
/// `10.0.2.2` is the Android emulator's alias for the host machine's loopback —
/// `localhost` inside the emulator refers to the emulator itself, not your PC.
///
/// Override without touching code:
///
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api/v1
///
/// Find your LAN IP with `hostname -I` (Linux), `ipconfig` (Windows) or
/// `ipconfig getifaddr en0` (macOS), and make sure the backend is reachable on
/// it (start it with `npm run dev` — Express binds all interfaces by default).
class ApiConfig {
  const ApiConfig._();

  /// Android emulator loopback alias — the safest default for `flutter run`.
  static const String androidEmulator = 'http://10.0.2.2:3000/api/v1';

  /// iOS simulator / desktop / web.
  static const String localhost = 'http://localhost:3000/api/v1';

  /// Explicit override, e.g.
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api/v1`
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// With no override the right default is picked per platform, so
  /// `flutter run` works on web, desktop and the Android emulator alike:
  /// only Android needs the 10.0.2.2 loopback alias.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return localhost;
    return defaultTargetPlatform == TargetPlatform.android
        ? androidEmulator
        : localhost;
  }

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Endpoints that must never carry an Authorization header and must never
  /// trigger the 401 refresh-and-retry flow.
  static const List<String> publicPaths = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/auth/verify-email',
    '/auth/refresh-token',
  ];
}
