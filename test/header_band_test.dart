import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/browse_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/theme/app_text.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
import 'package:math_app/screens/login_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/main_header.dart';
import 'package:math_app/widgets/profile_button.dart';
import 'package:math_app/widgets/year_tabs.dart';

const _identitaKey = Key('header-identity');
const _nomeKey = Key('header-name');
const _scuolaKey = Key('header-school');
const _avatarKey = Key('home-profile-avatar');
const _badgeKey = Key('home-profile-edit-badge');
const _ospiteKey = Key('profile-button-guest');

/// L'indaco del design, il colore della banda dell'header. Dentro la banda i
/// colori sono bianchi.
const Color _bluHeader = Color(0xFF2B1A6B);

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  BrowseStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
}

// Il tema vero, non quello di base: la banda e i suoi colori vengono da
// `AppPalette`, che il tema di base non registra.
Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> _register(
  WidgetTester tester, {
  String name = 'Anna Rossi',
  String schoolLevelId = 'high-school',
}) async {
  await AuthStore.instance.registerManual(
    name: name,
    email: 'anna@example.com',
    password: 'segreta1',
    schoolLevelId: schoolLevelId,
  );
  await _pumpHome(tester);
}

/// Contrasto WCAG fra due colori opachi. Il primo può avere alpha: va composto
/// sul secondo, perché `computeLuminance` ignora l'alpha e farebbe passare un
/// bianco all'80% come se fosse bianco pieno.
double _contrastoSu(Color sopra, Color sotto) {
  final composto = Color.lerp(sotto, sopra, sopra.a)!;
  final la = composto.computeLuminance();
  final lb = sotto.computeLuminance();
  return (la + 0.05) / (lb + 0.05);
}

/// Larghezza dello schermo in pixel logici, come la vede il layout.
double _schermo(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets('l\'header è una banda indaco che attraversa tutta la larghezza', (
    tester,
  ) async {
    await _register(tester);

    // Il blu sta sull'`AppBar`, non in una scatola attorno al testo: parte dai
    // due bordi dello schermo, quindi non è una pilla con i bordi curvi dentro
    // una pagina colorata.
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, _bluHeader);
    expect(
      appBar.foregroundColor,
      AppColors.of(tester.element(find.byKey(_identitaKey))).onHeaderBand,
    );

    final banda = tester.getRect(find.byType(AppBar));
    expect(banda.left, 0);
    expect(banda.right, closeTo(_schermo(tester), 1));
    expect(banda.height, closeTo(kHeaderToolbarHeight, 1));
  });

  testWidgets('gli angoli in basso sono smussati e sotto c\'è lo sfondo', (
    tester,
  ) async {
    await _register(tester);

    // Il taglio degli angoli lo fa lo `shape` dell'`AppBar`, quindi è
    // dell'`AppBar` e non della riga del titolo.
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final forma = appBar.shape! as RoundedRectangleBorder;
    final raggi = forma.borderRadius as BorderRadius;
    expect(raggi.bottomLeft.x, kHeaderBottomRadius);
    expect(raggi.bottomRight.x, kHeaderBottomRadius);
    // In alto la banda è appoggiata al bordo dello schermo: niente raggi.
    expect(raggi.topLeft.x, 0);
    expect(raggi.topRight.x, 0);

    // Dietro gli angoli non c'è nessuno strato colorato: si vede lo sfondo
    // della pagina. Dentro la banda i colori ci sono (la piastra dell'avatar),
    // fuori dall'`AppBar` no.
    final fuoriDallaBanda = tester
        .elementList(
          find.descendant(
            of: find.byType(MainHeaderAppBar),
            matching: find.byType(ColoredBox),
          ),
        )
        .where((e) => e.findAncestorWidgetOfExactType<AppBar>() == null);
    expect(fuoriDallaBanda, isEmpty);
  });

  testWidgets('in Lezioni gli anni stanno sotto la banda, non dentro', (
    tester,
  ) async {
    await AuthStore.instance.registerManual(
      name: 'Anna Rossi',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LessonListScreen(levelId: 'high-school'),
      ),
    );
    await tester.pumpAndSettle();

    final tabs = find.byType(YearTabs);
    expect(tabs, findsOneWidget);
    // Fuori dall'`AppBar`, quindi fuori dal blu.
    expect(
      find.ancestor(of: tabs, matching: find.byType(AppBar)),
      findsNothing,
    );
    final banda = tester.getRect(find.byType(AppBar));
    expect(tester.getRect(tabs).top, greaterThanOrEqualTo(banda.bottom));
  });

  testWidgets('le icone stanno sulla banda e sono bianche come il testo', (
    tester,
  ) async {
    await _register(tester);

    for (final icona in const [Icons.search_rounded, Icons.tune_rounded]) {
      final widget = tester.widget<Icon>(find.byIcon(icona).first);
      expect(
        widget.color,
        AppColors.of(tester.element(find.byKey(_identitaKey))).onHeaderBand,
        reason: '$icona',
      );
    }
  });

  testWidgets('loggato: nome in Outfit e titolo della scuola sotto', (
    tester,
  ) async {
    await _register(tester);

    expect(find.text('Anna Rossi'), findsOneWidget);
    expect(find.text('Scuola Superiore'), findsOneWidget);
    expect(find.byKey(_nomeKey), findsOneWidget);
    expect(find.byKey(_scuolaKey), findsOneWidget);

    final stile = tester.widget<Text>(find.byKey(_nomeKey)).style!;
    expect(stile.fontFamily, AppText.headingFont);
    expect(stile.fontWeight, FontWeight.w600);
    expect(
      stile.color,
      AppColors.of(tester.element(find.byKey(_identitaKey))).onHeaderBand,
    );

    // Le due righe sono impilate e alliniate a sinistra, non affiancate.
    final nome = tester.getRect(find.byKey(_nomeKey));
    final scuola = tester.getRect(find.byKey(_scuolaKey));
    expect(scuola.top, greaterThanOrEqualTo(nome.bottom - 1));
    expect(scuola.left, closeTo(nome.left, 1));
  });

  testWidgets(
    'contrasto: bianco e bianco all\'80% sull\'indaco passano 4.5:1',
    (tester) async {
      // Il secondario del tema sull'indaco non legge: dentro l'header la riga
      // sotto è bianco all'80%, non il colore secondario della pagina.
      await _register(tester);

      final scuola = tester.widget<Text>(find.byKey(_scuolaKey)).style!;
      expect(scuola.color!.a, lessThan(1.0));
      expect(
        _contrastoSu(scuola.color!, _bluHeader),
        greaterThan(4.5),
        reason: 'riga della scuola',
      );
      expect(
        _contrastoSu(Colors.white, _bluHeader),
        greaterThan(4.5),
        reason: 'nome',
      );
    },
  );

  testWidgets('avatar a sinistra del nome, sulla stessa riga', (tester) async {
    await _register(tester);

    final avatar = tester.getRect(find.byKey(_avatarKey));
    final nome = tester.getRect(find.byKey(_nomeKey));

    expect(avatar.left, lessThan(nome.left));
    expect((avatar.center.dy - nome.center.dy).abs(), lessThan(avatar.height));
    expect(nome.bottom, lessThanOrEqualTo(avatar.bottom));
    // L'avatar è a filo del margine sinistro dell'header: non c'è più una
    // pilla con l'aria interna che lo spingeva dentro.
    expect(avatar.left, closeTo(kHeaderHorizontalMargin, 1));
    expect(
      avatar.center.dy,
      closeTo(tester.getRect(find.byType(AppBar)).center.dy, 1),
    );
  });

  testWidgets(
    'badge di modifica: nell\'angolo in basso a destra e apre il profilo',
    (tester) async {
      await _register(tester);
      expect(find.text('Segnalibri'), findsNothing);

      final avatar = tester.getRect(find.byKey(_avatarKey));
      final badge = tester.getRect(find.byKey(_badgeKey));

      // Sovrapposto all'avatar e non accanto: sborda di 2px a destra e in basso.
      expect(badge.right, closeTo(avatar.right + 2, 1));
      expect(badge.bottom, closeTo(avatar.bottom + 2, 1));
      expect(badge.height, closeTo(20, 1));
      expect(
        tester.widget<Container>(find.byKey(_badgeKey)).decoration,
        isA<BoxDecoration>().having((d) => d.shape, 'shape', BoxShape.circle),
      );
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

      await tester.tap(find.byKey(_badgeKey));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    },
  );

  testWidgets('ospite: «Ospite», nessun badge, il tap porta all\'accesso', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('Ospite'), findsOneWidget);
    // Nessuna riga sotto il nome: da ospite senza livello non c'è una scuola
    // da scrivere, e una riga vuota sarebbe un buco nella banda.
    expect(find.byKey(_scuolaKey), findsNothing);
    expect(find.byKey(_badgeKey), findsNothing);
    expect(find.byKey(_avatarKey), findsNothing);
    expect(find.byKey(_ospiteKey), findsOneWidget);

    await tester.tap(find.byKey(_ospiteKey));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('ospite con livello scelto: la scuola compare sotto «Ospite»', (
    tester,
  ) async {
    // Da ospite la visita non esiste, quindi la riga arriva da chi apre la
    // pagina: Lezioni ed Esercizi sanno il livello che stanno mostrando, la
    // Home no e non mostra nulla.
    await _pumpHome(tester);
    expect(find.byKey(_scuolaKey), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pill-lessons')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();

    expect(find.text('Ospite'), findsOneWidget);
    expect(find.byKey(_scuolaKey), findsOneWidget);
    expect(find.text('Scuola Media'), findsOneWidget);
    expect(find.byKey(_badgeKey), findsNothing);
  });

  testWidgets('nome lunghissimo: si tronca e non fa crescere l\'header', (
    tester,
  ) async {
    // Schermo stretto, altrimenti il nome starebbe tutto e la troncatura
    // non sarebbe mai provata.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _register(
      tester,
      name: 'Alessandro Alessandro Alessandro Alessandro',
    );

    final nome = tester.widget<Text>(find.byKey(_nomeKey));
    expect(nome.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);

    // Il nome resta dentro schermo e non arriva alla lente: nessuno dei due
    // spinge l'altro fuori, e la banda non cresce.
    final testo = tester.getRect(find.byKey(_nomeKey));
    final lente = tester.getRect(find.byKey(const Key('header-search')));
    expect(testo.right, lessThan(lente.left));
    expect(testo.height, lessThanOrEqualTo(kProfileAvatarSize));
    expect(
      tester.getRect(find.byType(AppBar)).height,
      closeTo(kHeaderToolbarHeight, 1),
      reason: 'il nome è troncato, l\'header non cresce',
    );
  });
}
