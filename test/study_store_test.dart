import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/study_store.dart';

void main() {
  final day1 = DateTime(2026, 1, 10, 9);
  final day2 = DateTime(2026, 1, 11, 9);
  final day4 = DateTime(2026, 1, 13, 9);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stato iniziale: serie e obiettivi a zero', () async {
    StudyStore.instance.debugSetNow(day1);
    await StudyStore.instance.resetForTest();

    expect(StudyStore.instance.currentStreak, 0);
    expect(StudyStore.instance.bestStreak, 0);
    expect(StudyStore.instance.todayExercises, 0);
    expect(StudyStore.instance.todayMinutes, 0);
    expect(StudyStore.instance.exerciseGoalReached, isFalse);
    expect(StudyStore.instance.minutesGoalReached, isFalse);
  });

  test('5 esercizi in un giorno: obiettivo raggiunto una sola volta', () async {
    StudyStore.instance.debugSetNow(day1);
    await StudyStore.instance.resetForTest();

    final reached = <bool>[];
    for (var i = 0; i < 5; i++) {
      reached.add(await StudyStore.instance.recordExerciseCompleted('ex$i'));
    }

    expect(reached, [false, false, false, false, true]);
    expect(StudyStore.instance.exerciseGoalReached, isTrue);
    expect(StudyStore.instance.currentStreak, 1);
    expect(StudyStore.instance.bestStreak, 1);
  });

  test('lo stesso esercizio conta una sola volta al giorno', () async {
    StudyStore.instance.debugSetNow(day1);
    await StudyStore.instance.resetForTest();

    await StudyStore.instance.recordExerciseCompleted('ex1');
    await StudyStore.instance.recordExerciseCompleted('ex1');

    expect(StudyStore.instance.todayExercises, 1);
    expect(StudyStore.instance.exerciseGoalReached, isFalse);
  });

  test(
    'giorno consecutivo incrementa la serie, giorno saltato la azzera',
    () async {
      StudyStore.instance.debugSetNow(day1);
      await StudyStore.instance.resetForTest();
      await StudyStore.instance.recordExerciseCompleted('ex1');
      expect(StudyStore.instance.currentStreak, 1);

      StudyStore.instance.debugSetNow(day2);
      await StudyStore.instance.recordExerciseCompleted('ex2');
      expect(StudyStore.instance.currentStreak, 2);
      expect(StudyStore.instance.bestStreak, 2);

      StudyStore.instance.debugSetNow(day4);
      await StudyStore.instance.recordExerciseCompleted('ex3');
      expect(StudyStore.instance.currentStreak, 1);
      expect(StudyStore.instance.bestStreak, 2);
    },
  );

  test('10 minuti raggiungono l\'obiettivo di tempo', () async {
    StudyStore.instance.debugSetNow(day1);
    await StudyStore.instance.resetForTest();

    expect(await StudyStore.instance.addMinutes(9), isFalse);
    expect(StudyStore.instance.minutesGoalReached, isFalse);

    expect(await StudyStore.instance.addMinutes(1), isTrue);
    expect(StudyStore.instance.minutesGoalReached, isTrue);

    expect(await StudyStore.instance.addMinutes(5), isFalse);
  });

  test('contatori giornalieri si azzerano al cambio giorno', () async {
    StudyStore.instance.debugSetNow(day1);
    await StudyStore.instance.resetForTest();
    await StudyStore.instance.addMinutes(12);
    await StudyStore.instance.recordExerciseCompleted('ex1');

    StudyStore.instance.debugSetNow(day2);
    await StudyStore.instance.recordExerciseCompleted('ex2');

    expect(StudyStore.instance.todayExercises, 1);
    expect(StudyStore.instance.todayMinutes, 0);
    expect(StudyStore.instance.exerciseGoalReached, isFalse);
    expect(StudyStore.instance.minutesGoalReached, isFalse);
  });

  test(
    'persistenza: i dati sopravvivono a un nuovo load nello stesso giorno',
    () async {
      StudyStore.instance.debugSetNow(day1);
      await StudyStore.instance.resetForTest();
      await StudyStore.instance.recordExerciseCompleted('exA');
      await StudyStore.instance.recordExerciseCompleted('exB');
      await StudyStore.instance.addMinutes(10);

      StudyStore.instance.debugSetNow(day1);
      await StudyStore.instance.resetForTest();

      expect(StudyStore.instance.todayExercises, 2);
      expect(StudyStore.instance.todayMinutes, 10);
      expect(StudyStore.instance.currentStreak, 1);
      expect(StudyStore.instance.bestStreak, 1);
      expect(StudyStore.instance.exerciseGoalReached, isFalse);
      expect(StudyStore.instance.minutesGoalReached, isTrue);
    },
  );
}
