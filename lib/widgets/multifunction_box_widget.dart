import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../models/multifunction_box/box_payload.dart';
import '../models/multifunction_box/box_type.dart';
import '../models/multifunction_box/multifunction_box.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'chart_colors.dart';
import 'chart_widgets.dart';
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
      return const SizedBox.shrink();
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
      BoxType.image => _ImageView(payload: box.payload as ImageBoxPayload),
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

class _ImageView extends StatelessWidget {
  final ImageBoxPayload payload;

  const _ImageView({required this.payload});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: c.accentSoft,
        constraints: const BoxConstraints(maxHeight: 240),
        child: ImageSource(payload: payload),
      ),
    );
  }
}

class ImageSource extends StatelessWidget {
  final ImageBoxPayload payload;

  const ImageSource({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isUrl =
        payload.source.startsWith('http://') ||
        payload.source.startsWith('https://');
    final fit = BoxFit.cover;
    final placeholder = Container(
      height: 180,
      width: double.infinity,
      color: c.accentSoft,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 44, color: c.textSecondary),
    );
    final image = isUrl
        ? Image.network(
            payload.source,
            fit: fit,
            errorBuilder: (_, _, _) => placeholder,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder,
          )
        : Image.asset(
            payload.source,
            fit: fit,
            errorBuilder: (_, _, _) => placeholder,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(child: SizedBox(height: 200, child: image)),
        if (payload.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              payload.caption,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ),
      ],
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
