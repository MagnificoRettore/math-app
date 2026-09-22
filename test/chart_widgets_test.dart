import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/widgets/chart_widgets.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 300, height: 220, child: child)),
    ),
  );
}

void main() {
  final palette = [const Color(0xFF007AFF), const Color(0xFF9C27B0)];

  testWidgets('istogramma con due serie non va in errore', (tester) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(
          painter: BarChartPainter(
            series: const [
              ChartSeries(label: 'Serie A', values: [3, 5, 2]),
              ChartSeries(label: 'Serie B', values: [1, 4, 7]),
            ],
            xLabels: const ['Gen', 'Feb', 'Mar'],
            colors: palette,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('istogramma a dati vuoti non va in errore', (tester) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(
          painter: BarChartPainter(series: const [], colors: palette),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('istogramma con valori zero non va in errore', (tester) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(
          painter: BarChartPainter(
            series: const [
              ChartSeries(label: 'Leggera', values: [0, 0, 0]),
            ],
            colors: palette,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grafico a linee non va in errore', (tester) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(
          painter: LineChartPainter(
            series: const [
              ChartSeries(label: 'Crescita', values: [1, 2, 4, 8]),
            ],
            xLabels: const ['A', 'B', 'C', 'D'],
            colors: palette,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grafico a torta con valori negativi non va in errore', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(
          painter: PieChartPainter(
            values: const [30, 50, 20],
            labels: const ['X', 'Y', 'Z'],
            colors: palette,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grafico a torta con somma zero non va in errore', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(
          painter: PieChartPainter(values: const [0, 0], colors: palette),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grafico a torta con valori misti negativi non va in errore', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(
          painter: PieChartPainter(
            values: const [10, -5, 20],
            labels: const ['A', 'B', 'C'],
            colors: palette,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('istogramma con molte categorie non va in errore', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(
          painter: BarChartPainter(
            series: const [
              ChartSeries(label: 'S', values: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
            ],
            xLabels: const [
              'Gen',
              'Feb',
              'Mar',
              'Apr',
              'Mag',
              'Giu',
              'Lug',
              'Ago',
              'Set',
              'Ott',
            ],
            colors: palette,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
