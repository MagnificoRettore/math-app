import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/argomento.dart';
import 'package:math_app/models/argomento_status.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/argomento_status_badge.dart';
import 'package:math_app/widgets/completed_badge.dart';
import 'package:math_app/widgets/topic_grid.dart';

Argomento _argomento(String topicId) =>
    LessonRepository.instance.argomenti.firstWhere((a) => a.topicId == topicId);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ContentRepository.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  Future<void> risposta(
    Argomento a,
    String lessonId,
    int step,
    int exercise,
    bool correct,
  ) => ProgressStore.instance.recordQuizAnswer(
    a.levelId,
    lessonId,
    step: step,
    exercise: exercise,
    correct: correct,
  );

  group('stato dell\'argomento', () {
    test('senza niente fatto non è iniziato', () {
      final a = _argomento('year2-rette');
      expect(
        ProgressStore.instance.statusOfArgomento(a),
        ArgomentoStatus.notStarted,
      );
    });

    test(
      'con «Prova tu»: iniziato, non superato, superato con 3 giusti',
      () async {
        final a = _argomento('year2-rette');
        final lesson = a.lessons.first.id;
        final step = a.lessons.first.steps.indexWhere((s) => s.isPracticeQuiz);

        await ProgressStore.instance.completeLesson(
          a.levelId,
          a.lessons.first.id,
        );
        expect(
          ProgressStore.instance.statusOfArgomento(a),
          ArgomentoStatus.started,
        );

        await risposta(a, lesson, step, 0, true);
        await risposta(a, lesson, step, 1, false);
        expect(
          ProgressStore.instance.statusOfArgomento(a),
          ArgomentoStatus.failed,
        );

        await risposta(a, lesson, step, 1, true);
        expect(
          ProgressStore.instance.statusOfArgomento(a),
          ArgomentoStatus.failed,
        );

        // Lo stesso esercizio giusto due volte conta una volta sola.
        await risposta(a, lesson, step, 0, true);
        expect(
          ProgressStore.instance.statusOfArgomento(a),
          ArgomentoStatus.failed,
        );

        await risposta(a, lesson, step, 2, true);
        expect(
          ProgressStore.instance.statusOfArgomento(a),
          ArgomentoStatus.passed,
        );
      },
    );

    test('senza esercizi si supera finendo le lezioni', () async {
      final a = _argomento('year1-equations');
      expect(a.practiceExerciseCount, 0);

      await ProgressStore.instance.completeLesson(a.levelId, 'eq1-intro');

      expect(
        ProgressStore.instance.statusOfArgomento(a),
        ArgomentoStatus.passed,
      );
    });

    test('gli esiti sopravvivono a un nuovo load', () async {
      final a = _argomento('year2-rette');
      final lesson = a.lessons.first.id;
      await risposta(a, lesson, 1, 0, false);

      await ProgressStore.instance.reload();

      expect(
        ProgressStore.instance.statusOfArgomento(a),
        ArgomentoStatus.failed,
      );
    });
  });

  group('badge', () {
    Future<void> pumpCard(WidgetTester tester, ArgomentoStatus? status) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(
                width: 200,
                child: TopicGrid(
                  entries: [
                    TopicGridEntry(
                      key: const Key('card'),
                      icon: Icons.functions,
                      color: Colors.indigo,
                      title: 'Titolo',
                      caption: '2 lezioni · 0%',
                      status: status,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    testWidgets(
      'ogni stato ha la sua icona nell\'angolo, senza cambiare la card',
      (tester) async {
        await pumpCard(tester, null);
        final size = tester.getSize(find.byKey(const Key('card')));

        for (final status in ArgomentoStatus.values) {
          await pumpCard(tester, status);
          expect(tester.getSize(find.byKey(const Key('card'))), size);

          final badge = status == ArgomentoStatus.passed
              ? find.byKey(const Key('completed-badge'))
              : find.byKey(Key('status-badge-${status.name}'));
          expect(badge, findsOneWidget, reason: status.name);

          final card = tester.getRect(find.byKey(const Key('card')));
          final rect = tester.getRect(badge);
          expect(rect.top - card.top, CompletedBadge.inset);
          expect(card.right - rect.right, CompletedBadge.inset);
        }
      },
    );

    testWidgets('gli stati usano icone diverse', (tester) async {
      final icons = <IconData>{};
      for (final status in ArgomentoStatus.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: ArgomentoStatusBadge(status: status)),
          ),
        );
        icons.add(tester.widget<Icon>(find.byType(Icon)).icon!);
      }
      expect(icons.length, ArgomentoStatus.values.length);
    });
  });
}
