import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/login_screen.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/theme/app_colors.dart';
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

/// La fascia indaco della barra.
Finder _pillSurface() => find.byKey(const ValueKey('pill-surface'));

/// Il nome della sezione accesa nella barra dentro [pill] (di default l'unica
/// in albero): lo dice la semantica, «selezionato», come allo screen reader.
/// Durante un pop schermate diverse hanno la loro copia della barra.
String? _attiva(WidgetTester tester, [Finder? pill]) {
  final accese = tester
      .widgetList<Semantics>(
        find.descendant(
          of: pill ?? find.byType(PillNavBar),
          matching: find.byType(Semantics),
        ),
      )
      .where(
        (w) => w.properties.button == true && w.properties.selected == true,
      )
      .map((w) => w.properties.label)
      .toList();
  expect(accese, hasLength(1));
  return accese.single;
}

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

      await tester.tap(find.byKey(const ValueKey('pill-lessons')));
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

      await tester.tap(find.byKey(const ValueKey('pill-lessons')));
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

      await tester.tap(find.byKey(const ValueKey('pill-exercises')));
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

      await tester.tap(find.byKey(const ValueKey('pill-lessons')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();
      expect(find.byType(LessonListScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pill-exercises')));
      await tester.pumpAndSettle();

      expect(find.text('Esercizi per scuola'), findsOneWidget);
      expect(find.byType(LessonListScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    },
  );

  testWidgets('icona profilo: dalla home si apre il profilo e si torna', (
    tester,
  ) async {
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('home-profile-avatar')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    // il profilo non è più una sezione della pillola
    expect(find.byType(PillNavBar), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
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

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonListScreen), findsOneWidget);

    rec.events.clear();
    await tester.tap(find.byKey(const ValueKey('pill-exercises')));
    await tester.pumpAndSettle();

    // La sezione nuova prende il posto delle precedenti in un colpo solo:
    // nessun ritorno alla home nel mezzo, altrimenti la home lampeggerebbe.
    expect(rec.events, contains('remove'));
    expect(rec.events.where((e) => e == 'pop'), isEmpty);
    expect(find.byType(CourseScreen), findsOneWidget);
    expect(find.byType(LessonListScreen), findsNothing);
    // la home resta la radice dello stack ma non è dipinta
    expect(find.byType(HomeScreen), findsNothing);

    // il profilo è una sotto-pagina spinta sopra la sezione corrente
    rec.events.clear();
    await tester.tap(find.byKey(const Key('home-profile-avatar')));
    await tester.pumpAndSettle();
    expect(rec.events.where((e) => e == 'pop'), isEmpty);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(CourseScreen), findsNothing);

    await _systemBack(tester);
    expect(find.byType(CourseScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pill-home')));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();
    expect(find.byType(LessonListScreen), findsOneWidget);

    rec.events.clear();
    await tester.tap(find.byKey(const ValueKey('pill-exercises')));
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
    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();
    expect(find.byType(LessonListScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pill-home')));
    // Il pop tiene le lezioni in vista per altri 220ms: i pump campano dentro
    // il ritorno.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));

    // Le lezioni sono ancora in vista, ma la barra deve essere già su Home:
    // tornare indietro su Lezioni per un istante è il difetto. La barra va
    // cercata dentro le lezioni: durante il pop anche quella della home è in
    // albero.
    expect(find.byType(LessonListScreen), findsOneWidget);
    expect(_attiva(tester, _pillIn(find.byType(LessonListScreen))), 'Home');

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_attiva(tester), 'Home');
  });

  testWidgets('ospite: la pillola resta su LEZIONI col foglio scuola aperto', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    expect(find.text('Lezioni per scuola'), findsOneWidget);

    // Il foglio aspetta una scelta: la pillola non deve tornare su HOME
    // mentre l'utente è ancora lì.
    expect(_attiva(tester), 'Lezioni');

    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();

    expect(find.byType(LessonListScreen), findsOneWidget);
    expect(_attiva(tester), 'Lezioni');
  });

  testWidgets('la pillola compare solo sulle schermate principali', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byKey(const ValueKey('pill-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('pill-lessons')), findsOneWidget);
    expect(find.byKey(const ValueKey('pill-exercises')), findsOneWidget);
    expect(find.text('PROFILO'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();

    expect(find.byType(LessonListScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('pill-home')), findsOneWidget);
  });

  testWidgets('la barra parte su Home, al centro', (tester) async {
    await _pumpHome(tester);

    expect(_attiva(tester), 'Home');
    final schermo = tester.getSize(find.byType(HomeScreen)).width;
    expect(
      tester.getCenter(find.byKey(const ValueKey('pill-home'))).dx,
      closeTo(schermo / 2, 1),
    );
  });

  testWidgets('premuto, il cerchio di Home scende sul suo gradino', (
    tester,
  ) async {
    await _pumpHome(tester);
    final cerchio = find.descendant(
      of: find.byKey(const ValueKey('pill-home')),
      matching: find.byType(AnimatedContainer),
    );
    double discesa() =>
        tester.widget<AnimatedContainer>(cerchio).transform!.getTranslation().y;
    double gradino() =>
        (tester.widget<AnimatedContainer>(cerchio).decoration! as BoxDecoration)
            .boxShadow!
            .single
            .offset
            .dy;

    expect(discesa(), 0);
    expect(gradino(), 5);

    final gesture = await tester.startGesture(tester.getCenter(cerchio));
    await tester.pump(const Duration(milliseconds: 120));
    expect(discesa(), 5);
    expect(gradino(), 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(discesa(), 0);
    expect(gradino(), 5);
  });

  testWidgets('la barra è la fascia indaco a tutta larghezza', (tester) async {
    await _pumpHome(tester);

    final fascia = tester.getRect(_pillSurface());
    final schermo = tester.getSize(find.byType(HomeScreen));
    expect(fascia.left, 0);
    expect(fascia.width, schermo.width);
    expect(fascia.height, 72);
    expect(fascia.bottom, schermo.height);
    final decorazione =
        tester.widget<DecoratedBox>(_pillSurface()).decoration as BoxDecoration;
    expect(decorazione.color, AppPalette.light.headerBand);
    expect(
      decorazione.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(28)),
    );

    // Home sporge sopra la fascia; Lezioni ed Esercizi ci stanno dentro.
    final home = tester.getRect(
      find.descendant(
        of: find.byKey(const ValueKey('pill-home')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(home.size, const Size(70, 70));
    expect(home.top, lessThan(fascia.top));
    final lezioni = tester.getRect(find.byKey(const ValueKey('pill-lessons')));
    expect(lezioni.top, closeTo(fascia.top, 1));
    expect(find.text('Lezioni'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('dopo il back dalle lezioni la pillola torna su HOME', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();
    expect(find.byType(LessonListScreen), findsOneWidget);
    // schermata principale: niente tasto indietro, si torna con la pillola
    expect(find.byType(BackButton), findsNothing);

    await _systemBack(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_attiva(tester), 'Home');
  });

  testWidgets('dopo il back dal profilo la pillola torna su HOME', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('profile-button-guest')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await _systemBack(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_attiva(tester), 'Home');
  });

  testWidgets('dopo il back la pillola di Home resta navigabile', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();
    await _systemBack(tester);

    await tester.tap(find.byKey(const ValueKey('pill-exercises')));
    await tester.pumpAndSettle();
    expect(find.text('Esercizi per scuola'), findsOneWidget);
  });

  testWidgets(
    'ospite: annullare la scelta della scuola riporta la pillola su HOME',
    (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.byKey(const ValueKey('pill-lessons')));
      await tester.pumpAndSettle();
      expect(find.text('Lezioni per scuola'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Lezioni per scuola'), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);

      expect(_attiva(tester), 'Home');
    },
  );
}
