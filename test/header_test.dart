import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/customization_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
import 'package:math_app/screens/login_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/widgets/main_header.dart';

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

Future<void> _register() => AuthStore.instance.registerManual(
  name: 'Anna Rossi',
  email: 'anna@example.com',
  password: 'segreta1',
  schoolLevelId: 'middle-school',
);

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
}

/// Larghezza dello schermo in pixel logici, come la vede il layout.
double _schermo(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

/// L'icona di Personalizzazione, nelle `actions` delle tre pagine main.
final Finder _customizzazione = find.byKey(const Key('header-customization'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets('home: l\'icona profilo apre il profilo', (tester) async {
    await _register();
    await _pumpHome(tester);

    expect(find.text('Segnalibri'), findsNothing);

    await tester.tap(find.byKey(const Key('home-profile-avatar')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('lezioni: l\'icona profilo apre il profilo', (tester) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonListScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-profile-avatar')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(LessonListScreen), findsNothing);
  });

  testWidgets('esercizi: l\'icona profilo apre il profilo', (tester) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('pill-exercises')));
    await tester.pumpAndSettle();
    expect(find.byType(CourseScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-profile-avatar')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(CourseScreen), findsNothing);
  });

  testWidgets('home: l\'avatar sta a sinistra del nome, sulla stessa riga', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    final avatar = tester.getRect(find.byKey(const Key('home-profile-avatar')));
    final name = tester.getRect(find.byKey(const Key('header-name')));

    // ordine: avatar, poi il testo dell'header
    expect(avatar.left, lessThan(name.left));
    // e stanno sulla stessa riga: l'altezza della banda li contiene tutti e
    // due senza dividerli in due piani
    expect((avatar.center.dy - name.center.dy).abs(), lessThan(avatar.height));
    expect(name.bottom, lessThanOrEqualTo(avatar.bottom));
    // L'avatar è a filo del margine sinistro: la banda parte dal bordo dello
    // schermo, quindi non c'è aria interna che lo spinga dentro.
    expect(avatar.left, closeTo(kHeaderHorizontalMargin, 1));
  });

  testWidgets('home: l\'icona delle impostazioni sta a destra del nome', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    final name = tester.getRect(find.byKey(const Key('header-name')));
    final icon = tester.getRect(_customizzazione);

    // in alto a destra e sulla stessa riga del testo: le icone stanno nelle
    // `actions`, dentro la banda, e restano dentro l'altezza dell'header
    expect(icon.left, greaterThan(name.right));
    expect((icon.center.dy - name.center.dy).abs(), lessThan(icon.height));
    expect(icon.top, greaterThanOrEqualTo(0));
    expect(icon.bottom, lessThanOrEqualTo(kHeaderToolbarHeight));
  });

  testWidgets('ospite: l\'icona profilo porta all\'accesso', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('profile-button-guest')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('home: nell\'header non c\'è la lente, c\'è la serie', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    expect(find.byKey(const Key('header-search')), findsNothing);
    final serie = tester.getRect(find.byKey(const Key('header-streak')));
    final tune = tester.getRect(_customizzazione);
    final avatar = tester.getRect(find.byKey(const Key('home-profile-avatar')));
    expect(serie.left, greaterThan(avatar.right));
    expect((serie.center.dy - avatar.center.dy).abs(), lessThan(1));
    expect(serie.right, lessThanOrEqualTo(tune.left));
    expect(_schermo(tester) - tune.right, lessThanOrEqualTo(12));
  });

  testWidgets('lezioni: la ricerca sta a destra nella barra dei filtri', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();

    final lens = tester.getRect(find.byKey(const Key('header-search')));
    final tune = tester.getRect(_customizzazione);
    final avatar = tester.getRect(find.byKey(const Key('home-profile-avatar')));
    final tutti = tester.getRect(find.byKey(const Key('filter-all')));

    // La lente non è più nella banda: sta sulla riga dei filtri, in fondo a
    // destra, e nell'header restano le impostazioni.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byKey(const Key('header-search')),
      ),
      findsNothing,
    );
    expect(lens.top, greaterThanOrEqualTo(avatar.bottom));
    expect((lens.center.dy - tutti.center.dy).abs(), lessThan(1));
    expect(lens.left, greaterThan(tutti.right));
    expect(_schermo(tester) - lens.right, lessThanOrEqualTo(16));
    expect(avatar.left, closeTo(kHeaderHorizontalMargin, 1));
    expect(_schermo(tester) - tune.right, lessThanOrEqualTo(12));
  });

  testWidgets('esercizi: la ricerca sta a destra nella barra dei filtri', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('pill-exercises')));
    await tester.pumpAndSettle();

    final lens = tester.getRect(find.byKey(const Key('header-search')));
    final tune = tester.getRect(_customizzazione);
    final avatar = tester.getRect(find.byKey(const Key('home-profile-avatar')));
    final tutti = tester.getRect(find.byKey(const Key('filter-all')));

    // La lente non è più nella banda: sta sulla riga dei filtri, in fondo a
    // destra, e nell'header restano le impostazioni.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byKey(const Key('header-search')),
      ),
      findsNothing,
    );
    expect(lens.top, greaterThanOrEqualTo(avatar.bottom));
    expect((lens.center.dy - tutti.center.dy).abs(), lessThan(1));
    expect(lens.left, greaterThan(tutti.right));
    expect(_schermo(tester) - lens.right, lessThanOrEqualTo(16));
    expect(avatar.left, closeTo(kHeaderHorizontalMargin, 1));
    expect(_schermo(tester) - tune.right, lessThanOrEqualTo(12));
  });

  testWidgets('lezioni ed esercizi: le impostazioni sono in alto a destra', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    for (final sezione in ['pill-lessons', 'pill-exercises']) {
      await tester.tap(find.byKey(ValueKey(sezione)));
      await tester.pumpAndSettle();

      expect(_customizzazione, findsOneWidget, reason: sezione);
      final tune = tester.getRect(_customizzazione);
      final avatar = tester.getRect(
        find.byKey(const Key('home-profile-avatar')),
      );
      expect(tune.left, greaterThan(avatar.right), reason: sezione);
      expect(
        (tune.center.dy - avatar.center.dy).abs(),
        lessThan(1),
        reason: sezione,
      );

      await tester.tap(_customizzazione);
      await tester.pumpAndSettle();

      expect(find.byType(CustomizationScreen), findsOneWidget, reason: sezione);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('ospite: le impostazioni ci sono anche su lezioni ed esercizi', (
    tester,
  ) async {
    // Sono impostazioni dell'app, non del profilo: l'ospite le raggiunge
    // senza averlo. Prima però la pillola chiede la scuola, quindi il foglio
    // sta sopra l'header e il tap sulle icone finirebbe sul barrier.
    await _pumpHome(tester);

    for (final sezione in ['pill-lessons', 'pill-exercises']) {
      await tester.tap(find.byKey(ValueKey(sezione)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();

      expect(_customizzazione, findsOneWidget, reason: sezione);
      await tester.tap(_customizzazione);
      await tester.pumpAndSettle();

      expect(find.byType(CustomizationScreen), findsOneWidget, reason: sezione);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  group('pagine che si espandono dal pulsante', () {
    Future<void> apriPersonalizzazione(WidgetTester tester) async {
      await _pumpHome(tester);
      await tester.tap(_customizzazione);
      await tester.pump();
      await tester.pump();
    }

    testWidgets('la personalizzazione cresce dal pulsante', (tester) async {
      await apriPersonalizzazione(tester);
      expect(find.byType(CustomizationScreen), findsOneWidget);

      // A metà strada il cerchio non copre ancora la pagina.
      await tester.pump(const Duration(milliseconds: 100));
      final clipper = tester.widget<ClipPath>(
        find
            .ancestor(
              of: find.byType(CustomizationScreen),
              matching: find.byType(ClipPath),
            )
            .first,
      );
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      final path = clipper.clipper!.getClip(size);
      final pulsante = tester.getCenter(_customizzazione);
      expect(path.contains(pulsante), isTrue);
      expect(path.contains(Offset.zero), isFalse);

      await tester.pumpAndSettle();
      expect(find.byType(CustomizationScreen), findsOneWidget);
      final fine = tester
          .widget<ClipPath>(
            find
                .ancestor(
                  of: find.byType(CustomizationScreen),
                  matching: find.byType(ClipPath),
                )
                .first,
          )
          .clipper!
          .getClip(size);
      expect(fine.contains(Offset.zero), isTrue);
    });

    testWidgets('col movimento ridotto la pagina compare senza strada', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_customizzazione);
      await tester.pump();
      await tester.pump();
      expect(find.byType(CustomizationScreen), findsOneWidget);
    });

    testWidgets('la ricerca si apre dalla lente e si chiude', (tester) async {
      // La ricerca sta nella barra dei filtri di Lezioni.
      await tester.pumpWidget(
        const MaterialApp(home: LessonListScreen(levelId: 'high-school')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('header-search')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('search-overlay-close')), findsOneWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('search-overlay-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('search-overlay-close')), findsNothing);
    });
  });
}
