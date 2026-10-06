import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/login_screen.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/widgets/home_continue_card.dart';
import 'package:math_app/widgets/pill_nav_bar.dart';

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await LessonRepository.instance.resetForTest();
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
      expect(find.byKey(const Key('year-dropdown')), findsOneWidget);
      expect(find.text('Prima'), findsWidgets);
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
      expect(find.byKey(const Key('year-dropdown')), findsOneWidget);
      expect(find.text('Prima'), findsWidgets);
      expect(find.text('Nessuna lezione in prima'), findsOneWidget);

      // Anno 2: nessuna lezione, placeholder
      await tester.tap(find.byKey(const Key('year-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('year-option-ms-year2')));
      await tester.pumpAndSettle();

      expect(find.text('Nessuna lezione in seconda'), findsOneWidget);

      // Anno 3: nessuna lezione, placeholder
      await tester.tap(find.byKey(const Key('year-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('year-option-ms-year3')));
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
      expect(find.text('Prima'), findsWidgets);
      expect(find.text('Lezioni per scuola'), findsNothing);
    },
  );

  testWidgets(
    'ospite: ESERCIZI dopo LEZIONI chiede ancora la scuola, e le lezioni restano',
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

  testWidgets('loggato: cambiare sezione non tocca le rotte', (tester) async {
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
    rec.events.clear();

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonListScreen), findsOneWidget);
    expect(_attiva(tester), 'Lezioni');

    await tester.tap(find.byKey(const ValueKey('pill-exercises')));
    await tester.pumpAndSettle();
    expect(find.byType(CourseScreen), findsOneWidget);
    expect(_attiva(tester), 'Esercizi');

    // Le pagine scorrono dentro la radice: nessuna rotta spinta o tolta.
    expect(rec.events, isEmpty);

    // il profilo è una sotto-pagina spinta sopra la sezione corrente
    await tester.tap(find.byKey(const Key('home-profile-avatar')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await _systemBack(tester);
    expect(find.byType(ProfileScreen), findsNothing);
    expect(_attiva(tester), 'Esercizi');

    await tester.tap(find.byKey(const ValueKey('pill-home')));
    await tester.pumpAndSettle();
    expect(_attiva(tester), 'Home');
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
    expect(find.text('Prima'), findsWidgets);
    // il foglio di scelta è chiuso e la pagina delle lezioni non c'è più
    expect(find.text('Esercizi per scuola'), findsNothing);
    expect(find.byType(LessonListScreen), findsNothing);
  });

  testWidgets('toccando Home la barra è subito su Home, senza tappe', (
    tester,
  ) async {
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );
    await _pumpHome(tester);
    await tester.tap(find.byKey(const ValueKey('pill-exercises')));
    await tester.pumpAndSettle();
    expect(_attiva(tester), 'Esercizi');

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    // Da Esercizi a Lezioni la pagina passa da Home: la barra non ci si ferma.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(_attiva(tester), 'Lezioni');
    }
    await tester.pumpAndSettle();
    expect(_attiva(tester), 'Lezioni');
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

  group('swipe fra le pagine principali', () {
    Future<void> registra() => AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );

    Future<void> swipe(WidgetTester tester, {required bool verso}) async {
      // `verso` true: verso sinistra, la pagina successiva.
      // In alto, sopra le liste orizzontali (il carosello della Home vincerebbe
      // l'arena e scorrerebbe da sé).
      await tester.flingFrom(
        tester.getTopLeft(find.byKey(const Key('main-pages'))) +
            const Offset(200, 20),
        Offset(verso ? -300 : 300, 0),
        1000,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('da Home: sinistra Esercizi, destra Lezioni', (tester) async {
      await registra();
      await _pumpHome(tester);

      await swipe(tester, verso: true);
      expect(find.byType(CourseScreen), findsOneWidget);
      expect(_attiva(tester), 'Esercizi');
    });

    testWidgets('da Home: verso destra apre Lezioni', (tester) async {
      await registra();
      await _pumpHome(tester);

      await swipe(tester, verso: false);
      expect(find.byType(LessonListScreen), findsOneWidget);
      expect(_attiva(tester), 'Lezioni');
    });

    testWidgets('da Lezioni: verso sinistra torna alla Home', (tester) async {
      await registra();
      await _pumpHome(tester);
      await swipe(tester, verso: false);
      expect(find.byType(LessonListScreen), findsOneWidget);

      await swipe(tester, verso: true);
      expect(_attiva(tester), 'Home');
    });

    testWidgets('da Esercizi: verso destra torna alla Home', (tester) async {
      await registra();
      await _pumpHome(tester);
      await swipe(tester, verso: true);
      expect(find.byType(CourseScreen), findsOneWidget);

      await swipe(tester, verso: false);
      expect(_attiva(tester), 'Home');
    });

    testWidgets('trascinare il carosello degli argomenti scorre e basta', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await registra();
      await _pumpHome(tester);

      final lista = find.byKey(const Key('argomento-carousel-list'));
      await tester.fling(lista, const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(_attiva(tester), 'Home');
      expect(find.byType(CourseScreen), findsNothing);
    });

    testWidgets('ai capi non succede niente', (tester) async {
      await registra();
      await _pumpHome(tester);
      await swipe(tester, verso: false);
      await swipe(tester, verso: false);
      expect(find.byType(LessonListScreen), findsOneWidget);
    });

    testWidgets('l\'anno non si cambia più con lo swipe', (tester) async {
      await registra();
      await _pumpHome(tester);
      await tester.tap(find.byKey(const ValueKey('pill-lessons')));
      await tester.pumpAndSettle();
      // Il solo `PageView` è quello delle pagine principali.
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('header e barra restano fermi mentre le pagine scorrono', (
      tester,
    ) async {
      await registra();
      await _pumpHome(tester);
      final header = tester.getRect(find.byKey(const Key('header-identity')));
      final barra = tester.getRect(_pillSurface());
      final contenuto = tester.getTopLeft(find.byType(HomeContinueCard));

      final dito = await tester.startGesture(
        tester.getTopLeft(find.byKey(const Key('main-pages'))) +
            const Offset(300, 20),
      );
      for (var i = 0; i < 10; i++) {
        await dito.moveBy(const Offset(-12, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Il contenuto si è mosso, header e barra no.
      expect(
        tester.getTopLeft(find.byType(HomeContinueCard)).dx,
        lessThan(contenuto.dx),
      );
      expect(tester.getRect(find.byKey(const Key('header-identity'))), header);
      expect(tester.getRect(_pillSurface()), barra);

      await dito.up();
      await tester.pumpAndSettle();
    });

    testWidgets('l\'evidenziato della barra segue la pagina a metà strada', (
      tester,
    ) async {
      await registra();
      await _pumpHome(tester);
      expect(_attiva(tester), 'Home');

      final dito = await tester.startGesture(
        tester.getTopLeft(find.byKey(const Key('main-pages'))) +
            const Offset(300, 20),
      );
      for (var i = 0; i < 40; i++) {
        await dito.moveBy(const Offset(-12, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      // Oltre metà schermo: la pagina in vista è Esercizi.
      expect(_attiva(tester), 'Esercizi');
      await dito.up();
      await tester.pumpAndSettle();
      expect(_attiva(tester), 'Esercizi');
    });

    testWidgets('ospite: swipe su una pagina senza scuola apre il foglio', (
      tester,
    ) async {
      await _pumpHome(tester);

      await swipe(tester, verso: false);
      expect(find.text('Lezioni per scuola'), findsOneWidget);

      // Annullato, si torna a Home.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(_attiva(tester), 'Home');
    });
  });
}
