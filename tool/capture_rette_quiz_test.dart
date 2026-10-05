// Genera le immagini del «Prova tu» delle rette (`assets/images/rette-quiz-N.png`)
// con lo stesso `GraphView` delle lezioni.
//
//   flutter test tool/capture_rette_quiz_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/graph/graph_view.dart';

const _key = Key('capture');

/// Le cinque rette: a ognuna un caso di m e di q (m>0, m<0, m=0; q>0, q=0, q<0).
const _rette = ['2*x + 1', '-x + 2', '3', 'x', '-2*x - 1'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('immagini del prova tu delle rette', (tester) async {
    tester.view
      ..physicalSize = const Size(680, 400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final (i, expr) in _rette.indexed) {
      final box = MultifunctionBox.fromJson({
        'id': 'q${i + 1}',
        'box_type': 'graph',
        'payload': {
          'plane': 'cartesian',
          'aspect': 'equal',
          'x': [-6, 6],
          'y': [-3.5, 3.5],
          'grid': 1,
          'xLabel': 'x',
          'yLabel': 'y',
          'items': [
            {'type': 'function', 'expr': expr, 'color': 'accent'},
          ],
        },
      });
      await tester.pumpWidget(
        RepaintBoundary(
          key: _key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            // I numeri vanno letti a 330 px di larghezza: si disegnano grandi.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.9)),
              child: child!,
            ),
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: SizedBox(
                    width: 560,
                    child: GraphView(payload: box.payload as GraphPayload),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (var f = 0; f < 15; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_key),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('assets/images/rette-quiz-${i + 1}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}
