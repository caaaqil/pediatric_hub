import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manual light/dark switch, mirroring the web app's theme toggle.
///
/// The web stores the choice in `localStorage` under `phh-dark`
/// (see `frontend/index.html`); mobile persists the same key in
/// shared_preferences so the two clients read as one product.
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.dark) {
    _restore();
  }

  static const String _key = 'phh-dark';

  Future<void> _restore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? dark = prefs.getBool(_key);
    if (dark != null) state = dark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> toggle() async {
    final bool next = !isDark;
    state = next ? ThemeMode.dark : ThemeMode.light;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, next);
  }
}

final StateNotifierProvider<ThemeController, ThemeMode> themeModeProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
      (Ref ref) => ThemeController(),
    );
