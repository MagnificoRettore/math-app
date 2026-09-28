import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/settings_store.dart';
import 'package:math_app/screens/profile_screen.dart';

const _toggle = Key('theme-toggle-animation');

/// Tratti di timeline, in 0..1 come li dà `LottieComposition.getMarker`.
const _dayIdle = [0.0, 0.1];
const _nightIdle = [0.405, 0.595];

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await SettingsStore.instance.resetForTest();
}

/// La composizione lottie si carica dall'asset, quindi basta una pump.
Future<void> _pumpProfile(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

double _frame(WidgetTester tester) =>
    tester.widget<Lottie>(find.byType(Lottie)).controller!.value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets('profilo: il tema si cambia con l\'animazione sole e luna', (
    tester,
  ) async {
    await _pumpProfile(tester);

    expect(find.byKey(_toggle), findsOneWidget);
    expect(_frame(tester), inInclusiveRange(_dayIdle[0], _dayIdle[1]));
  });

  testWidgets('il tap porta l\'animazione nel segmento del nuovo tema', (
    tester,
  ) async {
    await _pumpProfile(tester);

    await tester.tap(find.byKey(_toggle));
    await tester.pump();
    expect(SettingsStore.instance.themeMode, ThemeMode.dark);

    await tester.pump(const Duration(seconds: 2));
    expect(_frame(tester), inInclusiveRange(_nightIdle[0], _nightIdle[1]));

    await tester.tap(find.byKey(_toggle));
    await tester.pump();
    expect(SettingsStore.instance.themeMode, ThemeMode.light);

    await tester.pump(const Duration(seconds: 2));
    expect(_frame(tester), inInclusiveRange(_dayIdle[0], _dayIdle[1]));
  });

  testWidgets('un tap durante la transizione viene ignorato', (tester) async {
    await _pumpProfile(tester);

    await tester.tap(find.byKey(_toggle));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(_toggle));
    await tester.pump(const Duration(seconds: 2));

    expect(SettingsStore.instance.themeMode, ThemeMode.dark);
    expect(_frame(tester), inInclusiveRange(_nightIdle[0], _nightIdle[1]));
  });
}
