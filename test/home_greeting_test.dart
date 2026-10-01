import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/widgets/main_header.dart';

const _helloKey = Key('home-greeting-hello');
const _nameKey = Key('home-greeting-name');
const _avatarKey = Key('home-profile-avatar');

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

Future<void> _register(WidgetTester tester, String name) async {
  await AuthStore.instance.registerManual(
    name: name,
    email: 'anna@example.com',
    password: 'segreta1',
    schoolLevelId: 'high-school',
  );
  await _pumpHome(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets('ospite: due righe, «Ciao,» e «Ospite», nessun avatar tondo', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byKey(_helloKey), findsOneWidget);
    expect(find.text('Ciao,'), findsOneWidget);
    expect(find.byKey(_nameKey), findsOneWidget);
    expect(find.text('Ospite'), findsOneWidget);
    expect(find.byKey(_avatarKey), findsNothing);
  });

  testWidgets('loggato: riga 1 il saluto, riga 2 il nome', (tester) async {
    await _register(tester, 'Anna Rossi');

    expect(find.text('Ciao,'), findsOneWidget);
    expect(find.text('Anna Rossi'), findsOneWidget);
    // Il cerchio con le iniziali sta accanto al nome, non al posto del nome.
    expect(find.byKey(_avatarKey), findsOneWidget);
    expect(find.text('AR'), findsOneWidget);
  });

  testWidgets('le due righe sono impilate, non affiancate', (tester) async {
    await _register(tester, 'Anna Rossi');

    final hello = tester.getRect(find.byKey(_helloKey));
    final name = tester.getRect(find.byKey(_nameKey));
    expect(name.top, greaterThanOrEqualTo(hello.bottom - 1));
    expect(hello.left, closeTo(name.left, 1));
  });

  testWidgets('nome lunghissimo: si tronca e non rompe la riga', (
    tester,
  ) async {
    // Schermo stretto, altrimenti il nome starebbe tutto e la troncatura
    // non sarebbe mai provata.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _register(tester, 'Alessandro Alessandro Alessandro Alessandro');

    final name = tester.widget<Text>(find.byKey(_nameKey));
    expect(name.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);

    // L'avatar resta a filo del margine sinistro dell'header e il nome resta
    // dentro schermo, senza arrivare alle icone a destra: nessuno dei due
    // spinge l'altro fuori.
    final avatar = tester.getRect(find.byKey(_avatarKey));
    final text = tester.getRect(find.byKey(_nameKey));
    final search = tester.getRect(find.byKey(const Key('header-search')));
    expect(avatar.left, closeTo(kHeaderHorizontalMargin, 1));
    expect(text.right, lessThan(search.left));
    // Il nome non va a capo: se avvolge, l'header cresce invece di troncare.
    expect(text.height, lessThanOrEqualTo(avatar.height));
  });

  testWidgets('il saluto segue il login fatto a schermo', (tester) async {
    await _pumpHome(tester);
    expect(find.text('Ospite'), findsOneWidget);

    await AuthStore.instance.registerManual(
      name: 'Anna Rossi',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );
    await tester.pumpAndSettle();

    expect(find.text('Ospite'), findsNothing);
    expect(find.text('Anna Rossi'), findsOneWidget);
  });
}
