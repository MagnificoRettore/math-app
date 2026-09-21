import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/widgets/notes_text.dart';

Future<void> _pump(WidgetTester tester, String data) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: NotesText(data))),
    ),
  );
}

RichText _richContaining(WidgetTester tester, String text) {
  final matches = tester
      .widgetList<RichText>(find.byType(RichText))
      .where((r) => (r.text as TextSpan).toPlainText().contains(text));
  expect(matches.length, greaterThan(0), reason: 'nessun RichText con "$text"');
  return matches.first;
}

TextStyle _spanStyle(WidgetTester tester, String expected) {
  final rich = _richContaining(tester, expected);
  TextStyle? found;

  void walk(List<InlineSpan>? spans) {
    if (found != null) return;
    for (final span in spans ?? const <InlineSpan>[]) {
      if (span is TextSpan) {
        if (span.text == expected) {
          found = span.style;
          return;
        }
        walk(span.children);
      }
    }
  }

  walk((rich.text as TextSpan).children);
  expect(found, isNotNull, reason: 'span "$expected" non trovato');
  return found!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('titolo usa font 28 e peso 800', (tester) async {
    await _pump(tester, '# Ciao');
    final style = _spanStyle(tester, 'Ciao');
    expect(style.fontSize, 28);
    expect(style.fontWeight, FontWeight.w800);
  });

  testWidgets('intestazione usa font 22 e peso 700', (tester) async {
    await _pump(tester, '## Sezione');
    final style = _spanStyle(tester, 'Sezione');
    expect(style.fontSize, 22);
    expect(style.fontWeight, FontWeight.w700);
  });

  testWidgets('sottointestazione usa font 17 e peso 600', (tester) async {
    await _pump(tester, '### Sottosezione');
    final style = _spanStyle(tester, 'Sottosezione');
    expect(style.fontSize, 17);
    expect(style.fontWeight, FontWeight.w600);
  });

  testWidgets('corpo usa il font di base', (tester) async {
    await _pump(tester, 'Testo normale');
    final style = _spanStyle(tester, 'Testo normale');
    expect(style.fontSize, 17);
    expect(style.fontWeight, FontWeight.w400);
  });

  testWidgets('elenco puntato mostra il pallino', (tester) async {
    await _pump(tester, '- primo elemento\n- secondo elemento');
    expect(find.text('•'), findsNWidgets(2));
    expect(_spanStyle(tester, 'primo elemento').fontWeight, FontWeight.w400);
  });

  testWidgets('blocco monostile usa famiglia monospace', (tester) async {
    await _pump(tester, '`ax + b = 0`');
    final spans =
        (_richContaining(tester, 'ax + b = 0').text as TextSpan).children!;
    expect(
      spans.any((s) => s is TextSpan && s.style?.fontFamily == 'monospace'),
      isTrue,
      reason: 'atteso un segmento monospace',
    );
  });

  testWidgets('allineamento centro applica TextAlign.center', (tester) async {
    await _pump(tester, '::center Centrato');
    final rich = _richContaining(tester, 'Centrato');
    expect(rich.textAlign, TextAlign.center);
  });

  testWidgets('allineamento su riga propria vale per il blocco successivo', (
    tester,
  ) async {
    await _pump(tester, '::center\nTesto centrato');
    final rich = _richContaining(tester, 'Testo centrato');
    expect(rich.textAlign, TextAlign.center);
  });

  testWidgets('allineamento destro applica TextAlign.right', (tester) async {
    await _pump(tester, '::right A destra');
    final rich = _richContaining(tester, 'A destra');
    expect(rich.textAlign, TextAlign.right);
  });

  testWidgets('grassetto, corsivo, sottolineato e barrato', (tester) async {
    await _pump(tester, '**bold** *italic* __under__ ~~strike~~');
    expect(_spanStyle(tester, 'bold').fontWeight, FontWeight.w700);
    expect(_spanStyle(tester, 'italic').fontStyle, FontStyle.italic);
    expect(_spanStyle(tester, 'under').decoration, TextDecoration.underline);
    expect(_spanStyle(tester, 'strike').decoration, TextDecoration.lineThrough);
  });

  testWidgets('stili combinabili dentro un solo run', (tester) async {
    await _pump(tester, '**__combo__**');
    final style = _spanStyle(tester, 'combo');
    expect(style.fontWeight, FontWeight.w700);
    expect(style.decoration, TextDecoration.underline);
  });

  testWidgets('matematica inline genera WidgetSpan', (tester) async {
    await _pump(tester, r'Soluzione: $$x = 2$$');
    final rich = _richContaining(tester, 'Soluzione');
    final children = (rich.text as TextSpan).children!;
    expect(
      children.any((s) => s is WidgetSpan),
      isTrue,
      reason: 'atteso un WidgetSpan con la formula',
    );
  });

  testWidgets('contenuto misto come nelle card non va in errore', (
    tester,
  ) async {
    await _pump(
      tester,
      r'# Titolo'
      '\n'
      r'Testo con **bold** e $$x^2$$.'
      '\n'
      '- voce 1\n- voce 2'
      '\n'
      r'::center'
      '\n'
      r'$$a = b$$'
      '\n'
      r'`code` fine.',
    );
    expect(tester.takeException(), isNull);
  });
}
