// ignore_for_file: invalid_use_of_visible_for_testing_member
// Genera le immagini della guida (`assets/guide/*.png`) dalle schermate vere.
// Non fa parte della suite: si lancia a mano quando servono immagini nuove.
//
//   flutter test tool/capture_guide_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/data/study_store.dart';
import 'package:math_app/screens/argomento_lessons_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/theme/app_theme.dart';

const _key = Key('capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // I test non caricano i font da soli: senza, ogni lettera è un quadrato.
  setUpAll(() async {
    final manifest = jsonDecode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;
    for (final family in manifest) {
      final loader = FontLoader(family['family'] as String);
      for (final font in family['fonts'] as List<dynamic>) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await ContentRepository.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
    await StudyStore.instance.resetForTest();
    SearchIndex.instance.build(ContentRepository.instance.levels);
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
      schoolLevelId: 'high-school',
    );
  });

  /// [pill] è il tab da toccare nella barra prima dello scatto: Lezioni ed
  /// Esercizi stanno dentro la `HomeScreen`.
  Future<void> shot(
    WidgetTester tester,
    String name,
    Widget screen, {
    String? pill,
  }) async {
    tester.view
      ..physicalSize = const Size(780, 1688)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: screen,
        ),
      ),
    );
    await tester.pump();
    if (pill != null) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(ValueKey(pill)));
    }
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_key),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('assets/guide/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('immagini della guida', (tester) async {
    final argomento = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Equazioni di primo grado',
    );

    await shot(tester, 'home', const HomeScreen());
    await shot(tester, 'argomenti', const HomeScreen(), pill: 'pill-lessons');
    await ProgressStore.instance.completeLesson(
      'high-school',
      argomento.lessons.first.id,
    );
    await shot(
      tester,
      'lezioni',
      ArgomentoLessonsScreen(argomento: argomento, levelId: 'high-school'),
    );
    await shot(
      tester,
      'lezione',
      LessonScreen(lesson: argomento.lessons.first, levelId: 'high-school'),
    );
    await shot(tester, 'esercizi', const HomeScreen(), pill: 'pill-exercises');
  });
}
