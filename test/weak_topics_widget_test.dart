import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/data/study_store.dart';
import 'package:math_app/models/progress.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/weak_points_screen.dart';
import 'package:math_app/screens/weak_topic_screen.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/weak_topic_row.dart';

Future<void> _resetStores() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await LessonRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  await StudyStore.instance.resetForTest();
  SearchIndex.instance.build(
    ContentRepository.instance.levels,
    lessons: LessonRepository.instance.lessons,
  );
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToWeakSection(WidgetTester tester) async {
  await tester.dragUntilVisible(
    find.text('I tuoi punti deboli'),
    find.byType(ListView),
    const Offset(0, -120),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_resetStores);

  testWidgets('la sezione punti deboli è nascosta senza progressi', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('I tuoi punti deboli'), findsNothing);
    expect(find.textContaining('Vedi tutti'), findsNothing);
    expect(find.byType(WeakTopicRow), findsNothing);
  });

  testWidgets('la sezione appare con un esercizio da ripassare', (
    tester,
  ) async {
    await _pumpHome(tester);
    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.needsReview,
    );
    await tester.pumpAndSettle();

    await _scrollToWeakSection(tester);

    expect(find.text('I tuoi punti deboli'), findsOneWidget);
    expect(find.text('1 da ripassare'), findsWidgets);
    expect(find.byType(WeakTopicRow), findsOneWidget);
    expect(find.text('Frazioni'), findsOneWidget);
  });

  testWidgets('toccando la riga si apre il dettaglio del topic', (
    tester,
  ) async {
    await _pumpHome(tester);
    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.needsReview,
    );
    await tester.pumpAndSettle();

    await _scrollToWeakSection(tester);
    await tester.tap(find.byType(WeakTopicRow));
    await tester.pumpAndSettle();

    expect(find.byType(WeakTopicScreen), findsOneWidget);
    expect(find.text('Progresso'), findsOneWidget);
    expect(find.text('Ripassa'), findsOneWidget);
    expect(find.text('Introduzione alle frazioni'), findsOneWidget);
    expect(find.text('Da ripassare'), findsOneWidget);
    expect(find.text('Confronto di frazioni'), findsOneWidget);
  });

  testWidgets('Vedi tutti apre la lista completa dei punti deboli', (
    tester,
  ) async {
    await _pumpHome(tester);
    const weakIds = [
      'ms-frac-compare-1',
      'ms-frac-sum-1',
      'ms-perc-1',
      'ms-prop-1',
      'ms-eq-1',
    ];
    for (final id in weakIds) {
      await ProgressStore.instance.setStatus(id, ExerciseStatus.needsReview);
    }
    await tester.pumpAndSettle();

    await _scrollToWeakSection(tester);

    expect(find.byType(WeakTopicRow), findsNWidgets(3));
    expect(find.text('Vedi tutti (4)'), findsOneWidget);

    await tester.tap(find.text('Vedi tutti (4)'));
    await tester.pumpAndSettle();

    expect(find.byType(WeakPointsScreen), findsOneWidget);
    expect(find.byType(WeakTopicRow), findsNWidgets(4));
  });

  testWidgets('la sezione scompare quando il topic non è più debole', (
    tester,
  ) async {
    await _pumpHome(tester);
    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.needsReview,
    );
    await tester.pumpAndSettle();
    await _scrollToWeakSection(tester);
    expect(find.byType(WeakTopicRow), findsOneWidget);

    await ProgressStore.instance.setStatus(
      'ms-frac-compare-1',
      ExerciseStatus.mastered,
    );
    await tester.pumpAndSettle();

    expect(find.byType(WeakTopicRow), findsNothing);
    expect(find.text('I tuoi punti deboli'), findsNothing);
  });
}
