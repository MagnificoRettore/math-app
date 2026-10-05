import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';
import 'package:math_app/widgets/graph/graph_params.dart';
import 'package:math_app/widgets/graph/graph_painter.dart';
import 'package:math_app/widgets/multifunction_box_widget.dart';

const _json = '''
{
  "id": "g", "box_type": "graph",
  "payload": {
    "plane": "cartesian", "x": [-6, 6], "y": [-5, 5],
    "params": {
      "m": {"min": -3, "max": 3, "step": 0.5, "value": 1},
      "q": {"min": -4, "max": 4, "step": 0.5, "value": -1},
      "p": {"min": 0, "max": 6, "step": 0.5, "value": 0, "animate": true}
    },
    "items": [
      {"type": "function", "expr": "m*x + q"},
      {"type": "point", "at": [0, "q"], "label": "q"},
      {"type": "line", "through": [[0, "q"], [1, "m + q"]]}
    ]
  }
}
''';

GraphPayload _payload() =>
    MultifunctionBox.fromJson(jsonDecode(_json) as Map<String, dynamic>).payload
        as GraphPayload;

Widget _host({bool reduced = false}) {
  final box = MultifunctionBox.fromJson(
    jsonDecode(_json) as Map<String, dynamic>,
  );
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: SingleChildScrollView(child: MultifunctionBoxWidget(box: box)),
      ),
    ),
  );
}

GraphPayload _drawn(WidgetTester tester) =>
    (tester.widget<CustomPaint>(find.byKey(const Key('graph-canvas'))).painter!
            as CartesianPainter)
        .payload;

void main() {
  group('modello', () {
    test('i parametri si leggono, con valori di base sensati', () {
      final p = GraphParam.fromJson('a', {'min': 1, 'max': 3});
      expect(p!.value, 1); // senza value: il minimo
      expect(p.step, closeTo(0.02, 1e-9)); // senza step: un centesimo
      expect(p.label, 'a');
      expect(
        GraphParam.fromJson('a', {'min': 0, 'max': 1, 'value': 9})!.value,
        1,
      );
    });

    test(
      'nomi riservati, intervalli rovesciati e forme strane si scartano',
      () {
        for (final name in ['x', 't', 'pi', 'e', 'sin', '1a', 'a b']) {
          expect(
            GraphParam.fromJson(name, {'min': 0, 'max': 1}),
            isNull,
            reason: name,
          );
        }
        expect(GraphParam.fromJson('a', {'min': 2, 'max': 1}), isNull);
        expect(GraphParam.fromJson('a', {'min': 1, 'max': 1}), isNull);
        expect(GraphParam.fromJson('a', 'boh'), isNull);
      },
    );

    test('il grafico tiene i suoi parametri e li riscrive', () {
      final payload = _payload();
      expect(payload.params.map((p) => p.name), ['m', 'q', 'p']);
      expect(payload.params.last.animate, isTrue);
      expect((payload.toJson()['params'] as Map).keys, ['m', 'q', 'p']);
      // Un grafico senza parametri non ne ha, e non tiene il JSON.
      final plain = GraphPayload.fromJson({'items': []});
      expect(plain.params, isEmpty);
      expect(plain.source, isNull);
    });
  });

  group('sostituzione', () {
    test('mette i numeri al posto dei nomi, solo parole intere', () {
      expect(
        substituteParams('a*abs(x) + sin(a) + ab', {'a': 2}),
        '2*abs(x) + sin(2) + ab',
      );
    });

    test(
      'un numero negativo va fra parentesi, e niente notazione scientifica',
      () {
        expect(substituteParams('m*x', {'m': -2}), '(-2)*x');
        expect(substituteParams('m*x', {'m': 0.0000001}), '0*x');
        expect(substituteParams('m*x', {'m': 1.25}), '1.25*x');
      },
    );

    test('anche le coordinate e le rette per due punti', () {
      final resolved = resolveGraph(_payload(), {'m': 2, 'q': -3, 'p': 0});
      final point = resolved.items[1] as GraphPoint;
      expect((point.at.x, point.at.y), (0, -3));
      final line = resolved.items[2] as GraphLine;
      expect(line.through, isNotNull);
      final fn = resolved.items[0] as GraphFunction;
      expect(fn.expr, '2*x + (-3)');
    });

    test('un grafico senza parametri resta lo stesso', () {
      final plain = GraphPayload.fromJson({'items': []});
      expect(identical(resolveGraph(plain, {}), plain), isTrue);
    });
  });

  group('lo slider', () {
    testWidgets('ha uno slider per parametro e il valore scritto', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Slider), findsNWidgets(3));
      expect(find.byKey(const Key('param-m')), findsOneWidget);
    });

    testWidgets('muoverlo ridisegna il grafico, senza rifare l\'entrata', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pump(const Duration(seconds: 1));
      expect((_drawn(tester).items.first as GraphFunction).expr, '1*x + (-1)');

      final slider = find.descendant(
        of: find.byKey(const Key('param-m')),
        matching: find.byType(Slider),
      );
      tester.widget<Slider>(slider).onChanged!(2.5);
      await tester.pump();

      expect(
        (_drawn(tester).items.first as GraphFunction).expr,
        '2.5*x + (-1)',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('trascinarlo col dito cambia il valore', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump(const Duration(seconds: 1));
      final slider = find.descendant(
        of: find.byKey(const Key('param-q')),
        matching: find.byType(Slider),
      );
      await tester.ensureVisible(slider);
      await tester.drag(slider, const Offset(400, 0));
      await tester.pump();
      final q = tester.widget<Slider>(slider).value;
      expect(q, greaterThan(-1));
    });
  });

  group('l\'animazione', () {
    testWidgets('il tasto c\'è solo dove c\'è animate; fa scorrere il valore', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('param-play-m')), findsNothing);
      expect(find.byKey(const Key('param-play-p')), findsOneWidget);

      double p() => tester
          .widget<Slider>(
            find.descendant(
              of: find.byKey(const Key('param-p')),
              matching: find.byType(Slider),
            ),
          )
          .value;
      expect(p(), 0);

      await tester.ensureVisible(find.byKey(const Key('param-play-p')));
      await tester.tap(find.byKey(const Key('param-play-p')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final moved = p();
      expect(moved, greaterThan(0));

      // Ferma: il valore non cambia più.
      await tester.tap(find.byKey(const Key('param-play-p')));
      await tester.pump();
      final stopped = p();
      await tester.pump(const Duration(seconds: 1));
      expect(p(), stopped);
    });

    testWidgets('toccare lo slider ferma l\'animazione', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump(const Duration(seconds: 1));
      await tester.ensureVisible(find.byKey(const Key('param-play-p')));
      await tester.tap(find.byKey(const Key('param-play-p')));
      await tester.pump(const Duration(milliseconds: 500));
      final slider = find.descendant(
        of: find.byKey(const Key('param-p')),
        matching: find.byType(Slider),
      );
      tester.widget<Slider>(slider).onChanged!(3);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<Slider>(slider).value, 3);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('col movimento ridotto non c\'è il tasto', (tester) async {
      await tester.pumpWidget(_host(reduced: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('param-play-p')), findsNothing);
      expect(find.byType(Slider), findsNWidgets(3));
    });
  });

  group('punti trascinabili', () {
    /// Un dito vero manda tanti piccoli movimenti, non un salto solo: dopo la
    /// soglia del tocco (kPanSlop) ognuno arriva al gesto come trascinamento.
    Future<void> trascina(
      WidgetTester tester,
      Finder finder,
      Offset total,
    ) async {
      final gesture = await tester.startGesture(tester.getCenter(finder));
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(total / 20);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();
    }

    const dragJson = '''
{
  "id": "d", "box_type": "graph",
  "payload": {
    "plane": "cartesian", "x": [-6, 6], "y": [-6, 6], "aspect": "equal",
    "params": {
      "px": {"min": -4, "max": 4, "step": 0.5, "value": 0, "slider": false},
      "py": {"min": -4, "max": 4, "step": 0.5, "value": 0, "slider": false},
      "s": {"min": 0, "max": 3, "step": 1, "value": 1}
    },
    "items": [
      {"type": "point", "at": ["px", "py"], "draggable": true, "label": "A"},
      {"type": "point", "at": ["px", "s"], "draggable": true, "label": "B"},
      {"type": "point", "at": [1, 1], "draggable": true, "label": "fisso"},
      {"type": "point", "at": ["px + 1", "py + 1"], "label": "M"}
    ]
  }
}
''';

    GraphPayload payload() =>
        MultifunctionBox.fromJson(jsonDecode(dragJson) as Map<String, dynamic>)
                .payload
            as GraphPayload;

    Widget host() => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MultifunctionBoxWidget(
            box: MultifunctionBox.fromJson(
              jsonDecode(dragJson) as Map<String, dynamic>,
            ),
          ),
        ),
      ),
    );

    test('quali punti si trascinano e quali parametri muovono', () {
      final handles = dragHandles(payload());
      // Il punto «fisso» non ha parametri fra le coordinate: niente da trascinare.
      expect(handles.map((h) => h.itemIndex), [0, 1]);
      expect((handles[0].xParam, handles[0].yParam), ('px', 'py'));
      // B muove solo la x: la y è lo slider `s`, che qui resta un'altra cosa.
      expect((handles[1].xParam, handles[1].yParam), ('px', 's'));
      expect((payload().items.first as GraphPoint).draggable, isTrue);
    });

    test('lo scatto più vicino, dentro min e max', () {
      final p = GraphParam.fromJson('a', {'min': -4, 'max': 4, 'step': 0.5})!;
      expect(snapParam(p, 1.3), 1.5);
      expect(snapParam(p, 1.2), 1);
      expect(snapParam(p, 99), 4);
      expect(snapParam(p, -99), -4);
    });

    test('slider: false nasconde lo slider e si riscrive', () {
      final params = payload().params;
      expect(params.map((p) => p.slider), [false, false, true]);
      expect(
        ((payload().toJson()['params'] as Map)['px'] as Map)['slider'],
        isFalse,
      );
    });

    testWidgets(
      'ci sono gli anelli dei punti trascinabili e solo lo slider che serve',
      (tester) async {
        await tester.pumpWidget(host());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byKey(const Key('drag-0')), findsOneWidget);
        expect(find.byKey(const Key('drag-1')), findsOneWidget);
        expect(find.byKey(const Key('drag-2')), findsNothing);
        expect(find.byKey(const Key('drag-3')), findsNothing);
        expect(find.byType(Slider), findsOneWidget);
        expect(find.byKey(const Key('param-px')), findsNothing);
      },
    );

    testWidgets('trascinare il punto cambia le sue coordinate, a scatti', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pump(const Duration(seconds: 1));
      GraphXY a() => (_drawn(tester).items[0] as GraphPoint).at;
      expect((a().x, a().y), (0, 0));

      await trascina(
        tester,
        find.byKey(const Key('drag-0')),
        const Offset(120, -80),
      );
      // A destra e in alto: x e y aumentano, sempre su multipli dello scatto.
      expect(a().x, greaterThan(0));
      expect(a().y, greaterThan(0));
      expect(a().x % 0.5, 0);
      expect(a().y % 0.5, 0);
      // M segue A (è un'espressione dei suoi parametri).
      final m = (_drawn(tester).items[3] as GraphPoint).at;
      expect((m.x, m.y), (a().x + 1, a().y + 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('non esce dai limiti dei parametri', (tester) async {
      await tester.pumpWidget(host());
      await tester.pump(const Duration(seconds: 1));
      await trascina(
        tester,
        find.byKey(const Key('drag-0')),
        const Offset(700, 0),
      );
      expect((_drawn(tester).items[0] as GraphPoint).at.x, 4);
    });

    testWidgets('un punto con una coordinata sola ne muove una', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pump(const Duration(seconds: 1));
      final before = (_drawn(tester).items[1] as GraphPoint).at;
      await trascina(
        tester,
        find.byKey(const Key('drag-1')),
        const Offset(120, 0),
      );
      final after = (_drawn(tester).items[1] as GraphPoint).at;
      expect(after.x, greaterThan(before.x));
      // Lo spostamento in verticale è zero: la y è `s`, non un trascinamento.
      expect(after.y, before.y);
    });
  });
}
