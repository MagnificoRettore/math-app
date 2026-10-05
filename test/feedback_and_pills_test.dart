import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/browse_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/feedback_store.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/models/level.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/customization_screen.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
import 'package:math_app/widgets/search_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await ContentRepository.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
    await FeedbackStore.instance.resetForTest();
    BrowseStore.instance.resetForTest();
    SearchIndex.instance.build(ContentRepository.instance.levels);
  });

  Future<void> register(String school) => AuthStore.instance.registerManual(
    name: 'Anna',
    email: 'anna@example.com',
    accountId: 'anna',
    password: 'Segreta1',
    schoolLevelId: school,
  );

  /// Di quanto la faccia della pillola è scesa (0 su, 4 giù).
  double scesa(WidgetTester tester, Key key) {
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(AnimatedContainer),
      ),
    );
    return container.transform!.getTranslation().y;
  }

  group('feedback', () {
    testWidgets('si apre dalle impostazioni; un messaggio corto non parte', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CustomizationScreen()));
      await tester.tap(find.byKey(const Key('open-feedback')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feedback-form')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('feedback-field')), 'ciao');
      await tester.tap(find.byKey(const Key('feedback-send')));
      await tester.pumpAndSettle();

      expect(find.text('Scrivi almeno 10 caratteri'), findsOneWidget);
      expect(FeedbackStore.instance.count, 0);
    });

    testWidgets('un messaggio valido si salva e ringrazia', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomizationScreen()));
      await tester.tap(find.byKey(const Key('open-feedback')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feedback-kind-problem')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('feedback-field')),
        'La calcolatrice si chiude da sola',
      );
      await tester.tap(find.byKey(const Key('feedback-send')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feedback-thanks')), findsOneWidget);
      expect(FeedbackStore.instance.count, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('feedback_v1'), contains('problem'));

      await tester.tap(find.byKey(const Key('feedback-done')));
      await tester.pumpAndSettle();
      expect(find.byType(CustomizationScreen), findsOneWidget);
    });
  });

  group('pillole della barra', () {
    Future<void> pumpLezioni(WidgetTester tester) async {
      await register('high-school');
      await tester.pumpWidget(
        const MaterialApp(home: LessonListScreen(levelId: 'high-school')),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('la ricerca ha il suo pulsante come i filtri', (tester) async {
      await pumpLezioni(tester);
      final ricerca = tester.getRect(find.byKey(const Key('header-search')));
      final filtro = tester.getRect(find.byKey(const Key('filter-all')));
      // Stessa altezza dei filtri, non un'icona nuda.
      expect(ricerca.height, filtro.height);
      expect(ricerca.width, greaterThan(40));
    });

    testWidgets('premuta, la pillola scende sul gradino e poi torna su', (
      tester,
    ) async {
      await pumpLezioni(tester);
      for (final key in const [
        Key('header-search'),
        Key('filter-in-progress'),
      ]) {
        expect(scesa(tester, key), 0, reason: '$key a riposo');
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(key)),
        );
        await tester.pumpAndSettle();
        expect(scesa(tester, key), 4, reason: '$key premuta');
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(scesa(tester, key), 0, reason: '$key rilasciata');
      }
    });

    testWidgets('il filtro attivo resta giù', (tester) async {
      await pumpLezioni(tester);
      expect(scesa(tester, const Key('filter-all')), 4);

      await tester.tap(find.byKey(const Key('filter-in-progress')));
      await tester.pumpAndSettle();
      expect(scesa(tester, const Key('filter-in-progress')), 4);
      expect(scesa(tester, const Key('filter-all')), 0);
    });

    testWidgets('la ricerca si espande dal centro del suo pulsante', (
      tester,
    ) async {
      await pumpLezioni(tester);
      final centro = tester.getCenter(find.byKey(const Key('header-search')));

      await tester.tap(find.byKey(const Key('header-search')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final clip = tester.widget<ClipPath>(
        find
            .descendant(
              of: find.byType(Navigator),
              matching: find.byType(ClipPath),
            )
            .last,
      );
      final bounds = clip.clipper!
          .getClip(tester.getSize(find.byType(SearchOverlay)))
          .getBounds();
      expect((bounds.center - centro).distance, lessThan(1));
    });
  });

  group('la pagina segue la scuola', () {
    testWidgets('Lezioni: cambiando scuola dal profilo si aggiorna subito', (
      tester,
    ) async {
      await register('high-school');
      await tester.pumpWidget(
        const MaterialApp(home: LessonListScreen(levelId: 'high-school')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Equazioni di primo grado'), findsOneWidget);

      await AuthStore.instance.updateSchool('university');
      await tester.pump();

      expect(find.text('Equazioni di primo grado'), findsNothing);
      expect(find.text('Analisi I'), findsOneWidget);
    });

    testWidgets('Esercizi: cambiando scuola dal profilo si aggiorna subito', (
      tester,
    ) async {
      await register('high-school');
      final Level liceo = ContentRepository.instance.levelById('high-school')!;
      await tester.pumpWidget(MaterialApp(home: CourseScreen(level: liceo)));
      await tester.pumpAndSettle();
      expect(find.text('Frazioni'), findsOneWidget);

      await AuthStore.instance.updateSchool('university');
      await tester.pump();

      expect(find.text('Frazioni'), findsNothing);
      expect(find.text('Analisi I'), findsOneWidget);
    });

    testWidgets('Lezioni: una visita ad altra scuola si vede subito', (
      tester,
    ) async {
      await register('high-school');
      await tester.pumpWidget(
        const MaterialApp(home: LessonListScreen(levelId: 'high-school')),
      );
      await tester.pumpAndSettle();

      BrowseStore.instance.browse('university');
      await tester.pump();

      expect(find.text('Equazioni di primo grado'), findsNothing);
      expect(find.text('Analisi I'), findsOneWidget);
    });
  });
}
