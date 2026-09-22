import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/widgets/interactive_chart_view.dart';

const _payload = InteractiveChartPayload(
  xLabel: 'x',
  yLabel: 'y',
  xMin: -3,
  xMax: 3,
  xStep: 0.5,
  yMin: -5,
  yMax: 5,
  parameter: InteractiveParameter(
    name: 't',
    min: 0.5,
    max: 2,
    step: 0.1,
    defaultValue: 1,
  ),
  series: [
    InteractiveSeries(
      label: 'Parabola',
      expression: 't * x * x',
      colorKey: 'accent',
    ),
    InteractiveSeries(label: 'Linea', expression: 'x + t', colorKey: 'teal'),
  ],
  toggleable: true,
);

Future<void> _pump(WidgetTester tester, Widget widget) {
  return tester.pumpWidget(widget);
}

Widget _host() {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 340,
          child: InteractiveChartView(payload: _payload),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rendere il grafico interattivo non va in errore', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    expect(tester.takeException(), isNull);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('mostra chips legenda quando toggleable', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('Parabola'), findsWidgets);
    expect(find.text('Linea'), findsWidgets);
  });

  testWidgets('muovere lo slider aggiorna il grafico senza errori', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap su chip nasconde la serie senza errori', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Linea'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Linea'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

testWidgets('mostra valore del parametro corrente', (tester) async {
    await _pump(tester, _host());
    expect(find.text('t = 1.0'), findsOneWidget);
  });

  testWidgets('passo zero nel parametro non va in errore', (tester) async {
    const payload = InteractiveChartPayload(
      xLabel: 'x',
      yLabel: 'y',
      xMin: -1,
      xMax: 1,
      xStep: 0.5,
      parameter: InteractiveParameter(
        name: 't',
        min: 0,
        max: 1,
        step: 0,
        defaultValue: 0.5,
      ),
      series: [
        InteractiveSeries(label: 'Curva', expression: 't * x'),
      ],
      toggleable: false,
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: InteractiveChartView(payload: payload))),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Slider), findsOneWidget);
  });
}
