import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson_resume.dart';
import 'package:math_app/models/progress.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/lesson_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ContentRepository.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  Future<void> pumpLezioni(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LessonListScreen(levelId: 'high-school', showPill: false),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpEsercizi(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourseScreen(
          level: ContentRepository.instance.levelById('high-school')!,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> inCorso(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('filter-in-progress')));
    await tester.pumpAndSettle();
  }

  group('Lezioni', () {
    testWidgets('gli argomenti sono una griglia a due colonne', (tester) async {
      await pumpLezioni(tester);

      expect(find.text('Tutti gli argomenti'), findsOneWidget);
      final a = tester.getTopLeft(find.text('Equazioni di primo grado'));
      final b = tester.getTopLeft(find.text('Esempio argomento'));
      expect(b.dx, greaterThan(a.dx));
      expect(b.dy, a.dy);
      expect(find.text('Riprendi da dove eri rimasto'), findsNothing);
    });

    testWidgets('In corso mostra solo gli argomenti iniziati e non finiti', (
      tester,
    ) async {
      final esempio = LessonRepository.instance.argomenti.firstWhere(
        (a) => a.title == 'Esempio argomento',
      );
      await pumpLezioni(tester);
      await inCorso(tester);
      expect(find.byKey(const Key('nessun-argomento-in-corso')), findsOne);

      // Una lezione su quattro: iniziato. Equazioni (1 su 1) è finito.
      await ProgressStore.instance.completeLesson(
        'high-school',
        esempio.lessons.first.id,
      );
      await ProgressStore.instance.completeLesson('high-school', 'eq1-intro');
      await tester.pumpAndSettle();
      expect(find.text('Esempio argomento'), findsOneWidget);
      expect(find.text('Equazioni di primo grado'), findsNothing);

      await tester.tap(find.byKey(const Key('filter-all')));
      await tester.pumpAndSettle();
      expect(find.text('Equazioni di primo grado'), findsOneWidget);
    });

    testWidgets('la lezione a metà si riprende dalla card in cima', (
      tester,
    ) async {
      await ProgressStore.instance.saveLessonResume(
        const LessonResume(
          levelId: 'high-school',
          lessonId: 'eq1-intro',
          step: 1,
        ),
      );
      await pumpLezioni(tester);

      expect(find.text('Riprendi da dove eri rimasto'), findsOneWidget);
      expect(find.textContaining('Card 2 di'), findsOneWidget);
    });
  });

  group('Esercizi', () {
    testWidgets('i topic sono una griglia con il conteggio e la percentuale', (
      tester,
    ) async {
      await pumpEsercizi(tester);

      expect(find.byKey(const Key('tutti-esercizi')), findsOneWidget);
      expect(find.text('2 esercizi · 0%'), findsOneWidget);
      expect(find.text('Riprendi da dove eri rimasto'), findsNothing);
    });

    testWidgets('In corso e la card di ripresa seguono gli esercizi fatti', (
      tester,
    ) async {
      final topic = ContentRepository.instance
          .levelById('high-school')!
          .courses
          .first
          .topics
          .firstWhere((t) => t.title == 'Frazioni');
      await ProgressStore.instance.setStatus(
        'high-school',
        topic.exercises.first.id,
        ExerciseStatus.mastered,
      );
      await pumpEsercizi(tester);

      expect(find.text('Riprendi da dove eri rimasto'), findsOneWidget);
      expect(find.text('2 esercizi · 50%'), findsOneWidget);

      await inCorso(tester);
      expect(find.byKey(const Key('topic-year1-fractions')), findsOneWidget);
      expect(find.byKey(const Key('tutti-esercizi')), findsNothing);
      expect(find.text('Equazioni di primo grado'), findsNothing);
    });
  });
}
