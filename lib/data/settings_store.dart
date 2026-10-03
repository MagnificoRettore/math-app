import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  static final SettingsStore instance = SettingsStore._();
  SettingsStore._();

  static const _key = 'settings_v1';

  bool _loaded = false;
  Object? _loadError;
  bool _onboardingSeen = false;
  bool _hapticsEnabled = true;

  bool get loaded => _loaded;
  Object? get loadError => _loadError;
  bool get onboardingSeen => _onboardingSeen;
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _onboardingSeen = json['onboardingSeen'] as bool? ?? false;
        // `themeMode` dei salvataggi di prima si ignora: il tema è uno solo.
        _hapticsEnabled = json['hapticsEnabled'] as bool? ?? true;
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
    _hapticsEnabled = true;
    await load();
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _onboardingSeen = false;
    _hapticsEnabled = true;
    _loadError = null;
    await load();
  }

  Future<void> completeOnboarding() async {
    _onboardingSeen = true;
    notifyListeners();
    await _persist();
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    if (_hapticsEnabled == enabled) return;
    _hapticsEnabled = enabled;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'onboardingSeen': _onboardingSeen,
        'hapticsEnabled': _hapticsEnabled,
      }),
    );
  }
}
