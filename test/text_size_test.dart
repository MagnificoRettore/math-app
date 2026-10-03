import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/app.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/settings_store.dart';
import 'package:math_app/haptics.dart';
import 'package:math_app/theme/app_text.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/math_text.dart';
import 'package:math_app/widgets/notes_text.dart';

/// Il testo del corpo di una lezione passa da `RichText`, che di default non
/// applica il `textScaler` di `MediaQuery`, e le formule sono `RichText` di
/// `flutter_math_fork`: senza il fattore letto a mano, la scala del testo
/// crescerebbe metà app e lascerebbe fermo il pezzo più importante.
double _bodyFontSize(WidgetTester tester) {
  final rich = tester.widget<RichText>(find.byType(RichText).first);
  final spans = (rich.text as TextSpan).children!;
  return spans.whereType<TextSpan>().first.style!.fontSize!;
}

Future<void> _pump(WidgetTester tester, double scale, Widget child) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ContentRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
    await SettingsStore.instance.resetForTest();
  });

  group('scala del testo nei widget che non la applicano da soli', () {
    testWidgets('MathText segue il fattore di scala', (tester) async {
      await _pump(tester, 1.0, const MathText(r'Testo $x+1$'));
      final base = _bodyFontSize(tester);
      expect(base, AppText.titleSmall);

      await _pump(tester, 1.3, const MathText(r'Testo $x+1$'));
      expect(_bodyFontSize(tester), closeTo(base * 1.3, 0.01));
    });

    testWidgets('NotesText segue il fattore di scala', (tester) async {
      await _pump(tester, 1.0, const NotesText(' corpo'));
      final base = _bodyFontSize(tester);
      expect(base, AppText.docBody);

      await _pump(tester, 1.15, const NotesText(' corpo'));
      expect(_bodyFontSize(tester), closeTo(base * 1.15, 0.01));
    });

    testWidgets('il fattore di scala di MathText è quello di MediaQuery', (
      tester,
    ) async {
      late double factor;
      await _pump(
        tester,
        1.2,
        Builder(
          builder: (context) {
            factor = textScaleFactorOf(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(factor, closeTo(1.2, 0.001));
    });
  });

  group('AppHaptics', () {
    test('le vibrazioni passano solo quando sono accese', () {
      expect(AppHaptics.enabled, isTrue);
      SettingsStore.instance.setHapticsEnabled(false);
      expect(AppHaptics.enabled, isFalse);
    });
  });

  group('MathApp', () {
    // Lo splash ha un timer di 2s: va lasciato scadere, altrimenti il test
    // finisce con timer pendenti.
    Future<void> settle(WidgetTester tester) async {
      await tester.pumpWidget(const MathApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    testWidgets('l\'app non mette le mani sulla scala di Accessibilità', (
      tester,
    ) async {
      // Il dispositivo chiede un testo più grande: dentro l'app deve restare
      // 1.5, non tornare a 1 e non essere riscritto da un'impostazione.
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await settle(tester);

      final context = tester.element(find.byType(Scaffold).first);
      expect(
        MediaQuery.textScalerOf(context).scale(16),
        closeTo(16 * 1.5, 0.01),
      );
    });
  });
}
