import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/data/study_store.dart';
import 'package:math_app/models/progress.dart';
import 'package:math_app/screens/weak_points_screen.dart';
import 'package:math_app/screens/weak_topic_screen.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/weak_topic_row.dart';

Future<void> _resetStores() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  await StudyStore.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

/// Le pagine dei punti deboli sono di chi ha un profilo: da ospite non ci sono
/// esercizi da ripassare e la pagina lo dice invece di promettere il contrario.
Future<void> _registra() => AuthStore.instance.registerManual(
  name: 'Anna',
  email: 'anna@example.com',
  password: 'segreta1',
  schoolLevelId: 'middle-school',
);

Future<void> _pumpPagina(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const WeakPointsScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> _ripassa(List<String> ids) async {
  for (final id in ids) {
    await ProgressStore.instance.setStatus(
      'middle-school',
      id,
      ExerciseStatus.needsReview,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_resetStores);

  testWidgets('senza esercizi da ripassare la pagina dice tutto assimilato', (
    tester,
  ) async {
    await _registra();
    await _pumpPagina(tester);

    expect(find.text('Tutto assimilato!'), findsOneWidget);
    expect(find.byType(WeakTopicRow), findsNothing);
  });

  testWidgets('un esercizio da ripassare fa comparire il suo topic', (
    tester,
  ) async {
    await _registra();
    await _pumpPagina(tester);
    await _ripassa(['ms-frac-compare-1']);
    await tester.pumpAndSettle();

    expect(find.byType(WeakTopicRow), findsOneWidget);
    expect(find.text('Frazioni'), findsOneWidget);
  });

  testWidgets('toccando la riga si apre il dettaglio del topic', (
    tester,
  ) async {
    await _registra();
    await _ripassa(['ms-frac-compare-1']);
    await _pumpPagina(tester);

    await tester.tap(find.byType(WeakTopicRow));
    await tester.pumpAndSettle();

    expect(find.byType(WeakTopicScreen), findsOneWidget);
    expect(find.text('Progresso'), findsOneWidget);
    expect(find.text('Da ripassare'), findsOneWidget);
    expect(find.text('Confronto di frazioni'), findsOneWidget);
  });

  testWidgets('la pagina elenca tutti i punti deboli', (tester) async {
    await _registra();
    await _ripassa([
      'ms-frac-compare-1',
      'ms-frac-sum-1',
      'ms-perc-1',
      'ms-prop-1',
      'ms-eq-1',
    ]);
    await _pumpPagina(tester);

    expect(find.byType(WeakTopicRow), findsNWidgets(4));
  });

  testWidgets('il topic sparisce quando non è più debole', (tester) async {
    await _registra();
    await _ripassa(['ms-frac-compare-1']);
    await _pumpPagina(tester);
    expect(find.byType(WeakTopicRow), findsOneWidget);

    await ProgressStore.instance.setStatus(
      'middle-school',
      'ms-frac-compare-1',
      ExerciseStatus.mastered,
    );
    await tester.pumpAndSettle();

    expect(find.byType(WeakTopicRow), findsNothing);
  });
}
