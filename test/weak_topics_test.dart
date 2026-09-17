import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/weak_topic_engine.dart';
import 'package:math_app/models/progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ContentRepository.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  test('nessun punto debole senza progressi', () {
    expect(WeakTopicEngine.weakTopics(), isEmpty);
  });

  test('un esercizio da ripassare rende debole il suo topic', () async {
    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.needsReview,
    );

    final weak = WeakTopicEngine.weakTopics();
    expect(weak.length, 1);
    expect(weak.single.topic.id, 'ms1-fractions');
    expect(weak.single.needsReviewCount, 1);
    expect(weak.single.masteredRatio, 0);
  });

  test('conta tutti gli esercizi da ripassare del topic', () async {
    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.needsReview,
    );
    await ProgressStore.instance.setStatus(
      'ms-frac-sum-1',
      ExerciseStatus.needsReview,
    );

    final weak = WeakTopicEngine.weakTopics();
    expect(weak.length, 1);
    expect(weak.single.topic.id, 'ms1-fractions');
    expect(weak.single.needsReviewCount, 2);
  });

  test('il topic scompare quando resta solo assimilato', () async {
    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.needsReview,
    );
    await ProgressStore.instance.setStatus(
      'ms-frac-sum-1',
      ExerciseStatus.needsReview,
    );

    expect(WeakTopicEngine.weakTopics(), hasLength(1));

    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.mastered,
    );
    await ProgressStore.instance.setStatus(
      'ms-frac-sum-1',
      ExerciseStatus.mastered,
    );

    expect(WeakTopicEngine.weakTopics(), isEmpty);
  });

  test('ordinamento per numero di esercizi da ripassare', () async {
    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.needsReview,
    );
    await ProgressStore.instance.setStatus(
      'ms-frac-sum-1',
      ExerciseStatus.needsReview,
    );
    await ProgressStore.instance.setStatus(
      'ms-perc-1',
      ExerciseStatus.needsReview,
    );

    final ids = WeakTopicEngine.weakTopics().map((w) => w.topic.id).toList();
    expect(ids.sublist(0, 2), ['ms1-fractions', 'ms1-percentage']);
  });

  test('a parità di conteggio vince chi ha completato meno', () async {
    await ProgressStore.instance.setStatus(
      'ms-perc-1',
      ExerciseStatus.needsReview,
    );
    await ProgressStore.instance.setStatus(
      'frac-easy-1',
      ExerciseStatus.needsReview,
    );
    await ProgressStore.instance.setStatus(
      'frac-hard-1',
      ExerciseStatus.mastered,
    );

    final ids = WeakTopicEngine.weakTopics().map((w) => w.topic.id).toList();
    final position = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    expect(position['ms1-percentage']!, lessThan(position['year1-fractions']!));

    final percentage = WeakTopicEngine.weakTopicFor('ms1-percentage')!;
    final yearFractions = WeakTopicEngine.weakTopicFor('year1-fractions')!;
    expect(percentage.masteredRatio, lessThan(yearFractions.masteredRatio));
  });

  test('masteredRatioFor conta solo gli esercizi assimilati', () async {
    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.mastered,
    );
    await ProgressStore.instance.setStatus(
      'ms-frac-sum-1',
      ExerciseStatus.needsReview,
    );

    final ids = ['ms-frac-compare-1', 'ms-frac-sum-1'];
    expect(ProgressStore.instance.masteredRatioFor(ids), 0.5);
    expect(ProgressStore.instance.completionFor(ids), 1.0);
  });

  test(
    'lezioni collegate a un topic, solo quelle non ancora completate',
    () async {
      final fractionsLessons = WeakTopicEngine.lessonsForTopic('ms1-fractions');
      expect(fractionsLessons.map((l) => l.id), contains('fractions-basics'));

      final equationsLessons = WeakTopicEngine.lessonsForTopic(
        'year1-equations',
      );
      expect(equationsLessons.map((l) => l.id), contains('linear-equations'));

      expect(WeakTopicEngine.lessonsForTopic('ms2-proportions'), isEmpty);

      await ProgressStore.instance.completeLesson('fractions-basics');
      expect(
        WeakTopicEngine.lessonsForTopic('ms1-fractions').map((l) => l.id),
        isNot(contains('fractions-basics')),
      );
    },
  );
}
