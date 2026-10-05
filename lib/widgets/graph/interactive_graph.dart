import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../haptics.dart';
import '../../models/multifunction_box/box_payload.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text.dart';
import '../math_text.dart';
import 'graph_params.dart';
import 'graph_view.dart';

/// Il grafico con i suoi slider: ogni parametro (`params`) ha uno slider che
/// ne cambia il valore, e il grafico si ridisegna subito.
///
/// Un parametro con `animate` ha anche un tasto che lo fa scorrere da solo, da
/// un estremo all'altro e ritorno; toccare lo slider lo ferma. Col movimento
/// ridotto il tasto non c'è: i valori si cambiano solo a mano.
///
/// Gli assi non si muovono: un grafico con parametri deve dire `x` e `y`, perché
/// i domini automatici seguirebbero la curva e la scena salterebbe a ogni
/// scatto. Il disegno è quello di [GraphView] e l'entrata parte una volta sola,
/// al montaggio.
class InteractiveGraph extends StatefulWidget {
  final GraphPayload payload;

  const InteractiveGraph({super.key, required this.payload});

  @override
  State<InteractiveGraph> createState() => _InteractiveGraphState();
}

class _InteractiveGraphState extends State<InteractiveGraph>
    with SingleTickerProviderStateMixin {
  late Map<String, double> _values = defaultParamValues(widget.payload);

  /// Quanto dura un'andata da un estremo all'altro.
  static const _sweep = Duration(seconds: 4);

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: _sweep,
  )..addListener(_onTick);

  /// Il parametro che sta scorrendo da solo, se c'è.
  GraphParam? _playing;

  void _onTick() {
    final p = _playing;
    if (p == null) return;
    setState(() {
      _values = {..._values, p.name: p.min + (p.max - p.min) * _anim.value};
    });
  }

  @override
  void didUpdateWidget(covariant InteractiveGraph old) {
    super.didUpdateWidget(old);
    // Un grafico diverso (un'altra lezione, un ricarica) riparte dai suoi valori.
    if (old.payload.source != widget.payload.source) {
      _stop();
      _values = defaultParamValues(widget.payload);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _stop() {
    _anim.stop();
    _playing = null;
  }

  void _set(GraphParam p, double value) {
    if (_playing != null) _stop();
    setState(() => _values = {..._values, p.name: value});
  }

  void _togglePlay(GraphParam p) {
    AppHaptics.selectionClick();
    if (_playing?.name == p.name) {
      setState(_stop);
      return;
    }
    _stop();
    setState(() => _playing = p);
    // Parte da dove si trova lo slider.
    _anim
      ..value = ((_values[p.name]! - p.min) / (p.max - p.min)).clamp(0.0, 1.0)
      ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.payload;
    final reduced = AppMotion.reduced(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GraphView(payload: resolveGraph(payload, _values)),
        for (final p in payload.params)
          _Control(
            key: Key('param-${p.name}'),
            param: p,
            value: _values[p.name]!,
            playing: _playing?.name == p.name,
            showPlay: p.animate && !reduced,
            reservePlay: payload.params.any((q) => q.animate) && !reduced,
            onChanged: (v) => _set(p, v),
            onPlay: () => _togglePlay(p),
          ),
      ],
    );
  }
}

class _Control extends StatelessWidget {
  final GraphParam param;
  final double value;
  final bool playing;
  final bool showPlay;

  /// Lascia lo spazio del tasto anche a chi non lo ha, così gli slider di tutti
  /// i parametri sono larghi uguale.
  final bool reservePlay;
  final ValueChanged<double> onChanged;
  final VoidCallback onPlay;

  const _Control({
    super.key,
    required this.param,
    required this.value,
    required this.playing,
    required this.showPlay,
    required this.reservePlay,
    required this.onChanged,
    required this.onPlay,
  });

  /// Il valore scritto con tante cifre quante ne ha lo scatto: 0.5 → «1.5»,
  /// 0.25 → «1.25», 1 → «2».
  String get _text {
    var decimals = 0;
    var s = param.step;
    while (decimals < 4 && (s - s.roundToDouble()).abs() > 1e-9) {
      s *= 10;
      decimals++;
    }
    return value.toStringAsFixed(decimals).replaceFirst('-', '−');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final size = AppText.label * textScaleFactorOf(context);
    final divisions = ((param.max - param.min) / param.step).round();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          // L'etichetta e il valore, sempre larghi uguale: lo slider non si
          // sposta mentre il numero cambia cifre.
          SizedBox(
            width: 84 * textScaleFactorOf(context),
            child: Math.tex(
              '${param.label} = $_text',
              textStyle: TextStyle(fontSize: size, color: c.textPrimary),
              options: MathOptions(fontSize: size, color: c.textPrimary),
              onErrorFallback: (_) => Text(
                '${param.label} = $_text',
                style: TextStyle(fontSize: size),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: c.accent,
                inactiveTrackColor: c.border,
                thumbColor: c.accent,
                overlayColor: c.accent.withValues(alpha: 0.12),
                trackHeight: 4,
                // Con uno scatto fine le tacche sarebbero decine: si vede solo
                // la barra.
                tickMarkShape: SliderTickMarkShape.noTickMark,
              ),
              child: Slider(
                value: value.clamp(param.min, param.max),
                min: param.min,
                max: param.max,
                divisions: divisions > 0 ? divisions : null,
                semanticFormatterCallback: (_) => '${param.name} $_text',
                onChanged: onChanged,
              ),
            ),
          ),
          if (!showPlay && reservePlay) const SizedBox(width: 48),
          if (showPlay)
            IconButton(
              key: Key('param-play-${param.name}'),
              tooltip: playing ? 'Ferma' : 'Anima ${param.name}',
              onPressed: onPlay,
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: c.accent,
              ),
            ),
        ],
      ),
    );
  }
}
