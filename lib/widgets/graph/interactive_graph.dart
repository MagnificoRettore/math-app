import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../haptics.dart';
import '../../models/multifunction_box/box_payload.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text.dart';
import '../math_text.dart';
import 'graph_layout.dart';
import 'graph_params.dart';
import 'graph_scale.dart';
import 'graph_view.dart';

/// Il grafico con i suoi slider: ogni parametro (`params`) ha uno slider che
/// ne cambia il valore, e il grafico si ridisegna subito.
///
/// Un parametro con `animate` ha anche un tasto che lo fa scorrere da solo, da
/// un estremo all'altro e ritorno; toccare lo slider lo ferma. Col movimento
/// ridotto il tasto non c'è: i valori si cambiano solo a mano.
///
/// Un punto con `draggable` si trascina sul grafico: ha attorno un anello e,
/// mosso, cambia i parametri che sono le sue coordinate (portati sullo scatto
/// più vicino, dentro `[min, max]`). Gli slider degli stessi parametri si
/// muovono con lui, e `"slider": false` li nasconde se bastano i punti.
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

  /// Il punto che si sta trascinando (indice dell'elemento) e dove sta il dito,
  /// in pixel del grafico: il dito si segue in pixel, il punto va a scatti.
  int? _dragging;
  Offset _finger = Offset.zero;

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

  void _dragStart(DragHandle h, Offset at) {
    if (_playing != null) setState(_stop);
    AppHaptics.selectionClick();
    setState(() {
      _dragging = h.itemIndex;
      _finger = at;
    });
  }

  void _dragUpdate(DragHandle h, Offset delta, GraphScale scale) {
    _finger += delta;
    final next = {..._values};
    for (final (name, data) in [
      (h.xParam, scale.xFromPx(_finger.dx)),
      (h.yParam, scale.yFromPx(_finger.dy)),
    ]) {
      if (name == null) continue;
      final p = widget.payload.params.firstWhere((q) => q.name == name);
      next[name] = snapParam(p, data);
    }
    if (next.entries.any((e) => e.value != _values[e.key])) {
      AppHaptics.selectionClick();
      setState(() => _values = next);
    }
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

  /// L'anello attorno a un punto trascinabile, grande abbastanza per il dito.
  Widget? _handle(
    DragHandle h,
    GraphPayload resolved,
    CartesianLayout layout,
    bool reduced,
  ) {
    // Il punto è fuori dal dominio, o un elemento non si è capito: niente anello.
    if (h.itemIndex >= resolved.items.length) return null;
    final item = resolved.items[h.itemIndex];
    if (item is! GraphPoint) return null;
    final s = layout.scale;
    if (!s.containsX(item.at.x) || !s.containsY(item.at.y)) return null;
    final px = Offset(s.xToPx(item.at.x), s.yToPx(item.at.y));
    final c = AppColors.of(context);
    final active = _dragging == h.itemIndex;
    final color = graphColor(c, item.colorKey, h.itemIndex);
    const hit = 48.0;
    return Positioned(
      left: px.dx - hit / 2,
      top: px.dy - hit / 2,
      width: hit,
      height: hit,
      child: Semantics(
        label: item.label.isEmpty
            ? 'Punto trascinabile'
            : 'Punto ${item.label}, trascinabile',
        // `EagerGestureRecognizer`: il dito che tocca l'anello vince subito
        // l'arena. Un trascinamento («pan») perderebbe contro lo swipe della
        // lezione e lo scorrimento della card, che hanno una soglia più bassa,
        // e il punto non si muoverebbe mai in orizzontale. I movimenti si
        // leggono con un `Listener`, che li riceve comunque.
        child: RawGestureDetector(
          gestures: {
            EagerGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                  EagerGestureRecognizer.new,
                  (_) {},
                ),
          },
          child: Listener(
            key: Key('drag-${h.itemIndex}'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _dragStart(h, px),
            onPointerMove: (e) => _dragUpdate(h, e.delta, s),
            onPointerUp: (_) => setState(() => _dragging = null),
            onPointerCancel: (_) => setState(() => _dragging = null),
            child: Center(
              child: AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.fast),
                curve: AppMotion.standard,
                width: active ? 34 : 26,
                height: active ? 34 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: active ? 0.22 : 0.12),
                  border: Border.all(color: color, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.payload;
    final reduced = AppMotion.reduced(context);
    final resolved = resolveGraph(payload, _values);
    final handles = dragHandles(payload);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (handles.isEmpty)
          GraphView(payload: resolved)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final layout = CartesianLayout.of(
                resolved,
                constraints.maxWidth,
                textScale: textScaleFactorOf(context),
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  GraphView(payload: resolved),
                  for (final h in handles)
                    ?_handle(h, resolved, layout, reduced),
                ],
              );
            },
          ),
        for (final p in payload.params)
          if (p.slider)
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
