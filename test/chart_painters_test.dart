import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/theme/chart_palette.dart';
import 'package:math_app/widgets/chart/chart_painters.dart';

/// Conta i pixel non trasparenti di un grafico: distingue «ha disegnato
/// qualcosa» da «è tornato indietro senza toccare il canvas».
Future<int> _pixeliDipinti(
  CustomPainter painter, {
  Size size = const Size(320, 200),
}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder, const Rect.fromLTWH(0, 0, 320, 200)), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(320, 200);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final data = bytes!.buffer.asUint8List();
  var count = 0;
  for (var i = 3; i < data.length; i += 4) {
    if (data[i] > 0) count++;
  }
  image.dispose();
  picture.dispose();
  return count;
}

ChartStyle _style() => ChartStyle(
  palette: const ChartPalette(
    grid: Color(0x22000000),
    axis: Color(0xFF888888),
    label: Color(0xFF666666),
  ),
  series: const Color(0xFF4F46E5),
);

ChartBoxPayload _function() => ChartBoxPayload.fromJson({
  'kind': 'function',
  'xMin': -4,
  'xMax': 8,
  'yMin': -10,
  'yMax': 10,
  'series': [
    {'label': 'y = 2x - 4', 'expression': '2 * x - 4'},
  ],
});

ChartBoxPayload _line() => ChartBoxPayload.fromJson({
  'kind': 'line',
  'series': [
    {
      'label': 'a',
      'points': [
        [0, 1],
        [1, 3],
        [2, 5],
      ],
    },
    {
      'label': 'b',
      'points': [
        [0, 3],
        [1, 2],
        [2, 0],
      ],
    },
  ],
});

ChartBoxPayload _bar() => ChartBoxPayload.fromJson({
  'kind': 'bar',
  'xLabels': ['-2', '-1', '0', '1', '2'],
  'series': [
    {
      'label': '|x|',
      'values': [2, 1, 0, 1, 2],
    },
  ],
});

void main() {
  testWidgets('la curva disegna assi, griglia e tracciato', (tester) async {
    final painted = await tester.runAsync(
      () => _pixeliDipinti(
        LineChartPainter(
          payload: _function(),
          colors: [const Color(0xFF4F46E5)],
          style: _style(),
        ),
      ),
    );
    expect(painted, greaterThan(500));
  });

  testWidgets('le barre disegnano le colonne', (tester) async {
    final painted = await tester.runAsync(
      () => _pixeliDipinti(
        BarChartPainter(
          payload: _bar(),
          colors: [const Color(0xFF4F46E5)],
          style: _style(),
        ),
      ),
    );
    expect(painted, greaterThan(500));
  });

  testWidgets(
    'più valori che etichette: le barre senza etichetta non rompono',
    (tester) async {
      final painted = await tester.runAsync(
        () => _pixeliDipinti(
          BarChartPainter(
            payload: ChartBoxPayload.fromJson({
              'kind': 'bar',
              'xLabels': ['a', 'b'],
              'series': [
                {
                  'values': [1, 2, 3],
                },
              ],
            }),
            colors: [const Color(0xFF4F46E5)],
            style: _style(),
          ),
        ),
      );
      expect(painted, greaterThan(500));
    },
  );

  testWidgets('una funzione senza dati non disegna niente', (tester) async {
    final painted = await tester.runAsync(
      () => _pixeliDipinti(
        LineChartPainter(
          payload: const ChartBoxPayload(series: []),
          colors: [const Color(0xFF4F46E5)],
          style: _style(),
        ),
      ),
    );
    expect(painted, 0);
  });

  testWidgets('un vuoto di 1x1 non disegna niente e non rompe', (tester) async {
    final painted = await tester.runAsync(
      () => _pixeliDipinti(
        LineChartPainter(
          payload: _function(),
          colors: [const Color(0xFF4F46E5)],
          style: _style(),
        ),
        size: const Size(1, 1),
      ),
    );
    expect(painted, 0);
  });

  testWidgets('a progressione zero la curva non è ancora tracciata', (
    tester,
  ) async {
    final painted = await tester.runAsync(
      () => _pixeliDipinti(
        LineChartPainter(
          payload: _function(),
          colors: [const Color(0xFF4F46E5)],
          style: _style(),
          progress: 0,
          fill: false,
        ),
      ),
    );
    // Restano griglia, assi ed etichette: il tracciato, no.
    expect(painted, greaterThan(100));
  });

  testWidgets('un punto assente non lascia una stacco nella curva', (
    tester,
  ) async {
    // sqrt(x - 2) esiste solo da x = 2: sotto il grafico deve restare solo
    // griglia e assi, non una retta verticale di collegamento.
    final payload = ChartBoxPayload.fromJson({
      'kind': 'function',
      'xMin': 0,
      'xMax': 4,
      'series': [
        {'label': 'radice', 'expression': 'sqrt(x - 2)'},
      ],
    });
    final painted = await tester.runAsync(
      () => _pixeliDipinti(
        LineChartPainter(
          payload: payload,
          colors: [const Color(0xFF4F46E5)],
          style: _style(),
          fill: false,
        ),
      ),
    );
    expect(painted, greaterThan(100));
  });

  testWidgets('due serie vengono disegnate entrambe', (tester) async {
    final painted = await tester.runAsync(
      () => _pixeliDipinti(
        LineChartPainter(
          payload: _line(),
          colors: [const Color(0xFF4F46E5), const Color(0xFF0F766E)],
          style: _style(),
          fill: false,
        ),
      ),
    );
    expect(painted, greaterThan(200));
  });

  test('shouldRepaint distingue i dati, il progresso e lo stile', () {
    final style = _style();
    // La stessa istanza di payload: il painter tiene un riferimento, non una
    // copia, e i dati sono confrontati per identità.
    final line = _line();
    final base = LineChartPainter(
      payload: line,
      colors: [const Color(0xFF4F46E5)],
      style: style,
    );
    expect(
      base.shouldRepaint(
        LineChartPainter(
          payload: _line(),
          colors: [const Color(0xFF4F46E5)],
          style: style,
          progress: 0.5,
        ),
      ),
      isTrue,
    );
    expect(
      base.shouldRepaint(
        LineChartPainter(
          payload: _function(),
          colors: [const Color(0xFF4F46E5)],
          style: style,
        ),
      ),
      isTrue,
    );
    expect(
      base.shouldRepaint(
        LineChartPainter(
          payload: line,
          colors: [const Color(0xFF4F46E5)],
          style: _style(),
        ),
      ),
      isFalse,
      reason: 'stili uguali per valore non ridisegnano',
    );
    final bar = BarChartPainter(
      payload: _bar(),
      colors: [const Color(0xFF4F46E5)],
      style: style,
    );
    expect(
      bar.shouldRepaint(
        BarChartPainter(
          payload: _bar(),
          colors: [const Color(0xFF4F766E)],
          style: style,
        ),
      ),
      isTrue,
    );
  });
}
