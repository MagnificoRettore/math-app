import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/argomento_lessons_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/widgets/search_overlay.dart';

const _lente = Key('header-search');
const _campo = Key('search-overlay-field');

/// Un testo dentro l'overlay: sotto c'è la Home, e il suo carosello ha le
/// slide con gli stessi titoli degli argomenti.
Finder _nellOverlay(String testo) =>
    find.descendant(of: find.byType(SearchOverlay), matching: find.text(testo));

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await LessonRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

Future<void> _register() => AuthStore.instance.registerManual(
  name: 'Anna Rossi',
  email: 'anna@example.com',
  password: 'segreta1',
  schoolLevelId: 'high-school',
);

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
}

/// Apre l'overlay dalla Home e aspetta che il campo sia pronto.
Future<void> _apriDaHome(WidgetTester tester) async {
  await _pumpHome(tester);
  await tester.tap(find.byKey(_lente));
  await tester.pumpAndSettle();
  expect(find.byType(SearchOverlay), findsOneWidget);
}

/// Scrive nella ricerca e lascia scadere il debounce.
Future<void> _cerca(WidgetTester tester, String testo) async {
  await tester.enterText(find.byKey(_campo), testo);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets(
    'la lente apre la ricerca sopra la pagina, non in una pagina nuova',
    (tester) async {
      await _register();
      await _apriDaHome(tester);

      // il campo prende il fuoco da solo: toccare la lente e poi scrivere è
      // un gesto, non due
      expect(tester.widget<TextField>(find.byKey(_campo)).autofocus, isTrue);
      // e sotto Home resta Home
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('la lente c\'è anche nelle altre due pagine', (tester) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_lente));
    await tester.pumpAndSettle();
    expect(find.byType(SearchOverlay), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-overlay-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pill-exercises')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_lente));
    await tester.pumpAndSettle();
    expect(find.byType(SearchOverlay), findsOneWidget);
  });

  testWidgets('l\'overlay si chiude con la X e con Escape', (tester) async {
    await _register();
    await _apriDaHome(tester);

    await tester.tap(find.byKey(const Key('search-overlay-close')));
    await tester.pumpAndSettle();
    expect(find.byType(SearchOverlay), findsNothing);

    await tester.tap(find.byKey(_lente));
    await tester.pumpAndSettle();

    // Escape chiude come la X: l'overlay copre tutta la pagina, il tocco
    // fuori non esiste
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(SearchOverlay), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('una lettera sola non cerca niente', (tester) async {
    await _register();
    await _apriDaHome(tester);

    await _cerca(tester, 'm');

    expect(find.text('Scrivi almeno due lettere.'), findsOneWidget);
    expect(_nellOverlay('Moduli'), findsNothing);
  });

  testWidgets('«modul» elenca l\'argomento e la lezione', (tester) async {
    await _register();
    await _apriDaHome(tester);

    await _cerca(tester, 'modul');

    expect(find.text('Modulo e Equazioni con Modulo'), findsOneWidget);
    // l'argomento porta il numero di lezioni, la lezione il suo argomento
    expect(
      find.text('Variabile reale e valore assoluto · 2 lezioni'),
      findsOneWidget,
    );
    // «Moduli» compare due volte: come titolo dell'argomento e come contesto
    // della lezione che gli appartiene
    expect(_nellOverlay('Moduli'), findsNWidgets(2));
    // e ogni riga dice che tipo è: senza, «Moduli» e «Modulo e Equazioni con
    // Modulo» sono due titoli e basta, e non si sa quale si apre
    expect(find.text('Argomento'), findsOneWidget);
    expect(find.text('Lezione'), findsOneWidget);
  });

  testWidgets(
    'la ricerca guarda tutti i livelli, quindi il risultato dice quale',
    (tester) async {
      await _register();
      await _apriDaHome(tester);

      await _cerca(tester, 'modul');

      // il nome del livello sta sulla riga: senza, «Moduli» non dice a chi
      // appartiene
      expect(find.textContaining('Scuola'), findsWidgets);
    },
  );

  testWidgets('gli esercizi non sono tra i risultati', (tester) async {
    await _register();
    await _apriDaHome(tester);

    // «quadratiche» è un tag di esercizio e «Frazioni» un topic: nessuno dei
    // due è un argomento, quindi la ricerca non deve trovarli
    await _cerca(tester, 'quadratiche');
    expect(find.text('Nessun risultato trovato.'), findsOneWidget);

    await _cerca(tester, 'frazioni');
    expect(find.text('Nessun risultato trovato.'), findsOneWidget);
  });

  testWidgets('una query senza riscontri lo dice', (tester) async {
    await _register();
    await _apriDaHome(tester);

    await _cerca(tester, 'qwertyui');

    expect(find.text('Nessun risultato trovato.'), findsOneWidget);
  });

  testWidgets('l\'argomento porta alla pagina delle sue lezioni', (
    tester,
  ) async {
    await _register();
    await _apriDaHome(tester);

    await _cerca(tester, 'modul');
    await tester.tap(
      find.text('Variabile reale e valore assoluto · 2 lezioni'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ArgomentoLessonsScreen), findsOneWidget);
    expect(find.byType(SearchOverlay), findsNothing);
  });

  testWidgets('la lezione si apre diretta, senza passare dall\'argomento', (
    tester,
  ) async {
    await _register();
    await _apriDaHome(tester);

    await _cerca(tester, 'modul');
    await tester.tap(find.text('Modulo e Equazioni con Modulo'));
    // `pumpAndSettle` qui non va: dentro `LessonScreen` qualcosa gira per
    // sempre (le barre animate del player), quindi due pump e basta.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.byType(ArgomentoLessonsScreen), findsNothing);
    expect(find.byType(SearchOverlay), findsNothing);
  });
}
