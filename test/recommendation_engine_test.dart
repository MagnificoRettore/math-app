import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/recommendation_engine.dart';
import 'package:math_app/models/difficulty.dart';
import 'package:math_app/models/progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ContentRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  test('consiglia esercizi solo del livello, mai tentati, facili prima', () {
    final middle = RecommendationEngine.recommendedExercises(
      'middle-school',
      limit: 100,
    );
    expect(middle, isNotEmpty);
    for (final loc in middle) {
      expect(loc.level.id, 'middle-school');
      expect(
        ProgressStore.instance.statusOf(loc.level.id, loc.exercise.id),
        ExerciseStatus.none,
      );
    }

    final high = RecommendationEngine.recommendedExercises(
      'high-school',
      limit: 100,
    );
    expect(high, isNotEmpty);
    final ranks = high.map((loc) => loc.exercise.difficulty).toList();
    for (var i = 1; i < ranks.length; i++) {
      expect(
        _rank(ranks[i - 1]) <= _rank(ranks[i]),
        isTrue,
        reason: 'Esercizi non ordinati per difficoltà',
      );
    }
  });

  test('esclude gli esercizi già affrontati', () async {
    final before = RecommendationEngine.recommendedExercises(
      'middle-school',
      limit: 1,
    );
    final first = before.first;
    await ProgressStore.instance.setStatus(
      first.level.id,
      first.exercise.id,
      ExerciseStatus.mastered,
    );

    final after = RecommendationEngine.recommendedExercises(
      'middle-school',
      limit: 1,
    );
    expect(after.map((l) => l.exercise.id), isNot(contains(first.exercise.id)));
  });
}

int _rank(Difficulty difficulty) {
  switch (difficulty) {
    case Difficulty.easy:
      return 0;
    case Difficulty.medium:
      return 1;
    case Difficulty.hard:
      return 2;
  }
}
