import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/browse_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson.dart';
import 'package:math_app/models/lesson_resume.dart';
import 'package:math_app/models/progress.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/school_level_tile.dart';

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  BrowseStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await LessonRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
}

Future<void> _registra({String school = 'high-school'}) =>
    AuthStore.instance.registerManual(
      name: 'Anna Rossi',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: school,
    );

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> _vaiAllezioni(WidgetTester tester) async {
  await tester.tap(find.text('LEZIONI'));
  await tester.pumpAndSettle();
}

Future<void> _vaiAgliEsercizi(WidgetTester tester) async {
  await tester.tap(find.text('ESERCIZI'));
  await tester.pumpAndSettle();
}

Finder _bottoneScuola() => find.byKey(const Key('header-school-browse'));

/// Apre il foglio dal bottone dell'header e sceglie la scuola dal titolo che
/// `SchoolLevelTile` mostra. Il tap è sulla tile, che è ciò che sta sotto il
/// dito, non sul testo.
Future<void> _scegliScuola(WidgetTester tester, String titolo) async {
  await tester.tap(_bottoneScuola());
  await tester.pumpAndSettle();

  await tester.tap(
    find.descendant(
      of: find.byType(SchoolLevelTile),
      matching: find.text(titolo),
    ),
  );
  await tester.pumpAndSettle();
}

/// `LessonScreen` non si assesta: il trofeo e la toolbar animano senza fine,
/// quindi `pumpAndSettle` andrebbe in timeout. Bastano due pump, come in
/// `lesson_test.dart`.
Future<void> _pumpLezione(WidgetTester tester, Widget lezione) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Material(child: lezione),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Le lezioni ci sono solo per il liceo: sono le uniche su cui provare la
/// ripresa.
Lesson _primaLezione({int step = 0}) => LessonRepository.instance.argomenti
    .expand((a) => a.lessons)
    .firstWhere((l) => l.steps.length > step);

/// Una lezione di una card sola: «Completa la lezione» compare sull'ultima
/// card e senza esercizio da risolvere, quindi si completa con un tap.
Lesson _lezioneDaCompletare() => LessonRepository.instance.argomenti
    .expand((a) => a.lessons)
    .firstWhere((l) => l.steps.length == 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets('da ospite il foglio è quello di sempre, senza il bottone', (
    tester,
  ) async {
    await _pumpHome(tester);
    await _vaiAllezioni(tester);

    // L'ospite non ha un bottone nell'header: arriva qui dal foglio della
    // pillola, che ha il footer sulla scuola ricordata.
    expect(_bottoneScuola(), findsNothing);
    expect(find.text('Lezioni per scuola'), findsOneWidget);
    expect(find.textContaining('non ti verrà più richiesta'), findsOneWidget);
  });

  testWidgets('da collegato il bottone c\'è e sta a sinistra della lente', (
    tester,
  ) async {
    await _registra();
    await _pumpHome(tester);
    await _vaiAllezioni(tester);

    expect(_bottoneScuola(), findsOneWidget);

    final scuola = tester.getRect(_bottoneScuola());
    final lente = tester.getRect(find.byKey(const Key('header-search')));
    final avatar = tester.getRect(find.byKey(const Key('home-profile-avatar')));

    expect(scuola.left, greaterThan(avatar.right));
    expect(scuola.right, lessThanOrEqualTo(lente.left));
    expect((scuola.center.dy - lente.center.dy).abs(), lessThan(1));
  });

  testWidgets('il tap apre il foglio delle altre scuole', (tester) async {
    await _registra();
    await _pumpHome(tester);
    await _vaiAllezioni(tester);

    await tester.tap(_bottoneScuola());
    await tester.pumpAndSettle();

    expect(find.text('Altre scuole, lezioni'), findsOneWidget);
    // Il footer da ospite promette «questa scelta non ti verrà più richiesta»:
    // sarebbe falso, il profilo può cambiare scuola quando vuole.
    expect(find.textContaining('non ti verrà più richiesta'), findsNothing);
  });

  testWidgets('gli esercizi aprono il foglio col proprio titolo', (
    tester,
  ) async {
    await _registra();
    await _pumpHome(tester);
    await _vaiAgliEsercizi(tester);

    await tester.tap(_bottoneScuola());
    await tester.pumpAndSettle();

    expect(find.text('Altre scuole, esercizi'), findsOneWidget);
  });

  testWidgets('la scuola in visita è scritta nell\'header', (tester) async {
    await _registra(school: 'high-school');
    await _pumpHome(tester);
    await _vaiAllezioni(tester);
    expect(find.text('Scuola Media'), findsNothing);

    await _scegliScuola(tester, 'Scuola Media');

    expect(find.text('Scuola Media'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('schermo stretto: scuola in visita e icone ci stanno tutte', (
    tester,
  ) async {
    // L'header in visita tiene tre icone più il nome della scuola: è la riga
    // più affollata dell'app, e su un telefono stretto il nome è la parte che
    // deve cedere, non le icone.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _registra(school: 'middle-school');
    await _pumpHome(tester);
    await _vaiAllezioni(tester);

    await _scegliScuola(tester, 'Scuola Superiore');

    expect(tester.takeException(), isNull);
    // Le tre icone ci sono tutte e restano dentro schermo: l'AppBar mette le
    // `actions` in una riga che non tronca, quindi una fourth icona
    // semplicemente uscirebbe dal bordo.
    for (final chiave in const [
      Key('header-school-browse'),
      Key('header-search'),
      Key('header-customization'),
    ]) {
      expect(find.byKey(chiave), findsOneWidget, reason: '$chiave');
      expect(
        tester.getRect(find.byKey(chiave)).right,
        lessThanOrEqualTo(360),
        reason: '$chiave esce da schermo',
      );
    }
    // Il nome della scuola si tronca invece di spingere fuori le icone, e non
    // va a capo perché l'header è alto 80.
    final nome = tester.getRect(find.text('Scuola Superiore'));
    final personalizzazione = tester.getRect(
      find.byKey(const Key('header-customization')),
    );
    expect(nome.width, lessThan(personalizzazione.left));
    expect(nome.height, lessThanOrEqualTo(80));
  });

  testWidgets('scegliere un\'altra scuola cambia tab e contenuti', (
    tester,
  ) async {
    await _registra(school: 'middle-school');
    await _pumpHome(tester);
    await _vaiAllezioni(tester);

    // Scuola Media: tre anni, nessuna lezione.
    expect(find.text('Nessuna lezione in prima'), findsOneWidget);

    await _scegliScuola(tester, 'Scuola Superiore');

    expect(find.text('Nessuna lezione in prima'), findsNothing);
    expect(find.text('Equazioni di primo grado'), findsOneWidget);
  });

  testWidgets('la scuola del profilo non viene scritta come visita', (
    tester,
  ) async {
    await _registra(school: 'middle-school');
    await _pumpHome(tester);
    await _vaiAllezioni(tester);

    await _scegliScuola(tester, 'Scuola Media');

    expect(BrowseStore.instance.levelId, isNull);
    expect(AuthStore.instance.currentUser!.schoolLevelId, 'middle-school');
  });

  testWidgets('tornando alla scuola del profilo la pagina si riallinea', (
    tester,
  ) async {
    await _registra(school: 'middle-school');
    await _pumpHome(tester);
    await _vaiAllezioni(tester);
    await _scegliScuola(tester, 'Scuola Superiore');
    expect(find.text('Equazioni di primo grado'), findsOneWidget);

    await _scegliScuola(tester, 'Scuola Media');

    expect(find.text('Equazioni di primo grado'), findsNothing);
    expect(find.text('Nessuna lezione in prima'), findsOneWidget);
    expect(find.text('Scuola Media'), findsNothing);
  });

  testWidgets('cambiare scuola con un anno aperto non lascia l\'indice', (
    tester,
  ) async {
    await _registra(school: 'high-school');
    await _pumpHome(tester);
    await _vaiAllezioni(tester);

    // «quarta» è il quarto di cinque: sui tre corsi dell'università quell'indice
    // sarebbe fuori range e la pagina resterebbe quella precedente.
    await tester.tap(find.text('quarta'));
    await tester.pumpAndSettle();

    await _scegliScuola(tester, 'Università');

    expect(tester.takeException(), isNull);
    expect(find.text('Analisi I'), findsOneWidget);
  });

  testWidgets('il cambio di sezione conserva la scuola in visita', (
    tester,
  ) async {
    await _registra(school: 'middle-school');
    await _pumpHome(tester);
    await _vaiAllezioni(tester);
    await _scegliScuola(tester, 'Scuola Superiore');

    await _vaiAgliEsercizi(tester);

    expect(find.byType(CourseScreen), findsOneWidget);
    expect(find.text('Tutti gli esercizi'), findsOneWidget);
    expect(find.text('Frazioni'), findsOneWidget);
    expect(find.text('Numeri e operazioni'), findsNothing);
  });

  testWidgets('il progresso non passa da una scuola all\'altra', (
    tester,
  ) async {
    await _registra(school: 'high-school');
    await _pumpHome(tester);
    await _vaiAgliEsercizi(tester);

    await ProgressStore.instance.setStatus(
      'university',
      'lim-medium-1',
      ExerciseStatus.mastered,
    );
    await tester.pumpAndSettle();

    await _scegliScuola(tester, 'Università');

    // Lo stesso id sta in quinta del liceo e in Analisi I: il segno di spunta
    // deve stare solo dove l'esercizio è stato fatto.
    expect(
      ProgressStore.instance.statusOf('university', 'lim-medium-1'),
      ExerciseStatus.mastered,
    );
    expect(
      ProgressStore.instance.statusOf('high-school', 'lim-medium-1'),
      ExerciseStatus.none,
    );
  });

  testWidgets('la lezione di un\'altra scuola non scrive la ripresa', (
    tester,
  ) async {
    await _registra(school: 'middle-school');
    await ProgressStore.instance.saveLessonResume(
      LessonResume(levelId: 'middle-school', lessonId: 'eq1-intro', step: 2),
    );

    // Lezione del liceo aperta mentre la pagina mostra la scuola del profilo:
    // è esattamente la visita.
    final lezione = _primaLezione(step: 1);
    await _pumpLezione(
      tester,
      LessonScreen(lesson: lezione, levelId: 'high-school'),
    );

    expect(ProgressStore.instance.lessonResume!.levelId, 'middle-school');
    expect(ProgressStore.instance.lessonResume!.step, 2);
  });

  testWidgets('la lezione della propria scuola scrive ancora la ripresa', (
    tester,
  ) async {
    await _registra(school: 'high-school');
    final lezione = _primaLezione(step: 1);

    await _pumpLezione(
      tester,
      LessonScreen(lesson: lezione, levelId: 'high-school'),
    );

    expect(ProgressStore.instance.lessonResume!.levelId, 'high-school');
    expect(ProgressStore.instance.lessonResume!.lessonId, lezione.id);
  });

  testWidgets('completare una lezione in visita non cancella la ripresa', (
    tester,
  ) async {
    await _registra(school: 'middle-school');
    await ProgressStore.instance.saveLessonResume(
      LessonResume(levelId: 'middle-school', lessonId: 'eq1-intro', step: 2),
    );
    final lezione = _lezioneDaCompletare();

    await _pumpLezione(
      tester,
      LessonScreen(lesson: lezione, levelId: 'high-school'),
    );
    await tester.tap(find.text('Completa la lezione'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // La lezione è stata fatta, quindi il completamento si registra anche su un
    // altro livello; la ripresa invece resta quella della scuola del profilo.
    expect(
      ProgressStore.instance.isLessonCompleted('high-school', lezione.id),
      isTrue,
    );
    expect(ProgressStore.instance.lessonResume!.lessonId, 'eq1-intro');
  });

  testWidgets('la lezione in visita non fa sparire «Jump Back In»', (
    tester,
  ) async {
    await _registra(school: 'high-school');
    await ProgressStore.instance.saveLessonResume(
      LessonResume(levelId: 'high-school', lessonId: 'eq1-intro', step: 1),
    );
    final lezione = _primaLezione(step: 1);

    await _pumpLezione(
      tester,
      LessonScreen(lesson: lezione, levelId: 'university'),
    );
    BrowseStore.instance.reset();

    await _pumpHome(tester);

    expect(find.byKey(const Key('jump-back-in-card')), findsOneWidget);
    expect(find.text('Jump Back In'), findsOneWidget);
  });
}
