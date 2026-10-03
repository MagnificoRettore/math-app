import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/models/lesson_resume.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/argomento_carousel.dart';
import 'package:math_app/widgets/progress_bar.dart';

Future<void> _resetStores() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await LessonRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

Future<void> _registra() async {
  await AuthStore.instance.registerManual(
    name: 'Anna',
    email: 'anna@example.com',
    password: 'segreta1',
    schoolLevelId: 'high-school',
  );
}

Future<void> _pausa(String lessonId, {int step = 0}) async {
  await ProgressStore.instance.saveLessonResume(
    LessonResume(levelId: 'high-school', lessonId: lessonId, step: step),
  );
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
  );
  await tester.pumpAndSettle();
}

final _card = find.byKey(const Key('jump-back-in-card'));

/// La barra della card, cercata dentro la card: sulla Home non c'è altra
/// `ProgressBar`, ma il finder è comunque ancorato alla sezione.
ProgressBar _barra(WidgetTester tester) => tester.widget<ProgressBar>(
  find.descendant(of: _card, matching: find.byType(ProgressBar)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_resetStores);

  testWidgets('la sezione è nascosta per un ospite', (tester) async {
    await _pausa('eq1-intro');
    await _pumpHome(tester);

    expect(find.text('Jump Back In'), findsNothing);
  });

  testWidgets('la sezione è nascosta senza una lezione mai aperta', (
    tester,
  ) async {
    await _registra();
    await _pumpHome(tester);

    expect(find.text('Jump Back In'), findsNothing);
  });

  testWidgets('la sezione è nascosta se il profilo non ha una scuola', (
    tester,
  ) async {
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: '',
    );
    await _pausa('eq1-intro');
    await _pumpHome(tester);

    expect(find.text('Jump Back In'), findsNothing);
  });

  testWidgets('la sezione compare con il topic come titolo e la barra sotto', (
    tester,
  ) async {
    await _registra();
    await _pausa('mod-equations-intro', step: 3);
    await _pumpHome(tester);

    expect(find.text('Jump Back In'), findsOneWidget);
    // Dentro la card: il carosello sotto ha anche lui una slide «Moduli».
    expect(
      find.descendant(of: _card, matching: find.text('Moduli')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _card,
        matching: find.text('Modulo e Equazioni con Modulo'),
      ),
      findsOneWidget,
    );
    // il contatore numerico non c'è più
    expect(find.textContaining('Step'), findsNothing);
    // 1 card di Definizione + 3 superate, su 10
    expect(_barra(tester).progress, closeTo(4 / 10, 0.001));
  });

  testWidgets('una lezione di un solo passo mostra la barra a zero', (
    tester,
  ) async {
    await _registra();
    await _pausa('mod-definition');
    await _pumpHome(tester);

    expect(find.text('Jump Back In'), findsOneWidget);
    expect(_barra(tester).progress, 0);
  });

  testWidgets('la sezione è la prima della home', (tester) async {
    await _registra();
    await _pausa('eq1-intro');
    await _pumpHome(tester);

    expect(find.text('Jump Back In'), findsOneWidget);
  });

  testWidgets('il blocco sotto non è attaccato alla card', (tester) async {
    await _registra();
    await _pausa('eq1-intro');
    await _pumpHome(tester);

    final cardBottom = tester.getBottomLeft(_card).dy;
    final carouselTop = tester.getTopLeft(find.byType(ArgomentoCarousel)).dy;
    expect(carouselTop - cardBottom, greaterThanOrEqualTo(12));
  });

  testWidgets('toccando la card si apre la lezione al passo salvato', (
    tester,
  ) async {
    await _registra();
    await _pausa('eq1-intro', step: 2);
    await _pumpHome(tester);

    await tester.tap(_card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LessonScreen), findsOneWidget);
    // «3 di 3» è il contatore dello schermo lezione, non della card
    expect(find.text('3 di 4'), findsOneWidget);
  });

  testWidgets('completando la lezione la sezione sparisce', (tester) async {
    await _registra();
    await _pausa('eq1-intro', step: 3);
    await _pumpHome(tester);

    await tester.tap(_card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('option_0')));
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.text('Completa la lezione'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsNothing);
    expect(ProgressStore.instance.lessonResume, isNull);
  });
}
