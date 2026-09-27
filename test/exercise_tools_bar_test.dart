import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'package:math_app/widgets/exercise_tools_bar.dart';

void main() {
  testWidgets('la barra strumenti è ancorata in basso a sinistra e verticale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(left: 16, bottom: 16, child: ExerciseToolsBar()),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final bar = tester.getRect(find.byType(ExerciseToolsBar));
    expect(bar.bottom, closeTo(600 - 16, 1));
    expect(bar.left, lessThan(400));

    final calc = tester.getRect(find.byIcon(M3EIcons.calculate));
    final functions = tester.getRect(find.byIcon(M3EIcons.functions));
    expect(calc.center.dx, closeTo(functions.center.dx, 1));
    expect(calc.center.dy, lessThan(functions.center.dy));
  });
}
