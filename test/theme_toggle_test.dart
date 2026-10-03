import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/settings_store.dart';
import 'package:math_app/screens/customization_screen.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_theme.dart';

const _toggle = Key('theme-toggle-animation');

/// Tratti di timeline, in 0..1 come li dà `LottieComposition.getMarker`.
const _dayIdle = [0.0, 0.1];
const _nightIdle = [0.405, 0.595];

/// Fine di «Day to Night»: 80 frame su 200, cioè 0.4. Il tratto finisce qui, non
/// all'inizio di «Night Idle» (0.405): la soglia del test di metà percorso
/// deve stare sotto questo valore, altrimenti un tratto di 1000ms — che a
/// metà è già arrivato — passerebbe lo stesso.
const _toNightEnd = 0.4;

/// Poco oltre la durata del tratto di transizione, per non campionare sul
/// confine.
const _settled = Duration(milliseconds: 400);

/// Ritardo con cui il tema segue l'avvio dell'animazione (`_onToggle`).
const _themeChangeDelay = Duration(milliseconds: 40);

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await SettingsStore.instance.resetForTest();
}

/// Come `MathApp`: i temi veri e il ListenableBuilder sullo store, senza i
/// quali il cambio tema non animerebbe niente e `Theme.of(...).animationStatus`
/// resterebbe `dismissed` per sempre.
Future<void> _pumpCustomization(WidgetTester tester) async {
  await tester.pumpWidget(
    ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: SettingsStore.instance.themeMode,
        themeAnimationStyle: AppTheme.transitionStyle,
        home: const CustomizationScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

double _frame(WidgetTester tester) =>
    tester.widget<Lottie>(find.byType(Lottie)).controller!.value;

/// Il colore di sfondo **interpolato** com'è a metà animazione: `ThemeData`
/// non ha uno status, quindi l'unico modo di sapere se i colori sono arrivati è
/// leggere il valore.
Color _sfondo(WidgetTester tester) =>
    AppColors.of(tester.element(find.byType(CustomizationScreen))).background;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets(
    'personalizzazione: il tema si cambia con l\'animazione sole e luna',
    (tester) async {
      await _pumpCustomization(tester);

      expect(find.byKey(_toggle), findsOneWidget);
      expect(_frame(tester), inInclusiveRange(_dayIdle[0], _dayIdle[1]));
    },
  );

  testWidgets('il tap porta l\'animazione nel segmento del nuovo tema', (
    tester,
  ) async {
    await _pumpCustomization(tester);

    await tester.tap(find.byKey(_toggle));
    await tester.pump(_themeChangeDelay);
    expect(SettingsStore.instance.themeMode, ThemeMode.dark);

    await tester.pump(_settled);
    expect(_frame(tester), inInclusiveRange(_nightIdle[0], _nightIdle[1]));

    await tester.tap(find.byKey(_toggle));
    await tester.pump(_themeChangeDelay);
    expect(SettingsStore.instance.themeMode, ThemeMode.light);

    await tester.pump(_settled);
    expect(_frame(tester), inInclusiveRange(_dayIdle[0], _dayIdle[1]));
  });

  testWidgets(
    'l\'animazione parte prima del cambio tema, che la segue di 40ms',
    (tester) async {
      await _pumpCustomization(tester);
      final start = _frame(tester);

      await tester.tap(find.byKey(_toggle));
      // Senza questa pump il controller non parte e il primo `pump` se ne va:
      // il ticker prende l'avvio al primo frame dopo il tap.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      // L'icona è già in viaggio mentre il tema è ancora quello di partenza.
      expect(_frame(tester), greaterThan(start));
      expect(SettingsStore.instance.themeMode, ThemeMode.light);

      await tester.pump(const Duration(milliseconds: 10));
      expect(SettingsStore.instance.themeMode, ThemeMode.dark);
    },
  );

  testWidgets('il tratto di transizione dura 320ms, non la durata del marker', (
    tester,
  ) async {
    await _pumpCustomization(tester);

    // «Day to Night» al tempo nativo dura 1000ms: a metà del tratto da 320ms
    // l'animazione deve essere ancora in viaggio, non già arrivata alla fine.
    await tester.tap(find.byKey(_toggle));
    // Senza questa pump il controller non parte e il primo `pump` se ne va:
    // il ticker prende l'avvio al primo frame dopo il tap.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    final mid = _frame(tester);
    expect(mid, greaterThan(_dayIdle[1]));
    expect(mid, lessThan(_toNightEnd));

    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_frame(tester), inInclusiveRange(_nightIdle[0], _nightIdle[1]));
  });

  testWidgets('i colori finiscono prima dell\'icona', (tester) async {
    await _pumpCustomization(tester);

    await tester.tap(find.byKey(_toggle));
    // Il ticker dell'icona parte al primo frame dopo il tap, con zero elapsed.
    await tester.pump();
    // Il timer da 40ms scrive il tema, e il frame dopo lo passa
    // all'`AnimatedTheme`: l'animazione dei colori parte da qui.
    await tester.pump(const Duration(milliseconds: 48));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 96));
    expect(_sfondo(tester), isNot(AppPalette.light.background));
    expect(_sfondo(tester), isNot(AppPalette.dark.background));

    // A 200ms di animazione i colori sono arrivati, mentre l'icona (320ms) è
    // ancora in viaggio: i due arresti sovrapposti si leggevano come un unico
    // scatto.
    await tester.pump(const Duration(milliseconds: 104));
    expect(_sfondo(tester), AppPalette.dark.background);
    expect(_frame(tester), lessThan(_toNightEnd));

    await tester.pumpAndSettle();
    expect(_frame(tester), inInclusiveRange(_nightIdle[0], _nightIdle[1]));
  });

  testWidgets('un tap durante la transizione viene ignorato', (tester) async {
    await _pumpCustomization(tester);

    await tester.tap(find.byKey(_toggle));
    await tester.pump(_themeChangeDelay);
    await tester.tap(find.byKey(_toggle));
    await tester.pump(_settled);

    expect(SettingsStore.instance.themeMode, ThemeMode.dark);
    expect(_frame(tester), inInclusiveRange(_nightIdle[0], _nightIdle[1]));
  });
}
