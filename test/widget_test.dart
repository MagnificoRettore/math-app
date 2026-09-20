import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/data/settings_store.dart';
import 'package:math_app/app.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ContentRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
    await SettingsStore.instance.resetForTest();
  });

  test('carica i contenuti dal JSON bundled', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ContentRepository.instance.load();
    SearchIndex.instance.build(ContentRepository.instance.levels);

    expect(ContentRepository.instance.levels.length, 3);
    final highSchool = ContentRepository.instance.levels[1];
    expect(highSchool.courses.length, greaterThanOrEqualTo(2));
  });

  test('indice di ricerca trova esercizi per tags e formule', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ContentRepository.instance.load();
    SearchIndex.instance.build(ContentRepository.instance.levels);

    final perParti = SearchIndex.instance.search('integrazione per parti');
    expect(perParti, isNotEmpty);
    expect(perParti.any((r) => r.type.name == 'exercise'), isTrue);
    expect(
      perParti.any((r) => r.exercise?.title == 'Integrazione per parti'),
      isTrue,
    );

    final quadratic = SearchIndex.instance.search('quadratiche');
    expect(quadratic, isNotEmpty);
  });

  testWidgets('Home screen renderizza il contenuto principale', (
    tester,
  ) async {
    await ContentRepository.instance.load();
    SearchIndex.instance.build(ContentRepository.instance.levels);
    await ProgressStore.instance.load();
    await SettingsStore.instance.load();
    await SettingsStore.instance.completeOnboarding();

    await tester.pumpWidget(const MathApp());
    await tester.pump();

    expect(find.text('Math App'), findsOneWidget);
    expect(find.byType(Lottie), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('La nostra missione'), findsOneWidget);
    expect(find.text('Livelli'), findsNothing);
  });
}
