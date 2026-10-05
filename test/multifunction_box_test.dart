import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/models/multifunction_box/box_type.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';

void main() {
  group('BoxType', () {
    test('fromString mappa tutte le chiavi valide', () {
      expect(BoxType.fromString('image'), BoxType.image);
      expect(BoxType.fromString('math_formula'), BoxType.mathFormula);
    });

    test('fromString ignora maiuscole', () {
      expect(BoxType.fromString('IMAGE'), BoxType.image);
      expect(BoxType.fromString('Math_Formula'), BoxType.mathFormula);
    });

    test('fromString con valore ignoto ricade su image', () {
      expect(BoxType.fromString('video'), BoxType.image);
    });
  });

  group('MultifunctionBox image', () {
    test('round-trip da json a json preserva i campi', () {
      final box = MultifunctionBox.fromJson({
        'id': 'img-1',
        'box_type': 'image',
        'title': 'Grafico illustrato',
        'payload': {'source': 'assets/images/figura.png'},
      });
      expect(box.id, 'img-1');
      expect(box.boxType, BoxType.image);
      expect(box.title, 'Grafico illustrato');
      final payload = box.payload as ImageBoxPayload;
      expect(payload.source, 'assets/images/figura.png');
      final json = box.toJson()['payload'] as Map<String, dynamic>;
      expect(json, {'source': 'assets/images/figura.png'});
      expect(box.toJson()['box_type'], 'image');
    });

    test('source assente produce stringa vuota', () {
      final box = MultifunctionBox.fromJson({
        'id': 'img-2',
        'box_type': 'image',
      });
      expect((box.payload as ImageBoxPayload).source, '');
      expect(box.toJson()['payload'], {'source': ''});
    });
  });

  group('MultifunctionBox math_formula', () {
    test('round-trip preserva tex e dimensione', () {
      final box = MultifunctionBox.fromJson({
        'id': 'formula-1',
        'box_type': 'math_formula',
        'title': 'Formula di risoluzione',
        'payload': {
          'tex': r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
          'fontSizeMultiplier': 1.4,
        },
      });
      final payload = box.payload as MathFormulaPayload;
      expect(payload.tex, r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}');
      expect(payload.fontSizeMultiplier, 1.4);
      final json = box.toJson()['payload'] as Map<String, dynamic>;
      expect(json['tex'], r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}');
      expect(json['fontSizeMultiplier'], 1.4);
    });

    test('hidden di default è true e round-trip', () {
      final box = MultifunctionBox.fromJson({
        'id': 'formula-3',
        'box_type': 'math_formula',
        'payload': {'tex': 'x + 1'},
      });
      final payload = box.payload as MathFormulaPayload;
      expect(payload.hidden, isTrue);
      expect(box.toJson()['payload'].containsKey('hidden'), isFalse);

      final box2 = MultifunctionBox.fromJson({
        'id': 'formula-4',
        'box_type': 'math_formula',
        'payload': {'tex': 'x + 1', 'hidden': false},
      });
      final payload2 = box2.payload as MathFormulaPayload;
      expect(payload2.hidden, isFalse);
      expect(
        (box2.toJson()['payload'] as Map<String, dynamic>)['hidden'],
        isFalse,
      );
    });

    test('anche il grafico è hidden di default', () {
      final box = MultifunctionBox.fromJson({
        'id': 'g',
        'box_type': 'graph',
        'payload': {
          'items': [
            {'type': 'function', 'expr': 'x'},
          ],
        },
      });
      expect((box.payload as GraphPayload).hidden, isTrue);
      final card = MultifunctionBox.fromJson({
        'id': 'g',
        'box_type': 'graph',
        'payload': {'hidden': false},
      });
      expect((card.payload as GraphPayload).hidden, isFalse);
    });
  });

  group('robustezza', () {
    test('box_type sconosciuto ricade su image senza errore', () {
      final box = MultifunctionBox.fromJson({
        'id': 'box-1',
        'box_type': 'video',
        'payload': {'source': 'assets/images/x.png'},
      });
      expect(box.boxType, BoxType.image);
      expect(box.payload, isA<ImageBoxPayload>());
    });

    test('json completamente vuoto produce default senza errore', () {
      final box = MultifunctionBox.fromJson(const {});
      expect(box.id, '');
      expect(box.boxType, BoxType.image);
      expect((box.payload as ImageBoxPayload).source, '');
    });

    test('campi sconosciuti nel json vengono ignorati', () {
      final box = MultifunctionBox.fromJson({
        'id': 'box-2',
        'box_type': 'math_formula',
        'is_expandable': true,
        'payload': {'tex': 'x', 'mode': 'inline', 'align': 'left'},
      });
      expect(box.boxType, BoxType.mathFormula);
      expect((box.payload as MathFormulaPayload).tex, 'x');
    });
  });
}
