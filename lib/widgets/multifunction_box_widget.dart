import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../models/multifunction_box/box_payload.dart';
import '../models/multifunction_box/box_type.dart';
import '../models/multifunction_box/multifunction_box.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'chart_colors.dart';
import 'chart_widgets.dart';
import 'image_source.dart';
import 'interactive_chart_view.dart';
import 'math_text.dart';

/// Card che mostra un [MultifunctionBox] in base a `box_type`.
class MultifunctionBoxWidget extends StatelessWidget {
  final MultifunctionBox box;

  const MultifunctionBoxWidget({super.key, required this.box});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final payload = box.payload;
    if (payload is MathFormulaPayload && payload.hidden) {
      return _FormulaView(payload: payload);
    }
    if (payload is ImageBoxPayload) {
      return _ImageView(box: box, payload: payload);
    }
    final hasTitle = box.title.isNotEmpty;
    return AppCard(
      padding: hasTitle
          ? const EdgeInsets.all(16)
          : const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle) ...[
            Text(
              box.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (box.boxType) {
      BoxType.image => _ImageView(
        box: box,
        payload: box.payload as ImageBoxPayload,
      ),
      BoxType.mathFormula => _FormulaView(
        payload: box.payload as MathFormulaPayload,
      ),
      BoxType.chart => SizedBox(
        height: 220,
        width: double.infinity,
        child: _buildChart(context, box.payload as ChartBoxPayload),
      ),
      BoxType.interactiveChart => InteractiveChartView(
        payload: box.payload as InteractiveChartPayload,
      ),
    };
  }

  Widget _buildChart(BuildContext context, ChartBoxPayload payload) {
    final c = AppColors.of(context);
    final colors = ChartColor.resolve(c, payload.series);
    switch (payload.kind) {
      case ChartKind.bar:
        return CustomPaint(
          painter: BarChartPainter(
            series: payload.series,
            xLabels: payload.xLabels,
            unit: payload.unit,
            colors: colors,
            gridColor: c.border,
            labelColor: c.textSecondary,
            axisColor: c.border,
          ),
        );
      case ChartKind.line:
        return CustomPaint(
          painter: LineChartPainter(
            series: payload.series,
            xLabels: payload.xLabels,
            unit: payload.unit,
            colors: colors,
            gridColor: c.border,
            labelColor: c.textSecondary,
            axisColor: c.border,
          ),
        );
      case ChartKind.pie:
        final values = payload.series.isEmpty
            ? const <num>[]
            : payload.series.first.values;
        return CustomPaint(
          painter: PieChartPainter(
            values: values,
            labels: payload.xLabels,
            colors: [
              for (var i = 0; i < values.length; i++)
                ChartColor.forSegment(c, i),
            ],
            labelColor: c.textSecondary,
            strokeColor: c.surface,
          ),
        );
    }
  }
}

/// Immagine senza card: nessun bordo, nessuna ombra, nessuna piastra di
/// sfondo e nessun ritaglio degli angoli. La foto sta nella colonna di testo
/// della lezione e si allinea come dice il payload.
class _ImageView extends StatelessWidget {
  final MultifunctionBox box;
  final ImageBoxPayload payload;

  const _ImageView({required this.box, required this.payload});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final align = switch (payload.align) {
      BoxAlign.left => Alignment.centerLeft,
      BoxAlign.center => Alignment.center,
      BoxAlign.right => Alignment.centerRight,
    };
    return Align(
      alignment: align,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (box.title.isNotEmpty) ...[
            Text(
              box.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ImageSource(
            source: payload.source,
            caption: payload.caption,
            naturalSize: true,
          ),
        ],
      ),
    );
  }
}

class _FormulaView extends StatelessWidget {
  final MathFormulaPayload payload;

  const _FormulaView({required this.payload});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cleaned = stripMathDelimiters(payload.tex);
    final fontSize = 18 * (payload.fontSizeMultiplier ?? 1).toDouble();
    final formula = Math.tex(
      cleaned,
      textStyle: TextStyle(fontSize: fontSize, color: c.textPrimary),
      options: MathOptions(fontSize: fontSize, color: c.textPrimary),
    );
    if (payload.mode == FormulaMode.inline) {
      return formula;
    }
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: formula,
      ),
    );
  }
}
