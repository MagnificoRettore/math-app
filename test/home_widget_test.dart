import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/recommendation_engine.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/data/study_store.dart';
import 'package:math_app/models/lesson_resume.dart';
import 'package:math_app/models/progress.dart';
import 'package:math_app/screens/argomento_lessons_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/screens/mission_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/screens/welcome_screen.dart';
import 'package:math_app/screens/weak_points_screen.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_text.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/app_card.dart';
import 'package:math_app/widgets/argomento_carousel.dart';
import 'package:math_app/widgets/recommendation_row.dart';
import 'package:math_app/widgets/section_header.dart';
import 'package:math_app/widgets/streak_card.dart';
import 'package:math_app/widgets/weak_topic_row.dart';

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

Future<void> _pausa(String lessonId, {int step = 0}) =>
    ProgressStore.instance.saveLessonResume(
      LessonResume(levelId: 'high-school', lessonId: lessonId, step: step),
    );

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
  );
  await tester.pumpAndSettle();
}

final _cardRiprendi = find.byKey(const Key('jump-back-in-card'));
final _ctaRiprendi = find.byKey(const Key('jump-back-in-button'));

TextStyle _stile(WidgetTester tester, Finder testo) =>
    tester.widget<Text>(testo).style!;

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

/// Il bottone play dentro la riga: è la stessa misura in ogni riga, quindi
/// confrontarlo dice se le due Home hanno la stessa forma.
Size _play(WidgetTester tester, Finder riga) => tester.getSize(
  find.descendant(of: riga, matching: find.byIcon(Icons.play_arrow_rounded)),
);

/// La riga della sezione dei consigli che contiene il testo indicato.
Finder _riga(WidgetTester tester, Finder testo) =>
    find.ancestor(of: testo, matching: find.byType(RecommendationRow));

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
    testWidgets('il titolo di sezione è a filo della card sotto', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);
      final testata = find.text('Per te \u00b7 Scuola Superiore');
      await _scrollaA(tester, testata);

      // I 20 px orizzontali della testata, sommati a quelli della pagina,
      // mettevano il titolo a 40 mentre le card erano a 20: disallineati e con
      // 20 px in meno per il testo.
      // La `AppCard` è dentro la riga, non sopra.
      final card = find.descendant(
        of: find.byType(RecommendationRow).first,
        matching: find.byType(AppCard),
      );
      expect(tester.getTopLeft(testata).dx, tester.getTopLeft(card).dx);
    });
  });

  group('superfici', () {
    testWidgets('la card ha il raggio e l\'ombra piena del design', (
      tester,
    ) async {
      await _registra();
      await _pausa('eq1-intro');
      await _pumpHome(tester);

      final box = tester.widget<Container>(
        find
            .descendant(of: _cardRiprendi, matching: find.byType(Container))
            .first,
      );
      final radius =
          (box.decoration! as BoxDecoration).borderRadius! as BorderRadius;

      expect(radius.topLeft.x, kCardRadius);
      expect(kCardRadius, 20);
      // Un gradino pieno e dorato, non un'ombra sfumata.
      final ombra = (box.decoration! as BoxDecoration).boxShadow!.single;
      expect(ombra.color, AppPalette.light.cardShadow);
      expect(ombra.blurRadius, 0);
      expect(ombra.offset, const Offset(0, 6));
    });

    testWidgets('la card riprendi è a quaderno: righe e spirale', (
      tester,
    ) async {
      await _registra();
      await _pausa('eq1-intro');
      await _pumpHome(tester);

      expect(
        find.descendant(
          of: _cardRiprendi,
          matching: find.byKey(const Key('jump-back-in-paper')),
        ),
        findsOneWidget,
      );
      // Niente alone: il design non ce l'ha e sulle righe stonerebbe.
      expect(
        find.descendant(
          of: _cardRiprendi,
          matching: find.byType(ImageFiltered),
        ),
        findsNothing,
      );
    });

    testWidgets('su uno schermo stretto la card non sfora', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _registra();
      await _pausa('eq1-intro');
      await _pumpHome(tester);

      // La spirale e il margine del quaderno tolgono 50 px al testo: su
      // 360 px la card deve stare comunque senza sforare.
      expect(tester.takeException(), isNull);
    });
  });

  group('riprendi', () {
    testWidgets('il bottone apre la lezione al passo salvato', (tester) async {
      await _registra();
      await _pausa('eq1-intro', step: 2);
      await _pumpHome(tester);

      await tester.tap(_ctaRiprendi);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LessonScreen), findsOneWidget);
      expect(find.text('3 di 4'), findsOneWidget);
    });

    testWidgets('il badge dice se la lezione era già aperta', (tester) async {
      await _registra();
      await _pausa('mod-equations-intro', step: 1);
      await _pumpHome(tester);
      expect(find.text('In corso'), findsOneWidget);

      // Completata altrove: la sezione ripesca una lezione mai aperta, che non
      // è «in corso» perché l'utente non ci è mai arrivato.
      await ProgressStore.instance.completeLesson(
        'high-school',
        'mod-equations-intro',
      );
      await tester.pumpAndSettle();

      expect(find.text('In corso'), findsNothing);
      expect(find.text('Da iniziare'), findsOneWidget);
    });

    testWidgets('il testo di progresso conta card, non esercizi', (
      tester,
    ) async {
      await _registra();
      await _pausa('mod-equations-intro', step: 3);
      await _pumpHome(tester);

      // 1 card di Definizione + 3 superate, su 10: il conteggio è posizionale
      // e `LessonResumeEngine` lo dice già nei suoi test.
      expect(find.text('4 di 10 card'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.textContaining('esercizi'), findsNothing);
    });
  });

  group('carosello degli argomenti', () {
    final carousel = find.byType(ArgomentoCarousel);
    final lista = find.byKey(const Key('argomento-carousel-list'));
    Finder slide() => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('carousel-'),
    );
    const titoli = ['Equazioni di primo grado', 'Moduli', 'Le rette'];

    testWidgets('con la scuola: tutti gli argomenti della scuola', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);

      // La Superiore ha un argomento per anno, tre in tutto.
      expect(slide(), findsNWidgets(3));
      expect(find.text('Equazioni di primo grado'), findsOneWidget);
    });

    testWidgets('le card sono quadrate e se ne vedono circa due', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);

      final schermo = tester.getSize(find.byType(HomeScreen)).width;
      final card = tester.getSize(slide().first);
      expect(card.width, card.height);
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

      // Ogni anno con argomenti ne ha uno: una card sola.
      expect(slide(), findsOneWidget);
      final mostrati = titoli.where(
        (t) => find
            .descendant(of: carousel, matching: find.text(t))
            .evaluate()
            .isNotEmpty,
      );
      expect(mostrati, hasLength(1));
    });

    testWidgets('una scuola senza argomenti non mostra il carosello', (
      tester,
    ) async {
      await _registra(levelId: 'middle-school');
      await _pumpHome(tester);

      expect(lista, findsNothing);
    });

    testWidgets('il tap su una slide apre le lezioni dell\'argomento', (
      tester,
    ) async {
      await _registra();
      await _pumpHome(tester);

      await tester.tap(find.text('Equazioni di primo grado'));
      await tester.pumpAndSettle();

      expect(find.byType(ArgomentoLessonsScreen), findsOneWidget);
    });
  });

  group('serie di giorni', () {
    testWidgets('la card è il traguardo arancio del design', (tester) async {
      await _registra();
      await _pausa('eq1-intro');
      await _pumpHome(tester);
      await _scrollaA(tester, find.byType(StreakCard));

      final card = tester.widget<Container>(
        find.byKey(const Key('streak-card')),
      );
      final box = card.decoration! as BoxDecoration;
      expect(box.color, AppPalette.light.orange);
      // Il gradino pieno sotto, come i bottoni e le card del design.
      expect(box.boxShadow!.single.color, AppPalette.light.orangeDeep);
      expect(box.boxShadow!.single.blurRadius, 0);
      expect(find.text('TRAGUARDO'), findsOneWidget);
      expect(find.textContaining('Serie di'), findsOneWidget);
    });

    testWidgets('obiettivi chiusi: spunta sulle due barre e banner', (
      tester,
    ) async {
      await _registra();
      await _pausa('eq1-intro');
      for (var i = 0; i < StudyStore.exerciseGoal; i++) {
        await StudyStore.instance.recordExerciseCompleted('ex$i');
      }
      await StudyStore.instance.addMinutes(StudyStore.minutesGoal);
      await _pumpHome(tester);

      await _scrollaA(tester, find.byType(StreakCard));
      expect(find.text('Obiettivi di oggi raggiunti!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });
  });

  group('missione', () {
    testWidgets('da collegato ci sono le quattro scorciatoie', (tester) async {
      await _registra();
      await _pumpHome(tester);

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

  group('ospite e collegato', () {
    testWidgets('la sezione dei consigli ha la stessa anatomia', (
      tester,
    ) async {
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('Per iniziare'));

      expect(find.text('Per iniziare'), findsOneWidget);
      expect(find.text('Da dove cominciare'), findsOneWidget);
      expect(find.text('Crea il tuo profilo'), findsOneWidget);
      expect(find.byKey(const Key('guest-join-play')), findsOneWidget);
      expect(find.byType(SectionHeader), findsOneWidget);
      expect(find.text('Esplora'), findsOneWidget);
      // La card «riprendi» è l'unica sezione che l'ospite non ha.
      expect(_cardRiprendi, findsNothing);

      // Le misure dell'ospite si leggono prima di accedere: dopo, la sezione
      // dell'invito non c'è più.
      final playOspite = _play(
        tester,
        _riga(tester, find.text('Crea il tuo profilo')),
      );
      final titoloOspite = _stile(tester, find.text('Crea il tuo profilo'));

      await _registra();
      await _pumpHome(tester);
      final primo = RecommendationEngine.recommendedExercises('high-school')
          .first
          .exercise
          .title;
      await _scrollaA(tester, find.text(primo));
      final playCollegato = _play(tester, _riga(tester, find.text(primo)));
      final titoloCollegato = _stile(tester, find.text(primo));

      // Stessa riga e stesso play: la geometria è di `RecommendationRow`, non
      // due widget che si somigliano.
      expect(titoloOspite.fontSize, AppText.bodyLarge);
      expect(titoloCollegato.fontSize, titoloOspite.fontSize);
      expect(titoloCollegato.fontWeight, titoloOspite.fontWeight);
      expect(playCollegato, playOspite);
    });

    testWidgets('l\'ospite esplora scegliendo la scuola', (tester) async {
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('Per iniziare'));

      await tester.tap(find.text('Esplora'));
      await tester.pumpAndSettle();

      expect(find.text('Esercizi per scuola'), findsOneWidget);
      // Il footer da ospite promette che la scuola verrà ricordata: qui la
      // scelta è una visita e non viene salvata.
      expect(find.textContaining('non ti verrà più richiesta'), findsOneWidget);
    });

    testWidgets('l\'invito dell\'ospite apre il benvenuto', (tester) async {
      await _pumpHome(tester);
      await _scrollaA(tester, find.text('Per iniziare'));

      await tester.tap(find.byKey(const Key('guest-join-play')));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  group('punti deboli', () {
    Future<void> daRipassare(WidgetTester tester, {required int count}) async {
      await _registra(levelId: 'middle-school');
      const ids = [
        'ms-frac-compare-1',
        'ms-frac-sum-1',
        'ms-perc-1',
        'ms-prop-1',
        'ms-eq-1',
      ];
      for (final id in ids.take(count)) {
        await ProgressStore.instance.setStatus(
          'middle-school',
          id,
          ExerciseStatus.needsReview,
        );
      }
      await _pumpHome(tester);
    }

    testWidgets('le righe stanno in una card sola', (tester) async {
      await daRipassare(tester, count: 5);
      await _scrollaA(tester, find.text('I tuoi punti deboli'));

      // Tre righe e un solo bordo: se ogni riga avesse la sua card, i bordi
      // sarebbero quattro.
      final bordi = tester
          .widgetList<Container>(
            find.descendant(
              of: find.ancestor(
                of: find.byType(WeakTopicRow).first,
                matching: find.byType(AppCard),
              ),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration! as BoxDecoration).border)
          .whereType<Border>()
          .toList();
      expect(bordi, isNotEmpty);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('il bottone dei punti deboli sta dentro la card', (
      tester,
    ) async {
      await daRipassare(tester, count: 5);
      await _scrollaA(tester, find.text('Vedi tutti (4)'));

      final card = find.ancestor(
        of: find.text('Vedi tutti (4)'),
        matching: find.byType(AppCard),
      );
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.byType(WeakTopicRow)),
        findsNWidgets(3),
      );
    });

    testWidgets('le righe sono numerate', (tester) async {
      await daRipassare(tester, count: 5);
      await _scrollaA(tester, find.text('I tuoi punti deboli'));

      final numeri = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(WeakTopicRow),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .where((d) => d == '1' || d == '2' || d == '3')
          .toList();
      expect(numeri, ['1', '2', '3']);
    });

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
