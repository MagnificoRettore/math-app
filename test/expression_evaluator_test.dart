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

  group('ExpressionEvaluator funzioni e costanti scientifiche', () {
    test('costante pi', () {
      expect(ExpressionEvaluator.evaluate('pi'), closeTo(3.14159, 1e-5));
    });

    test('costante e', () {
      expect(ExpressionEvaluator.evaluate('e'), closeTo(2.71828, 1e-5));
    });

    test('sin(pi/2) = 1', () {
      expect(ExpressionEvaluator.evaluate('sin(pi / 2)'), closeTo(1, 1e-9));
    });

    test('cos(0) = 1', () {
      expect(ExpressionEvaluator.evaluate('cos(0)'), 1);
    });

    test('tan(0) = 0', () {
      expect(ExpressionEvaluator.evaluate('tan(0)'), 0);
    });

    test('ln(e) = 1', () {
      expect(ExpressionEvaluator.evaluate('ln(e)'), closeTo(1, 1e-9));
    });

    test('log(100) = 2 in base 10', () {
      expect(ExpressionEvaluator.evaluate('log(100)'), closeTo(2, 1e-9));
    });

    test('sqrt(16) = 4', () {
      expect(ExpressionEvaluator.evaluate('sqrt(16)'), 4);
    });

    test('abs(-3) = 3', () {
      expect(ExpressionEvaluator.evaluate('abs(-3)'), 3);
    });

    test('exp(0) = 1', () {
      expect(ExpressionEvaluator.evaluate('exp(0)'), 1);
    });

    test('funzioni annidate', () {
      expect(
        ExpressionEvaluator.evaluate('sqrt(abs(-4 * 4))'),
        closeTo(4, 1e-9),
      );
    });

    test('sqrt(pi)^2 = pi', () {
      expect(
        ExpressionEvaluator.evaluate('sqrt(pi) ^ 2'),
        closeTo(3.14159, 1e-5),
      );
    });
  });

  group('ExpressionEvaluator tryEvaluate distingue errore da zero', () {
    test('valore valido restituisce double', () {
      expect(ExpressionEvaluator.tryEvaluate('2 + 3'), 5);
    });

    test('errore restituisce null', () {
      expect(ExpressionEvaluator.tryEvaluate('()'), isNull);
      expect(ExpressionEvaluator.tryEvaluate('2 +'), isNull);
      expect(ExpressionEvaluator.tryEvaluate('sqrt('), isNull);
    });

    test('divisione per zero restituisce null', () {
      expect(ExpressionEvaluator.tryEvaluate('1 / 0'), isNull);
    });

    test('stringa vuota restituisce null', () {
      expect(ExpressionEvaluator.tryEvaluate(''), isNull);
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
