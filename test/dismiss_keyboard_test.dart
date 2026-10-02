import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/screens/login_screen.dart';
import 'package:math_app/widgets/dismiss_keyboard.dart';

void main() {
  // Nei test `defaultTargetPlatform` è android e il tap è col dito: è
  // esattamente il caso in cui il default di Flutter non toglie il focus, quindi
  // i casi qui sotto sono rossi senza `DismissKeyboard`.

  const fieldKey = Key('campo');
  const outsideKey = Key('fuori');

  Future<FocusNode> pumpHarness(WidgetTester tester) async {
    final node = FocusNode(debugLabel: 'campo');
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DismissKeyboard(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              TextField(key: fieldKey, focusNode: node),
              const SizedBox(height: 400),
              const Text('fuori dal campo', key: outsideKey),
            ],
          ),
        ),
      ),
    );
    return node;
  }

  testWidgets('tap fuori dal campo: la tastiera scende', (tester) async {
    final node = await pumpHarness(tester);

    await tester.tap(find.byKey(fieldKey));
    await tester.pump();
    expect(node.hasFocus, isTrue);

    await tester.tap(find.byKey(outsideKey));
    await tester.pump();
    expect(node.hasFocus, isFalse);
  });

  testWidgets('tap dentro il campo: il focus resta', (tester) async {
    final node = await pumpHarness(tester);

    await tester.tap(find.byKey(fieldKey));
    await tester.pump();
    await tester.tap(find.byKey(fieldKey));
    await tester.pump();

    expect(node.hasFocus, isTrue);
  });

  testWidgets('trascinamento fuori dal campo: il focus resta', (tester) async {
    final node = await pumpHarness(tester);

    await tester.tap(find.byKey(fieldKey));
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(outsideKey)),
    );
    await gesture.moveBy(const Offset(0, 120));
    await gesture.up();
    await tester.pump();

    expect(node.hasFocus, isTrue);
  });

  testWidgets('su LoginScreen il tap fuori toglie il focus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DismissKeyboard(child: child!),
        home: const LoginScreen(),
      ),
    );

    final field = find.byType(TextFormField).first;
    await tester.tap(field);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.tap(find.text('Bentornato'));
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isFalse,
    );
  });
}
