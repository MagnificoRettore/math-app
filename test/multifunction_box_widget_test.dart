import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';
import 'package:math_app/widgets/app_card.dart';
import 'package:math_app/widgets/graph/graph_painter.dart';
import 'package:math_app/widgets/graph/graph_view.dart';
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
    tester.widget<CustomPaint>(find.byKey(const Key('graph-canvas'))).painter;

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

  const functionGraphJson =
      '{"id":"g1","box_type":"graph","title":"La retta",'
      '"payload":{"x":[-4,8],"y":[-10,10],'
      '"items":[{"type":"function","expr":"2 * x - 4","label":"y = 2x - 4"},'
      '{"type":"point","at":[2,0],"label":"(2, 0)"}]}}';
  const barGraphJson =
      '{"id":"g2","box_type":"graph","title":"Valori assoluti",'
      '"payload":{"plane":"bars","categories":["-5","0","5"],'
      '"series":[{"label":"|x|","values":[5,0,5]}]}}';
  const emptyGraphJson =
      '{"id":"g3","box_type":"graph","title":"Vuoto",'
      '"payload":{"items":[{"type":"sconosciuto"}]}}';

  testWidgets('box graph disegna il piano in card con titolo', (tester) async {
    await _pump(tester, functionGraphJson);
    expect(tester.takeException(), isNull);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.byType(GraphView), findsOneWidget);
    // Un painter non è un widget: si cerca il `CustomPaint` che lo tiene.
    expect(_painter(tester), isA<CartesianPainter>());
    expect(find.text('La retta'), findsOneWidget);
  });

  testWidgets('legenda ed etichette sono formule, non testo', (tester) async {
    await _pump(tester, functionGraphJson);
    // Legenda (la funzione), etichetta del punto e i due nomi degli assi.
    expect(find.byType(Math), findsNWidgets(4));
    expect(find.text('y = 2x - 4'), findsNothing);
  });

  testWidgets('box graph a barre usa il painter delle barre', (tester) async {
    await _pump(tester, barGraphJson);
    expect(tester.takeException(), isNull);
    expect(_painter(tester), isA<BarsPainter>());
    expect(find.text('Valori assoluti'), findsOneWidget);
  });

  testWidgets('un grafico senza elementi validi non disegna e non rompe', (
    tester,
  ) async {
    await _pump(tester, emptyGraphJson);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('graph-canvas')), findsNothing);
  });

  testWidgets('il grafico entra disegnandosi, non di colpo', (tester) async {
    await _pump(tester, functionGraphJson);
    double progress() => (_painter(tester)! as CartesianPainter).progress;
    expect(progress(), 0);
    await tester.pump(const Duration(milliseconds: 150));
    expect(progress(), greaterThan(0));
    expect(progress(), lessThan(1));
    await tester.pumpAndSettle();
    expect(progress(), 1);
  });
}
