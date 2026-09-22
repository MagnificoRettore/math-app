import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/widgets/expression_evaluator.dart';

void main() {
  group('ExpressionEvaluator espressioni valide', () {
    test('somma e sottrazione', () {
      expect(ExpressionEvaluator.evaluate('2 + 3 - 1'), 4);
    });

    test('moltiplicazione e divisione', () {
      expect(ExpressionEvaluator.evaluate('6 / 3 * 2'), 4);
    });

    test('priorità esponente', () {
      expect(ExpressionEvaluator.evaluate('2 + 3 ^ 2'), 11);
    });

    test('parentesi', () {
      expect(ExpressionEvaluator.evaluate('(2 + 3) * 4'), 20);
    });

    test('parentesi annidate', () {
      expect(ExpressionEvaluator.evaluate('2 * (3 + (4 - 1))'), 12);
    });

    test('unario meno', () {
      expect(ExpressionEvaluator.evaluate('-3 + 5'), 2);
    });

    test('doppio unario meno', () {
      expect(ExpressionEvaluator.evaluate('--4'), 4);
    });

    test('decimali', () {
      expect(ExpressionEvaluator.evaluate('1.5 + 2.25'), closeTo(3.75, 1e-9));
    });

    test('modulo', () {
      expect(ExpressionEvaluator.evaluate('7 % 3'), 1);
    });

    test('variabile x', () {
      expect(ExpressionEvaluator.evaluate('2 * x + 1', x: 3), 7);
    });

    test('variabile t nella espressione quadratica', () {
      expect(ExpressionEvaluator.evaluate('t * x * x', x: 2, t: 3), 12);
    });

    test('spazi opzionali', () {
      expect(ExpressionEvaluator.evaluate('  10 - 4 '), 6);
    });
  });

  group('ExpressionEvaluator errori ricadono a zero', () {
    test('stringa vuota', () {
      expect(ExpressionEvaluator.evaluate(''), 0.0);
    });

    test('divisione per zero', () {
      expect(ExpressionEvaluator.evaluate('1 / 0'), 0.0);
    });

    test('modulo per zero', () {
      expect(ExpressionEvaluator.evaluate('1 % 0'), 0.0);
    });

    test('variabile ignota', () {
      expect(ExpressionEvaluator.evaluate('PI * 2'), 0.0);
    });

    test('parentesi non chiusa', () {
      expect(ExpressionEvaluator.evaluate('(2 + 3'), 0.0);
    });

    test('parentesi vuota', () {
      expect(ExpressionEvaluator.evaluate('()'), 0.0);
    });

    test('operatore mancante', () {
      expect(ExpressionEvaluator.evaluate('2 +'), 0.0);
    });

    test('carattere non supportato', () {
      expect(ExpressionEvaluator.evaluate('2 & 3'), 0.0);
    });

    test('token in mezzo', () {
      expect(ExpressionEvaluator.evaluate('2 3'), 0.0);
    });

    test('numero malformato', () {
      expect(ExpressionEvaluator.evaluate('1.2.3'), 0.0);
    });

    test('potenza non finita', () {
      expect(ExpressionEvaluator.evaluate('10 ^ 1000'), 0.0);
    });

    test('parentesi estreme non vanno in errore', () {
      final deep = '${'(' * 100000}1${')' * 100000}';
      expect(() => ExpressionEvaluator.evaluate(deep), returnsNormally);
    });
  });
}
