import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../haptics.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import 'expression_evaluator.dart';

/// Calcolatrice scientifica non modale, ancorata al basso della lezione.
///
/// Scivola su dal basso, lascia il contenuto sottostante scrollabile in
/// parallelo e si chiude trascinandola verso il basso oppure con [onClose].
class ScientificCalculatorSheet extends StatefulWidget {
  final VoidCallback onClose;

  const ScientificCalculatorSheet({super.key, required this.onClose});

  @override
  State<ScientificCalculatorSheet> createState() =>
      _ScientificCalculatorSheetState();
}

class _ScientificCalculatorSheetState extends State<ScientificCalculatorSheet>
    with TickerProviderStateMixin {
  /// Oltre questa frazione dell'altezza, lasciata, la calcolatrice si chiude;
  /// prima, torna su.
  static const _dismissFraction = 0.35;
  static const _dismissVelocity = 700.0;

  final GlobalKey _sheetKey = GlobalKey();
  double? _sheetHeight;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));
  // 0..1, solo per il ritorno: lo spostamento in pixel sta in [_dragOffset]
  // (un `AnimationController` non può tenerlo, il suo valore si ferma a 1).
  late final AnimationController _snapBack = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );

  double _dragOffset = 0;
  bool _interactive = false;
  bool _dismissing = false;

  /// L'espressione come lista di token, non come stringa: ⌫ toglie `sin(` in
  /// un colpo, e la moltiplicazione implicita si decide fra token interi.
  final List<String> _tokens = [];
  String _result = '0';

  /// `true` subito dopo `=`: un numero comincia un'espressione nuova, un
  /// operatore continua da `Ans`.
  bool _fresh = false;
  bool _deg = false;

  /// Il tasto 2nd: cambia le etichette dei tasti che hanno una seconda
  /// funzione e si spegne dopo averne usata una, come sulle calcolatrici.
  bool _second = false;

  /// L'ultimo risultato valido (`Ans`) e la memoria (`M`).
  double _ans = 0;
  double _memory = 0;

  String get _expr => _tokens.join();

  @override
  void initState() {
    super.initState();
    _entrance
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _interactive = true);
        }
      })
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        setState(() => _sheetHeight = box.size.height);
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _snapBack.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_interactive || _dismissing) return;
    _snapBack.stop();
    // Solo verso il basso: sopra la posizione di riposo non va.
    setState(
      () => _dragOffset = (_dragOffset + details.delta.dy).clamp(0, 2000),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_interactive || _dismissing) return;
    final fast =
        details.primaryVelocity != null &&
        details.primaryVelocity! > _dismissVelocity;
    final height = _sheetHeight;
    final beyondThreshold =
        height != null && _dragOffset > height * _dismissFraction;
    if (fast || beyondThreshold) {
      _dismiss();
    } else if (_dragOffset > 0) {
      final from = _dragOffset;
      _snapBack
        ..removeListener(_onSnap)
        ..addListener(_onSnap)
        ..value = 0
        ..animateTo(
          1,
          duration: AppMotion.duration(context, AppMotion.medium),
          curve: AppMotion.standard,
        );
      _snapFrom = from;
    }
  }

  double _snapFrom = 0;

  void _onSnap() =>
      setState(() => _dragOffset = _snapFrom * (1 - _snapBack.value));

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    AppHaptics.mediumImpact();
    _entrance.reverse().whenComplete(widget.onClose);
  }

  static const _binary = ['+', '−', '×', '÷', '^'];
  static const _postfix = ['²', '^(−1)', '!', '%'];

  static bool _isNumberPart(String t) => t == '.' || _isDigit(t);
  static bool _isDigit(String t) =>
      t.length == 1 && t.codeUnitAt(0) >= 0x30 && t.codeUnitAt(0) <= 0x39;

  /// Un token dopo cui un valore è completo: `2`, `)`, `π`, `Ans`, `5!`…
  static bool _endsValue(String t) =>
      _isNumberPart(t) ||
      t == ')' ||
      t == 'π' ||
      t == 'e' ||
      t == 'Ans' ||
      t == 'M' ||
      _postfix.contains(t);

  /// Un token che comincia un valore: numeri, costanti, `(` e funzioni.
  static bool _startsValue(String t) =>
      _isNumberPart(t) ||
      t.endsWith('(') ||
      t == 'π' ||
      t == 'e' ||
      t == 'Ans' ||
      t == 'M';

  String? get _last => _tokens.isEmpty ? null : _tokens.last;

  /// Le cifre (e il punto) in coda: il numero che si sta scrivendo.
  int get _numberStart {
    var i = _tokens.length;
    while (i > 0 && _isNumberPart(_tokens[i - 1])) {
      i--;
    }
    return i;
  }

  /// Un valore nuovo: dopo `=` comincia un'espressione da capo.
  void _value(String token) {
    setState(() {
      if (_fresh) _tokens.clear();
      _tokens.add(token);
      _fresh = false;
      _second = false;
    });
  }

  void _dot() {
    setState(() {
      if (_fresh) _tokens.clear();
      _fresh = false;
      final start = _numberStart;
      // Un punto solo per numero: `1.2.3` non è un numero.
      if (_tokens.sublist(start).contains('.')) return;
      if (start == _tokens.length) _tokens.add('0');
      _tokens.add('.');
    });
  }

  /// Dopo `=` o su un'espressione vuota, l'operatore parte dal risultato di
  /// prima, come sulle calcolatrici: `2 + 3 =` e poi `× 2` fa 10.
  bool _continueFromAns() {
    if (_fresh || _tokens.isEmpty) {
      _tokens
        ..clear()
        ..add('Ans');
      _fresh = false;
      return true;
    }
    return false;
  }

  void _operator(String op) {
    setState(() {
      _second = false;
      final last = _last;
      // Il meno all'inizio, dopo `(` o dopo un altro operatore è il segno.
      if (op == '−' &&
          !_fresh &&
          (last == null || last.endsWith('(') || '×÷^'.contains(last))) {
        _tokens.add(op);
        return;
      }
      _continueFromAns();
      if (_binary.contains(_last)) {
        _tokens.removeLast();
        if (_tokens.isEmpty) return;
      }
      if (_last!.endsWith('(')) return;
      _tokens.add(op);
    });
  }

  /// `x²`, `1/x`, `n!` e `%` si applicano al valore che li precede.
  void _postfixOp(String op) {
    setState(() {
      _second = false;
      _continueFromAns();
      if (!_endsValue(_last!)) return;
      _tokens.add(op);
    });
  }

  void _open() => _value('(');

  void _close() {
    final opens = _tokens.where((t) => t.endsWith('(')).length;
    final closes = _tokens.where((t) => t == ')').length;
    if (opens <= closes || _last == null || !_endsValue(_last!)) return;
    setState(() => _tokens.add(')'));
  }

  void _clear() {
    setState(() {
      _tokens.clear();
      _result = '0';
      _fresh = false;
      _second = false;
    });
  }

  void _delete() {
    if (_tokens.isEmpty) return;
    setState(() {
      _tokens.removeLast();
      _fresh = false;
      if (_tokens.isEmpty) _result = '0';
    });
  }

  /// ± cambia il segno del numero che si sta scrivendo; senza numero in coda
  /// mette il meno, che è il segno del valore che segue.
  void _toggleSign() {
    setState(() {
      _second = false;
      if (_fresh) {
        _tokens
          ..clear()
          ..add('Ans');
        _fresh = false;
      }
      final start = _numberStart;
      if (start == _tokens.length) {
        if (_last == null || !_endsValue(_last!)) _tokens.add('−');
        return;
      }
      final before = start > 0 ? _tokens[start - 1] : null;
      final unary =
          before == '−' &&
          (start < 2 ||
              !_endsValue(_tokens[start - 2]) ||
              _tokens[start - 2] == '(');
      if (unary) {
        _tokens.removeAt(start - 1);
      } else {
        _tokens.insert(start, '−');
      }
    });
  }

  void _equals() {
    if (_tokens.isEmpty) return;
    setState(() {
      _closeAll();
      final value = _evaluate();
      if (value == null) {
        _result = 'Errore';
      } else {
        _ans = value;
        _result = _format(value);
      }
      _fresh = true;
      _second = false;
    });
  }

  /// M+ e M− calcolano l'espressione e la sommano alla memoria, come un `=`.
  void _memoryAdd(double sign) {
    if (_tokens.isEmpty) return;
    setState(() {
      _closeAll();
      final value = _evaluate();
      if (value == null) {
        _result = 'Errore';
      } else {
        _ans = value;
        _memory += sign * value;
        _result = _format(value);
      }
      _fresh = true;
      _second = false;
    });
  }

  void _memoryClear() => setState(() {
    _memory = 0;
    _second = false;
  });

  void _closeAll() {
    final opens = _tokens.where((t) => t.endsWith('(')).length;
    final closes = _tokens.where((t) => t == ')').length;
    for (var i = closes; i < opens; i++) {
      _tokens.add(')');
    }
  }

  double? _evaluate() =>
      ExpressionEvaluator.tryEvaluate(_toEval(_tokens), deg: _deg);

  /// I token in sintassi dell'[ExpressionEvaluator], con il `*` della
  /// moltiplicazione implicita (`2π`, `2(3)`, `)(`) fra un valore che finisce
  /// e uno che comincia.
  String _toEval(List<String> tokens) {
    final out = StringBuffer();
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (i > 0) {
        final prev = tokens[i - 1];
        final sameNumber = _isNumberPart(prev) && _isNumberPart(t);
        if (!sameNumber && _endsValue(prev) && _startsValue(t)) out.write('*');
      }
      out.write(switch (t) {
        '×' => '*',
        '÷' => '/',
        '−' => '-',
        'π' => 'pi',
        '√(' => 'sqrt(',
        '²' => '^2',
        '^(−1)' => '^(-1)',
        '%' => '/100',
        'Ans' => _literal(_ans),
        'M' => _literal(_memory),
        _ => t,
      });
    }
    return out.toString();
  }

  /// Un double scritto per il parser, che non legge la notazione `1e-7`.
  static String _literal(double v) {
    final s = v.toString();
    final e = s.indexOf('e');
    if (e < 0) return '($s)';
    return '(${s.substring(0, e)}*10^(${s.substring(e + 1)}))';
  }

  String _format(double value) {
    if (value == 0) return '0';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.round().toString();
    }
    final abs = value.abs();
    if (abs >= 1e-6 && abs < 1e15) {
      var s = value.toStringAsFixed(10);
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
      return s;
    }
    return value.toStringAsExponential(6);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismiss,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            key: const ValueKey('calc-sheet'),
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: SlideTransition(
              position: _slide,
              child: AnimatedBuilder(
                animation: _snapBack,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: child,
                ),
                child: _buildSheet(context, c),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheet(BuildContext context, AppPalette c) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: _sheetKey,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Calcolatrice',
                      style: TextStyle(
                        fontSize: AppText.bodyLarge,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'trascina giù per chiudere',
                      style: TextStyle(
                        fontSize: AppText.caption,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDisplay(context, c),
              const SizedBox(height: 10),
              _buildKeypad(context, c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplay(BuildContext context, AppPalette c) {
    return Container(
      key: const ValueKey('calc-display'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildModeChip(c),
              // Come sul display di una calcolatrice: la memoria piena si vede.
              if (_memory != 0) ...[
                const SizedBox(width: 6),
                Text(
                  'M',
                  key: const ValueKey('calc-memory'),
                  style: TextStyle(
                    fontSize: AppText.micro,
                    fontWeight: FontWeight.w500,
                    color: c.accent,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                // Un'espressione lunga scorre dal fondo invece di tagliarsi con i
                // puntini: l'ellissi mostrerebbe `sin(90…` per `sin(900)`.
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _expr.isEmpty ? '0' : _expr,
                    key: const ValueKey('calc-expr'),
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: AppText.titleMedium,
                      color: c.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  _result,
                  key: const ValueKey('calc-result'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: AppText.hero,
                    fontWeight: FontWeight.w500,
                    color: _result == 'Errore' ? c.hard : c.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(AppPalette c) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _deg = !_deg);
          AppHaptics.selectionClick();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          key: const ValueKey('calc-mode'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _deg ? 'DEG' : 'RAD',
            style: TextStyle(
              fontSize: AppText.micro,
              fontWeight: FontWeight.w500,
              color: c.accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context, AppPalette c) {
    final second = _second;
    return Column(
      children: [
        _row(context, c, [
          _key(
            '2nd',
            () => setState(() => _second = !_second),
            primary: second,
            accent: !second,
          ),
          // Etichette che i font sanno disegnare: Plus Jakarta Sans non ha `ˣ ʸ`, e sul
          // web il carattere di riserva andrebbe scaricato.
          _fn(second ? 'asin' : 'sin', second ? 'asin(' : 'sin('),
          _fn(second ? 'acos' : 'cos', second ? 'acos(' : 'cos('),
          _fn(second ? 'atan' : 'tan', second ? 'atan(' : 'tan('),
          _key(second ? 'e' : 'π', () => _value(second ? 'e' : 'π')),
        ]),
        _row(context, c, [
          _key('x²', () => _postfixOp('²'), accent: true),
          _key('x^y', () => _operator('^'), accent: true),
          _fn('√', '√('),
          _key('1/x', () => _postfixOp('^(−1)'), accent: true),
          _key('n!', () => _postfixOp('!'), accent: true),
        ]),
        _row(context, c, [
          _fn(second ? 'e^x' : 'ln', second ? 'e^(' : 'ln('),
          _fn(second ? '10^x' : 'log', second ? '10^(' : 'log('),
          _key('(', _open),
          _key(')', _close),
          _key('%', () => _postfixOp('%')),
        ]),
        _row(context, c, [
          _key('MC', _memoryClear),
          _key('MR', () => _value('M')),
          _key('M+', () => _memoryAdd(1)),
          _key('M−', () => _memoryAdd(-1)),
          _key('Ans', () => _value('Ans')),
        ]),
        _row(context, c, [
          _key('7', () => _value('7')),
          _key('8', () => _value('8')),
          _key('9', () => _value('9')),
          _key('⌫', _delete, destructive: true, icon: Icons.backspace_outlined),
          _key('AC', _clear, destructive: true),
        ]),
        _row(context, c, [
          _key('4', () => _value('4')),
          _key('5', () => _value('5')),
          _key('6', () => _value('6')),
          _key('×', () => _operator('×'), operator: true),
          _key('÷', () => _operator('÷'), operator: true),
        ]),
        _row(context, c, [
          _key('1', () => _value('1')),
          _key('2', () => _value('2')),
          _key('3', () => _value('3')),
          _key('+', () => _operator('+'), operator: true),
          _key('−', () => _operator('−'), operator: true),
        ]),
        _row(context, c, [
          _key('0', () => _value('0')),
          _key('.', _dot),
          _key('±', _toggleSign),
          _key('=', _equals, primary: true, flex: 2),
        ]),
      ],
    );
  }

  Widget _row(BuildContext context, AppPalette c, List<Widget> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(flex: (keys[i] as _CalcKey).flex, child: keys[i]),
          ],
        ],
      ),
    );
  }

  Widget _fn(String label, String token) =>
      _key(label, () => _value(token), accent: true);

  Widget _key(
    String label,
    VoidCallback onTap, {
    int flex = 1,
    bool accent = false,
    bool operator = false,
    bool primary = false,
    bool destructive = false,
    IconData? icon,
  }) {
    return _CalcKey(
      label: label,
      onTap: onTap,
      flex: flex,
      accent: accent,
      operator: operator,
      primary: primary,
      destructive: destructive,
      icon: icon,
    );
  }
}

/// Un tasto nello stile del design: le cifre bianche col bordo da 3, gli
/// operatori gialli e `=` indaco col gradino pieno sotto, le funzioni lilla,
/// AC e ⌫ in rosso.
class _CalcKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final int flex;
  final bool accent;
  final bool operator;
  final bool primary;
  final bool destructive;

  /// Al posto dell'etichetta: `⌫` non c'è in Plus Jakarta Sans.
  final IconData? icon;

  const _CalcKey({
    required this.label,
    required this.onTap,
    this.flex = 1,
    this.accent = false,
    this.operator = false,
    this.primary = false,
    this.destructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (background, foreground, border, step) = primary
        ? (c.accent, Colors.white, null, c.accentDeep)
        : operator
        ? (c.yellow, c.textPrimary, null, c.yellowDeep)
        : destructive
        ? (
            c.hard.withValues(alpha: 0.10),
            c.hard,
            c.hard.withValues(alpha: 0.4),
            null,
          )
        : accent
        ? (c.accentSoft, c.accent, null, null)
        : (c.surface, c.textPrimary, c.border, null);
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      label: icon == null ? null : label,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: border == null ? null : Border.all(color: border, width: 3),
          boxShadow: [
            if (step != null)
              BoxShadow(color: step, offset: const Offset(0, 3)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              onTap();
              AppHaptics.selectionClick();
            },
            borderRadius: radius,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 20, color: foreground)
                  : Text(
                      label,
                      // Il carattere del testo e non quello dei titoli: Outfit non ha `π` né `√`.
                      style: TextStyle(
                        fontSize: AppText.titleMedium,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
