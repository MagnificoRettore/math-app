part of '../box_payload.dart';

/// Tipo di grafico del riquadro `chart`.
///
/// Sono tre e sono quelli che i tre argomenti con le lezioni chiedono: curve di
/// funzione, serie di punti e valori per categoria. Niente barre raggruppate,
/// niente diagrammi a torta: un tipo entra quando un argomento lo vuole.
enum ChartKind {
  function,
  line,
  bar;

  static ChartKind fromString(String value) {
    switch (value.toLowerCase()) {
      case 'function':
        return ChartKind.function;
      case 'line':
        return ChartKind.line;
      case 'bar':
        return ChartKind.bar;
      default:
        return ChartKind.function;
    }
  }

  String get key => switch (this) {
    ChartKind.function => 'function',
    ChartKind.line => 'line',
    ChartKind.bar => 'bar',
  };

  String get label => switch (this) {
    ChartKind.function => 'Grafico di una funzione',
    ChartKind.line => 'Grafico a linee',
    ChartKind.bar => 'Grafico a barre',
  };
}

/// Una serie del grafico.
///
/// I tre tipi si prendono i dati in modi diversi e uno solo basta a ogni serie:
/// `bar` usa [values] (una altezza per voce di `xLabels`), `line` usa [points]
/// (coppie `[x, y]`, quindi la x non deve essere regolare), `function` usa
/// [expression] e la campiona fra i limiti del dominio. Vuota, la serie non
/// disegna nulla: è la difesa contro un JSON incompleto.
class ChartSeries {
  final String label;
  final List<num?> values;
  final List<ChartPoint> points;
  final String expression;
  final String? colorKey;

  const ChartSeries({
    this.label = '',
    this.values = const <num?>[],
    this.points = const [],
    this.expression = '',
    this.colorKey,
  });

  /// `true` se la serie non ha nessun dato da disegnare.
  bool get isEmpty => values.isEmpty && points.isEmpty && expression.isEmpty;

  factory ChartSeries.fromJson(Map<String, dynamic> json) {
    return ChartSeries(
      label: json['label'] as String? ?? '',
      values: _nums(json['values']),
      points: _points(json['points']),
      expression: json['expression'] as String? ?? '',
      colorKey: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (label.isNotEmpty) 'label': label,
    if (values.isNotEmpty) 'values': values,
    if (points.isNotEmpty)
      'points': [
        for (final p in points) [p.x, p.y],
      ],
    if (expression.isNotEmpty) 'expression': expression,
    if (colorKey != null) 'color': colorKey,
  };
}

/// Un punto del piano, in coordinate dei dati (non in pixel).
class ChartPoint {
  final double x;
  final double y;

  const ChartPoint(this.x, this.y);

  List<double> toJson() => [x, y];
}

/// Le altezze delle barre.
///
/// Una voce non numerica resta `null` e non diventa `0`: metterci uno zero
/// stampe una barra inesistente, mentre saltarla sposta tutte le voci
/// successive di una posizione.
List<num?> _nums(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is num) e else num.tryParse('$e'),
  ];
}

List<ChartPoint> _points(Object? raw) {
  if (raw is! List) return const [];
  final out = <ChartPoint>[];
  for (final e in raw) {
    if (e is List && e.length >= 2) {
      final x = e[0] is num ? (e[0] as num).toDouble() : double.nan;
      final y = e[1] is num ? (e[1] as num).toDouble() : double.nan;
      if (!x.isNaN && !y.isNaN) out.add(ChartPoint(x, y));
    } else if (e is Map) {
      final x = (e['x'] as num?)?.toDouble() ?? double.nan;
      final y = (e['y'] as num?)?.toDouble() ?? double.nan;
      if (!x.isNaN && !y.isNaN) out.add(ChartPoint(x, y));
    }
  }
  return out;
}

double? _optionalDouble(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

class ChartBoxPayload extends BoxPayload {
  final ChartKind kind;
  final List<String> xLabels;
  final List<ChartSeries> series;
  final String xLabel;
  final String yLabel;
  final String unit;
  final double? xMin;
  final double? xMax;
  final double? yMin;
  final double? yMax;
  final int samples;
  final bool smooth;

  const ChartBoxPayload({
    this.kind = ChartKind.function,
    this.xLabels = const [],
    this.series = const [],
    this.xLabel = '',
    this.yLabel = '',
    this.unit = '',
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.samples = 160,
    this.smooth = true,
  });

  factory ChartBoxPayload.fromJson(Map<String, dynamic> json) {
    return ChartBoxPayload(
      kind: ChartKind.fromString(json['kind'] as String? ?? 'function'),
      xLabels: [
        for (final e in json['xLabels'] as List<dynamic>? ?? const []) '$e',
      ],
      series: [
        for (final e in json['series'] as List<dynamic>? ?? const [])
          if (e is Map<String, dynamic>) ChartSeries.fromJson(e),
      ],
      xLabel: json['xLabel'] as String? ?? '',
      yLabel: json['yLabel'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      xMin: _optionalDouble(json['xMin']),
      xMax: _optionalDouble(json['xMax']),
      yMin: _optionalDouble(json['yMin']),
      yMax: _optionalDouble(json['yMax']),
      samples: ((json['samples'] as num?)?.toInt() ?? 160).clamp(16, 2000),
      smooth: json['smooth'] != false,
    );
  }

  /// `true` se nessuna serie ha dati: il box non ha niente da disegnare.
  bool get isEmpty => series.every((s) => s.isEmpty);

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.key,
    if (xLabels.isNotEmpty) 'xLabels': xLabels,
    if (xLabel.isNotEmpty) 'xLabel': xLabel,
    if (yLabel.isNotEmpty) 'yLabel': yLabel,
    if (unit.isNotEmpty) 'unit': unit,
    if (xMin != null) 'xMin': xMin,
    if (xMax != null) 'xMax': xMax,
    if (yMin != null) 'yMin': yMin,
    if (yMax != null) 'yMax': yMax,
    'samples': samples,
    if (!smooth) 'smooth': false,
    'series': [for (final s in series) s.toJson()],
  };
}
