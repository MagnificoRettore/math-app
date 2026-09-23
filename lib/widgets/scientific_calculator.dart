import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
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
  static const _dismissFraction = 0.5;
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
  late final AnimationController _dragCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => setState(() {}));

  double _dragOffset = 0;
  bool _interactive = false;
  bool _dismissing = false;

  String _expr = '';
  String _result = '0';
  bool _fresh = true;
  bool _deg = false;

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
    _dragCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_interactive || _dismissing) return;
    _dragOffset += details.delta.dy;
    _dragCtrl.value = _dragOffset;
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
      _dragCtrl
        ..value = _dragOffset
        ..animateBack(0);
    }
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    HapticFeedback.mediumImpact();
    _entrance.reverse().whenComplete(widget.onClose);
  }

  void _append(String part) {
    setState(() {
      if (_fresh &&
          part != '(' &&
          part != 'sin(' &&
          part != 'cos(' &&
          part != 'tan(' &&
          part != 'ln(' &&
          part != 'log(' &&
          part != 'sqrt(' &&
          part != 'abs(' &&
          part != 'exp(') {
        _expr = '';
      }
      _expr += part;
      _fresh = false;
    });
  }

  void _clear() {
    setState(() {
      _expr = '';
      _result = '0';
      _fresh = true;
    });
  }

  void _delete() {
    if (_expr.isEmpty) return;
    setState(() {
      _expr = _expr.substring(0, _expr.length - 1);
      if (_expr.isEmpty) _result = '0';
    });
  }

  void _operator(String op) {
    if (_expr.isEmpty && op != '−') return;
    setState(() {
      final last = _expr.isNotEmpty ? _expr[_expr.length - 1] : '';
      if ('+−×÷^%'.contains(last)) {
        _expr = _expr.substring(0, _expr.length - 1);
      }
      if (op == '=') {
        _evaluate();
      } else {
        _expr += op;
        _fresh = false;
      }
    });
  }

  void _toggleSign() {
    setState(() {
      if (_expr.isEmpty) {
        _expr = '−';
        _fresh = false;
        return;
      }
      final match = RegExp(r'[0-9.]+$').firstMatch(_expr);
      if (match != null) {
        final value = match.group(0)!;
        final prefix = _expr.substring(0, match.start);
        _expr =
            prefix + (value.startsWith('−') ? value.substring(1) : '−$value');
      } else if (_expr.startsWith('−')) {
        _expr = _expr.substring(1);
      } else {
        _expr = '−$_expr';
      }
      _fresh = false;
    });
  }

  void _evaluate() {
    if (_expr.isEmpty) return;
    final closed = _autoClose(_expr);
    if (closed != _expr) {
      setState(() => _expr = closed);
    }
    final value = ExpressionEvaluator.tryEvaluate(_toEval(closed), deg: _deg);
    if (value == null) {
      _result = 'Errore';
    } else {
      _result = _format(value);
    }
    _fresh = true;
  }

  String _autoClose(String expr) {
    final opens = '('.allMatches(expr).length;
    final closes = ')'.allMatches(expr).length;
    if (opens <= closes) return expr;
    return expr + ')' * (opens - closes);
  }

  String _toEval(String expr) {
    return expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAll('√(', 'sqrt(');
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
                animation: _dragCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _dragCtrl.value),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'trascina giù per chiudere',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _expr.isEmpty ? '0' : _expr,
                  key: const ValueKey('calc-expr'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 17,
                    color: c.textSecondary,
                    fontFamily: 'monospace',
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
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
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
          HapticFeedback.selectionClick();
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context, AppPalette c) {
    return Column(
      children: [
        _row(context, c, [
          _fn('sin', 'sin('),
          _fn('cos', 'cos('),
          _fn('tan', 'tan('),
          _fn('ln', 'ln('),
          _fn('log', 'log('),
        ]),
        _row(context, c, [
          _fn('√', '√('),
          _key('x²', () => _append('^2'), accent: true),
          _key('(', () => _append('(')),
          _key(')', () => _append(')')),
          _key('π', () => _append('π')),
        ]),
        _row(context, c, [
          _fn('abs', 'abs('),
          _fn('exp', 'exp('),
          _key('AC', _clear, destructive: true),
          _key('⌫', _delete, destructive: true),
          _key('%', () => _operator('%')),
        ]),
        _row(context, c, [
          _key('e', () => _append('e')),
          _key('7', () => _append('7')),
          _key('8', () => _append('8')),
          _key('9', () => _append('9')),
          _key('×', () => _operator('×'), accent: true),
        ]),
        _row(context, c, [
          _key('4', () => _append('4')),
          _key('5', () => _append('5')),
          _key('6', () => _append('6')),
          _key('−', () => _operator('−'), accent: true),
          _key('±', _toggleSign, accent: true),
        ]),
        _row(context, c, [
          _key('1', () => _append('1')),
          _key('2', () => _append('2')),
          _key('3', () => _append('3')),
          _key('+', () => _operator('+'), accent: true),
          _key('^', () => _append('^')),
        ]),
        _row(context, c, [
          _key('0', () => _append('0'), flex: 3),
          _key('.', () => _append('.')),
          _key('=', () => _operator('='), primary: true, flex: 3),
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

  Widget _fn(String label, String tex) =>
      _key(label, () => _append(tex), accent: true);

  Widget _key(
    String label,
    VoidCallback onTap, {
    int flex = 1,
    bool accent = false,
    bool primary = false,
    bool destructive = false,
  }) {
    return _CalcKey(
      label: label,
      onTap: onTap,
      flex: flex,
      accent: accent,
      primary: primary,
      destructive: destructive,
    );
  }
}

class _CalcKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final int flex;
  final bool accent;
  final bool primary;
  final bool destructive;

  const _CalcKey({
    required this.label,
    required this.onTap,
    this.flex = 1,
    this.accent = false,
    this.primary = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final Color background;
    final Color foreground;
    final Color? borderColor;
    if (primary) {
      background = c.accent;
      foreground = c.surface;
      borderColor = null;
    } else if (destructive) {
      background = c.hard.withValues(alpha: 0.10);
      foreground = c.hard;
      borderColor = c.hard.withValues(alpha: 0.3);
    } else if (accent) {
      background = c.accentSoft;
      foreground = c.accent;
      borderColor = null;
    } else {
      background = c.surface;
      foreground = c.textPrimary;
      borderColor = c.border;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          HapticFeedback.selectionClick();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: borderColor == null ? null : Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
