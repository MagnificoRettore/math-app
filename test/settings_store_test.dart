import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/settings_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.instance.resetForTest();
  });

  test('stato iniziale: onboarding non visto e tema chiaro', () async {
    expect(SettingsStore.instance.onboardingSeen, isFalse);
    expect(SettingsStore.instance.themeMode, ThemeMode.light);
  });

  test('stato iniziale: vibrazioni accese', () {
    expect(SettingsStore.instance.hapticsEnabled, isTrue);
  });

  test('completeOnboarding persiste il flag visto', () async {
    await SettingsStore.instance.completeOnboarding();

    await SettingsStore.instance.reload();
    expect(SettingsStore.instance.onboardingSeen, isTrue);
  });

  test('setThemeMode persiste il tema scuro', () async {
    await SettingsStore.instance.setThemeMode(ThemeMode.dark);

    await SettingsStore.instance.reload();
    expect(SettingsStore.instance.themeMode, ThemeMode.dark);
  });

  test(
    'setHapticsEnabled persiste la scelta di spegnere le vibrazioni',
    () async {
      await SettingsStore.instance.setHapticsEnabled(false);

      await SettingsStore.instance.reload();
      expect(SettingsStore.instance.hapticsEnabled, isFalse);
    },
  );
}
