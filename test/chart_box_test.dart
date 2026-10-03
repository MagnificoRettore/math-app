import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/models/multifunction_box/box_type.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';

void main() {
  group('ChartKind', () {
    test('le chiavi sono quelle che scrivono i JSON', () {
      expect(ChartKind.fromString('function'), ChartKind.function);
      expect(ChartKind.fromString('line'), ChartKind.line);
      expect(ChartKind.fromString('bar'), ChartKind.bar);
      expect(ChartKind.bar.key, 'bar');
      expect(ChartKind.bar.label, 'Grafico a barre');
    });

    test('una chiave sconosciuta non inventa un tipo nuovo', () {
      expect(ChartKind.fromString('radar'), ChartKind.function);
      expect(ChartKind.fromString(''), ChartKind.function);
    });
  });

  group('ChartBoxPayload', () {
    test('una funzione con dominio e campionamento espliciti', () {
      final p = ChartBoxPayload.fromJson({
        'kind': 'function',
        'xMin': -4,
        'xMax': 8,
        'yMin': -10,
        'yMax': 10,
        'samples': 200,
        'xLabel': 'x',
        'yLabel': 'y',
        'series': [
          {'label': 'y = 2x - 4', 'color': 'accent', 'expression': '2 * x - 4'},
        ],
      });

      expect(p.kind, ChartKind.function);
      expect(p.xMin, -4);
      expect(p.xMax, 8);
      expect(p.yMin, -10);
      expect(p.yMax, 10);
      expect(p.samples, 200);
      expect(p.xLabel, 'x');
      expect(p.series.single.label, 'y = 2x - 4');
      expect(p.series.single.expression, '2 * x - 4');
      expect(p.series.single.points, isEmpty);
      expect(p.isEmpty, isFalse);
    });

    test('una linea di punti espliciti', () {
      final p = ChartBoxPayload.fromJson({
        'kind': 'line',
        'smooth': false,
        'series': [
          {
            'label': 'retta',
            'points': [
              [0, 1],
              [1, 3],
              [2, 5],
            ],
          },
        ],
      });

      expect(p.kind, ChartKind.line);
      expect(p.smooth, isFalse);
      expect(p.series.single.points.length, 3);
      expect(p.series.single.points.first.x, 0);
      expect(p.series.single.points.last.y, 5);
    });

    test('le barre prendono etichette e valori', () {
      final p = ChartBoxPayload.fromJson({
        'kind': 'bar',
        'xLabels': ['a', 'b'],
        'series': [
          {
            'values': [1, 2.5],
          },
        ],
      });

      expect(p.xLabels, ['a', 'b']);
      expect(p.series.single.values, [1, 2.5]);
    });

    test('campionamento con un limite sensato', () {
      expect(ChartBoxPayload.fromJson({'series': []}).samples, greaterThan(1));
      expect(
        ChartBoxPayload.fromJson({'samples': 1, 'series': []}).samples,
        greaterThan(1),
      );
    });

    test('vuoto senza serie', () {
      expect(ChartBoxPayload.fromJson(const {}).isEmpty, isTrue);
      expect(
        ChartBoxPayload.fromJson(const {
          'series': [
            {'label': 'senza dati'},
          ],
        }).isEmpty,
        isTrue,
      );
    });

    test('una voce non numerica resta assente e non sposta le altre', () {
      final p = ChartBoxPayload.fromJson({
        'series': [
          {
            'values': [1, 'due', 3],
          },
        ],
      });
      expect(p.series.single.values, [1, null, 3]);
    });

    test('il colore del JSON è la chiave `color`', () {
      final p = ChartBoxPayload.fromJson({
        'series': [
          {'label': 'a', 'color': 'accent', 'expression': 'x'},
        ],
      });
      expect(p.series.single.colorKey, 'accent');
    });
  });

  group('MultifunctionBox con chart', () {
    test('il box legge il tipo e conserva il titolo', () {
      final box = MultifunctionBox.fromJson({
        'id': 'eq1-chart-function',
        'box_type': 'chart',
        'title': 'La retta y = 2x - 4',
        'payload': {
          'kind': 'function',
          'series': [
            {'label': 'y = 2x - 4', 'expression': '2 * x - 4'},
          ],
        },
      });

      expect(box.boxType, BoxType.chart);
      expect(box.title, 'La retta y = 2x - 4');
      expect(box.payload, isA<ChartBoxPayload>());
      expect((box.payload as ChartBoxPayload).kind, ChartKind.function);
    });

    test('un chart senza payload non rompe', () {
      final box = MultifunctionBox.fromJson({'box_type': 'chart'});
      expect(box.payload, isA<ChartBoxPayload>());
      expect((box.payload as ChartBoxPayload).isEmpty, isTrue);
    });
  });
}
