import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../models/multifunction_box/box_payload.dart';
import '../models/multifunction_box/multifunction_box.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'image_source.dart';
import 'math_text.dart';

/// Card che mostra un [MultifunctionBox] in base a `box_type`: l'immagine sta
/// nuda nella colonna di testo, la formula va in card e `hidden` la lascia
/// da sola.
class MultifunctionBoxWidget extends StatelessWidget {
  final MultifunctionBox box;

  const MultifunctionBoxWidget({super.key, required this.box});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (box.payload is ImageBoxPayload) return _ImageView(box: box);

    final formula = box.payload as MathFormulaPayload;
    if (formula.hidden) return _FormulaView(payload: formula);

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
          _FormulaView(payload: formula),
        ],
      ),
    );
  }
}

/// Immagine senza card: nessun bordo, nessuna ombra, nessuna piastra di
/// sfondo e nessun ritaglio degli angoli. La foto sta centrata nella colonna
/// di testo della lezione.
class _ImageView extends StatelessWidget {
  final MultifunctionBox box;

  const _ImageView({required this.box});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            source: (box.payload as ImageBoxPayload).source,
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
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Math.tex(
          cleaned,
          textStyle: TextStyle(fontSize: fontSize, color: c.textPrimary),
          options: MathOptions(fontSize: fontSize, color: c.textPrimary),
        ),
      ),
    );
  }
}
