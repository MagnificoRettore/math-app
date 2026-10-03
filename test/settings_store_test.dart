import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/settings_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.instance.resetForTest();
  });

  test('stato iniziale: onboarding non visto', () async {
    expect(SettingsStore.instance.onboardingSeen, isFalse);
  });

  test('stato iniziale: vibrazioni accese', () {
    expect(SettingsStore.instance.hapticsEnabled, isTrue);
  });

  test('completeOnboarding persiste il flag visto', () async {
    await SettingsStore.instance.completeOnboarding();

    await SettingsStore.instance.reload();
    expect(SettingsStore.instance.onboardingSeen, isTrue);
  });

  test('un themeMode salvato prima si ignora senza perdere il resto', () async {
    SharedPreferences.setMockInitialValues({
      'settings_v1':
          '{"onboardingSeen":true,"themeMode":"dark",'
          '"hapticsEnabled":false}',
    });
    await SettingsStore.instance.reload();
    expect(SettingsStore.instance.onboardingSeen, isTrue);
    expect(SettingsStore.instance.hapticsEnabled, isFalse);
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
