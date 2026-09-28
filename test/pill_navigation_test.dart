import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/bookmarks_screen.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/widgets/pill_nav_bar.dart';

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
}

/// Back di sistema: le schermate principali non hanno più il tasto
/// indietro, ma il gesture del sistema deve comunque tornare alla home.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Finder _pillIcon(IconData icon) =>
    find.descendant(of: find.byType(PillNavBar), matching: find.byIcon(icon));

/// Ascissa dell'indicatore della pillola: dice su quale segmento è.
/// Le icone non bastano: per HOME il glifo outlined e il filled sono
/// lo stesso simbolo, quindi l'evidenziazione si controlla solo qui.
double _indicatorX(WidgetTester tester) =>
    tester.getCenter(find.byKey(const ValueKey('pill-indicator'))).dx;

/// Ascissa del centro del segmento con la label data: la label sta al
/// centro del suo segmento, quindi è il riferimento per capire dove
/// dovrebbe essere l'indicatore.
double _segmentX(WidgetTester tester, String label) =>
    tester.getCenter(find.text(label)).dx;

/// Come [_segmentX], ma limitata a una pillola precisa: durante un pop
/// schermate diverse hanno la loro copia della barra in albero.
double _segmentXIn(WidgetTester tester, Finder pill, String label) =>
    tester.getCenter(find.descendant(of: pill, matching: find.text(label))).dx;

/// Ascissa dell'indicatore della pillola dentro [pill], che va cercata in
/// una schermata precisa: durante un pop la schermata sotto è ancora in
/// albero e ha la sua copia.
double _indicatorXIn(WidgetTester tester, Finder pill) => tester
    .getCenter(
      find.descendant(
        of: pill,
        matching: find.byKey(const ValueKey('pill-indicator')),
      ),
    )
    .dx;

Finder _pillIn(Finder screen) =>
    find.descendant(of: screen, matching: find.byType(PillNavBar));

/// Registra gli eventi di navigazione: serve a distinguere un ritorno
/// animato alla home (`didPop`) dalla sostituzione atomica dello stack
/// (`didRemove` + `didPush` nello stesso aggiornamento).
class _NavRecorder extends NavigatorObserver {
  final List<String> events = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    events.add('push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // il foglio modale della scelta scuola si chiude con un pop: non
    // interessa, il lampo da cercare è il ritorno alla home
    if (route is PopupRoute) return;
    events.add('pop');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    events.add('remove');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets(
    'ospite: LEZIONI apre pop-up e mostra la barra anni della scuola scelta',
    (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('LEZIONI'));
      await tester.pumpAndSettle();

      expect(find.text('Lezioni per scuola'), findsOneWidget);
      expect(find.text('Scuola Media'), findsWidgets);

      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();

      expect(find.byType(LessonListScreen), findsOneWidget);
      expect(find.text('prima'), findsWidgets);
      expect(find.text('seconda'), findsWidgets);
      expect(find.text('terza'), findsWidgets);
      expect(find.text('Nessuna lezione in prima'), findsOneWidget);
    },
  );

  testWidgets(
    'ospite: la pagina lezioni ha la barra anni con il placeholder vuoto',
    (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('LEZIONI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();

      // Step anno: barra anni in alto (come ESERCIZI), Anno 1 già attivo
      expect(find.byType(LessonListScreen), findsOneWidget);
      expect(find.text('prima'), findsWidgets);
      expect(find.text('seconda'), findsWidgets);
      expect(find.text('terza'), findsWidgets);
      expect(find.text('Nessuna lezione in prima'), findsOneWidget);

      // Anno 2: nessuna lezione, placeholder
      await tester.tap(find.text('seconda'));
      await tester.pumpAndSettle();

      expect(find.text('Nessuna lezione in seconda'), findsOneWidget);

      // Anno 3: nessuna lezione, placeholder
      await tester.tap(find.text('terza'));
      await tester.pumpAndSettle();

      expect(find.text('Nessuna lezione in terza'), findsOneWidget);
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
      expect(find.text('prima'), findsWidgets);
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

  testWidgets('loggato: cambiare sezione non torna animando alla home', (
    tester,
  ) async {
    final rec = _NavRecorder();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );
    await tester.pumpWidget(
      MaterialApp(navigatorObservers: [rec], home: const HomeScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('PROFILO'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    rec.events.clear();
    await tester.tap(find.text('ESERCIZI'));
    await tester.pumpAndSettle();

    // La sezione nuova prende il posto delle precedenti in un colpo solo:
    // nessun ritorno alla home nel mezzo, altrimenti la home lampeggerebbe.
    expect(rec.events, contains('remove'));
    expect(rec.events.where((e) => e == 'pop'), isEmpty);
    expect(find.byType(CourseScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
    // la home resta la radice dello stack ma non è dipinta
    expect(find.byType(HomeScreen), findsNothing);

    rec.events.clear();
    await tester.tap(find.text('PROFILO'));
    await tester.pumpAndSettle();
    expect(rec.events.where((e) => e == 'pop'), isEmpty);
    expect(find.byType(ProfileScreen), findsOneWidget);

    await _systemBack(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('ospite: la scelta della scuola non torna animando alla home', (
    tester,
  ) async {
    final rec = _NavRecorder();
    await tester.pumpWidget(
      MaterialApp(navigatorObservers: [rec], home: const HomeScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();
    expect(find.byType(LessonListScreen), findsOneWidget);

    rec.events.clear();
    await tester.tap(find.text('ESERCIZI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();

    expect(rec.events.where((e) => e == 'pop'), isEmpty);
    expect(find.byType(CourseScreen), findsOneWidget);
    expect(find.text('prima'), findsWidgets);
    // il foglio di scelta è chiuso e la pagina delle lezioni non c'è più
    expect(find.text('Esercizi per scuola'), findsNothing);
    expect(find.byType(LessonListScreen), findsNothing);
  });

  testWidgets('la pillola resta su HOME durante il ritorno animato', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.tap(find.text('PROFILO'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(find.text('HOME'));
    // Lo scorrimento dell'indicatore dura 260ms: a fine snap parte il pop,
    // che tiene il profilo in vista per altri 220ms. I due pump dopo il
    // primo campano dentro il ritorno, quando un eventuale ritorno
    // dell'indicatore su PROFILO si sarebbe già mosso.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));

    // Il profilo è ancora in vista, ma l'indicatore deve essere già su
    // HOME: tornare indietro su PROFILO per un istante è il difetto.
    // La pillola va cercata dentro il profilo: durante il pop anche quella
    // della home è in albero.
    expect(find.byType(ProfileScreen), findsOneWidget);
    final profilePill = _pillIn(find.byType(ProfileScreen));
    expect(
      (_indicatorXIn(tester, profilePill) -
              _segmentXIn(tester, profilePill, 'HOME'))
          .abs(),
      lessThan(1),
    );

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      (_indicatorX(tester) - _segmentX(tester, 'HOME')).abs(),
      lessThan(1),
    );
  });

  testWidgets('trascinando verso HOME la pillola non torna indietro', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.tap(find.text('PROFILO'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    final barRect = tester.getRect(find.byType(PillNavBar));
    // larghezza del segmento: la barra ha 24px di margine per lato
    final seg = (barRect.width - 48) / 4;
    final gesture = await tester.startGesture(
      Offset(barRect.center.dx + barRect.width * 3 / 8, barRect.center.dy),
    );
    await tester.pump();
    // Tre segmenti esatti: si arriva su HOME, ma l'indicatore resta
    // disallineato di qualche pixel, quindi lo scorrimento c'è e la
    // navigazione parte a fine assestamento.
    await gesture.moveBy(Offset(-3 * seg, 0));
    await tester.pump();
    await gesture.up();

    // Il rilascio avvia l'assestamento dell'indicatore (260ms): il primo
    // pump è il frame che lo avvia, il secondo lo porta a fine e avvia il
    // ritorno animato, gli ultimi due campano dentro il ritorno.
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));

    final profilePill = _pillIn(find.byType(ProfileScreen));
    expect(profilePill, findsOneWidget);
    expect(
      (_indicatorXIn(tester, profilePill) -
              _segmentXIn(tester, profilePill, 'HOME'))
          .abs(),
      lessThan(1),
    );

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      (_indicatorX(tester) - _segmentX(tester, 'HOME')).abs(),
      lessThan(1),
    );
  });

  testWidgets('ospite: la pillola resta su LEZIONI col foglio scuola aperto', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();
    expect(find.text('Lezioni per scuola'), findsOneWidget);

    // Il foglio aspetta una scelta: la pillola non deve tornare su HOME
    // mentre l'utente è ancora lì.
    expect(
      (_indicatorX(tester) - _segmentX(tester, 'LEZIONI')).abs(),
      lessThan(1),
    );

    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();

    expect(find.byType(LessonListScreen), findsOneWidget);
    expect(
      (_indicatorX(tester) - _segmentX(tester, 'LEZIONI')).abs(),
      lessThan(1),
    );
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
    // schermata principale: niente tasto indietro, si torna con la pillola
    expect(find.byType(BackButton), findsNothing);

    await _systemBack(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_pillIcon(Symbols.home_rounded), findsOneWidget);
    expect(_pillIcon(Icons.home_outlined), findsNothing);
  });

  testWidgets('dopo il back dal profilo la pillola torna su HOME', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('PROFILO'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await _systemBack(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_pillIcon(Symbols.home_rounded), findsOneWidget);
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
    await _systemBack(tester);

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

      await _systemBack(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(_pillIcon(Symbols.home_rounded), findsOneWidget);
      expect(_pillIcon(Symbols.book_2_rounded), findsOneWidget);
      expect(_pillIcon(Icons.menu_book_outlined), findsNothing);
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

      // Le icone non distinguono la sezione attiva (per HOME il glifo
      // outlined e il filled coincidono), quindi la posizione
      // dell'indicatore è la verifica vera.
      expect(
        (_indicatorX(tester) - _segmentX(tester, 'HOME')).abs(),
        lessThan(1),
      );
    },
  );
}
