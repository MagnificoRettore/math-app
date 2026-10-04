import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/lesson_resume_engine.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson_resume.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LessonRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  Future<void> salvaPausa(
    String lessonId, {
    int step = 0,
    String? levelId,
  }) async {
    await ProgressStore.instance.saveLessonResume(
      LessonResume(
        levelId: levelId ?? 'high-school',
        lessonId: lessonId,
        step: step,
      ),
    );
  }

  group('senza un punto di ripresa', () {
    test('senza lezioni aperte non propone niente', () {
      expect(LessonResumeEngine.target(levelId: 'high-school'), isNull);
    });

    test('senza livello non propone niente', () async {
      await salvaPausa('eq1-intro');
      expect(LessonResumeEngine.target(levelId: ''), isNull);
    });
  });

  group('lezione lasciata aperta', () {
    test('ripropone la lezione all\'ultimo passo', () async {
      await salvaPausa('eq1-intro', step: 2);

      final target = LessonResumeEngine.target(levelId: 'high-school');
      expect(target, isNotNull);
      expect(target!.lesson.id, 'eq1-intro');
      expect(target.argomento.title, 'Equazioni di primo grado');
      expect(target.step, 2);
      expect(target.isPaused, isTrue);
    });

    test('un passo oltre la fine viene ricondotto all\'ultimo', () async {
      await salvaPausa('eq1-intro', step: 99);

      expect(LessonResumeEngine.target(levelId: 'high-school')!.step, 3);
    });

    test('il passo riparte da zero senza pausa', () async {
      await salvaPausa('mod-definition');

      final target = LessonResumeEngine.target(levelId: 'high-school');
      expect(target!.lesson.id, 'mod-definition');
      expect(target.step, 0);
    });

    test('una lezione di un altro livello viene ignorata', () async {
      await salvaPausa('eq1-intro', levelId: 'middle-school');

      expect(LessonResumeEngine.target(levelId: 'high-school'), isNull);
    });

    test('una lezione sparita dal contenuto viene ignorata', () async {
      await salvaPausa('non-esiste-piu');

      expect(LessonResumeEngine.target(levelId: 'high-school'), isNull);
    });
  });

  group('la lezione in pausa è stata completata altrove', () {
    test('va alla lezione successiva dello stesso argomento', () async {
      await salvaPausa('mod-definition');
      await ProgressStore.instance.completeLesson(
        'high-school',
        'mod-definition',
      );

      final target = LessonResumeEngine.target(levelId: 'high-school');
      expect(target!.lesson.id, 'mod-equations-intro');
      expect(target.argomento.title, 'Moduli');
      expect(target.step, 0);
      expect(target.isPaused, isFalse);
    });

    test('torna indietro se la lezione successiva era già finita', () async {
      await salvaPausa('mod-equations-intro');
      await ProgressStore.instance.completeLesson(
        'high-school',
        'mod-equations-intro',
      );

      final target = LessonResumeEngine.target(levelId: 'high-school');
      expect(target!.lesson.id, 'mod-definition');
      expect(target.isPaused, isFalse);
    });

    test('anno interamente completato: niente da proporre', () async {
      await salvaPausa('eq1-intro');
      await ProgressStore.instance.completeLesson('high-school', 'eq1-intro');
      await ProgressStore.instance.completeLesson(
        'high-school',
        'mod-definition',
      );
      await ProgressStore.instance.completeLesson(
        'high-school',
        'mod-equations-intro',
      );
      // Anche le lezioni dell'argomento d'esempio dei grafici, in prima.
      for (final id in [
        'ex-arg-funzioni',
        'ex-arg-geometria',
        'ex-arg-disequazioni',
        'ex-arg-barre',
      ]) {
        await ProgressStore.instance.completeLesson('high-school', id);
      }

      expect(LessonResumeEngine.target(levelId: 'high-school'), isNull);
    });
  });

  // Argomento «Moduli»: Definizione da 1 card, Modulo e Equazioni da 9, in
  // tutto 10.
  group('avanzamento dentro il topic', () {
    test('sul primo passo non c\'è ancora nessuna card superata', () async {
      await salvaPausa('mod-definition');

      final target = LessonResumeEngine.target(levelId: 'high-school')!;
      expect(LessonResumeEngine.topicProgress(target), 0);
    });

    test('conta le card superate della lezione in pausa', () async {
      await salvaPausa('mod-equations-intro', step: 3);

      final target = LessonResumeEngine.target(levelId: 'high-school')!;
      // 1 card di Definizione che la precede + 3 superate, su 10.
      expect(LessonResumeEngine.topicProgress(target), closeTo(4 / 10, 0.001));
    });

    test('conta anche le lezioni precedenti mai aperte', () async {
      await salvaPausa('mod-equations-intro');
      expect(
        ProgressStore.instance.isLessonCompleted(
          'high-school',
          'mod-definition',
        ),
        isFalse,
      );

      final target = LessonResumeEngine.target(levelId: 'high-school')!;
      // Definizione non è stata fatta, ma il topic si affronta in ordine e
      // la sua card conta lo stesso.
      expect(LessonResumeEngine.topicProgress(target), closeTo(1 / 10, 0.001));
    });

    test(
      'la lezione proposta dopo una completata riparte dal suo inizio',
      () async {
        await salvaPausa('mod-definition');
        await ProgressStore.instance.completeLesson(
          'high-school',
          'mod-definition',
        );

        final target = LessonResumeEngine.target(levelId: 'high-school')!;
        expect(target.lesson.id, 'mod-equations-intro');
        expect(
          LessonResumeEngine.topicProgress(target),
          closeTo(1 / 10, 0.001),
        );
      },
    );

    test('un passo fuori range non spinge la barra oltre uno', () async {
      await salvaPausa('mod-equations-intro', step: 99);

      final target = LessonResumeEngine.target(levelId: 'high-school')!;
      expect(target.step, 8);
      expect(LessonResumeEngine.topicProgress(target), closeTo(9 / 10, 0.001));
    });
  });
}
