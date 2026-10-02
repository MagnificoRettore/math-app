import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';
import 'package:math_app/widgets/app_card.dart';
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
}
