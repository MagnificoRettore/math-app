/// Dove sta ogni cosa in un grafico: domini, misura, margini, tick, campioni.
///
/// Logica pura come [GraphScale]: il painter disegna quello che trova qui, e i
/// test misurano un grafico senza montarlo.
library;

import 'dart:math' as math;

import '../../models/multifunction_box/box_payload.dart';
import '../expression_evaluator.dart';
import 'graph_scale.dart';

/// Rapporto altezza/larghezza dei grafici con gli assi a unità diverse.
const double kGraphFitRatio = 0.75;

/// Limiti dell'altezza di un grafico a unità uguali, in frazione della
/// larghezza: oltre, il dominio corto si allarga invece di schiacciare il
/// grafico.
const double kGraphMinRatio = 0.5;
const double kGraphMaxRatio = 1.3;

/// Spazio per le frecce degli assi, a destra e in alto.
const double _kArrowRoom = 16;

/// Distanza minima fra due numeri sull'asse, in pixel (scalata col testo).
const double _kMinTickGapX = 28;
const double _kMinTickGapY = 20;

/// Il dominio di riserva quando il JSON non dice niente.
const (double, double) _kDefaultRange = (-10, 10);

class CartesianLayout {
  final double width;
  final double height;
  final GraphScale scale;
  final List<GraphTick> xTicks;
  final List<GraphTick> yTicks;

  /// Un numero ogni quanti tick, per non accavallarli.
  final int xLabelEvery;
  final int yLabelEvery;

  /// I tracciati di ogni elemento, nello stesso ordine di [GraphPayload.items]:
  /// i tratti di una funzione o di una curva (spezzati nei buchi), il contorno
  /// chiuso di una circonferenza. Vuoto per gli altri.
  final List<List<List<GraphXY>>> samples;

  /// Le forme da riempire di ogni elemento: aree, regioni, poligoni e cerchi
  /// pieni. Una regione può essere fatta di più pezzi.
  final List<List<List<GraphXY>>> fills;

  /// I bordi di ogni regione: una curva per condizione, tratteggiata se la
  /// condizione è stretta (`<`, `>`).
  final List<List<GraphEdge>> edges;

  const CartesianLayout({
    required this.width,
    required this.height,
    required this.scale,
    required this.xTicks,
    required this.yTicks,
    required this.xLabelEvery,
    required this.yLabelEvery,
    required this.samples,
    this.fills = const [],
    this.edges = const [],
  });

  /// `true` se l'origine è dentro il grafico: lì si scrive «O».
  bool get showsOrigin => scale.containsX(0) && scale.containsY(0);

  /// La retta [line] tagliata sul dominio, o `null` se non lo attraversa.
  (GraphXY, GraphXY)? clip(GraphLine line) {
    final s = scale;
    if (line.x != null) {
      return s.containsX(line.x!)
          ? (GraphXY(line.x!, s.minY), GraphXY(line.x!, s.maxY))
          : null;
    }
    if (line.y != null) {
      return s.containsY(line.y!)
          ? (GraphXY(s.minX, line.y!), GraphXY(s.maxX, line.y!))
          : null;
    }
    final (a, b) = line.through!;
    if ((b.x - a.x).abs() < 1e-12) {
      return clip(GraphLine.vertical(a.x));
    }
    final m = (b.y - a.y) / (b.x - a.x);
    double yAt(double x) => a.y + m * (x - a.x);
    double xAt(double y) => a.x + (y - a.y) / m;
    final hits = <GraphXY>[
      if (s.containsY(yAt(s.minX))) GraphXY(s.minX, yAt(s.minX)),
      if (s.containsY(yAt(s.maxX))) GraphXY(s.maxX, yAt(s.maxX)),
      if (m != 0 && s.containsX(xAt(s.minY))) GraphXY(xAt(s.minY), s.minY),
      if (m != 0 && s.containsX(xAt(s.maxY))) GraphXY(xAt(s.maxY), s.maxY),
    ]..sort((p, q) => p.x.compareTo(q.x));
    if (hits.length < 2) return null;
    return (hits.first, hits.last);
  }

  static CartesianLayout of(
    GraphPayload payload,
    double width, {
    double textScale = 1,
  }) {
    final xRange = payload.x ?? _autoX(payload) ?? _kDefaultRange;
    final samples = <List<List<GraphXY>>>[];
    // Il dominio y automatico guarda i valori delle funzioni: si campiona una
    // prima volta senza fascia, poi di nuovo sul dominio deciso.
    final yRange = payload.y ?? _autoY(payload, xRange) ?? _kDefaultRange;

    var (minX, maxX) = xRange;
    var (minY, maxY) = yRange;
    double height;
    if (payload.aspect == GraphAspect.equal) {
      final ratio = (maxY - minY) / (maxX - minX);
      final clamped = ratio.clamp(kGraphMinRatio, kGraphMaxRatio);
      height = width * clamped;
      // Stessa unità sui due assi: se l'altezza è stata limitata, si allarga
      // il dominio più corto attorno al suo centro.
      if (ratio < clamped) {
        final need = (maxX - minX) * clamped;
        final mid = (minY + maxY) / 2;
        minY = mid - need / 2;
        maxY = mid + need / 2;
      } else if (ratio > clamped) {
        final need = (maxY - minY) / clamped;
        final mid = (minX + maxX) / 2;
        minX = mid - need / 2;
        maxX = mid + need / 2;
      }
    } else {
      height = width * kGraphFitRatio;
    }

    // I numeri stanno accanto agli assi; se un asse è sul bordo (lo zero è
    // fuori dal dominio), i suoi numeri hanno bisogno di un margine fuori.
    final left = minX >= 0 ? 30 * textScale : 10.0;
    final bottom = minY >= 0 ? 22 * textScale : 10.0;
    final rect = RectD(
      left,
      _kArrowRoom + 6 * textScale,
      math.max(1, width - left - _kArrowRoom),
      math.max(1, height - bottom - _kArrowRoom - 6 * textScale),
    );
    final scale = GraphScale(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      rect: rect,
    );

    final stepX = payload.grid ?? niceStep((maxX - minX) / (rect.width / 48));
    final stepY =
        payload.grid ??
        (payload.aspect == GraphAspect.equal
            ? stepX
            : niceStep((maxY - minY) / (rect.height / 40)));
    final xTicks = ticksEvery(minX, maxX, stepX);
    final yTicks = ticksEvery(minY, maxY, stepY);
    final pxPerX = rect.width / (maxX - minX) * stepX;
    final pxPerY = rect.height / (maxY - minY) * stepY;

    final count = math.max(240, (rect.width * 1.5).round());
    final fills = <List<List<GraphXY>>>[];
    final edges = <List<GraphEdge>>[];
    for (final item in payload.items) {
      var stroke = const <List<GraphXY>>[];
      var fill = const <List<GraphXY>>[];
      var edge = const <GraphEdge>[];
      switch (item) {
        case GraphFunction():
          final (from, to) = item.domain ?? (minX, maxX);
          stroke = sampledSegments(
            item.expr,
            math.max(from, minX),
            math.min(to, maxX),
            samples: count,
            yMin: minY,
            yMax: maxY,
          );
        case GraphCurve():
          stroke = _curve(item, scale, count);
        case GraphCircle():
          final ring = _circle(item.center, item.radius);
          stroke = [ring];
          if (item.fill) fill = [ring];
        case GraphPolygon():
          if (item.fill) fill = [item.points];
        case GraphArea():
          fill = _band(
            item.upper,
            item.lower,
            math.max(item.from, minX),
            math.min(item.to, maxX),
            count,
          );
        case GraphRegion():
          (fill, edge) = _region(item, scale, count);
        case GraphPoint() || GraphLine() || GraphSegment() || GraphInterval():
          break;
      }
      samples.add(stroke);
      fills.add(fill);
      edges.add(edge);
    }

    return CartesianLayout(
      width: width,
      height: height,
      scale: scale,
      xTicks: xTicks,
      yTicks: yTicks,
      xLabelEvery: math.max(1, (_kMinTickGapX * textScale / pxPerX).ceil()),
      yLabelEvery: math.max(1, (_kMinTickGapY * textScale / pxPerY).ceil()),
      samples: samples,
      fills: fills,
      edges: edges,
    );
  }

  /// Una curva parametrica campionata su `t`, spezzata dove non esiste o dove
  /// scappa lontano dal dominio (come le funzioni vicino a un asintoto).
  static List<List<GraphXY>> _curve(GraphCurve c, GraphScale s, int count) {
    final (t0, t1) = c.t;
    final out = <List<GraphXY>>[];
    var current = <GraphXY>[];
    for (var i = 0; i < count; i++) {
      final t = t0 + (t1 - t0) * i / (count - 1);
      final x = ExpressionEvaluator.tryEvaluate(c.x, t: t);
      final y = ExpressionEvaluator.tryEvaluate(c.y, t: t);
      final missing =
          x == null ||
          y == null ||
          x < s.minX - s.spanX ||
          x > s.maxX + s.spanX ||
          y < s.minY - s.spanY ||
          y > s.maxY + s.spanY;
      if (missing) {
        if (current.isNotEmpty) out.add(current);
        current = <GraphXY>[];
        continue;
      }
      current.add(GraphXY(x, y));
    }
    if (current.isNotEmpty) out.add(current);
    return out;
  }

  /// Il contorno di una circonferenza, chiuso.
  static List<GraphXY> _circle(GraphXY c, double r) => [
    for (var i = 0; i <= 180; i++)
      GraphXY(
        c.x + r * math.cos(2 * math.pi * i / 180),
        c.y + r * math.sin(2 * math.pi * i / 180),
      ),
  ];

  /// La fascia fra [upper] e [lower] (o l'asse x) da [from] a [to], spezzata
  /// dove una delle due non esiste. Ogni pezzo è un contorno: sopra in
  /// avanti, sotto all'indietro.
  static List<List<GraphXY>> _band(
    String upper,
    String? lower,
    double from,
    double to,
    int count,
  ) {
    if (!(to > from)) return const [];
    final out = <List<GraphXY>>[];
    var top = <GraphXY>[], bottom = <GraphXY>[];
    void close() {
      if (top.length > 1) out.add([...top, ...bottom.reversed]);
      top = <GraphXY>[];
      bottom = <GraphXY>[];
    }

    for (var i = 0; i < count; i++) {
      final x = from + (to - from) * i / (count - 1);
      final hi = ExpressionEvaluator.tryEvaluate(upper, x: x);
      final lo = lower == null
          ? 0.0
          : ExpressionEvaluator.tryEvaluate(lower, x: x);
      if (hi == null || lo == null) {
        close();
        continue;
      }
      top.add(GraphXY(x, hi));
      bottom.add(GraphXY(x, lo));
    }
    close();
    return out;
  }

  /// La regione: a ogni `x` campionata va dal più alto dei bordi di sotto al
  /// più basso dei bordi di sopra, tagliata sul dominio. Si spezza dove una
  /// condizione non si calcola o dove i bordi si incrociano. I bordi sono le
  /// curve delle condizioni su tutto il grafico, come sul quaderno.
  static (List<List<GraphXY>>, List<GraphEdge>) _region(
    GraphRegion region,
    GraphScale s,
    int count,
  ) {
    var minX = s.minX, maxX = s.maxX;
    final edges = <GraphEdge>[];
    for (final c in region.where.where((c) => !c.onY)) {
      final v = ExpressionEvaluator.tryEvaluate(c.expr);
      if (v == null) return (const [], const []);
      if (c.compare.above) {
        minX = math.max(minX, v);
      } else {
        maxX = math.min(maxX, v);
      }
      if (s.containsX(v)) {
        edges.add(
          GraphEdge([
            [GraphXY(v, s.minY), GraphXY(v, s.maxY)],
          ], dashed: c.compare.strict),
        );
      }
    }
    final onY = region.where.where((c) => c.onY).toList();
    for (final c in onY) {
      edges.add(
        GraphEdge(
          sampledSegments(
            c.expr,
            s.minX,
            s.maxX,
            samples: count,
            yMin: s.minY,
            yMax: s.maxY,
          ),
          dashed: c.compare.strict,
        ),
      );
    }
    if (!(maxX > minX)) return (const [], edges);

    final out = <List<GraphXY>>[];
    var top = <GraphXY>[], bottom = <GraphXY>[];
    void close() {
      if (top.length > 1) out.add([...top, ...bottom.reversed]);
      top = <GraphXY>[];
      bottom = <GraphXY>[];
    }

    for (var i = 0; i < count; i++) {
      final x = minX + (maxX - minX) * i / (count - 1);
      var lo = s.minY, hi = s.maxY;
      var ok = true;
      for (final c in onY) {
        final v = ExpressionEvaluator.tryEvaluate(c.expr, x: x);
        if (v == null) {
          ok = false;
          break;
        }
        if (c.compare.above) {
          lo = math.max(lo, v);
        } else {
          hi = math.min(hi, v);
        }
      }
      if (!ok || !(hi > lo)) {
        close();
        continue;
      }
      top.add(GraphXY(x, hi));
      bottom.add(GraphXY(x, lo));
    }
    close();
    return (out, edges);
  }

  /// Il dominio x dai punti e dalle rette, se il JSON non lo dice e ci sono.
  static (double, double)? _autoX(GraphPayload payload) {
    final xs = <double>[
      for (final i in payload.items)
        if (i is GraphPoint)
          i.at.x
        else if (i is GraphLine && i.x != null)
          i.x!
        else if (i is GraphFunction && i.domain != null) ...[
          i.domain!.$1,
          i.domain!.$2,
        ] else
          ..._geometry(i).map((p) => p.x),
    ];
    if (xs.isEmpty) return null;
    final r = niceRange(xs.reduce(math.min), xs.reduce(math.max));
    return (math.min(r.min, 0), math.max(r.max, 0));
  }

  /// Il dominio y dai valori delle funzioni e dai punti. Si usano i valori fra
  /// il 5° e il 95° percentile: un asintoto non schiaccia tutto il resto.
  static (double, double)? _autoY(GraphPayload payload, (double, double) x) {
    final ys = <double>[
      for (final i in payload.items)
        if (i is GraphPoint)
          i.at.y
        else if (i is GraphLine && i.y != null)
          i.y!
        else if (i is GraphFunction)
          for (final seg in sampledSegments(i.expr, x.$1, x.$2, samples: 120))
            for (final p in seg) p.y
        else
          ..._geometry(i).map((p) => p.y),
    ]..sort();
    if (ys.isEmpty) return null;
    final lo = ys[(ys.length * 0.05).floor()];
    final hi = ys[math.min(ys.length - 1, (ys.length * 0.95).ceil())];
    final r = niceRange(lo, hi);
    return (math.min(r.min, 0), math.max(r.max, 0));
  }
}

/// I punti che una figura occupa, per i domini automatici: i vertici, gli
/// estremi, il riquadro di una circonferenza, i campioni di una curva.
Iterable<GraphXY> _geometry(GraphItem item) => switch (item) {
  GraphCircle(:final center, :final radius) => [
    GraphXY(center.x - radius, center.y - radius),
    GraphXY(center.x + radius, center.y + radius),
  ],
  GraphPolygon(:final points) => points,
  GraphSegment(:final from, :final to) => [from, to],
  GraphCurve() => [
    for (var i = 0; i <= 60; i++)
      if (ExpressionEvaluator.tryEvaluate(
            item.x,
            t: item.t.$1 + (item.t.$2 - item.t.$1) * i / 60,
          )
          case final x?)
        if (ExpressionEvaluator.tryEvaluate(
              item.y,
              t: item.t.$1 + (item.t.$2 - item.t.$1) * i / 60,
            )
            case final y?)
          GraphXY(x, y),
  ],
  GraphArea(:final from, :final to) => [GraphXY(from, 0), GraphXY(to, 0)],
  _ => const [],
};

/// Il bordo di una regione: i suoi tratti e se è tratteggiato.
class GraphEdge {
  final List<List<GraphXY>> segments;
  final bool dashed;

  const GraphEdge(this.segments, {this.dashed = false});
}

class BarsLayout {
  final double width;
  final double height;
  final GraphScale scale;
  final List<GraphTick> yTicks;
  final int groups;

  /// Una categoria scritta ogni quante, per non accavallarle.
  final int labelEvery;

  const BarsLayout({
    required this.width,
    required this.height,
    required this.scale,
    required this.yTicks,
    required this.groups,
    required this.labelEvery,
  });

  static BarsLayout of(
    GraphPayload payload,
    double width, {
    double textScale = 1,
  }) {
    final values = [
      0.0,
      for (final s in payload.series)
        for (final v in s.values) ?v,
    ];
    final r = payload.y != null
        ? (min: payload.y!.$1, max: payload.y!.$2)
        : niceRange(values.reduce(math.min), values.reduce(math.max));
    final height = width * kGraphFitRatio;
    final left = 32 * textScale;
    final bottom = 24 * textScale;
    final rect = RectD(
      left,
      _kArrowRoom + 6 * textScale,
      math.max(1, width - left - 8),
      math.max(1, height - bottom - _kArrowRoom - 6 * textScale),
    );
    final groups = barGroupCount(payload.categories.length, [
      for (final s in payload.series) s.values.length,
    ]);
    final step = payload.grid ?? niceStep((r.max - r.min) / (rect.height / 40));
    final cell = rect.width / groups;
    return BarsLayout(
      width: width,
      height: height,
      scale: GraphScale(
        minX: 0,
        maxX: groups.toDouble(),
        minY: r.min,
        maxY: r.max,
        rect: rect,
      ),
      yTicks: ticksEvery(r.min, r.max, step),
      groups: groups,
      labelEvery: math.max(1, (24 * textScale / cell).ceil()),
    );
  }
}

/// La retta numerica: una riga per intervallo, dall'alto nell'ordine del
/// JSON (come le disequazioni di un sistema sul quaderno), e la retta sotto.
/// I punti stanno sulla retta: l'insieme `{3, 7}` si disegna così.
///
/// I numeri sotto la retta sono gli estremi e i punti, scritti come nel
/// JSON (`5/3` resta `5/3`); con `grid` anche quelli a passo regolare.
class NumberLineLayout {
  final double width;
  final double height;

  /// Conta solo la x: la y in pixel la danno [rowY] e [axis].
  final GraphScale scale;

  /// La y in pixel della retta.
  final double axis;
  final double rowGap;
  final double labelRoom;
  final List<GraphTick> ticks;

  /// La riga di ogni elemento, nell'ordine di [GraphPayload.items]; `null`
  /// per i punti, che stanno sulla retta.
  final List<int?> rows;

  const NumberLineLayout({
    required this.width,
    required this.height,
    required this.scale,
    required this.axis,
    required this.rowGap,
    required this.labelRoom,
    required this.ticks,
    required this.rows,
  });

  /// La y in pixel dell'elemento [index]: la sua riga, o la retta.
  double rowY(int index) => switch (rows[index]) {
    final row? => labelRoom + rowGap * row,
    null => axis,
  };

  static NumberLineLayout of(
    GraphPayload payload,
    double width, {
    double textScale = 1,
  }) {
    final marks = <double, String>{};
    for (final item in payload.items) {
      if (item is GraphInterval) {
        if (item.from case final v?) marks[v] = item.fromText;
        if (item.to case final v?) marks[v] = item.toText;
      } else if (item is GraphPoint) {
        marks[item.at.x] = formatTick(item.at.x);
      }
    }
    final (double, double) range;
    if (payload.x != null) {
      range = payload.x!;
    } else if (marks.isEmpty) {
      range = (-5, 5);
    } else {
      final lo = marks.keys.reduce(math.min), hi = marks.keys.reduce(math.max);
      // Spazio oltre gli estremi: un intervallo verso l'infinito deve
      // vedersi andare avanti.
      final pad = math.max((hi - lo) * 0.3, 1.0);
      range = (lo - pad, hi + pad);
    }
    // Fra due righe ci sta un'etichetta con una frazione.
    final rowGap = 36 * textScale;
    final labelRoom = 30 * textScale;
    var count = 0;
    final rows = [
      for (final item in payload.items) item is GraphInterval ? count++ : null,
    ];
    final axis = labelRoom + rowGap * count;
    final rect = RectD(14, 0, math.max(1, width - 14 - _kArrowRoom - 8), axis);
    final scale = GraphScale(
      minX: range.$1,
      maxX: range.$2,
      minY: 0,
      maxY: 1,
      rect: rect,
    );
    final ticks = [
      for (final e in marks.entries)
        if (scale.containsX(e.key)) GraphTick(e.key, e.value),
    ];
    if (payload.grid case final step?) {
      // I numeri del passo regolare cedono il posto a quelli degli estremi.
      final marked = [...ticks];
      // Uno ogni quanti, contando dallo zero, se il passo è troppo fitto.
      final every = math.max(
        1,
        (_kMinTickGapX * textScale / (rect.width * step / scale.spanX)).ceil(),
      );
      for (final t in ticksEvery(range.$1, range.$2, step)) {
        if ((t.value / step).round() % every != 0) continue;
        final near = marked.any(
          (m) =>
              (scale.xToPx(m.value) - scale.xToPx(t.value)).abs() <
              24 * textScale,
        );
        if (!near) ticks.add(t);
      }
    }
    ticks.sort((a, b) => a.value.compareTo(b.value));
    return NumberLineLayout(
      width: width,
      height: axis + 26 * textScale,
      scale: scale,
      axis: axis,
      rowGap: rowGap,
      labelRoom: labelRoom,
      ticks: ticks,
      rows: rows,
    );
  }
}
