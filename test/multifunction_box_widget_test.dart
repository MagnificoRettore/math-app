import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';
import 'package:math_app/widgets/app_card.dart';
import 'package:math_app/widgets/chart/chart_painters.dart';
import 'package:math_app/widgets/chart/chart_view.dart';
import 'package:math_app/widgets/multifunction_box_widget.dart';

Widget _hostBox(MultifunctionBox box) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: MultifunctionBoxWidget(box: box)),
    ),
  );
}

Widget _host(String json) {
  return _hostBox(
    MultifunctionBox.fromJson(jsonDecode(json) as Map<String, dynamic>),
  );
}

/// Il painter del grafico: non è un widget, quindi non si cerca con
/// `find.byType` ma leggendo il `CustomPaint` che lo contiene.
CustomPainter? _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(const Key('chart-canvas'))).painter;

Future<void> _pump(WidgetTester tester, String json) async {
  await tester.pumpWidget(_host(json));
  await tester.pump();
}

void main() {
  const imageJson =
      '{"id":"i1","box_type":"image","title":"Figura",'
      '"payload":{"source":"assets/images/missing.png"}}';
  const formulaJson =
      '{"id":"f1","box_type":"math_formula","title":"Formula",'
      '"payload":{"tex":"\\\\frac{a}{b}"}}';
  const hiddenFormulaJson =
      '{"id":"f2","box_type":"math_formula","title":"Formula",'
      '"payload":{"tex":"\\\\frac{a}{b}","hidden":true}}';
  const untitledFormulaJson =
      '{"id":"f3","box_type":"math_formula",'
      '"payload":{"tex":"x + 1"}}';

  testWidgets('box immagine mostra il titolo', (tester) async {
    await _pump(tester, imageJson);
    expect(tester.takeException(), isNull);
    expect(find.text('Figura'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('box immagine non ha card ne contorno', (tester) async {
    await _pump(tester, imageJson);
    expect(tester.takeException(), isNull);
    expect(find.byType(AppCard), findsNothing);
    expect(find.byType(ClipRRect), findsNothing);
  });

  testWidgets('box formula rende Math.tex', (tester) async {
    await _pump(tester, formulaJson);
    expect(tester.takeException(), isNull);
    expect(find.byType(Math), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);
  });

  testWidgets('box formula hidden mostra formula senza card', (tester) async {
    await _pump(tester, hiddenFormulaJson);
    expect(tester.takeException(), isNull);
    expect(find.byType(Math), findsOneWidget);
    expect(find.byType(AppCard), findsNothing);
    expect(find.text('Formula'), findsNothing);
  });

  testWidgets('formula senza titolo non mostra testo del titolo', (
    tester,
  ) async {
    await _pump(tester, untitledFormulaJson);
    expect(tester.takeException(), isNull);
    expect(find.byType(Math), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.text('Formula'), findsNothing);
  });

  const functionChartJson =
      '{"id":"c1","box_type":"chart","title":"La retta",'
      '"payload":{"kind":"function","xMin":-4,"xMax":8,"yMin":-10,"yMax":10,'
      '"series":[{"label":"y = 2x - 4","expression":"2 * x - 4"}]}}';
  const barChartJson =
      '{"id":"c2","box_type":"chart","title":"Valori assoluti",'
      '"payload":{"kind":"bar","xLabels":["-5","0","5"],'
      '"series":[{"label":"|x|","values":[5,0,5]}]}}';
  const lineChartJson =
      '{"id":"c3","box_type":"chart","title":"Due rette",'
      '"payload":{"kind":"line","series":[{"label":"una","points":[[0,1],[2,3]]},'
      '{"label":"due","points":[[0,3],[2,1]]}]}}';
  const emptyChartJson =
      '{"id":"c4","box_type":"chart","title":"Vuoto",'
      '"payload":{"kind":"bar","series":[]}}';

  testWidgets('box chart disegna la curva in card con titolo', (tester) async {
    await _pump(tester, functionChartJson);
    expect(tester.takeException(), isNull);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.byType(ChartView), findsOneWidget);
    // Un painter non è un widget: si cerca il `CustomPaint` che lo tiene.
    expect(_painter(tester), isA<LineChartPainter>());
    expect(find.byKey(const Key('chart-canvas')), findsOneWidget);
    expect(find.text('La retta'), findsOneWidget);
  });

  testWidgets('box chart a barre usa il painter delle barre', (tester) async {
    await _pump(tester, barChartJson);
    expect(tester.takeException(), isNull);
    expect(_painter(tester), isA<BarChartPainter>());
    expect(find.text('Valori assoluti'), findsOneWidget);
  });

  testWidgets('due serie con nomi diversi fanno la legenda', (tester) async {
    await _pump(tester, lineChartJson);
    expect(find.text('una'), findsOneWidget);
    expect(find.text('due'), findsOneWidget);
  });

  testWidgets('una sola serie non fa la legenda', (tester) async {
    await _pump(tester, functionChartJson);
    expect(find.text('y = 2x - 4'), findsNothing);
  });

  testWidgets('un chart senza dati non disegna niente e non rompe', (
    tester,
  ) async {
    await _pump(tester, emptyChartJson);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('chart-canvas')), findsNothing);
  });

  testWidgets('il grafico entra disegnandosi, non di colpo', (tester) async {
    await _pump(tester, functionChartJson);
    final mid = tester.widget<CustomPaint>(
      find.byKey(const Key('chart-canvas')),
    );
    expect((mid.painter! as LineChartPainter).progress, 0);
    await tester.pump(const Duration(milliseconds: 200));
    final half = tester.widget<CustomPaint>(
      find.byKey(const Key('chart-canvas')),
    );
    expect((half.painter! as LineChartPainter).progress, greaterThan(0));
    expect((half.painter! as LineChartPainter).progress, lessThan(1));
    await tester.pumpAndSettle();
    final done = tester.widget<CustomPaint>(
      find.byKey(const Key('chart-canvas')),
    );
    expect((done.painter! as LineChartPainter).progress, 1);
  });

  testWidgets('il chart sopravvive a una serie senza dati', (tester) async {
    await _pump(
      tester,
      '{"id":"c5","box_type":"chart","title":"Mista",'
      '"payload":{"kind":"line","series":[{"label":"vuota"},'
      '{"label":"piena","points":[[0,0],[1,1]]}]}}',
    );
    expect(tester.takeException(), isNull);
    expect(_painter(tester), isA<LineChartPainter>());
  });
}
