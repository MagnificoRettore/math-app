import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/settings_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsStore.instance.reload();
  });

  test('stato iniziale: onboarding non visto e tema chiaro', () async {
    await SettingsStore.instance.load();

    expect(SettingsStore.instance.onboardingSeen, isFalse);
    expect(SettingsStore.instance.themeMode, ThemeMode.light);
  });

  test('completeOnboarding persiste il flag visto', () async {
    await SettingsStore.instance.load();
    await SettingsStore.instance.completeOnboarding();

    await SettingsStore.instance.reload();
    expect(SettingsStore.instance.onboardingSeen, isTrue);
  });

  test('setThemeMode persiste il tema scuro', () async {
    await SettingsStore.instance.load();
    await SettingsStore.instance.setThemeMode(ThemeMode.dark);

    await SettingsStore.instance.reload();
    expect(SettingsStore.instance.themeMode, ThemeMode.dark);
  });
}