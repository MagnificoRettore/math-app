import 'dart:math' as math;

/// Valuta espressioni aritmetiche semplici (parser recursive-descent).
///
/// Sintassi supportata: `+ - * / ^ %`, parentesi, numeri decimali,
/// variabili `x` e `t`, costanti `pi`/`e` e funzioni
/// `sin cos tan ln log sqrt abs exp`. Qualsiasi errore o risultato non finito
/// in [evaluate] restituisce `0.0` (mai eccezioni in rendering);
/// [tryEvaluate] distingue invece errore/valore non finito con `null`.
class ExpressionEvaluator {
  const ExpressionEvaluator._();

  static double evaluate(String source, {double x = 0, double t = 0, bool deg = false}) {
    return tryEvaluate(source, x: x, t: t, deg: deg) ?? 0.0;
  }

  /// Come [evaluate] ma restituisce `null` su errore di parsing,
  /// espressione vuota o risultato non finito.
  static double? tryEvaluate(String source, {double x = 0, double t = 0, bool deg = false}) {
    try {
      final tokens = _tokenize(source);
      if (tokens.isEmpty) return null;
      final parser = _Parser(tokens, x: x, t: t, deg: deg);
      final value = parser.parseExpression();
      if (parser.hasMore) return null;
      return value.isFinite ? value : null;
    } on FormatException {
      return null;
    } on StackOverflowError {
      return null;
    }
  }
}

enum _TokenKind { number, variable, operator, leftParen, rightParen }

class _Token {
  final _TokenKind kind;
  final String text;
  final double? value;

  const _Token(this.kind, this.text, [this.value]);
}

List<_Token> _tokenize(String source) {
  final tokens = <_Token>[];
  var i = 0;
  final s = source;
  while (i < s.length) {
    final ch = s[i];
    if (ch == ' ' || ch == '\t' || ch == '\n') {
      i++;
      continue;
    }
    if (_isDigit(ch) || (ch == '.' && i + 1 < s.length && _isDigit(s[i + 1]))) {
      final start = i;
      while (i < s.length && (_isDigit(s[i]) || s[i] == '.')) {
        i++;
      }
      final raw = s.substring(start, i);
      final value = double.tryParse(raw);
      if (value == null) {
        throw FormatException('numero non valido: $raw');
      }
      tokens.add(_Token(_TokenKind.number, raw, value));
      continue;
    }
    if (RegExp(r'[a-zA-Z_]').hasMatch(ch)) {
      final start = i;
      while (i < s.length && RegExp(r'[a-zA-Z0-9_]').hasMatch(s[i])) {
        i++;
      }
      tokens.add(_Token(_TokenKind.variable, s.substring(start, i)));
      continue;
    }
    if ('+-*/^%'.contains(ch)) {
      tokens.add(_Token(_TokenKind.operator, ch));
      i++;
      continue;
    }
    if (ch == '(') {
      tokens.add(const _Token(_TokenKind.leftParen, '('));
      i++;
      continue;
    }
    if (ch == ')') {
      tokens.add(const _Token(_TokenKind.rightParen, ')'));
      i++;
      continue;
    }
    throw FormatException('carattere non supportato: $ch');
  }
  return tokens;
}

bool _isDigit(String ch) {
  final code = ch.codeUnitAt(0);
  return code >= 0x30 && code <= 0x39;
}

class _Parser {
  final List<_Token> tokens;
  final double x;
  final double t;
  final double trigFactor;
  int pos = 0;

  _Parser(this.tokens, {required this.x, required this.t, bool deg = false})
      : trigFactor = deg ? math.pi / 180 : 1;

  bool get hasMore => pos < tokens.length;

  _Token? get peek => pos < tokens.length ? tokens[pos] : null;

  _Token next() {
    if (pos >= tokens.length) {
      throw const FormatException('fine inattesa');
    }
    return tokens[pos++];
  }

  bool _matchOperator(String op) {
    final token = peek;
    if (token == null ||
        token.kind != _TokenKind.operator ||
        token.text != op) {
      return false;
    }
    pos++;
    return true;
  }

  double parseExpression() {
    var value = parseTerm();
    while (true) {
      if (_matchOperator('+')) {
        value += parseTerm();
      } else if (_matchOperator('-')) {
        value -= parseTerm();
      } else {
        return value;
      }
    }
  }

  double parseTerm() {
    var value = parseFactor();
    while (true) {
      if (_matchOperator('*')) {
        value *= parseFactor();
      } else if (_matchOperator('/')) {
        final divisor = parseFactor();
        value = divisor == 0 ? double.infinity : value / divisor;
      } else if (_matchOperator('%')) {
        final divisor = parseFactor();
        value = divisor == 0 ? double.infinity : value % divisor;
      } else {
        return value;
      }
    }
  }

  double parseFactor() {
    final base = parseUnary();
    if (_matchOperator('^')) {
      final exponent = parseFactor();
      return _pow(base, exponent);
    }
    return base;
  }

  double parseUnary() {
    if (_matchOperator('-')) {
      return -parseUnary();
    }
    if (_matchOperator('+')) {
      return parseUnary();
    }
    return parsePrimary();
  }

  double parsePrimary() {
    final token = next();
    switch (token.kind) {
      case _TokenKind.number:
        return token.value ?? 0;
      case _TokenKind.variable:
        return _resolveIdentifier(token.text);
      case _TokenKind.leftParen:
        final value = parseExpression();
        final closing = peek;
        if (closing == null || closing.kind != _TokenKind.rightParen) {
          throw const FormatException('parentesi non chiusa');
        }
        pos++;
        return value;
      default:
        throw const FormatException('token inatteso');
    }
  }

  double _resolveIdentifier(String name) {
    switch (name) {
      case 'x':
        return x;
      case 't':
        return t;
      case 'pi':
        return math.pi;
      case 'e':
        return math.e;
      case 'sin':
      case 'cos':
      case 'tan':
      case 'ln':
      case 'log':
      case 'sqrt':
      case 'abs':
      case 'exp':
        return _callFunction(name);
      default:
        throw FormatException('variabile ignota: $name');
    }
  }

  double _callFunction(String name) {
    final opening = peek;
    if (opening == null || opening.kind != _TokenKind.leftParen) {
      throw FormatException('serve una parentesi dopo $name');
    }
    pos++;
    final arg = parseExpression();
    final closing = peek;
    if (closing == null || closing.kind != _TokenKind.rightParen) {
      throw const FormatException('parentesi non chiusa');
    }
    pos++;
    return _applyFunction(name, arg, trigFactor);
  }

  static double _applyFunction(String name, double arg, double trigFactor) {
    switch (name) {
      case 'sin':
        return math.sin(arg * trigFactor);
      case 'cos':
        return math.cos(arg * trigFactor);
      case 'tan':
        return math.tan(arg * trigFactor);
      case 'ln':
        return math.log(arg);
      case 'log':
        return math.log(arg) / math.ln10;
      case 'sqrt':
        return math.sqrt(arg);
      case 'abs':
        return arg.abs();
      case 'exp':
        return math.exp(arg);
      default:
        throw FormatException('funzione ignota: $name');
    }
  }

  static double _pow(double base, double exponent) {
    final result = math.pow(base, exponent).toDouble();
    return result.isFinite ? result : 0;
  }
}
