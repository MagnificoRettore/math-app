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
import 'package:math_app/screens/exercise_detail_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/app_card.dart';
import 'package:math_app/widgets/argomento_carousel.dart';
import 'package:math_app/widgets/section_header.dart';
import 'package:math_app/widgets/daily_exercise_card.dart';
import 'package:math_app/widgets/home_continue_card.dart';

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
    testWidgets('il titolo del percorso è a filo della prima card', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);
      final testata = find.text('Il tuo percorso');
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
      await _scrollaA(tester, find.text('Esercizio del giorno'));

      final box = tester.widget<Container>(
        find
            .descendant(
              of: find
                  .ancestor(
                    of: find.text('Esercizio del giorno'),
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

    testWidgets('Continua, esercizio del giorno, percorso, curiosità', (
      tester,
    ) async {
      schermoAlto(tester);
      await _registra();
      await _pumpHome(tester);

      double y(Finder f) => tester.getTopLeft(f).dy;
      final ordine = [
        y(find.byType(HomeContinueCard)),
        y(find.byKey(const Key('daily-exercise-card'))),
        y(find.text('Il tuo percorso')),
        y(find.byKey(const Key('math-fact-card'))),
      ];
      expect(ordine, [...ordine]..sort());
      // Le sezioni tolte non tornano: la serie sta nell'header.
      expect(find.byKey(const Key('streak-card')), findsNothing);
      expect(find.text('La nostra missione'), findsNothing);
      expect(find.text('Jump Back In'), findsNothing);
      expect(find.textContaining('Per te'), findsNothing);
    });
  });

  group('Continua', () {
    void schermoAlto(WidgetTester tester) {
      tester.view.physicalSize = const Size(400, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('l\'ospite trova il perché', (tester) async {
      schermoAlto(tester);
      await _pumpHome(tester);

      expect(find.byKey(const Key('continue-guest')), findsOneWidget);
      expect(find.text('Accedi per continuare'), findsOneWidget);
    });

    testWidgets('con un profilo e niente a metà propone la prima lezione', (
      tester,
    ) async {
      schermoAlto(tester);
      await _registra();
      await _pumpHome(tester);

      expect(find.byKey(const Key('continue-next')), findsOneWidget);
      expect(find.text('Inizia'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      await tester.tap(find.byKey(const Key('continue-next')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LessonScreen), findsOneWidget);
    });

    testWidgets('con una lezione a metà la riprende, con la percentuale', (
      tester,
    ) async {
      schermoAlto(tester);
      await _registra();
      await ProgressStore.instance.saveLessonResume(
        const LessonResume(
          levelId: 'high-school',
          lessonId: 'eq1-intro',
          step: 1,
        ),
      );
      await _pumpHome(tester);

      expect(find.byKey(const Key('continue-card')), findsOneWidget);
      expect(find.text('Continua'), findsOneWidget);
      // Un passo su N: la percentuale non è zero.
      final percent = tester.widget<Text>(
        find.byKey(const Key('continue-percent')),
      );
      expect(percent.data, isNot('0%'));

      await tester.tap(find.byKey(const Key('continue-card')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LessonScreen), findsOneWidget);
    });
  });

  group('Esercizio del giorno', () {
    void schermoAlto(WidgetTester tester) {
      tester.view.physicalSize = const Size(400, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    test(
      'lo stesso giorno dà lo stesso esercizio, il giorno dopo un altro',
      () {
        final oggi = DateTime(2026, 10, 5);
        final a = DailyExercise.of(oggi)!;
        expect(DailyExercise.of(oggi)!.exercise.id, a.exercise.id);
        expect(
          DailyExercise.of(oggi.add(const Duration(days: 1)))!.exercise.id,
          isNot(a.exercise.id),
        );
      },
    );

    test('con un profilo pesca solo dalla sua scuola', () async {
      await _registra(levelId: 'university');
      for (var giorno = 0; giorno < 5; giorno++) {
        final daily = DailyExercise.of(DateTime(2026, 1, 1 + giorno))!;
        expect(daily.level.id, 'university');
      }
    });

    testWidgets('«Provalo» apre l\'esercizio', (tester) async {
      schermoAlto(tester);
      await _registra();
      await _pumpHome(tester);

      expect(find.text('Esercizio del giorno'), findsOneWidget);
      await tester.tap(find.byKey(const Key('daily-exercise-button')));
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseDetailScreen), findsOneWidget);
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
      final prima = opacita(tester, find.byType(HomeContinueCard));
      final seconda = opacita(tester, find.byType(ArgomentoCarousel));
      expect(prima, greaterThan(seconda));
      expect(prima, lessThan(1));

      await tester.pumpAndSettle();
      expect(opacita(tester, find.byType(HomeContinueCard)), 1);
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
      expect(find.byType(HomeContinueCard), findsNothing);
      await tester.drag(lista, const Offset(0, 2000));
      await tester.pump();

      expect(opacita(tester, find.byType(HomeContinueCard)), 1);
      // Lo scroll ha ancora i suoi timer brevi: si lasciano finire.
      await tester.pumpAndSettle();
    });

    testWidgets('col movimento ridotto niente entrata', (tester) async {
      await _registra();
      await pumpPrimoFrame(tester, reduced: true);
      await tester.pump();

      expect(
        find.ancestor(
          of: find.byType(HomeContinueCard),
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
    testWidgets('sta nell\'header, a sinistra dell\'ingranaggio', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);

      final chip = tester.getRect(find.byKey(const Key('header-streak')));
      final gear = tester.getRect(
        find.byKey(const Key('header-customization')),
      );
      expect(chip.right, lessThanOrEqualTo(gear.left));
      expect((chip.center.dy - gear.center.dy).abs(), lessThan(1));
      expect(find.text('0'), findsWidgets);
      // Non c'è altro testo: né «giorni» né il vecchio traguardo.
      expect(find.text('TRAGUARDO'), findsNothing);
    });

    testWidgets('la fiamma è grigia senza attività e arancio dopo', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);
      Color fiamma() =>
          tester.widget<Icon>(find.byKey(const Key('streak-flame'))).color!;

      expect(fiamma(), isNot(AppPalette.light.orange));

      await StudyStore.instance.recordLessonCompleted();
      await tester.pumpAndSettle();
      expect(fiamma(), AppPalette.light.orange);
      expect(
        find.descendant(
          of: find.byKey(const Key('header-streak')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('il tocco apre il foglio con la settimana e il record', (
      tester,
    ) async {
      await _registra();
      await StudyStore.instance.recordLessonCompleted();
      await _pumpHome(tester);

      await tester.tap(find.byKey(const Key('header-streak')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('streak-sheet')), findsOneWidget);
      expect(find.text('Serie di 1 giorno'), findsOneWidget);
      expect(find.text('Record: 1 giorno'), findsOneWidget);
      // Oggi è fatto: un giorno della settimana è della serie.
      expect(find.byKey(const Key('streak-day-done')), findsOneWidget);
    });
  });
}
