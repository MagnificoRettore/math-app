part of '../box_payload.dart';

/// Il piano su cui sta un grafico.
enum GraphPlane {
  /// Il piano cartesiano: assi per l'origine, funzioni, punti, rette.
  cartesian,

  /// Le barre: un valore per categoria.
  bars,

  /// La retta numerica: intervalli e punti, per disequazioni e insiemi.
  numberLine;

  static GraphPlane fromString(String value) => switch (value.toLowerCase()) {
    'bars' => GraphPlane.bars,
    'numberline' => GraphPlane.numberLine,
    _ => GraphPlane.cartesian,
  };

  String get key => name;

  String get label => switch (this) {
    GraphPlane.cartesian => 'Piano cartesiano',
    GraphPlane.bars => 'Grafico a barre',
    GraphPlane.numberLine => 'Retta numerica',
  };
}

/// Come il grafico prende l'altezza.
enum GraphAspect {
  /// Un rapporto fisso: gli assi hanno unità diverse, per le funzioni.
  fit,

  /// La stessa unità sui due assi: una circonferenza è rotonda.
  equal;

  static GraphAspect fromString(String value) =>
      value.toLowerCase() == 'equal' ? GraphAspect.equal : GraphAspect.fit;

  String get key => name;

  String get label => switch (this) {
    GraphAspect.fit => 'Adattato',
    GraphAspect.equal => 'Stessa unità',
  };
}

enum GraphLineStyle {
  solid,
  dashed;

  static GraphLineStyle fromString(String? value) =>
      value?.toLowerCase() == 'dashed' ? GraphLineStyle.dashed : solid;

  String get key => name;

  String get label => switch (this) {
    GraphLineStyle.solid => 'Continua',
    GraphLineStyle.dashed => 'Tratteggiata',
  };
}

/// Un punto del piano, in coordinate dei dati (non in pixel).
class GraphXY {
  final double x;
  final double y;

  const GraphXY(this.x, this.y);

  /// `[x, y]` dal JSON, o `null` se non sono due numeri.
  static GraphXY? fromJson(Object? raw) {
    if (raw is! List || raw.length < 2) return null;
    final x = raw[0], y = raw[1];
    if (x is! num || y is! num) return null;
    return GraphXY(x.toDouble(), y.toDouble());
  }

  List<double> toJson() => [x, y];
}

/// Un intervallo `[da, a]` dal JSON, o `null` se non lo è.
(double, double)? _range(Object? raw) {
  final xy = GraphXY.fromJson(raw);
  if (xy == null || !(xy.y > xy.x)) return null;
  return (xy.x, xy.y);
}

/// Un elemento del piano cartesiano.
///
/// [label] è LaTeX (senza `$`), [colorKey] un nome della palette dei grafici,
/// [style] continua o tratteggiata. Un `type` sconosciuto non diventa un
/// elemento: [fromJson] restituisce `null` e il grafico lo salta.
sealed class GraphItem {
  final String label;
  final String? colorKey;
  final GraphLineStyle style;

  const GraphItem({
    this.label = '',
    this.colorKey,
    this.style = GraphLineStyle.solid,
  });

  static GraphItem? fromJson(Map<String, dynamic> json) {
    final label = json['label'] as String? ?? '';
    final color = json['color'] as String?;
    final style = GraphLineStyle.fromString(json['style'] as String?);
    switch (json['type']) {
      case 'function':
        final expr = json['expr'] as String? ?? '';
        if (expr.trim().isEmpty) return null;
        return GraphFunction(
          expr: expr,
          domain: _range(json['domain']),
          label: label,
          colorKey: color,
          style: style,
        );
      case 'point':
        // Sulla retta numerica il punto è un numero solo.
        final raw = json['at'];
        final at = raw is num
            ? GraphXY(raw.toDouble(), 0)
            : GraphXY.fromJson(raw);
        if (at == null) return null;
        return GraphPoint(
          at: at,
          guides: json['guides'] == true,
          label: label,
          colorKey: color,
        );
      case 'line':
        final x = json['x'], y = json['y'];
        final through = json['through'];
        if (x is num) {
          return GraphLine.vertical(
            x.toDouble(),
            label: label,
            colorKey: color,
            style: style,
          );
        }
        if (y is num) {
          return GraphLine.horizontal(
            y.toDouble(),
            label: label,
            colorKey: color,
            style: style,
          );
        }
        if (through is List && through.length >= 2) {
          final a = GraphXY.fromJson(through[0]);
          final b = GraphXY.fromJson(through[1]);
          if (a == null || b == null || (a.x == b.x && a.y == b.y)) return null;
          return GraphLine.through(
            a,
            b,
            label: label,
            colorKey: color,
            style: style,
          );
        }
        return null;
      case 'curve':
        final xt = json['x'] as String? ?? '';
        final yt = json['y'] as String? ?? '';
        final t = _range(json['t']);
        if (xt.trim().isEmpty || yt.trim().isEmpty || t == null) return null;
        return GraphCurve(
          x: xt,
          y: yt,
          t: t,
          label: label,
          colorKey: color,
          style: style,
        );
      case 'circle':
        final center = GraphXY.fromJson(json['center']);
        final radius = json['radius'];
        if (center == null || radius is! num || radius <= 0) return null;
        return GraphCircle(
          center: center,
          radius: radius.toDouble(),
          fill: json['fill'] == true,
          label: label,
          colorKey: color,
          style: style,
        );
      case 'segment':
      case 'vector':
        final from = GraphXY.fromJson(json['from']);
        final to = GraphXY.fromJson(json['to']);
        if (from == null || to == null) return null;
        return GraphSegment(
          from: from,
          to: to,
          arrow: json['type'] == 'vector',
          label: label,
          colorKey: color,
          style: style,
        );
      case 'polygon':
        final points = [
          for (final p in json['points'] as List<dynamic>? ?? const [])
            ?GraphXY.fromJson(p),
        ];
        if (points.length < 3) return null;
        return GraphPolygon(
          points: points,
          fill: json['fill'] != false,
          label: label,
          colorKey: color,
          style: style,
        );
      case 'area':
        final from = json['from'], to = json['to'];
        if (from is! num || to is! num || !(to > from)) return null;
        final under = json['under'] as String?;
        final between = json['between'];
        final (String, String)? pair =
            between is List &&
                between.length == 2 &&
                between[0] is String &&
                between[1] is String
            ? (between[0] as String, between[1] as String)
            : null;
        if ((under == null || under.trim().isEmpty) && pair == null) {
          return null;
        }
        return GraphArea(
          upper: pair?.$1 ?? under!,
          lower: pair?.$2,
          from: from.toDouble(),
          to: to.toDouble(),
          label: label,
          colorKey: color,
        );
      case 'interval':
        final set = json['set'];
        if (set is! String) return null;
        return GraphInterval.parse(set, label: label, colorKey: color);
      case 'region':
        final raw = json['where'] as List<dynamic>? ?? const [];
        final conditions = [
          for (final c in raw)
            if (c is String) ?GraphCondition.parse(c),
        ];
        // Una condizione illeggibile salta la regione intera: senza, si
        // colorerebbe una regione più grande di quella scritta.
        if (conditions.isEmpty || conditions.length != raw.length) return null;
        return GraphRegion(where: conditions, label: label, colorKey: color);
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson();

  Map<String, dynamic> _common() => {
    if (label.isNotEmpty) 'label': label,
    if (colorKey != null) 'color': colorKey,
    if (style == GraphLineStyle.dashed) 'style': 'dashed',
  };
}

/// Il grafico di `y = expr(x)`, sul dominio del piano o su [domain].
class GraphFunction extends GraphItem {
  final String expr;
  final (double, double)? domain;

  const GraphFunction({
    required this.expr,
    this.domain,
    super.label,
    super.colorKey,
    super.style,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'function',
    'expr': expr,
    if (domain != null) 'domain': [domain!.$1, domain!.$2],
    ..._common(),
  };
}

/// Un punto, con le proiezioni tratteggiate sugli assi se [guides].
class GraphPoint extends GraphItem {
  final GraphXY at;
  final bool guides;

  const GraphPoint({
    required this.at,
    this.guides = false,
    super.label,
    super.colorKey,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'point',
    'at': at.toJson(),
    if (guides) 'guides': true,
    ..._common(),
  };
}

/// Una retta: verticale (`x = c`), orizzontale (`y = c`) o per due punti.
/// Un asintoto è una retta tratteggiata.
class GraphLine extends GraphItem {
  final double? x;
  final double? y;
  final (GraphXY, GraphXY)? through;

  const GraphLine.vertical(
    double this.x, {
    super.label,
    super.colorKey,
    super.style,
  }) : y = null,
       through = null;

  const GraphLine.horizontal(
    double this.y, {
    super.label,
    super.colorKey,
    super.style,
  }) : x = null,
       through = null;

  const GraphLine.through(
    GraphXY a,
    GraphXY b, {
    super.label,
    super.colorKey,
    super.style,
  }) : through = (a, b),
       x = null,
       y = null;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'line',
    if (x != null) 'x': x,
    if (y != null) 'y': y,
    if (through != null)
      'through': [through!.$1.toJson(), through!.$2.toJson()],
    ..._common(),
  };
}

/// Una curva parametrica `(x(t), y(t))` per `t` in [t]: ellissi, iperboli,
/// spirali.
class GraphCurve extends GraphItem {
  final String x;
  final String y;
  final (double, double) t;

  const GraphCurve({
    required this.x,
    required this.y,
    required this.t,
    super.label,
    super.colorKey,
    super.style,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'curve',
    'x': x,
    'y': y,
    't': [t.$1, t.$2],
    ..._common(),
  };
}

/// Una circonferenza. È rotonda solo con `aspect: equal`.
class GraphCircle extends GraphItem {
  final GraphXY center;
  final double radius;
  final bool fill;

  const GraphCircle({
    required this.center,
    required this.radius,
    this.fill = false,
    super.label,
    super.colorKey,
    super.style,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'circle',
    'center': center.toJson(),
    'radius': radius,
    if (fill) 'fill': true,
    ..._common(),
  };
}

/// Un segmento con i pallini agli estremi, o un vettore con la punta in [to].
class GraphSegment extends GraphItem {
  final GraphXY from;
  final GraphXY to;
  final bool arrow;

  const GraphSegment({
    required this.from,
    required this.to,
    this.arrow = false,
    super.label,
    super.colorKey,
    super.style,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': arrow ? 'vector' : 'segment',
    'from': from.toJson(),
    'to': to.toJson(),
    ..._common(),
  };
}

/// Un poligono chiuso, riempito leggero salvo `fill: false`.
class GraphPolygon extends GraphItem {
  final List<GraphXY> points;
  final bool fill;

  const GraphPolygon({
    required this.points,
    this.fill = true,
    super.label,
    super.colorKey,
    super.style,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'polygon',
    'points': [for (final p in points) p.toJson()],
    if (!fill) 'fill': false,
    ..._common(),
  };
}

/// Un'area da [from] a [to]: fra [upper] e l'asse x, o fra [upper] e [lower].
class GraphArea extends GraphItem {
  final String upper;
  final String? lower;
  final double from;
  final double to;

  const GraphArea({
    required this.upper,
    this.lower,
    required this.from,
    required this.to,
    super.label,
    super.colorKey,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'area',
    if (lower == null) 'under': upper else 'between': [upper, lower],
    'from': from,
    'to': to,
    ..._common(),
  };
}

enum GraphCompare {
  less('<'),
  lessEqual('<='),
  greater('>'),
  greaterEqual('>=');

  const GraphCompare(this.symbol);

  final String symbol;

  /// `<` e `>`: il bordo non appartiene alla regione, e si tratteggia.
  bool get strict => this == less || this == greater;

  /// `>` e `>=`: la variabile sta sopra (o a destra) del bordo.
  bool get above => this == greater || this == greaterEqual;
}

/// Una condizione di una regione: `y ≥ f(x)`, `y < f(x)`, `x ≤ c`, …
///
/// A sinistra la variabile (`x` o `y`), a destra un'espressione: in `x` per le
/// condizioni su `y`, un numero (o un'espressione costante) per quelle su `x`.
class GraphCondition {
  /// `true` per le condizioni su `y`, `false` per quelle su `x`.
  final bool onY;
  final GraphCompare compare;
  final String expr;

  const GraphCondition({
    required this.onY,
    required this.compare,
    required this.expr,
  });

  static final _pattern = RegExp(r'^\s*([xy])\s*(<=|>=|≤|≥|<|>)\s*(.+?)\s*$');

  /// La condizione scritta, o `null` se non è nella forma `x|y op espressione`.
  static GraphCondition? parse(String text) {
    final m = _pattern.firstMatch(text);
    if (m == null) return null;
    final compare = switch (m.group(2)) {
      '<' => GraphCompare.less,
      '<=' || '≤' => GraphCompare.lessEqual,
      '>' => GraphCompare.greater,
      _ => GraphCompare.greaterEqual,
    };
    return GraphCondition(
      onY: m.group(1) == 'y',
      compare: compare,
      expr: m.group(3)!,
    );
  }

  @override
  String toString() => '${onY ? 'y' : 'x'} ${compare.symbol} $expr';
}

/// Una regione del piano: l'intersezione delle condizioni [where]. Il bordo è
/// continuo per `≤` e `≥`, tratteggiato per `<` e `>`.
class GraphRegion extends GraphItem {
  final List<GraphCondition> where;

  const GraphRegion({required this.where, super.label, super.colorKey});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'region',
    'where': [for (final c in where) c.toString()],
    ..._common(),
  };
}

/// Un intervallo della retta numerica, scritto come sul libro: `[-1, 3]`,
/// `]2, +inf[` o `(2, +inf)`. Una parentesi tonda o una quadra girata verso
/// l'esterno esclude l'estremo, una quadra verso l'interno lo include.
/// L'infinito (`-inf`, `+inf`, `∞`) è `null` ed è sempre escluso.
class GraphInterval extends GraphItem {
  final double? from;
  final double? to;
  final bool fromOpen;
  final bool toOpen;

  /// Gli estremi come sono scritti (`5/3`), per i numeri sotto la retta.
  final String fromText;
  final String toText;

  const GraphInterval({
    required this.from,
    required this.to,
    this.fromOpen = false,
    this.toOpen = false,
    this.fromText = '',
    this.toText = '',
    super.label,
    super.colorKey,
  });

  static final _pattern = RegExp(
    r'^\s*([\[\](])\s*([^,;]+?)\s*[,;]\s*([^,;]+?)\s*([\[\])])\s*$',
  );

  /// L'intervallo scritto, o `null` se non si capisce o è vuoto.
  static GraphInterval? parse(
    String text, {
    String label = '',
    String? colorKey,
  }) {
    final m = _pattern.firstMatch(text);
    if (m == null) return null;
    final (fromInf, from) = _end(m.group(2)!, negative: true);
    final (toInf, to) = _end(m.group(3)!, negative: false);
    if ((!fromInf && from == null) || (!toInf && to == null)) return null;
    if (from != null && to != null && !(to > from)) return null;
    return GraphInterval(
      from: from,
      to: to,
      fromOpen: fromInf || m.group(1) != '[',
      toOpen: toInf || m.group(4) != ']',
      fromText: fromInf ? '' : m.group(2)!.trim(),
      toText: toInf ? '' : m.group(3)!.trim(),
      label: label,
      colorKey: colorKey,
    );
  }

  /// Un estremo: `(true, null)` se è l'infinito dalla parte giusta, il
  /// numero (anche una frazione `a/b`) altrimenti.
  static (bool, double?) _end(String raw, {required bool negative}) {
    final t = raw.replaceAll(' ', '').replaceAll('−', '-');
    const inf = {'inf', '∞', 'infinity'};
    if (negative && t.startsWith('-') && inf.contains(t.substring(1))) {
      return (true, null);
    }
    if (!negative &&
        (inf.contains(t) ||
            (t.startsWith('+') && inf.contains(t.substring(1))))) {
      return (true, null);
    }
    final parts = t.split('/');
    if (parts.length == 2) {
      final a = double.tryParse(parts[0]), b = double.tryParse(parts[1]);
      return (false, a == null || b == null || b == 0 ? null : a / b);
    }
    return (false, double.tryParse(t));
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'interval',
    'set':
        '${fromOpen ? ']' : '['}${from == null ? '-inf' : fromText}, '
        '${to == null ? '+inf' : toText}${toOpen ? '[' : ']'}',
    ..._common(),
  };
}

/// Una serie del grafico a barre: un valore per categoria, `null` se manca.
class GraphBarSeries {
  final String label;
  final String? colorKey;
  final List<double?> values;

  const GraphBarSeries({
    this.label = '',
    this.colorKey,
    this.values = const [],
  });

  factory GraphBarSeries.fromJson(Map<String, dynamic> json) => GraphBarSeries(
    label: json['label'] as String? ?? '',
    colorKey: json['color'] as String?,
    // Una voce non numerica resta `null` e non diventa `0`: uno zero stampa
    // una barra che non c'è, saltarla sposta le voci successive.
    values: [
      for (final v in json['values'] as List<dynamic>? ?? const [])
        v is num ? v.toDouble() : null,
    ],
  );

  Map<String, dynamic> toJson() => {
    if (label.isNotEmpty) 'label': label,
    if (colorKey != null) 'color': colorKey,
    'values': values,
  };
}

/// Un parametro che il lettore muove con uno slider (`params` del grafico).
///
/// Il [name] si usa nelle espressioni (`"m*x + q"`) e nelle coordinate dei
/// punti; [label] è LaTeX (di base il nome); [step] è lo scatto dello slider.
/// Con [animate] c'è anche un tasto che lo fa scorrere da solo avanti e
/// indietro.
class GraphParam {
  /// I nomi che il motore delle espressioni usa già: non si possono dare a un
  /// parametro.
  static const reserved = {
    'x', 't', 'pi', 'e', //
    'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'ln', 'log', 'sqrt', 'abs',
    'exp',
  };

  final String name;
  final String label;
  final double min;
  final double max;
  final double step;
  final double value;
  final bool animate;

  const GraphParam({
    required this.name,
    required this.label,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    this.animate = false,
  });

  /// Un parametro dal JSON, o `null` se non si capisce (nome non valido o già
  /// preso, intervallo rovesciato): il grafico lo salta come ogni elemento che
  /// non capisce.
  static GraphParam? fromJson(String name, Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name) ||
        reserved.contains(name)) {
      return null;
    }
    final min = raw['min'], max = raw['max'];
    if (min is! num || max is! num || !(max > min)) return null;
    final span = max.toDouble() - min.toDouble();
    final step = raw['step'];
    final value = raw['value'];
    return GraphParam(
      name: name,
      label: raw['label'] as String? ?? name,
      min: min.toDouble(),
      max: max.toDouble(),
      step: step is num && step > 0 ? step.toDouble() : span / 100,
      value: value is num
          ? value.toDouble().clamp(min.toDouble(), max.toDouble())
          : min.toDouble(),
      animate: raw['animate'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'step': step,
    'value': value,
    if (label != name) 'label': label,
    if (animate) 'animate': true,
  };
}

/// Il riquadro `graph`: un grafico dal JSON della lezione.
///
/// Di base è fermo; con [params] ha degli slider che ne cambiano le espressioni.
///
/// [x] e [y] sono i domini (`null` = automatici), [grid] il passo della
/// griglia (`null` = automatico), [xLabel] e [yLabel] i nomi degli assi in
/// LaTeX. Sul piano cartesiano contano [items]; sulle barre [categories] e
/// [series].
class GraphPayload extends BoxPayload {
  final GraphPlane plane;
  final (double, double)? x;
  final (double, double)? y;
  final GraphAspect aspect;
  final double? grid;
  final String xLabel;
  final String yLabel;
  final List<GraphItem> items;
  final List<String> categories;
  final List<GraphBarSeries> series;

  /// Gli slider, nell'ordine del JSON. Vuoto = grafico fermo.
  final List<GraphParam> params;

  /// Il JSON da cui nasce, tenuto solo se ci sono [params]: a ogni scatto dello
  /// slider si rilegge con i valori messi al posto dei nomi (`resolveGraph`).
  final Map<String, dynamic>? source;

  /// Senza la card che lo avvolge e senza il titolo: il grafico sta da solo.
  /// **Di base è `true`**: la card si chiede con `"hidden": false`.
  final bool hidden;

  const GraphPayload({
    this.plane = GraphPlane.cartesian,
    this.x,
    this.y,
    this.aspect = GraphAspect.fit,
    this.grid,
    this.xLabel = 'x',
    this.yLabel = 'y',
    this.items = const [],
    this.categories = const [],
    this.series = const [],
    this.params = const [],
    this.source,
    this.hidden = true,
  });

  factory GraphPayload.fromJson(Map<String, dynamic> json) {
    final grid = json['grid'];
    final rawParams = json['params'];
    final params = [
      if (rawParams is Map<String, dynamic>)
        for (final e in rawParams.entries) ?GraphParam.fromJson(e.key, e.value),
    ];
    return GraphPayload(
      params: params,
      source: params.isEmpty ? null : json,
      plane: GraphPlane.fromString(json['plane'] as String? ?? ''),
      x: _range(json['x']),
      y: _range(json['y']),
      aspect: GraphAspect.fromString(json['aspect'] as String? ?? ''),
      grid: grid is num && grid > 0 ? grid.toDouble() : null,
      xLabel: json['xLabel'] as String? ?? 'x',
      yLabel: json['yLabel'] as String? ?? 'y',
      items: [
        for (final e in json['items'] as List<dynamic>? ?? const [])
          if (e is Map<String, dynamic>) ?GraphItem.fromJson(e),
      ],
      categories: [
        for (final e in json['categories'] as List<dynamic>? ?? const []) '$e',
      ],
      series: [
        for (final e in json['series'] as List<dynamic>? ?? const [])
          if (e is Map<String, dynamic>) GraphBarSeries.fromJson(e),
      ],
      hidden: json['hidden'] as bool? ?? true,
    );
  }

  /// `true` se non c'è niente da disegnare.
  bool get isEmpty => switch (plane) {
    GraphPlane.cartesian || GraphPlane.numberLine => items.isEmpty,
    GraphPlane.bars => series.every((s) => s.values.every((v) => v == null)),
  };

  @override
  Map<String, dynamic> toJson() => {
    'plane': plane.key,
    if (x != null) 'x': [x!.$1, x!.$2],
    if (y != null) 'y': [y!.$1, y!.$2],
    if (aspect == GraphAspect.equal) 'aspect': 'equal',
    if (grid != null) 'grid': grid,
    if (xLabel != 'x') 'xLabel': xLabel,
    if (yLabel != 'y') 'yLabel': yLabel,
    if (items.isNotEmpty) 'items': [for (final i in items) i.toJson()],
    if (categories.isNotEmpty) 'categories': categories,
    if (series.isNotEmpty) 'series': [for (final s in series) s.toJson()],
    if (params.isNotEmpty)
      'params': {for (final p in params) p.name: p.toJson()},
    if (!hidden) 'hidden': hidden,
  };
}
