import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/screens/argomento_lessons_screen.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/exercise_feed_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/widgets/app_card.dart';
import 'package:math_app/widgets/completed_badge.dart';
import 'package:math_app/widgets/main_header.dart';
import 'package:math_app/widgets/list_filter_bar.dart';

final _segno = find.byKey(const Key('completed-badge'));

/// Il segno sta nell'angolo in alto a destra della card che contiene [testo],
/// a [CompletedBadge.inset] dai due bordi.
void _nellAngolo(WidgetTester tester, Finder testo) {
  final card = tester.getRect(
    find.ancestor(of: testo, matching: find.byType(AppCard)).first,
  );
  final segno = tester.getRect(_segno);
  expect(segno.top - card.top, closeTo(CompletedBadge.inset, 0.5));
  expect(card.right - segno.right, closeTo(CompletedBadge.inset, 0.5));
  expect(segno.width, CompletedBadge.size);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
    await ContentRepository.instance.resetForTest();
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

  testWidgets(
    'lezione completata: spunta verde nell\'angolo in alto a destra',
    (tester) async {
      await tester.pumpWidget(host('high-school'));
      await tester.pump();
      expect(_segno, findsNothing);

      await ProgressStore.instance.completeLesson('high-school', 'eq1-intro');
      await tester.pump();

      expect(_segno, findsOneWidget);
      _nellAngolo(tester, find.text('Concetti e risoluzione guidata'));
    },
  );

  testWidgets('argomento completato: la stessa spunta sulla sua card', (
    tester,
  ) async {
    await ProgressStore.instance.completeLesson('high-school', 'eq1-intro');
    await tester.pumpWidget(
      const MaterialApp(home: LessonListScreen(levelId: 'high-school')),
    );
    await tester.pumpAndSettle();

    // Equazioni di primo grado ha una lezione sola: completata quella, lo è
    // l'argomento. L'argomento d'esempio dello stesso anno no.
    expect(_segno, findsOneWidget);
    _nellAngolo(tester, find.text('Equazioni di primo grado'));
  });

  testWidgets('la card dell\'argomento dice quante lezioni e a che punto', (
    tester,
  ) async {
    Future<void> apri() async {
      await tester.pumpWidget(
        const MaterialApp(home: LessonListScreen(levelId: 'high-school')),
      );
      await tester.pumpAndSettle();
    }

    await apri();
    expect(find.text('1 lezione · 0%'), findsOneWidget);
    await ProgressStore.instance.completeLesson('high-school', 'eq1-intro');
    await apri();
    expect(find.text('1 lezione · 100%'), findsOneWidget);
  });

  testWidgets('Lezioni si apre sull\'anno scelto alla registrazione', (
    tester,
  ) async {
    final corsi = ContentRepository.instance.levelById('high-school')!.courses;
    await AuthStore.instance.resetForTest();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'Segreta1',
      schoolLevelId: 'high-school',
      courseId: corsi[1].id,
    );
    await tester.pumpWidget(
      const MaterialApp(home: LessonListScreen(levelId: 'high-school')),
    );
    await tester.pumpAndSettle();

    final menu = tester.widget<YearDropdown>(find.byType(YearDropdown));
    expect(menu.selectedIndex, 1);
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

  group('Vai agli esercizi', () {
    final vai = find.byKey(const Key('vai-agli-esercizi'));

    /// L'argomento aperto sopra la radice vera, la `HomeScreen`: «Vai agli
    /// esercizi» torna a lei e le chiede di mostrare Esercizi.
    Future<void> apriArgomento(WidgetTester tester, String titolo) async {
      final argomento = LessonRepository.instance.argomenti.firstWhere(
        (a) => a.title == titolo,
      );
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ArgomentoLessonsScreen(
                argomento: argomento,
                levelId: 'high-school',
              ),
            ),
          );
      await tester.pumpAndSettle();
    }

    testWidgets('c\'è in basso a destra se l\'argomento ha esercizi', (
      tester,
    ) async {
      await tester.pumpWidget(host('high-school'));
      await tester.pump();

      expect(vai, findsOneWidget);
      final schermo = tester.view.physicalSize / tester.view.devicePixelRatio;
      final rect = tester.getRect(vai);
      expect(schermo.width - rect.right, closeTo(20, 1));
      expect(rect.center.dy, greaterThan(schermo.height / 2));
    });

    testWidgets('non c\'è se l\'argomento non ha esercizi', (tester) async {
      final argomento = LessonRepository.instance.argomenti.firstWhere(
        (a) => a.topicId == 'year1-esempio-argomento',
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
      expect(vai, findsNothing);
    });

    testWidgets('porta agli esercizi di quell\'anno e di quell\'argomento', (
      tester,
    ) async {
      await apriArgomento(tester, 'Equazioni di primo grado');

      await tester.tap(vai);
      await tester.pumpAndSettle();

      // Gli esercizi del topic, con sotto la sezione Esercizi sull'anno giusto.
      expect(find.byType(ExerciseFeedScreen), findsOneWidget);
      final corso = tester.widget<CourseScreen>(
        find.byType(CourseScreen, skipOffstage: false),
      );
      expect(corso.initialCourseId, 'year1');
      expect(corso.embedded, isTrue);

      // Il back torna all'elenco dell'anno, non all'argomento.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CourseScreen), findsOneWidget);
      expect(find.byType(ArgomentoLessonsScreen), findsNothing);
      expect(find.byType(ExerciseFeedScreen), findsNothing);
    });
  });
}
