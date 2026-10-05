import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/course.dart';
import 'package:math_app/models/level.dart';
import 'package:math_app/models/topic.dart';
import 'package:math_app/screens/exercise_detail_screen.dart';
import 'package:math_app/screens/exercise_feed_screen.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/scientific_calculator.dart';

const _key = ValueKey('tools_toolbar');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Level level;
  late Course course;
  late Topic topic;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ContentRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
    level = ContentRepository.instance.levelById('high-school')!;
    course = level.courses.first;
    topic = course.topics.firstWhere((t) => t.exercises.isNotEmpty);
  });

  Future<void> apri(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: page));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Widget feed() =>
      ExerciseFeedScreen(level: level, course: course, topic: topic);

  Widget detail() => ExerciseDetailScreen(
    level: level,
    course: course,
    topic: topic,
    exercise: topic.exercises.first,
  );

  for (final (nome, pagina) in [
    ('l\'elenco degli esercizi', feed),
    ('la pagina dell\'esercizio', detail),
  ]) {
    group(nome, () {
      testWidgets(
        'ha la toolbar delle lezioni, una sola, in basso a sinistra',
        (tester) async {
          await apri(tester, pagina());

          expect(find.byType(M3EToolbar), findsOneWidget);
          final fab = tester.getRect(
            find.descendant(
              of: find.byKey(_key),
              matching: find.byIcon(M3EIcons.handyman_rounded),
            ),
          );
          final schermo =
              tester.view.physicalSize / tester.view.devicePixelRatio;
          expect(fab.left, lessThan(schermo.width / 2));
          expect(fab.bottom, greaterThan(schermo.height - 100));
          // La vecchia pila con le due azioni vuote non c'è più.
          expect(find.byIcon(M3EIcons.functions), findsNothing);
        },
      );

      testWidgets('ha l\'indaco della barra di avanzamento delle lezioni', (
        tester,
      ) async {
        await apri(tester, pagina());
        final toolbar = tester.widget<M3EToolbar>(find.byType(M3EToolbar));
        expect(
          toolbar.backgroundColor,
          AppColors.of(tester.element(find.byType(M3EToolbar))).accent,
        );
      });

      testWidgets('apre la calcolatrice e il drag giù la chiude', (
        tester,
      ) async {
        await apri(tester, pagina());
        expect(find.byType(ScientificCalculatorSheet), findsNothing);

        await tester.tap(
          find.descendant(
            of: find.byKey(_key),
            matching: find.byIcon(M3EIcons.handyman_rounded),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(
          find.descendant(
            of: find.byKey(_key),
            matching: find.byIcon(M3EIcons.calculate_rounded),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(ScientificCalculatorSheet), findsOneWidget);

        await tester.fling(
          find.byKey(const ValueKey('calc-sheet')),
          const Offset(0, 300),
          1200,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(ScientificCalculatorSheet), findsNothing);
      });
    });
  }

  test('Topic.fromJson ignora la chiave \'image\' legacy senza rompersi', () {
    final topic = Topic.fromJson({
      'id': 't',
      'title': 'T',
      'image': 'assets/images/x.jpg',
    });
    expect(topic.title, 'T');
  });
}
