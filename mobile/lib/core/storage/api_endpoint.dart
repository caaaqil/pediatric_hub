import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

/// Runtime-editable API base URL.
///
/// The compile-time value (`--dart-define=API_BASE_URL`, or the per-platform
/// default) is only a starting point. A laptop's LAN IP changes whenever the
/// router hands out a new DHCP lease, which would otherwise mean rebuilding and
/// reinstalling the APK every time. Instead the address can be changed on the
/// device and is remembered between launches.
class ApiEndpoint {
  const ApiEndpoint._();

  static const String _key = 'phh_api_base_url';

  static String _override = '';

  /// The address every request should use right now.
  static String get current =>
      _override.isEmpty ? ApiConfig.baseUrl : _override;

  /// True when the user has set an address that differs from the built-in one.
  static bool get isCustom => _override.isNotEmpty;

  /// The address the app was compiled with, shown as the "reset" target.
  static String get compiled => ApiConfig.baseUrl;

  /// Loads any saved address. Call once before `runApp`.
  static Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _override = prefs.getString(_key) ?? '';
    } on Exception {
      _override = '';
    }
  }

  /// Saves a new address. Pass an empty string to fall back to the compiled one.
  static Future<void> save(String value) async {
    final String cleaned = normalise(value);
    _override = cleaned;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (cleaned.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, cleaned);
    }
  }

  /// Accepts what a person would actually type — `192.168.1.20`,
  /// `192.168.1.20:3000`, or a full URL — and returns a usable base URL.
  static String normalise(String input) {
    String value = input.trim();
    if (value.isEmpty) return '';

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    // Strip a trailing slash so we don't build "//api/v1".
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    // A bare host (no port) gets the backend's default port.
    final Uri? parsed = Uri.tryParse(value);
    if (parsed != null && !parsed.hasPort) {
      value = '${parsed.scheme}://${parsed.host}:3000';
    }
    if (!value.contains('/api/')) {
      value = '$value/api/v1';
    }
    return value;
  }
}
