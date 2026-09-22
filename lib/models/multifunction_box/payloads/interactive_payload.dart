part of '../box_payload.dart';

class InteractiveParameter {
  final String name;
  final double min;
  final double max;
  final double step;
  final double defaultValue;

  const InteractiveParameter({
    required this.name,
    required this.min,
    required this.max,
    required this.step,
    required this.defaultValue,
  });

  factory InteractiveParameter.fromJson(Map<String, dynamic> json) {
    final min = (json['min'] as num?)?.toDouble() ?? 0;
    final max = (json['max'] as num?)?.toDouble() ?? 1;
    return InteractiveParameter(
      name: json['name'] as String? ?? 't',
      min: min,
      max: max,
      step: (json['step'] as num?)?.toDouble() ?? 0.1,
      defaultValue:
          (json['default'] as num?)?.toDouble() ?? (min + (max - min) / 2),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'min': min,
    'max': max,
    'step': step,
    'default': defaultValue,
  };
}

class InteractiveSeries {
  final String label;
  final String expression;
  final String? colorKey;

  const InteractiveSeries({
    required this.label,
    required this.expression,
    this.colorKey,
  });

  factory InteractiveSeries.fromJson(Map<String, dynamic> json) {
    return InteractiveSeries(
      label: json['label'] as String? ?? '',
      expression: json['expression'] as String? ?? '0',
      colorKey: json['colorKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'expression': expression,
    if (colorKey != null) 'colorKey': colorKey,
  };
}

class InteractiveChartPayload extends BoxPayload {
  final String xLabel;
  final String yLabel;
  final double xMin;
  final double xMax;
  final double xStep;
  final double yMin;
  final double yMax;
  final InteractiveParameter parameter;
  final List<InteractiveSeries> series;
  final bool toggleable;

  const InteractiveChartPayload({
    required this.xLabel,
    required this.yLabel,
    required this.parameter,
    required this.series,
    this.xMin = -3,
    this.xMax = 3,
    this.xStep = 0.25,
    this.yMin = -5,
    this.yMax = 5,
    this.toggleable = true,
  });

  factory InteractiveChartPayload.fromJson(Map<String, dynamic> json) {
    return InteractiveChartPayload(
      xLabel: json['xLabel'] as String? ?? 'x',
      yLabel: json['yLabel'] as String? ?? 'y',
      xMin: (json['xMin'] as num?)?.toDouble() ?? -3,
      xMax: (json['xMax'] as num?)?.toDouble() ?? 3,
      xStep: (json['xStep'] as num?)?.toDouble() ?? 0.25,
      yMin: (json['yMin'] as num?)?.toDouble() ?? -5,
      yMax: (json['yMax'] as num?)?.toDouble() ?? 5,
      parameter: InteractiveParameter.fromJson(
        json['parameter'] as Map<String, dynamic>? ?? const {},
      ),
      series: (json['series'] as List<dynamic>? ?? const [])
          .map((e) => InteractiveSeries.fromJson(e as Map<String, dynamic>))
          .toList(),
      toggleable: json['toggleable'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'xLabel': xLabel,
    'yLabel': yLabel,
    'xMin': xMin,
    'xMax': xMax,
    'xStep': xStep,
    'yMin': yMin,
    'yMax': yMax,
    'parameter': parameter.toJson(),
    'series': series.map((s) => s.toJson()).toList(),
    'toggleable': toggleable,
  };
}
