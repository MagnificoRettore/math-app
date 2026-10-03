import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/data/settings_store.dart';
import 'package:math_app/screens/customization_screen.dart';
import 'package:math_app/screens/home_screen.dart';

const _icon = Key('header-customization');
const _hapticsSwitch = Key('haptics-switch');

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await ContentRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  await SettingsStore.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

/// La composizione lottie del toggle va caricata dall'asset.
Future<void> _pumpCustomization(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: CustomizationScreen()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Switch _switch(WidgetTester tester) =>
    tester.widget<Switch>(find.byKey(_hapticsSwitch));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets('home: l\'icona in alto a destra apre la personalizzazione', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(_icon), findsOneWidget);
    await tester.tap(find.byKey(_icon));
    await tester.pumpAndSettle();

    expect(find.byType(CustomizationScreen), findsOneWidget);
  });

  testWidgets('la pagina offre le vibrazioni e niente tema scuro', (
    tester,
  ) async {
    await _pumpCustomization(tester);

    // Il tema è uno solo, quello chiaro del design.
    expect(find.text('Tema scuro'), findsNothing);
    expect(find.text('Vibrazioni'), findsOneWidget);
    // La scelta della dimensione del testo non c'è più: si legge da soli con
    // le Impostazioni di Accessibilità del telefono.
    expect(find.text('Dimensione del testo'), findsNothing);
  });

  testWidgets('l\'interruttore delle vibrazioni viene salvato', (tester) async {
    await _pumpCustomization(tester);
    expect(SettingsStore.instance.hapticsEnabled, isTrue);
    expect(_switch(tester).value, isTrue);

    await tester.tap(find.byKey(_hapticsSwitch));
    await tester.pumpAndSettle();

    expect(SettingsStore.instance.hapticsEnabled, isFalse);
    // Lo switch deve seguire lo store da solo, senza un rebuild della pagina.
    expect(_switch(tester).value, isFalse);
    await SettingsStore.instance.reload();
    expect(SettingsStore.instance.hapticsEnabled, isFalse);
  });
}
