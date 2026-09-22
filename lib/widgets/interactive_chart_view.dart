import 'package:flutter/material.dart';

import '../models/multifunction_box/box_payload.dart';
import '../theme/app_colors.dart';
import 'chart_colors.dart';
import 'chart_widgets.dart';
import 'expression_evaluator.dart';

/// Grafico a linee interattivo: slider parametrizza le serie tramite
/// espressioni su `x` e `t`; chips legenda (se [toggleable]) mostrano/nascondono serie.
class InteractiveChartView extends StatefulWidget {
  final InteractiveChartPayload payload;

  const InteractiveChartView({super.key, required this.payload});

  @override
  State<InteractiveChartView> createState() => _InteractiveChartViewState();
}

class _InteractiveChartViewState extends State<InteractiveChartView> {
  late double _t;
  final Set<int> _hidden = {};

  @override
  void initState() {
    super.initState();
    _t = widget.payload.parameter.defaultValue;
  }

  InteractiveChartPayload get payload => widget.payload;

  List<ChartSeries> _computedSeries() {
    final result = <ChartSeries>[];
    final count = ((payload.xMax - payload.xMin) / payload.xStep).floor() + 1;
    for (var si = 0; si < payload.series.length; si++) {
      final meta = payload.series[si];
      if (_hidden.contains(si)) {
        result.add(ChartSeries(label: meta.label, values: const []));
        continue;
      }
      final values = <num>[];
      for (var i = 0; i < count; i++) {
        final x = payload.xMin + i * payload.xStep;
        values.add(ExpressionEvaluator.evaluate(meta.expression, x: x, t: _t));
      }
      result.add(
        ChartSeries(label: meta.label, values: values, colorKey: meta.colorKey),
      );
    }
    return result;
  }

  int _decimals() {
    final step = payload.parameter.step;
    if (step >= 1) return 0;
    final raw = step.toString();
    return raw.substring(raw.indexOf('.') + 1).length;
  }

  void _toggleSeries(int index) {
    setState(() {
      if (_hidden.contains(index)) {
        _hidden.remove(index);
      } else {
        _hidden.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final colors = [
      for (var i = 0; i < payload.series.length; i++)
        ChartColor.forKey(c, payload.series[i].colorKey, i),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 200,
          child: CustomPaint(
            painter: LineChartPainter(
              series: _computedSeries(),
              colors: colors,
              gridColor: c.border,
              labelColor: c.textSecondary,
              axisColor: c.border,
            ),
          ),
        ),
        if (payload.toggleable && payload.series.length > 1) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (var i = 0; i < payload.series.length; i++)
                _SeriesChip(
                  label: payload.series[i].label,
                  color: colors[i],
                  hidden: _hidden.contains(i),
                  onTap: () => _toggleSeries(i),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _t.clamp(payload.parameter.min, payload.parameter.max),
                min: payload.parameter.min,
                max: payload.parameter.max,
                divisions: payload.parameter.step <= 0
                    ? null
                    : ((payload.parameter.max - payload.parameter.min) /
                            payload.parameter.step)
                        .round()
                        .clamp(1, 1000),
                onChanged: (value) => setState(() => _t = value),
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${payload.parameter.name} = ${_t.toStringAsFixed(_decimals())}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SeriesChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool hidden;
  final VoidCallback onTap;

  const _SeriesChip({
    required this.label,
    required this.color,
    required this.hidden,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final textColor = hidden
        ? c.textSecondary.withValues(alpha: 0.4)
        : c.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hidden
              ? c.border.withValues(alpha: 0.35)
              : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hidden ? c.border : color.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: hidden ? c.textSecondary : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
