import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/profile_screen.dart';

const _greetingKey = Key('home-greeting');
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets('ospite: compare solo la frase di benvenuto', (tester) async {
    await _pumpHome(tester);

    expect(find.byKey(_greetingKey), findsOneWidget);
    expect(find.byKey(_avatarKey), findsNothing);
  });

  testWidgets('loggato: compare il cerchio con le iniziali del nome', (
    tester,
  ) async {
    await AuthStore.instance.registerManual(
      name: 'Anna Rossi',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );

    await _pumpHome(tester);

    expect(find.byKey(_avatarKey), findsOneWidget);
    expect(find.byKey(_greetingKey), findsOneWidget);
    expect(find.text('AR'), findsOneWidget);
  });

  testWidgets('toccando il cerchio si apre il profilo', (tester) async {
    await AuthStore.instance.registerManual(
      name: 'Anna Rossi',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );

    await _pumpHome(tester);
    await tester.tap(find.byKey(_avatarKey));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('nome molto lungo: il saluto resta su una sola riga', (
    tester,
  ) async {
    await AuthStore.instance.registerManual(
      name: 'Alessandro Alessandro Alessandro Alessandro',
      email: 'alex@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );

    await _pumpHome(tester);

    final greeting = tester.widget<Text>(find.byKey(_greetingKey));
    expect(greeting.maxLines, 1);
  });
}