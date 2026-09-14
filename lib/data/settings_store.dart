import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  static final SettingsStore instance = SettingsStore._();
  SettingsStore._();

  static const _key = 'settings_v1';

  bool _loaded = false;
  Object? _loadError;
  bool _onboardingSeen = false;
  ThemeMode _themeMode = ThemeMode.light;

  bool get loaded => _loaded;
  Object? get loadError => _loadError;
  bool get onboardingSeen => _onboardingSeen;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _onboardingSeen = json['onboardingSeen'] as bool? ?? false;
        final mode = json['themeMode'] as String?;
        _themeMode = switch (mode) {
          'dark' => ThemeMode.dark,
          'system' => ThemeMode.system,
          _ => ThemeMode.light,
        };
      }
      _loaded = true;
      notifyListeners();
    } catch (error) {
      _loadError = error;
    }
  }

  Future<void> reload() async {
    _loaded = false;
    _onboardingSeen = false;
    _themeMode = ThemeMode.light;
    await load();
  }

  Future<void> completeOnboarding() async {
    _onboardingSeen = true;
    notifyListeners();
    await _persist();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'onboardingSeen': _onboardingSeen,
        'themeMode': _themeMode.name,
      }),
    );
  }
}