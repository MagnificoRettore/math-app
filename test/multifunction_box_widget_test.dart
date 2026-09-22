import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';
import 'package:math_app/widgets/multifunction_box_widget.dart';

Widget _host(String json) {
  final box = MultifunctionBox.fromJson(
    jsonDecode(json) as Map<String, dynamic>,
  );
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: MultifunctionBoxWidget(box: box)),
    ),
  );
}

Future<void> _pump(WidgetTester tester, String json) async {
  await tester.pumpWidget(_host(json));
  await tester.pump();
}

void main() {
  const imageJson =
      '{"id":"i1","box_type":"image","title":"Figura",'
      '"payload":{"source":"assets/images/missing.png","caption":"Captio"}}';
  const chartJson =
      '{"id":"c1","box_type":"chart","title":"Vendite",'
      '"payload":{"kind":"bar","unit":"€","xLabels":["A","B"],'
      '"series":[{"label":"S1","values":[3,5],"colorKey":"teal"},{"label":"S2","values":[1,2]}]}}';
  const formulaJson =
      '{"id":"f1","box_type":"math_formula","title":"Formula",'
      '"payload":{"tex":"\\\\frac{a}{b}","mode":"display"}}';
  const interactiveJson =
      '{"id":"v1","box_type":"interactive_chart","title":"Interattivo",'
      '"payload":{"xLabel":"x","yLabel":"y","xMin":-2,"xMax":2,"xStep":0.5,'
      '"parameter":{"name":"t","min":1,"max":3,"step":0.5,"default":2},'
      '"series":[{"label":"Curva","expression":"t * x","colorKey":"accent"}]}}';

  testWidgets('box immagine mostra titolo e caption', (tester) async {
    await _pump(tester, imageJson);
    expect(tester.takeException(), isNull);
    expect(find.text('Figura'), findsOneWidget);
    expect(find.text('Captio'), findsOneWidget);
  });

  testWidgets('box grafico istogramma rende CustomPaint', (tester) async {
    await _pump(tester, chartJson);
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Vendite'), findsOneWidget);
  });

  testWidgets('box formula rende Math.tex', (tester) async {
    await _pump(tester, formulaJson);
    expect(tester.takeException(), isNull);
    expect(find.byType(Math), findsOneWidget);
  });

  testWidgets('box grafico interattivo mostra slider', (tester) async {
    await _pump(tester, interactiveJson);
    expect(tester.takeException(), isNull);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('nessuna icona di espansione', (tester) async {
    await _pump(tester, interactiveJson);
    expect(find.byIcon(Icons.open_in_full), findsNothing);
  });
}
