import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/screens/customization_screen.dart';
import 'package:math_app/screens/lesson_preview_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LessonRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  /// La lezione entra dopo il primo frame (si apre sopra la pagina di base) e
  /// con la transizione della rotta: qualche frame, non un `pumpAndSettle`,
  /// perché la lezione ha animazioni che non finiscono.
  Future<void> passa(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> apri(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(900, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LessonPreviewScreen()));
    await tester.pump();
  }

  testWidgets('si apre dalle impostazioni, in debug', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CustomizationScreen()));
    await tester.tap(find.byKey(const Key('open-lesson-preview')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonPreviewScreen), findsOneWidget);
  });

  testWidgets('elenca tutte le lezioni', (tester) async {
    await apri(tester);
    for (final a in LessonRepository.instance.argomenti) {
      for (final l in a.lessons) {
        await tester.ensureVisible(find.byKey(Key('preview-lesson-${l.id}')));
        expect(find.byKey(Key('preview-lesson-${l.id}')), findsOneWidget);
      }
    }
  });

  testWidgets('la lezione sta in una cornice della dimensione scelta', (
    tester,
  ) async {
    await apri(tester);
    await tester.tap(find.byKey(const Key('preview-lesson-rette-intro')));
    await passa(tester);
    expect(find.byType(LessonScreen), findsOneWidget);

    Size screen() => tester.getSize(
      find
          .ancestor(
            of: find.byType(LessonScreen),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(screen(), kPreviewDevices[1].$2);

    await tester.tap(find.byKey(const Key('preview-device-0')));
    await passa(tester);
    expect(screen(), kPreviewDevices[0].$2);
  });

  testWidgets('la scala del testo arriva alla lezione dentro la cornice', (
    tester,
  ) async {
    await apri(tester);
    await tester.tap(find.byKey(const Key('preview-lesson-rette-intro')));
    await passa(tester);
    double scala() =>
        MediaQuery.textScalerOf(tester.element(find.byType(LessonScreen)))
            .scale(10);
    expect(scala(), closeTo(10, 0.01));

    await tester.ensureVisible(find.byKey(const Key('preview-scale-1.6')));
    await tester.tap(find.byKey(const Key('preview-scale-1.6')));
    await passa(tester);
    expect(scala(), closeTo(16, 0.01));
  });

  testWidgets('«Ricarica» rilegge i contenuti e tiene la lezione aperta', (
    tester,
  ) async {
    await apri(tester);
    await tester.tap(find.byKey(const Key('preview-lesson-rette-intro')));
    await passa(tester);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('preview-reload')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await passa(tester);

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con la freccia si torna all\'elenco', (tester) async {
    await apri(tester);
    await tester.tap(find.byKey(const Key('preview-lesson-rette-intro')));
    await passa(tester);
    await tester.tap(find.byKey(const Key('preview-back')));
    await tester.pump();
    expect(find.byKey(const Key('preview-list')), findsOneWidget);
  });
}
