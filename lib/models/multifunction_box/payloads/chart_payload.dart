part of '../box_payload.dart';

class ChartSeries {
  final String label;
  final List<num> values;
  final String? colorKey;

  const ChartSeries({required this.label, required this.values, this.colorKey});

  factory ChartSeries.fromJson(Map<String, dynamic> json) {
    return ChartSeries(
      label: json['label'] as String? ?? '',
      values: (json['values'] as List<dynamic>? ?? const [])
          .map((e) => e is num ? e : (num.tryParse(e.toString()) ?? 0))
          .toList(),
      colorKey: json['colorKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'values': values,
    if (colorKey != null) 'colorKey': colorKey,
  };
}

class ChartBoxPayload extends BoxPayload {
  final ChartKind kind;
  final List<String> xLabels;
  final List<ChartSeries> series;
  final String unit;

  const ChartBoxPayload({
    required this.kind,
    required this.series,
    this.xLabels = const [],
    this.unit = '',
  });

  factory ChartBoxPayload.fromJson(Map<String, dynamic> json) {
    return ChartBoxPayload(
      kind: ChartKind.fromString(json['kind'] as String? ?? 'bar'),
      xLabels: (json['xLabels'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      unit: json['unit'] as String? ?? '',
      series: (json['series'] as List<dynamic>? ?? const [])
          .map((e) => ChartSeries.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.key,
    'xLabels': xLabels,
    'unit': unit,
    'series': series.map((s) => s.toJson()).toList(),
  };
}
