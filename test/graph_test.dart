import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/widgets/graph/graph_params.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/models/multifunction_box/box_type.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/graph/graph_layout.dart';
import 'package:math_app/widgets/graph/graph_painter.dart';
import 'package:math_app/widgets/graph/graph_view.dart';

GraphPayload _graph(Map<String, dynamic> json) => GraphPayload.fromJson(json);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formato', () {
    test('legge piano, domini, griglia ed elementi', () {
      final g = _graph({
        'x': [-4, 8],
        'y': [-10, 10],
        'grid': 2,
        'aspect': 'equal',
        'items': [
          {
            'type': 'function',
            'expr': '2*x',
            'domain': [0, 4],
            'label': 'f',
          },
          {
            'type': 'point',
            'at': [2, 0],
            'guides': true,
          },
          {'type': 'line', 'x': 5, 'style': 'dashed'},
          {'type': 'line', 'y': -1},
          {
            'type': 'line',
            'through': [
              [0, 0],
              [1, 2],
            ],
          },
        ],
      });
      expect(g.plane, GraphPlane.cartesian);
      expect(g.x, (-4, 8));
      expect(g.grid, 2);
      expect(g.aspect, GraphAspect.equal);
      expect(g.items, hasLength(5));
      expect((g.items[0] as GraphFunction).domain, (0, 4));
      expect((g.items[1] as GraphPoint).guides, isTrue);
      expect((g.items[2] as GraphLine).x, 5);
      expect(g.items[2].style, GraphLineStyle.dashed);
      expect((g.items[3] as GraphLine).y, -1);
      expect((g.items[4] as GraphLine).through, isNotNull);
    });

    test('un tipo sconosciuto o un elemento malformato si salta', () {
      final g = _graph({
        'items': [
          {'type': 'sconosciuto'},
          {'type': 'point', 'at': 'qui'},
          {'type': 'function', 'expr': '  '},
          {
            'type': 'line',
            'through': [
              [1, 1],
              [1, 1],
            ],
          },
          {'type': 'function', 'expr': 'x'},
        ],
      });
      expect(g.items.single, isA<GraphFunction>());
    });

    test('un dominio rovesciato vale come nessun dominio', () {
      expect(
        _graph({
          'x': [5, 1],
        }).x,
        isNull,
      );
    });

    test('le barre tengono i buchi come null', () {
      final g = _graph({
        'plane': 'bars',
        'categories': ['a', 'b', 'c'],
        'series': [
          {
            'values': [1, 'x', 3],
          },
        ],
      });
      expect(g.plane, GraphPlane.bars);
      expect(g.series.single.values, [1, null, 3]);
      expect(g.isEmpty, isFalse);
      expect(
        _graph({
          'plane': 'bars',
          'series': [
            {
              'values': ['x'],
            },
          ],
        }).isEmpty,
        isTrue,
      );
    });

    test('legge curve, circonferenze, segmenti, vettori e poligoni', () {
      final g = _graph({
        'items': [
          {
            'type': 'curve',
            'x': 'cos(t)',
            'y': 'sin(t)',
            't': [0, 3],
            'label': 'γ',
          },
          {
            'type': 'circle',
            'center': [1, 2],
            'radius': 3,
            'fill': true,
          },
          {
            'type': 'segment',
            'from': [0, 0],
            'to': [1, 1],
          },
          {
            'type': 'vector',
            'from': [0, 0],
            'to': [2, 1],
          },
          {
            'type': 'polygon',
            'points': [
              [0, 0],
              [2, 0],
              [1, 2],
            ],
          },
        ],
      });
      expect(g.items, hasLength(5));
      expect((g.items[0] as GraphCurve).t, (0, 3));
      final cerchio = g.items[1] as GraphCircle;
      expect(cerchio.radius, 3);
      expect(cerchio.fill, isTrue);
      expect((g.items[2] as GraphSegment).arrow, isFalse);
      expect((g.items[3] as GraphSegment).arrow, isTrue);
      expect((g.items[4] as GraphPolygon).fill, isTrue);
    });

    test('aree sotto una curva e fra due curve, regioni con le condizioni', () {
      final g = _graph({
        'items': [
          {'type': 'area', 'under': 'x^2', 'from': 0, 'to': 2},
          {
            'type': 'area',
            'between': ['x + 2', 'x^2'],
            'from': -1,
            'to': 2,
          },
          {
            'type': 'region',
            'where': ['y >= x^2', 'y < 4', 'x ≤ 1'],
          },
        ],
      });
      final sotto = g.items[0] as GraphArea;
      expect(sotto.lower, isNull);
      final fra = g.items[1] as GraphArea;
      expect((fra.upper, fra.lower), ('x + 2', 'x^2'));
      final where = (g.items[2] as GraphRegion).where;
      expect(where.map((c) => c.onY), [true, true, false]);
      expect(where.map((c) => c.compare), [
        GraphCompare.greaterEqual,
        GraphCompare.less,
        GraphCompare.lessEqual,
      ]);
      expect(where[0].expr, 'x^2');
      expect(where[1].compare.strict, isTrue);
      expect(where[0].compare.above, isTrue);
    });

    test('figure malformate si saltano, e una condizione sbagliata salta la '
        'regione intera', () {
      final g = _graph({
        'items': [
          {
            'type': 'circle',
            'center': [0, 0],
            'radius': 0,
          },
          {
            'type': 'polygon',
            'points': [
              [0, 0],
              [1, 1],
            ],
          },
          {'type': 'area', 'under': 'x', 'from': 3, 'to': 1},
          {'type': 'area', 'from': 0, 'to': 1},
          {
            'type': 'region',
            'where': ['y > x', 'z < 2'],
          },
          {
            'type': 'curve',
            'x': 't',
            'y': 't',
            't': [1, 0],
          },
        ],
      });
      expect(g.items, isEmpty);
    });

    test('la condizione si riscrive com\'era', () {
      expect(GraphCondition.parse('y<=2*x')!.toString(), 'y <= 2*x');
      expect(GraphCondition.parse('2 < x'), isNull);
    });

    test('il riquadro graph diventa un GraphPayload', () {
      final box = MultifunctionBox.fromJson({
        'id': 'g',
        'box_type': 'graph',
        'payload': {
          'items': [
            {'type': 'function', 'expr': 'x'},
          ],
        },
      });
      expect(box.boxType, BoxType.graph);
      expect(box.payload, isA<GraphPayload>());
    });

    test('ogni grafico delle lezioni si legge e non è vuoto', () async {
      final index = jsonDecode(
        await rootBundle.loadString('assets/data/lessons/index.json'),
      ) as Map<String, dynamic>;
      final boxes = <Map<String, dynamic>>[];
      void collect(Object? node) {
        if (node is Map<String, dynamic>) {
          if (node['box_type'] == 'graph') boxes.add(node);
          node.values.forEach(collect);
        } else if (node is List) {
          node.forEach(collect);
        }
      }

      for (final file in index['argomenti'] as List<dynamic>) {
        collect(
          jsonDecode(await rootBundle.loadString('assets/data/lessons/$file')),
        );
      }
      expect(boxes, isNotEmpty);
      for (final box in boxes) {
        final payload = MultifunctionBox.fromJson(box).payload as GraphPayload;
        // Con i parametri, i valori di partenza degli slider.
        final shown = resolveGraph(payload, defaultParamValues(payload));
        expect(shown.isEmpty, isFalse, reason: box['id'] as String);
      }
    });
  });

  group('disposizione', () {
    final funzione = _graph({
      'x': [-4, 8],
      'y': [-10, 10],
      'items': [
        {'type': 'function', 'expr': '2*x - 4'},
      ],
    });

    test('adattato: altezza a tre quarti della larghezza', () {
      final l = CartesianLayout.of(funzione, 320);
      expect(l.height, 320 * kGraphFitRatio);
      expect(l.scale.axisX, 0);
      expect(l.scale.axisY, 0);
    });

    test('stessa unità: un pixel vale lo stesso sui due assi', () {
      final l = CartesianLayout.of(
        _graph({
          'x': [-5, 5],
          'y': [-5, 5],
          'aspect': 'equal',
          'items': [
            {
              'type': 'point',
              'at': [0, 0],
            },
          ],
        }),
        300,
      );
      final s = l.scale;
      final perX = s.rect.width / s.spanX;
      final perY = s.rect.height / s.spanY;
      expect(perX, closeTo(perY, perX * 0.15));
    });

    test(
      'stessa unità con un dominio molto basso: si allarga, non si schiaccia',
      () {
        final l = CartesianLayout.of(
          _graph({
            'x': [-10, 10],
            'y': [-1, 1],
            'aspect': 'equal',
            'items': [
              {
                'type': 'point',
                'at': [0, 0],
              },
            ],
          }),
          300,
        );
        expect(l.height, 300 * kGraphMinRatio);
        expect(l.scale.spanY, greaterThan(2));
      },
    );

    test('con lo zero fuori, gli assi stanno sul bordo e c\'è margine', () {
      final l = CartesianLayout.of(
        _graph({
          'x': [2, 8],
          'y': [1, 5],
          'items': [
            {'type': 'function', 'expr': 'x'},
          ],
        }),
        300,
      );
      expect(l.scale.axisX, 2);
      expect(l.scale.axisY, 1);
      expect(l.showsOrigin, isFalse);
      expect(l.scale.rect.left, greaterThan(20));
    });

    test('una retta per due punti si taglia sul bordo del dominio', () {
      final l = CartesianLayout.of(funzione, 300);
      final ends = l.clip(
        const GraphLine.through(GraphXY(0, 0), GraphXY(1, 1)),
      )!;
      expect(ends.$1.x, -4);
      expect(ends.$2.x, 8);
      expect(l.clip(const GraphLine.vertical(100)), isNull);
    });

    test('senza domini il grafico li trova dalle funzioni', () {
      final l = CartesianLayout.of(
        _graph({
          'items': [
            {
              'type': 'function',
              'expr': 'x^2',
              'domain': [-3, 3],
            },
          ],
        }),
        300,
      );
      expect(l.scale.minX, lessThanOrEqualTo(-3));
      expect(l.scale.maxY, greaterThanOrEqualTo(8));
      expect(l.scale.minY, lessThanOrEqualTo(0));
    });

    test('su un grafico stretto i numeri si diradano', () {
      final largo = CartesianLayout.of(funzione, 600);
      final stretto = CartesianLayout.of(funzione, 160);
      expect(stretto.xLabelEvery, greaterThanOrEqualTo(largo.xLabelEvery));
    });

    test('la circonferenza è un contorno chiuso a distanza r dal centro', () {
      final l = CartesianLayout.of(
        _graph({
          'x': [-5, 5],
          'y': [-5, 5],
          'items': [
            {
              'type': 'circle',
              'center': [1, -1],
              'radius': 2,
              'fill': true,
            },
          ],
        }),
        300,
      );
      final ring = l.samples[0].single;
      expect(ring.first.x, closeTo(ring.last.x, 1e-9));
      expect(ring.first.y, closeTo(ring.last.y, 1e-9));
      for (final p in ring) {
        final d = (p.x - 1) * (p.x - 1) + (p.y + 1) * (p.y + 1);
        expect(d, closeTo(4, 1e-9));
      }
      expect(l.fills[0], hasLength(1));
    });

    test('la regione sta dentro le sue condizioni', () {
      final l = CartesianLayout.of(
        _graph({
          'x': [-4, 4],
          'y': [-2, 6],
          'items': [
            {
              'type': 'region',
              'where': ['y >= x^2', 'y < 4', 'x <= 1'],
            },
          ],
        }),
        300,
      );
      final pezzi = l.fills[0];
      expect(pezzi, hasLength(1));
      for (final p in pezzi.single) {
        expect(p.y, greaterThanOrEqualTo(p.x * p.x - 1e-9));
        expect(p.y, lessThanOrEqualTo(4 + 1e-9));
        expect(p.x, lessThanOrEqualTo(1 + 1e-9));
        expect(p.x, greaterThanOrEqualTo(-2 - 0.05));
      }
      // Tre bordi: la parabola e la retta y = 4 (tratteggiata, è stretta),
      // poi la verticale x = 1.
      final bordi = l.edges[0];
      expect(bordi, hasLength(3));
      expect(bordi.where((e) => e.dashed), hasLength(1));
    });

    test('una regione vuota non riempie niente', () {
      final l = CartesianLayout.of(
        _graph({
          'x': [-4, 4],
          'y': [-4, 4],
          'items': [
            {
              'type': 'region',
              'where': ['y > 2', 'y < 1'],
            },
          ],
        }),
        300,
      );
      expect(l.fills[0], isEmpty);
      expect(l.edges[0], hasLength(2));
    });

    test('l\'area fra due curve va dalla più bassa alla più alta', () {
      final l = CartesianLayout.of(
        _graph({
          'x': [-2, 3],
          'y': [-1, 5],
          'items': [
            {
              'type': 'area',
              'between': ['x + 2', 'x^2'],
              'from': -1,
              'to': 2,
            },
          ],
        }),
        300,
      );
      final contorno = l.fills[0].single;
      expect(contorno.first.x, closeTo(-1, 1e-9));
      expect(contorno.first.y, closeTo(1, 1e-9));
      final meta = contorno.length ~/ 2;
      expect(contorno[meta - 1].x, closeTo(2, 1e-9));
      expect(contorno.last.y, closeTo(1, 1e-9));
    });

    test('senza domini il grafico li trova dalle figure', () {
      final l = CartesianLayout.of(
        _graph({
          'items': [
            {
              'type': 'circle',
              'center': [10, 10],
              'radius': 3,
            },
            {
              'type': 'segment',
              'from': [-2, 0],
              'to': [0, 0],
            },
          ],
        }),
        300,
      );
      expect(l.scale.maxX, greaterThanOrEqualTo(13));
      expect(l.scale.maxY, greaterThanOrEqualTo(13));
      expect(l.scale.minX, lessThanOrEqualTo(-2));
    });

    test('le barre partono dallo zero', () {
      final l = BarsLayout.of(
        _graph({
          'plane': 'bars',
          'categories': ['a', 'b'],
          'series': [
            {
              'values': [3, 5],
            },
          ],
        }),
        300,
      );
      expect(l.scale.minY, 0);
      expect(l.scale.maxY, greaterThanOrEqualTo(5));
      expect(l.groups, 2);
    });
  });

  group('retta numerica', () {
    test('gli intervalli si scrivono come sul libro', () {
      final aperto = GraphInterval.parse(']2, +inf[')!;
      expect((aperto.from, aperto.to), (2, null));
      expect((aperto.fromOpen, aperto.toOpen), (true, true));

      final misto = GraphInterval.parse('[-1, 5/3)')!;
      expect(misto.from, -1);
      expect(misto.to, closeTo(5 / 3, 1e-12));
      expect((misto.fromOpen, misto.toOpen), (false, true));
      expect(misto.toText, '5/3');

      final sinistra = GraphInterval.parse('(−∞; 3]')!;
      expect((sinistra.from, sinistra.to, sinistra.toOpen), (null, 3, false));
    });

    test('un intervallo vuoto o scritto male non c\'è', () {
      for (final t in ['[3, 1]', '[2, 2]', '[a, 2]', '[+inf, 2]', '2, 3']) {
        expect(GraphInterval.parse(t), isNull, reason: t);
      }
    });

    test('il riquadro legge piano, intervalli e punti con un numero solo', () {
      final g = _graph({
        'plane': 'numberLine',
        'items': [
          {'type': 'interval', 'set': '[0, 4]', 'label': 'A'},
          {'type': 'point', 'at': 2},
          {'type': 'interval'},
        ],
      });
      expect(g.plane, GraphPlane.numberLine);
      expect(g.items, hasLength(2));
      expect((g.items[1] as GraphPoint).at.x, 2);
      expect(g.isEmpty, isFalse);
      expect(
        GraphPayload.fromJson(g.toJson()).items.first,
        isA<GraphInterval>(),
      );
    });

    final sistema = _graph({
      'plane': 'numberLine',
      'items': [
        {'type': 'interval', 'set': '[-1, +inf['},
        {'type': 'point', 'at': 0},
        {'type': 'interval', 'set': ']-inf, 5/3['},
      ],
    });

    test('una riga per intervallo dall\'alto, i punti sulla retta', () {
      final l = NumberLineLayout.of(sistema, 320);
      expect(l.rows, [0, null, 1]);
      expect(l.rowY(0), lessThan(l.rowY(2)));
      expect(l.rowY(2), lessThan(l.axis));
      expect(l.rowY(1), l.axis);
    });

    test('i numeri sono gli estremi scritti come nel JSON, con margine', () {
      final l = NumberLineLayout.of(sistema, 320);
      expect(l.ticks.map((t) => t.label), ['-1', '0', '5/3']);
      expect(l.scale.minX, lessThan(-1));
      expect(l.scale.maxX, greaterThan(5 / 3));
    });

    test(
      'con la griglia i numeri regolari cedono e si diradano dallo zero',
      () {
        final g = _graph({
          'plane': 'numberLine',
          'x': [-20, 20],
          'grid': 1,
          'items': [
            {'type': 'interval', 'set': '[0.4, 3]'},
          ],
        });
        final l = NumberLineLayout.of(g, 320);
        final regolari = l.ticks.where(
          (t) => t.label != '0.4' && t.label != '3',
        );
        // Su 40 unità in 300 px il passo 1 non ci sta: uno ogni tanti, e lo
        // zero, troppo vicino a 0.4, cede il posto.
        expect(regolari.length, lessThan(41));
        expect(l.ticks.any((t) => t.value == 0), isFalse);
        final step = regolari.elementAt(1).value - regolari.first.value;
        for (final t in regolari) {
          expect((t.value / step).round() * step, closeTo(t.value, 1e-9));
        }
      },
    );
  });

  group('widget', () {
    Future<void> pump(
      WidgetTester tester,
      GraphPayload payload, {
      bool reduced = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: Scaffold(
                body: SizedBox(width: 320, child: GraphView(payload: payload)),
              ),
            ),
          ),
        ),
      );
    }

    CartesianPainter painter(WidgetTester tester) =>
        tester
                .widget<CustomPaint>(find.byKey(const Key('graph-canvas')))
                .painter!
            as CartesianPainter;

    final due = _graph({
      'items': [
        {'type': 'function', 'expr': 'x', 'label': 'f'},
        {'type': 'function', 'expr': '-x', 'label': 'g'},
      ],
    });

    testWidgets('due funzioni senza colore hanno colori diversi', (
      tester,
    ) async {
      await pump(tester, due);
      final colors = painter(tester).style.colors;
      expect(colors[0], isNot(colors[1]));
    });

    test(
      'i nomi della palette, e un nome sconosciuto ricade sulla sequenza',
      () {
        const c = AppPalette.light;
        expect(graphColor(c, 'orange', 0), c.orangeDeep);
        expect(graphColor(c, 'green', 0), c.easy);
        expect(graphColor(c, 'boh', 1), graphColor(c, null, 1));
      },
    );

    test('ogni colore della sequenza su bianco passa 3:1', () {
      const c = AppPalette.light;
      double contrasto(Color a, Color b) {
        final la = a.computeLuminance(), lb = b.computeLuminance();
        return (lb + 0.05) / (la + 0.05);
      }

      for (var i = 0; i < 6; i++) {
        expect(
          contrasto(graphColor(c, null, i), Colors.white),
          greaterThanOrEqualTo(3),
        );
      }
    });

    testWidgets('in legenda la funzione tratteggiata ha il suo trattino', (
      tester,
    ) async {
      await pump(
        tester,
        _graph({
          'items': [
            {
              'type': 'function',
              'expr': 'x',
              'label': 'f',
              'color': 'orange',
              'style': 'dashed',
            },
          ],
        }),
      );
      await tester.pumpAndSettle();
      final pezzi = find.byWidgetPredicate(
        (w) => w is Container && w.color == AppPalette.light.orangeDeep,
      );
      expect(pezzi, findsNWidgets(2));
      for (final e in pezzi.evaluate()) {
        expect(tester.getSize(find.byWidget(e.widget)).height, 4);
      }
    });

    testWidgets('le curve vanno in legenda, le figure hanno l\'etichetta '
        'sul piano', (tester) async {
      await pump(
        tester,
        _graph({
          'x': [-5, 5],
          'y': [-5, 5],
          'items': [
            {
              'type': 'curve',
              'x': 'cos(t)',
              'y': 'sin(t)',
              't': [0, 3],
              'label': '\\gamma',
            },
            {
              'type': 'circle',
              'center': [0, 0],
              'radius': 2,
              'label': 'C',
            },
            {
              'type': 'vector',
              'from': [0, 0],
              'to': [3, 1],
              'label': 'v',
            },
            {
              'type': 'region',
              'where': ['y > 1'],
              'label': 'R',
            },
          ],
        }),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Wrap), findsOneWidget);
      final legenda = find.descendant(
        of: find.byType(Wrap),
        matching: find.byType(Math),
      );
      expect(legenda, findsOneWidget);
      // Tre etichette sul piano, più i nomi dei due assi.
      expect(find.byType(Math), findsNWidgets(1 + 3 + 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('la retta numerica ha il suo disegno e la sua descrizione', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await pump(
        tester,
        _graph({
          'plane': 'numberLine',
          'items': [
            {'type': 'interval', 'set': ']2, +inf[', 'label': 'x > 2'},
          ],
        }),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CustomPaint>(find.byKey(const Key('graph-canvas')))
            .painter,
        isA<NumberLinePainter>(),
      );
      expect(find.bySemanticsLabel('Retta numerica: x > 2'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('col movimento ridotto il grafico è già tutto lì', (
      tester,
    ) async {
      await pump(tester, due, reduced: true);
      await tester.pump();
      expect(painter(tester).progress, 1);
    });

    testWidgets('lo screen reader legge un\'immagine con le etichette', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await pump(tester, due);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Piano cartesiano: f, g'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('su un grafico molto stretto non rompe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(width: 60, child: GraphView(payload: due)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
