import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/models/multifunction_box/box_type.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';

void main() {
  group('BoxType', () {
    test('fromString mappa tutte le chiavi valide', () {
      expect(BoxType.fromString('image'), BoxType.image);
      expect(BoxType.fromString('chart'), BoxType.chart);
      expect(BoxType.fromString('interactive_chart'), BoxType.interactiveChart);
      expect(BoxType.fromString('math_formula'), BoxType.mathFormula);
    });

    test('fromString ignora maiuscole', () {
      expect(BoxType.fromString('IMAGE'), BoxType.image);
      expect(BoxType.fromString('Interactive_Chart'), BoxType.interactiveChart);
    });

    test('fromString con valore ignoto ricade su image', () {
      expect(BoxType.fromString('video'), BoxType.image);
    });
  });

  group('MultifunctionBox image', () {
    test('round-trip da json a json preserva i campi', () {
      final box = MultifunctionBox.fromJson({
        'id': 'img-1',
        'box_type': 'image',
        'title': 'Grafico illustrato',
        'payload': {'source': 'assets/images/figura.png', 'caption': 'Fig. 1'},
      });
      expect(box.id, 'img-1');
      expect(box.boxType, BoxType.image);
      expect(box.title, 'Grafico illustrato');
      final payload = box.payload as ImageBoxPayload;
      expect(payload.source, 'assets/images/figura.png');
      expect(payload.caption, 'Fig. 1');
      expect(box.toJson()['box_type'], 'image');
    });

    test('payload senza caption produce caption vuota', () {
      final box = MultifunctionBox.fromJson({
        'id': 'img-2',
        'box_type': 'image',
        'payload': {'source': 'assets/images/x.jpg'},
      });
      final payload = box.payload as ImageBoxPayload;
      expect(payload.caption, '');
      expect(box.toJson().containsKey('caption'), isFalse);
    });
  });

  group('MultifunctionBox chart', () {
    test('round-trip preserva kind, label, unit e serie', () {
      final box = MultifunctionBox.fromJson({
        'id': 'chart-1',
        'box_type': 'chart',
        'payload': {
          'kind': 'line',
          'unit': 'cm',
          'xLabels': ['A', 'B'],
          'series': [
            {
              'label': 'Serie 1',
              'values': [1, 2, 3],
              'colorKey': 'teal',
            },
          ],
        },
      });
      final payload = box.payload as ChartBoxPayload;
      expect(payload.kind, ChartKind.line);
      expect(payload.unit, 'cm');
      expect(payload.xLabels, ['A', 'B']);
      expect(payload.series, hasLength(1));
      expect(payload.series.first.label, 'Serie 1');
      expect(payload.series.first.values, [1, 2, 3]);
      expect(payload.series.first.colorKey, 'teal');
      final json = box.toJson()['payload'] as Map<String, dynamic>;
      expect(json['kind'], 'line');
    });

    test('valori stringa numerici vengono convertiti', () {
      final box = MultifunctionBox.fromJson({
        'id': 'chart-2',
        'box_type': 'chart',
        'payload': {
          'kind': 'bar',
          'series': [
            {
              'label': 'S',
              'values': ['2', 3.5],
            },
          ],
        },
      });
      final payload = box.payload as ChartBoxPayload;
      expect(payload.series.first.values, [2, 3.5]);
    });

    test('kind sconosciuto ricade su bar', () {
      final box = MultifunctionBox.fromJson({
        'id': 'chart-3',
        'box_type': 'chart',
        'payload': {'kind': 'treemap'},
      });
      expect((box.payload as ChartBoxPayload).kind, ChartKind.bar);
    });
  });

  group('MultifunctionBox interactive_chart', () {
    test('round-trip preserva range, parametro e serie', () {
      final box = MultifunctionBox.fromJson({
        'id': 'int-1',
        'box_type': 'interactive_chart',
        'payload': {
          'xLabel': 'x',
          'yLabel': 'y',
          'xMin': -3,
          'xMax': 3,
          'xStep': 0.25,
          'yMin': -5,
          'yMax': 5,
          'toggleable': false,
          'parameter': {
            'name': 't',
            'min': 0.5,
            'max': 2,
            'step': 0.1,
            'default': 1,
          },
          'series': [
            {
              'label': 'Parabola',
              'expression': 't * x * x',
              'colorKey': 'accent',
            },
          ],
        },
      });
      final payload = box.payload as InteractiveChartPayload;
      expect(payload.xMin, -3);
      expect(payload.xMax, 3);
      expect(payload.toggleable, isFalse);
      expect(payload.parameter.name, 't');
      expect(payload.parameter.defaultValue, 1);
      expect(payload.parameter.step, 0.1);
      expect(payload.series.single.label, 'Parabola');
      expect(payload.series.single.expression, 't * x * x');
      expect(payload.series.single.colorKey, 'accent');
    });

    test('default espliciti quando il payload è vuoto', () {
      final box = MultifunctionBox.fromJson({
        'id': 'int-2',
        'box_type': 'interactive_chart',
      });
      final payload = box.payload as InteractiveChartPayload;
      expect(payload.xLabel, 'x');
      expect(payload.yLabel, 'y');
      expect(payload.xMin, -3);
      expect(payload.xMax, 3);
      expect(payload.toggleable, isTrue);
      expect(payload.parameter.min, 0);
      expect(payload.parameter.max, 1);
    });

    test('parametro senza default usa il centro del range', () {
      final box = MultifunctionBox.fromJson({
        'id': 'int-3',
        'box_type': 'interactive_chart',
        'payload': {
          'parameter': {'min': 0, 'max': 4, 'step': 1},
        },
      });
      final payload = box.payload as InteractiveChartPayload;
      expect(payload.parameter.defaultValue, 2);
    });
  });

  group('MultifunctionBox math_formula', () {
    test('round-trip preserva tex, mode e dimensione', () {
      final box = MultifunctionBox.fromJson({
        'id': 'formula-1',
        'box_type': 'math_formula',
        'title': 'Formula di risoluzione',
        'payload': {
          'tex': r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
          'mode': 'display',
          'fontSizeMultiplier': 1.4,
        },
      });
      final payload = box.payload as MathFormulaPayload;
      expect(payload.tex, r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}');
      expect(payload.mode, FormulaMode.display);
      expect(payload.fontSizeMultiplier, 1.4);
      final json = box.toJson()['payload'] as Map<String, dynamic>;
      expect(json['mode'], 'display');
    });

    test('mode inline viene serializzato come inline', () {
      final payload = const MathFormulaPayload(
        tex: r'\alpha + \beta',
        mode: FormulaMode.inline,
      );
      expect(payload.toJson()['mode'], 'inline');
    });

    test('modo sconosciuto ricade su display', () {
      final box = MultifunctionBox.fromJson({
        'id': 'formula-2',
        'box_type': 'math_formula',
        'payload': {'tex': 'x + 1', 'mode': 'gigantic'},
      });
      expect((box.payload as MathFormulaPayload).mode, FormulaMode.display);
    });
  });

  group('robustezza', () {
    test('box_type sconosciuto ricade su image senza errore', () {
      final box = MultifunctionBox.fromJson({
        'id': 'box-1',
        'box_type': 'video',
        'payload': {'source': 'assets/images/x.png'},
      });
      expect(box.boxType, BoxType.image);
      expect(box.payload, isA<ImageBoxPayload>());
    });

    test('json completamente vuoto produce default senza errore', () {
      final box = MultifunctionBox.fromJson(const {});
      expect(box.id, '');
      expect(box.boxType, BoxType.image);
      expect((box.payload as ImageBoxPayload).source, '');
    });

    test('campi sconosciuti nel json vengono ignorati', () {
      final box = MultifunctionBox.fromJson({
        'id': 'box-2',
        'box_type': 'chart',
        'is_expandable': true,
      });
      expect(box.boxType, BoxType.chart);
    });
  });
}
