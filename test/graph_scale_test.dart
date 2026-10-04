import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/widgets/graph/graph_scale.dart';

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

  group('GraphScale', () {
    final scale = GraphScale(
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

    test('gli assi passano per lo zero, o sul bordo se lo zero è fuori', () {
      expect(scale.axisX, 0);
      expect(scale.axisY, 0);
      const fuori = GraphScale(
        minX: 2,
        maxX: 8,
        minY: -9,
        maxY: -1,
        rect: RectD(0, 0, 1, 1),
      );
      expect(fuori.axisX, 2);
      expect(fuori.axisY, -1);
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

    test(
      'vicino a un asintoto il tratto si spezza, dentro la fascia resta',
      () {
        // 1/x salta da -inf a +inf: collegare i due lati stamperebbe una
        // verticale che nel grafico non c'è.
        final segs = sampledSegments(
          '1 / x',
          -1,
          1,
          samples: 200,
          yMin: -5,
          yMax: 5,
        );
        expect(segs.length, 2);
        expect(segs.first.every((p) => p.x < 0), isTrue);
        expect(segs.last.every((p) => p.x > 0), isTrue);
        // Un'altezza oltre il dominio i punti restano: la curva esce dal bordo
        // invece di fermarsi un pixel prima.
        final escono = sampledSegments('x', -10, 10, yMin: -2, yMax: 2);
        expect(escono.single.any((p) => p.y > 2), isTrue);
      },
    );

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
    test('conti le voci dalle categorie', () {
      expect(barGroupCount(3, [2]), 3);
    });

    test('conti i valori quando le categorie mancano', () {
      expect(barGroupCount(0, [4, 2]), 4);
    });

    test('mai zero caselle', () {
      expect(barGroupCount(0, const []), 1);
    });
  });

  group('ticksEvery', () {
    test('i multipli del passo dentro il dominio', () {
      expect(
        [for (final t in ticksEvery(-4, 8, 2)) t.value],
        [-4, -2, 0, 2, 4, 6, 8],
      );
      expect(ticksEvery(0, 1, 0), isEmpty);
    });
  });
}
