import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/screens/argomento_lessons_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/widgets/main_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
  });

  Widget host(String levelId) {
    final argomento = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Equazioni di primo grado',
    );
    return MaterialApp(
      home: ArgomentoLessonsScreen(argomento: argomento, levelId: levelId),
    );
  }

  testWidgets('il capitolo mostra le lezioni con numero e minuti', (
    tester,
  ) async {
    await tester.pumpWidget(host('high-school'));
    await tester.pump();

    expect(find.byType(ArgomentoLessonsScreen), findsOneWidget);
    expect(find.text('Equazioni di primo grado'), findsWidgets);
    // Il numero a sinistra è stato rimosso
    expect(find.text('Concetti e risoluzione guidata'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('Completata'), findsNothing);
  });

  testWidgets('toccare una lezione apre il player dei passaggi', (
    tester,
  ) async {
    await tester.pumpWidget(host('high-school'));
    await tester.pump();

    await tester.tap(find.text('Concetti e risoluzione guidata'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('lezione completata mostra il badge', (tester) async {
    await ProgressStore.instance.completeLesson('high-school', 'eq1-intro');
    await tester.pumpWidget(host('high-school'));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('Moduli mostra le lezioni Definizione e Modulo e Equazioni', (
    tester,
  ) async {
    final argomento = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Moduli',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ArgomentoLessonsScreen(
          argomento: argomento,
          levelId: 'high-school',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Moduli'), findsOneWidget);
    expect(find.text('Definizione'), findsOneWidget);
    expect(find.text('Modulo e Equazioni con Modulo'), findsOneWidget);
    expect(find.text('6 min'), findsOneWidget);

    await tester.tap(find.text('Modulo e Equazioni con Modulo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('la pagina dell\'argomento ha la banda dell\'header', (
    tester,
  ) async {
    await tester.pumpWidget(host('high-school'));
    await tester.pump();

    // La stessa banda delle pagine main: identità, lente e personalizzazione.
    expect(find.byType(MainHeaderAppBar), findsOneWidget);
    expect(find.byKey(const Key('header-identity')), findsOneWidget);
    expect(find.byKey(const Key('header-search')), findsOneWidget);
    expect(find.byKey(const Key('header-customization')), findsOneWidget);
    // Il titolo dell'argomento sta nel corpo, sotto la banda.
    final banda = tester.getRect(find.byType(AppBar));
    expect(
      // La lezione si chiama come l'argomento: la prima è l'intestazione.
      tester.getTopLeft(find.text('Equazioni di primo grado').first).dy,
      greaterThanOrEqualTo(banda.bottom),
    );
  });

  testWidgets('la freccia nella banda torna alla pagina di prima', (
    tester,
  ) async {
    final argomento = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Moduli',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ArgomentoLessonsScreen(argomento: argomento),
              ),
            ),
            child: const Text('apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    expect(find.byType(ArgomentoLessonsScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ArgomentoLessonsScreen), findsNothing);
  });
}
