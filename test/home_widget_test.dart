import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/math_facts.dart';
import 'package:math_app/models/lesson_resume.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/data/study_store.dart';
import 'package:math_app/screens/argomento_lessons_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/screens/mission_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/screens/welcome_screen.dart';
import 'package:math_app/screens/weak_points_screen.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/app_card.dart';
import 'package:math_app/widgets/argomento_carousel.dart';
import 'package:math_app/widgets/section_header.dart';
import 'package:math_app/widgets/streak_card.dart';

/// Rapporto di contrasto WCAG fra due colori opachi.
double _contrasto(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final chiaro = la > lb ? la : lb;
  final scuro = la > lb ? lb : la;
  return (chiaro + 0.05) / (scuro + 0.05);
}

Future<void> _resetStores() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await LessonRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  await StudyStore.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

Future<void> _registra({String levelId = 'high-school'}) =>
    AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: levelId,
    );

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
  );
  await tester.pumpAndSettle();
}

/// Le scorciatoie dentro la card missione.
///
/// La ricerca senza ambito non basta: la pillola in basso ha le icone delle
/// sezioni e il tap finirebbe su quella.
Finder _scorciatoia(IconData icon) => find.descendant(
  of: find.ancestor(
    of: find.text('La nostra missione'),
    matching: find.byType(AppCard),
  ),
  matching: find.byIcon(icon),
);

Future<void> _scrollaA(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(
    target,
    find.byType(ListView).first,
    const Offset(0, -120),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_resetStores);

  group('tema', () {
    test('il primary è l\'indaco del design, non quello del seme', () {
      // `ColorScheme.fromSeed` prende dal seme la tonalità 40 e l'indaco ne
      // esce diverso: il primary va dichiarato, il resto della scala no.
      expect(AppTheme.light.colorScheme.primary, const Color(0xFF2B1A6B));
    });

    test('il secondario è il giallo del design, con l\'inchiostro sopra', () {
      expect(AppTheme.light.colorScheme.secondary, const Color(0xFFF6B818));
      expect(
        _contrasto(
          AppTheme.light.colorScheme.onSecondary,
          AppTheme.light.colorScheme.secondary,
        ),
        greaterThan(4.5),
      );
    });

    test('il terziario è il rosa scuro di «da ripassare»', () {
      expect(AppTheme.light.colorScheme.tertiary, const Color(0xFF8B1B34));
    });

    test('lo sfondo della pagina è il crema, le card sono bianche', () {
      expect(AppTheme.light.scaffoldBackgroundColor, const Color(0xFFFFF4D6));
      expect(AppPalette.light.surface, Colors.white);
    });

    test('i colori usati come testo passano 4.5:1 sul bianco e sul crema', () {
      final p = AppPalette.light;
      for (final colore in [
        p.textPrimary,
        p.textSecondary,
        p.accent,
        p.easy,
        p.medium,
        p.hard,
        p.indigo,
        p.danger,
      ]) {
        expect(_contrasto(colore, p.surface), greaterThan(4.5));
        expect(_contrasto(colore, p.background), greaterThan(4.5));
      }
    });

    test('il testo del bottone pieno contrasta col primary', () {
      // Il bottone «Riprendi» è pieno di primary: se il testo non passa 4.5:1
      // il bottone è illeggibile proprio dove l'azione è importante.
      expect(
        _contrasto(
          AppTheme.light.colorScheme.onPrimary,
          AppTheme.light.colorScheme.primary,
        ),
        greaterThan(4.5),
      );
    });
  });

  group('testate', () {
    testWidgets('il titolo degli argomenti è a filo della prima card', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);
      final testata = find.text('Argomenti');
      await _scrollaA(tester, testata);

      // I 20 px orizzontali della testata, sommati a quelli della pagina,
      // mettevano il titolo a 40 mentre le card erano a 20: disallineati e con
      // 20 px in meno per il testo.
      expect(find.byType(SectionHeader), findsOneWidget);
      final card = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('carousel-'),
      );
      expect(tester.getTopLeft(testata).dx, tester.getTopLeft(card.first).dx);
    });
  });

  group('superfici', () {
    testWidgets('la card ha il raggio del design e un\'ombra fine', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('La nostra missione'));

      final box = tester.widget<Container>(
        find
            .descendant(
              of: find
                  .ancestor(
                    of: find.text('La nostra missione'),
                    matching: find.byType(AppCard),
                  )
                  .first,
              matching: find.byType(Container),
            )
            .first,
      );
      final radius =
          (box.decoration! as BoxDecoration).borderRadius! as BorderRadius;

      expect(radius.topLeft.x, kCardRadius);
      expect(kCardRadius, 20);
      // Un'ombra fine, sfumata e bassa: non un gradino pieno, che è dei
      // bottoni.
      final ombra = (box.decoration! as BoxDecoration).boxShadow!.single;
      expect(ombra.color, AppPalette.light.shadow);
      expect(ombra.blurRadius, inInclusiveRange(1, 12));
      expect(ombra.offset.dy, inInclusiveRange(1, 4));
    });

    testWidgets('su uno schermo stretto la Home non sfora', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _registra();
      await _pumpHome(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('ordine delle sezioni', () {
    void schermoAlto(WidgetTester tester) {
      // Uno schermo alto abbastanza da avere tutta la Home costruita.
      tester.view.physicalSize = const Size(400, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('serie, Jump Back In, argomenti, missione, curiosità', (
      tester,
    ) async {
      schermoAlto(tester);
      await _registra();
      await _pumpHome(tester);

      double y(Finder f) => tester.getTopLeft(f).dy;
      final ordine = [
        y(find.byType(StreakCard)),
        y(find.text('Jump Back In')),
        y(find.text('Argomenti')),
        y(find.text('La nostra missione')),
        y(find.byKey(const Key('math-fact-card'))),
      ];
      expect(ordine, [...ordine]..sort());
      // Le sezioni tolte non tornano.
      expect(find.textContaining('Per te'), findsNothing);
      expect(find.text('I tuoi punti deboli'), findsNothing);
    });
  });

  group('Jump Back In', () {
    void schermoAlto(WidgetTester tester) {
      tester.view.physicalSize = const Size(400, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('l\'ospite trova il perché', (tester) async {
      schermoAlto(tester);
      await _pumpHome(tester);

      expect(find.text('Jump Back In'), findsOneWidget);
      expect(find.byKey(const Key('jump-back-in-guest')), findsOneWidget);
      expect(find.text('Accedi per riprendere'), findsOneWidget);
    });

    testWidgets('con un profilo ma senza lezioni aperte lo dice', (
      tester,
    ) async {
      schermoAlto(tester);
      await _registra();
      await _pumpHome(tester);

      expect(find.byKey(const Key('jump-back-in-empty')), findsOneWidget);
      expect(find.text('Niente da riprendere'), findsOneWidget);
    });

    testWidgets('con una lezione a metà propone di riprenderla', (
      tester,
    ) async {
      schermoAlto(tester);
      await _registra();
      await ProgressStore.instance.saveLessonResume(
        const LessonResume(
          levelId: 'high-school',
          lessonId: 'eq1-intro',
          step: 0,
        ),
      );
      await _pumpHome(tester);

      expect(find.byKey(const Key('jump-back-in-card')), findsOneWidget);
      expect(find.textContaining('Card 1 di'), findsOneWidget);

      await tester.tap(find.byKey(const Key('jump-back-in-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LessonScreen), findsOneWidget);
    });
  });

  group('Lo sapevi?', () {
    testWidgets('il tocco passa alla curiosità successiva', (tester) async {
      tester.view.physicalSize = const Size(400, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await _pumpHome(tester);

      String testo() =>
          mathFacts.firstWhere((f) => find.text(f).evaluate().isNotEmpty);
      final prima = testo();
      await tester.tap(find.byKey(const Key('math-fact-card')));
      await tester.pumpAndSettle();
      expect(testo(), isNot(prima));
      expect(find.text('Lo sapevi?'), findsOneWidget);
    });
  });

  group('entrata in sequenza', () {
    /// L'opacità della dissolvenza d'entrata della sezione [sezione]: la
    /// `FadeTransition` più vicina sopra di lei.
    double opacita(WidgetTester tester, Finder sezione) => tester
        .widget<FadeTransition>(
          find
              .ancestor(of: sezione, matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;

    Future<void> pumpPrimoFrame(WidgetTester tester, {bool reduced = false}) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            // Il `MediaQuery` vero con la sola riduzione del movimento: uno
            // nuovo avrebbe larghezza zero.
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reduced),
                child: const HomeScreen(),
              ),
            ),
          ),
        );

    testWidgets('le sezioni entrano una dopo l\'altra', (tester) async {
      await _registra();
      await pumpPrimoFrame(tester);
      // `Animate` parte al frame dopo che l'orologio è avanzato: due frame
      // per avviarla, poi l'entrata corre.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 150));

      // La prima sezione è più avanti della seconda, che parte 60 ms dopo.
      final prima = opacita(tester, find.byType(StreakCard));
      final seconda = opacita(tester, find.byType(ArgomentoCarousel));
      expect(prima, greaterThan(seconda));
      expect(prima, lessThan(1));

      await tester.pumpAndSettle();
      expect(opacita(tester, find.byType(StreakCard)), 1);
      expect(opacita(tester, find.byType(ArgomentoCarousel)), 1);
    });

    testWidgets('una sezione ricreata dopo l\'entrata non rientra', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);

      // Giù abbastanza perché la lista butti la serie, poi su: la card è
      // ricreata e deve essere già al suo posto.
      final lista = find.byType(ListView).first;
      await tester.drag(lista, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.byType(StreakCard), findsNothing);
      await tester.drag(lista, const Offset(0, 2000));
      await tester.pump();

      expect(opacita(tester, find.byType(StreakCard)), 1);
      // Lo scroll ha ancora i suoi timer brevi: si lasciano finire.
      await tester.pumpAndSettle();
    });

    testWidgets('col movimento ridotto niente entrata', (tester) async {
      await _registra();
      await pumpPrimoFrame(tester, reduced: true);
      await tester.pump();

      expect(
        find.ancestor(
          of: find.byType(StreakCard),
          matching: find.byType(Animate),
        ),
        findsNothing,
      );
    });
  });

  group('carosello degli argomenti', () {
    final lista = find.byKey(const Key('argomento-carousel-list'));
    Finder slide() => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('carousel-'),
    );

    testWidgets('con la scuola: tutti gli argomenti della scuola', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);

      // Tutti gli argomenti della Superiore: la lista li costruisce
      // pigramente, quindi si contano i figli dichiarati, che in una lista
      // `separated` sono le card più i separatori.
      final superiore = LessonRepository.instance.argomenti
          .where((a) => a.levelId == 'high-school')
          .length;
      expect(
        tester.widget<ListView>(lista).childrenDelegate.estimatedChildCount,
        superiore * 2 - 1,
      );
      expect(find.text('Equazioni di primo grado'), findsOneWidget);
    });

    testWidgets('le card sono un poco più alte che larghe, tutte uguali, e se '
        'ne vedono circa due', (tester) async {
      await _registra();
      await _pumpHome(tester);

      final schermo = tester.getSize(find.byType(HomeScreen)).width;
      final card = tester.getSize(slide().first);
      expect(card.height / card.width, closeTo(1.15, 0.01));
      for (final e in slide().evaluate()) {
        expect(tester.getSize(find.byWidget(e.widget)), card);
      }
      // Due card intere e un pezzo della terza.
      expect(schermo / card.width, inInclusiveRange(2, 3));
      // La striscia scavalca i 20 di margine della pagina: va da bordo a bordo,
      // e la prima card resta a filo del testo.
      final striscia = tester.getRect(lista);
      expect(striscia.left, 0);
      expect(striscia.width, schermo);
      expect(tester.getTopLeft(slide().first).dx, 20);
    });

    testWidgets('da ospite: gli argomenti di un anno a caso', (tester) async {
      await _pumpHome(tester);

      // Tutti gli argomenti di un solo anno, quello estratto.
      final mostrati = [
        for (final e in slide().evaluate())
          (e.widget.key! as ValueKey<String>).value.substring(
            'carousel-'.length,
          ),
      ];
      final anni = {
        for (final a in LessonRepository.instance.argomenti)
          if (mostrati.contains(a.topicId)) a.yearId,
      };
      expect(anni, hasLength(1));
      expect(
        mostrati,
        hasLength(
          LessonRepository.instance.argomenti
              .where(
                (a) => a.yearId == anni.single && a.levelId == 'high-school',
              )
              .length,
        ),
      );
    });

    testWidgets('una scuola senza argomenti non mostra il carosello', (
      tester,
    ) async {
      await _registra(levelId: 'middle-school');
      await _pumpHome(tester);

      expect(lista, findsNothing);
    });

    testWidgets('un argomento completato ha la spunta nell\'angolo', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);
      final segno = find.byKey(const Key('completed-badge'));
      expect(segno, findsNothing);

      // Equazioni di primo grado ha una lezione sola.
      await ProgressStore.instance.completeLesson('high-school', 'eq1-intro');
      await tester.pump();

      final card = tester.getRect(
        find.byKey(const ValueKey('carousel-year1-equations')),
      );
      expect(segno, findsOneWidget);
      expect(tester.getRect(segno).topRight.dy - card.top, 10);
      expect(card.right - tester.getRect(segno).right, 10);
    });

    testWidgets('il tap su una slide apre le lezioni dell\'argomento', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);

      await _scrollaA(tester, find.text('Equazioni di primo grado'));
      await tester.tap(find.text('Equazioni di primo grado'));
      await tester.pumpAndSettle();

      expect(find.byType(ArgomentoLessonsScreen), findsOneWidget);
    });
  });

  group('serie di giorni', () {
    testWidgets('la card è il traguardo arancio del design', (tester) async {
      await _registra();
      await _pumpHome(tester);
      await _scrollaA(tester, find.byType(StreakCard));

      final card = tester.widget<Container>(
        find.byKey(const Key('streak-card')),
      );
      final box = card.decoration! as BoxDecoration;
      expect(box.color, AppPalette.light.orange);
      // La stessa ombra fine delle altre card.
      expect(box.boxShadow, cardShadow(AppPalette.light));
      expect(find.text('TRAGUARDO'), findsOneWidget);
      expect(find.textContaining('Serie di'), findsOneWidget);
    });

    testWidgets('la card è bassa: serie, record e settimana, niente barre', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);

      final card = find.byKey(const Key('streak-card'));
      expect(find.textContaining('Record:'), findsOneWidget);
      expect(
        find.descendant(
          of: card,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
      // Era alta circa 280: ora la metà.
      expect(tester.getSize(card).height, lessThan(150));
    });
  });

  group('missione', () {
    testWidgets('da collegato ci sono le quattro scorciatoie', (tester) async {
      await _registra();
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('Profilo'));

      expect(find.text('Lezioni'), findsWidgets);
      expect(find.text('Esercizi'), findsWidgets);
      expect(find.text('Punti deboli'), findsWidgets);
      expect(find.text('Profilo'), findsWidgets);
    });

    testWidgets('da ospite ci sono le stesse quattro scorciatoie', (
      tester,
    ) async {
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('La nostra missione'));

      // La Home è una pagina sola: le scorciatoie non dipendono dall'accesso.
      expect(find.text('La nostra missione'), findsOneWidget);
      expect(_scorciatoia(Icons.school_outlined), findsOneWidget);
      expect(_scorciatoia(Icons.calculate_outlined), findsOneWidget);
      expect(_scorciatoia(Icons.healing_outlined), findsOneWidget);
      expect(find.text('Profilo'), findsOneWidget);
    });

    testWidgets('da ospite lezioni ed esercizi chiedono la scuola', (
      tester,
    ) async {
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('La nostra missione'));

      await tester.tap(_scorciatoia(Icons.school_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Lezioni per scuola'), findsOneWidget);

      // Il foglio è un bottom sheet: si chiude toccando la barriera, non c'è
      // una freccia indietro.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await _scrollaA(tester, find.text('La nostra missione'));

      await tester.tap(_scorciatoia(Icons.calculate_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Esercizi per scuola'), findsOneWidget);
    });

    testWidgets('da ospite la scorciatoia del profilo apre l\'accesso', (
      tester,
    ) async {
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('La nostra missione'));

      await tester.tap(find.text('Profilo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Accedi'), findsOneWidget);
    });

    testWidgets('la scorciatoia del profilo apre il profilo', (tester) async {
      await _registra();
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('La nostra missione'));

      await tester.tap(find.text('Profilo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('sulla pagina missione le scorciatoie non ci sono', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('La nostra missione'));

      await tester.tap(find.text('La nostra missione'));
      await tester.pumpAndSettle();

      expect(find.byType(MissionScreen), findsOneWidget);
      expect(find.text('Profilo'), findsNothing);
    });
  });

  group('punti deboli', () {
    testWidgets('da ospite non gli dice che ha assimilato tutto', (
      tester,
    ) async {
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('La nostra missione'));

      await tester.tap(_scorciatoia(Icons.healing_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(WeakPointsScreen), findsOneWidget);
      expect(find.text('Ancora niente da ripassare'), findsOneWidget);
      expect(find.text('Tutto assimilato!'), findsNothing);

      await tester.tap(find.byKey(const Key('weak-points-guest-cta')));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}
