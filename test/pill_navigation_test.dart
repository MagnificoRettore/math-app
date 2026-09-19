import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/bookmarks_screen.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/widgets/pill_nav_bar.dart';

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await LessonRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  SearchIndex.instance.build(
    ContentRepository.instance.levels,
    lessons: LessonRepository.instance.lessons,
  );
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
}

Finder _pillIcon(IconData icon) =>
    find.descendant(of: find.byType(PillNavBar), matching: find.byIcon(icon));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets(
    'ospite: LEZIONI apre pop-up e mostra lezioni della scuola scelta',
    (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('LEZIONI'));
      await tester.pumpAndSettle();

      expect(find.text('Lezioni per scuola'), findsOneWidget);
      expect(find.text('Scuola Media'), findsWidgets);

      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();

      expect(find.byType(LessonListScreen), findsOneWidget);
      expect(find.text('Anno 1'), findsWidgets);
      expect(find.text('Anno 2'), findsWidgets);
      expect(find.text('Anno 3'), findsWidgets);
      expect(find.text('Equazioni di primo grado'), findsNothing);
    },
  );

  testWidgets(
    'ospite: le lezioni hanno la barra anni e poi argomento e sezione',
    (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('LEZIONI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();

      // Step anno: barra anni in alto (come ESERCIZI), Anno 1 già attivo
      expect(find.byType(LessonListScreen), findsOneWidget);
      expect(find.text('Anno 1'), findsWidgets);
      expect(find.text('Anno 2'), findsWidgets);
      expect(find.text('Anno 3'), findsWidgets);
      expect(find.text('Frazioni'), findsOneWidget);
      expect(find.text('Teorema di Pitagora'), findsNothing);

      // Step argomento → sezione → lezione (Anno 1, Scuola Media)
      await tester.tap(find.text('Frazioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Introduzione alle frazioni'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LessonListScreen), findsOneWidget);

      // Anno 2: senza lezioni, pagina argomento vuota
      await tester.tap(find.text('Anno 2'));
      await tester.pumpAndSettle();

      expect(find.text('Nessuna lezione in questo anno'), findsOneWidget);
      expect(find.text('Introduzione alle frazioni'), findsNothing);

      // Anno 3: solo i propri argomenti
      await tester.tap(find.text('Anno 3'));
      await tester.pumpAndSettle();

      expect(find.text('Teorema di Pitagora'), findsOneWidget);
      expect(find.text('Introduzione alle frazioni'), findsNothing);
    },
  );

  testWidgets(
    'loggato: ESERCIZI apre subito la pagina della scuola del profilo',
    (tester) async {
      await AuthStore.instance.registerManual(
        name: 'Anna',
        email: 'anna@example.com',
        password: 'segreta1',
        schoolLevelId: 'high-school',
      );
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ESERCIZI'));
      await tester.pumpAndSettle();

      expect(find.byType(CourseScreen), findsOneWidget);
      expect(find.text('Anno 1'), findsWidgets);
      expect(find.text('Lezioni per scuola'), findsNothing);
    },
  );

  testWidgets(
    'ospite: ESERCIZI da una pagina di profondità non torna alla home',
    (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('LEZIONI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();
      expect(find.byType(LessonListScreen), findsOneWidget);

      await tester.tap(find.text('ESERCIZI'));
      await tester.pumpAndSettle();

      expect(find.text('Esercizi per scuola'), findsOneWidget);
      expect(find.byType(LessonListScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    },
  );

  testWidgets('segnalibri: si può tornare indietro con il pulsante back', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byTooltip('Segnalibri'));
    await tester.pumpAndSettle();
    expect(find.byType(BookmarksScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(BookmarksScreen), findsNothing);
  });

  testWidgets('la pillola compare solo sulle schermate principali', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('LEZIONI'), findsOneWidget);
    expect(find.text('ESERCIZI'), findsOneWidget);
    expect(find.text('PROFILO'), findsOneWidget);

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();

    expect(find.byType(LessonListScreen), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);

    await tester.tap(find.text('Frazioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Introduzione alle frazioni'));
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('PROFILO apre il profilo e HOME ritorna alla home', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('PROFILO'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('trascinando la pillola si cambia sezione', (tester) async {
    await _pumpHome(tester);

    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.text('HOME'), findsOneWidget);

    final bar = find.byType(PillNavBar);
    final barSize = tester.getSize(bar);
    final center = tester.getCenter(bar);

    final gesture = await tester.startGesture(
      Offset(center.dx - barSize.width * 3 / 8, center.dy),
    );
    await tester.pump();
    await gesture.moveBy(Offset(barSize.width * 3 / 4, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('la pillola parte centrata sulla HOME', (tester) async {
    await _pumpHome(tester);

    final barRect = tester.getRect(find.byType(PillNavBar));
    final indicator = tester.getRect(
      find.byKey(const ValueKey('pill-indicator')),
    );

    // L'indicatore deve partire centrato sul primo segmento (HOME),
    // non sul confine HOME/LEZIONI.
    expect(indicator.left - barRect.left, lessThan(60));
    expect(indicator.center.dx - barRect.left, lessThan(barRect.width * 0.2));
    expect(
      indicator.center.dx - barRect.left,
      greaterThan(barRect.width * 0.05),
    );
  });

  testWidgets(
    'ospite: trascinando verso LEZIONI la scelta appare una sola volta',
    (tester) async {
      await _pumpHome(tester);

      final bar = find.byType(PillNavBar);
      final barSize = tester.getSize(bar);
      final center = tester.getCenter(bar);

      final gesture = await tester.startGesture(
        Offset(center.dx - barSize.width * 3 / 8, center.dy),
      );
      await tester.pump();
      await gesture.moveBy(Offset(barSize.width / 4, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Lezioni per scuola'), findsOneWidget);
    },
  );

  testWidgets('dopo il back dalle lezioni la pillola torna su HOME', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();
    expect(find.byType(LessonListScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_pillIcon(Icons.home), findsOneWidget);
    expect(_pillIcon(Icons.home_outlined), findsNothing);
  });

  testWidgets('dopo il back dal profilo la pillola torna su HOME', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('PROFILO'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_pillIcon(Icons.home), findsOneWidget);
    expect(_pillIcon(Icons.home_outlined), findsNothing);
  });

  testWidgets('dopo il back la pillola di Home resta navigabile', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('ESERCIZI'));
    await tester.pumpAndSettle();
    expect(find.text('Esercizi per scuola'), findsOneWidget);
  });

  testWidgets(
    'dopo un drag verso le lezioni e il back la pillola non resta evidenziata',
    (tester) async {
      await _pumpHome(tester);

      final bar = find.byType(PillNavBar);
      final barSize = tester.getSize(bar);
      final center = tester.getCenter(bar);

      final gesture = await tester.startGesture(
        Offset(center.dx - barSize.width * 3 / 8, center.dy),
      );
      await tester.pump();
      await gesture.moveBy(Offset(barSize.width / 4, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Lezioni per scuola'), findsOneWidget);
      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();
      expect(find.byType(LessonListScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(_pillIcon(Icons.home), findsOneWidget);
      expect(_pillIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(_pillIcon(Icons.menu_book), findsNothing);
    },
  );

  testWidgets(
    'ospite: annullare la scelta della scuola riporta la pillola su HOME',
    (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('LEZIONI'));
      await tester.pumpAndSettle();
      expect(find.text('Lezioni per scuola'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Lezioni per scuola'), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);

      final pill = find.byType(PillNavBar);
      expect(
        find.descendant(of: pill, matching: find.byIcon(Icons.home)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: pill, matching: find.byIcon(Icons.home_outlined)),
        findsNothing,
      );
    },
  );
}
