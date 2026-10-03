import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/widgets/chart/chart_scale.dart';

void main() {
  group('niceStep', () {
    test('sceglie il passo più vicino sopra il grezzo', () {
      expect(niceStep(0.9), 1);
      expect(niceStep(1.4), 2);
      expect(niceStep(2.4), 2.5);
      expect(niceStep(3.1), 5);
      expect(niceStep(7), 10);
      expect(niceStep(23), 25);
    });

    test('un grezzo non valido non rompe', () {
      expect(niceStep(0), 1);
      expect(niceStep(double.nan), 1);
    });
  });

  group('niceRange', () {
    test('allarga il dominio su un passo bello', () {
      final r = niceRange(0, 7);
      expect(r.min, 0);
      expect(r.max, greaterThanOrEqualTo(7));
    });

    test('un punto solo diventa un intervallo', () {
      final r = niceRange(3, 3);
      expect(r.max, greaterThan(r.min));
    });

    test('zero e non finiti', () {
      final z = niceRange(0, 0);
      expect(z.min, lessThan(0));
      expect(z.max, greaterThan(0));
      expect(niceRange(double.nan, 1), (min: 0.0, max: 1.0));
    });
  });

  group('formatTick', () {
    test('intero senza decimali, altrimenti al massimo due cifre pulite', () {
      expect(formatTick(2), '2');
      expect(formatTick(-3), '-3');
      expect(formatTick(0), '0');
      expect(formatTick(2.5), '2.5');
      expect(formatTick(1.25), '1.25');
      expect(formatTick(2.50), '2.5');
    });
  });

  group('niceTicks', () {
    test('etichette pulite e dentro il dominio', () {
      final ticks = niceTicks(0, 10);
      expect(ticks, isNotEmpty);
      expect(ticks.first.value, 0);
      expect(ticks.last.value, 10);
      for (final t in ticks) {
        expect(t.value, greaterThanOrEqualTo(0));
        expect(t.value, lessThanOrEqualTo(10));
        expect(t.label, isNot(contains('e')));
        expect(t.label, isNot(endsWith('0.0')));
        expect(t.label.length, lessThanOrEqualTo(4));
      }
    });
  });

  group('ChartScale', () {
    final scale = ChartScale(
      minX: -10,
      maxX: 10,
      minY: -4,
      maxY: 4,
      rect: const RectD(0, 0, 100, 50),
    );

    test('lo zero y sta al centro del rettangolo', () {
      expect(scale.yToPx(0), 25);
      expect(scale.yToPx(4), 0);
      expect(scale.yToPx(-4), 50);
    });

    test('x crescente va a destra', () {
      expect(scale.xToPx(-10), 0);
      expect(scale.xToPx(10), 100);
    });

    test('crossesZero solo se il dominio contiene lo zero', () {
      expect(scale.crossesZero, isTrue);
      expect(
        ChartScale(
          minX: 0,
          maxX: 1,
          minY: 1,
          maxY: 2,
          rect: const RectD(0, 0, 1, 1),
        ).crossesZero,
        isFalse,
      );
    });
  });

  group('sampledSegments', () {
    test('un valore assente spezza il tratto invece di metterci zero', () {
      // sqrt(x - 2) non esiste per x < 2: due tratti, non tre punti.
      final segs = sampledSegments('sqrt(x - 2)', 0, 4, samples: 41);
      expect(segs.length, 1);
      for (final s in segs) {
        for (final p in s) {
          expect(p.x, greaterThanOrEqualTo(2));
        }
      }
    });

    test('una funzione continua sta in un solo segmento', () {
      final segs = sampledSegments('2 * x - 4', -4, 8, samples: 100);
      expect(segs.length, 1);
      expect(segs.first.length, 100);
      expect(segs.first.first.x, closeTo(-4, 1e-9));
    });

    test('clipMin e clipMax tagliano fuori dal rettangolo', () {
      final segs = sampledSegments(
        'x',
        -10,
        10,
        samples: 101,
        clipMin: -2,
        clipMax: 2,
      );
      for (final s in segs) {
        for (final p in s) {
          expect(p.y, inInclusiveRange(-2, 2));
        }
      }
    });

    test('una funzione senza radici reali non produce punti', () {
      expect(sampledSegments('sqrt(x - 10)', 0, 4, samples: 20), isEmpty);
    });

    test('ingressi inutili non producono segmenti', () {
      expect(sampledSegments('', 0, 1), isEmpty);
      expect(sampledSegments('x', 0, 1, samples: 1), isEmpty);
      expect(sampledSegments('x', double.nan, 1), isEmpty);
    });
  });

  group('barGeometry', () {
    test('una sola serie prende quasi tutta la casella', () {
      final g = barGeometry(plotWidth: 300, groups: 3, series: 1);
      expect(g.width, closeTo(70, 1));
      expect(g.width, greaterThan(0));
    });

    test('più serie dividono la casella', () {
      final g = barGeometry(plotWidth: 300, groups: 3, series: 3);
      expect(g.width, closeTo(70 / 3 - 2, 0.01));
      expect(g.width, greaterThan(0));
      expect(g.gap, 2);
    });
  });

  group('barGroupCount', () {
    ChartBoxPayload payload(List<String> labels, List<num> values) =>
        ChartBoxPayload.fromJson({
          'kind': 'bar',
          if (labels.isNotEmpty) 'xLabels': labels,
          'series': [
            {'values': values},
          ],
        });

    test('conti le voci dalle etichette', () {
      expect(barGroupCount(payload(['a', 'b', 'c'], [1, 2])), 3);
    });

    test('conti i valori quando le etichette mancano', () {
      expect(barGroupCount(payload([], [1, 2, 3, 4])), 4);
    });

    test('mai zero caselle', () {
      expect(barGroupCount(payload([], [])), 1);
    });
  });
}
