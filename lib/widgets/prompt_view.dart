import 'package:flutter/material.dart';

import 'image_source.dart';
import 'math_text.dart';

/// Testo di un esercizio a risposta multipla.
///
/// Il tipo viene dedotto dal contenuto: un percorso di asset o un URL
/// diventano immagine, tutto il resto passa a [MathText], che gestisce da sé
/// il blocco `$$...$$`, la matematica inline `$...$` e il testo semplice.
class PromptView extends StatelessWidget {
  final String prompt;
  final double fontSize;

  const PromptView({super.key, required this.prompt, this.fontSize = 18});

  static bool isImageSource(String value) {
    return value.startsWith('assets/') ||
        value.startsWith('http://') ||
        value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (isImageSource(prompt)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ImageSource(source: prompt),
      );
    }
    return MathText(prompt, fontSize: fontSize);
  }
}
