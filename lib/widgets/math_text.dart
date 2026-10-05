import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../theme/app_text.dart';
import '../theme/app_colors.dart';

class MathSegment {
  final String text;
  final bool isMath;
  const MathSegment(this.text, {required this.isMath});
}

/// Fattore di scala del testo in vigore, letto dal [MediaQuery].
///
/// `RichText` non applica il `textScaler` (di default `TextScaler.noScaling`)
/// e dentro `flutter_math_fork` le formule sono `RichText` costruite a mano,
/// quindi il corpo delle lezioni crescerebbe da solo ma la matematica no.
/// Chi rende testo con dimensioni esplicite moltiplica per questo fattore e
/// così segue l'impostazione «Dimensione del testo» di Personalizzazione.
double textScaleFactorOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(16) / 16;

/// Divide un testo in segmenti matematici (`$$..$$`, block) e inline (`$..$`)
/// e segmenti di testo puro.
List<MathSegment> splitMath(String data) {
  final segments = <MathSegment>[];
  final block = RegExp(r'\$\$.*?\$\$');
  var lastIndex = 0;
  for (final match in block.allMatches(data)) {
    if (match.start > lastIndex) {
      segments.addAll(_splitInlineMath(data.substring(lastIndex, match.start)));
    }
    segments.add(MathSegment(match.group(0)!, isMath: true));
    lastIndex = match.end;
  }
  if (lastIndex < data.length) {
    segments.addAll(_splitInlineMath(data.substring(lastIndex)));
  }
  return segments;
}

List<MathSegment> _splitInlineMath(String text) {
  if (text.isEmpty) return const [];
  final segments = <MathSegment>[];
  final inline = RegExp(r'\$[^$\n]+\$');
  var lastIndex = 0;
  for (final match in inline.allMatches(text)) {
    if (match.start > lastIndex) {
      segments.add(
        MathSegment(text.substring(lastIndex, match.start), isMath: false),
      );
    }
    segments.add(MathSegment(match.group(0)!, isMath: true));
    lastIndex = match.end;
  }
  if (lastIndex < text.length) {
    segments.add(MathSegment(text.substring(lastIndex), isMath: false));
  }
  return segments;
}

/// Rimuove i delimitatori `$$...$$` o `$...$` (se presenti) da una stringa LaTeX.
String stripMathDelimiters(String value) {
  var s = value.trim();
  if (s.startsWith(r'$$') && s.endsWith(r'$$')) {
    s = s.substring(2, s.length - 2);
  } else if (s.startsWith(r'$') && s.endsWith(r'$')) {
    s = s.substring(1, s.length - 1);
  }
  return s;
}

/// Widget span per matematica inline, condiviso tra [MathText] e NotesText.
InlineSpan mathSpan(
  String tex, {
  required double fontSize,
  required Color color,
  FontWeight? fontWeight,
}) {
  final cleaned = stripMathDelimiters(tex);
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Math.tex(
      cleaned,
      textStyle: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
      options: MathOptions(
        fontSize: fontSize,
        color: color,
        mathFontOptions: fontWeight == null
            ? null
            : FontOptions(fontWeight: fontWeight),
      ),
    ),
  );
}

class MathText extends StatelessWidget {
  final String data;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;
  final FontWeight? fontWeight;

  /// Una formula da sola resta una riga di testo: stessa dimensione e stessa
  /// altezza di una riga di parole. Senza, una formula sola è «in display»,
  /// ingrandita del 10% e con 8 px sopra e sotto, e la sua riga risulta più
  /// alta di quelle di testo accanto (le opzioni di un quiz, per esempio).
  final bool inline;

  const MathText(
    this.data, {
    super.key,
    this.fontSize = AppText.titleSmall,
    this.color,
    this.textAlign = TextAlign.left,
    this.fontWeight,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final effectiveColor = color ?? c.textPrimary;
    final size = fontSize * textScaleFactorOf(context);
    final segments = splitMath(data);
    if (!inline && segments.length == 1 && segments.first.isMath) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Math.tex(
            stripMathDelimiters(segments.first.text),
            textStyle: TextStyle(
              fontSize: size * 1.1,
              color: effectiveColor,
              fontWeight: fontWeight,
            ),
            options: MathOptions(
              fontSize: size * 1.1,
              color: effectiveColor,
              mathFontOptions: fontWeight == null
                  ? null
                  : FontOptions(fontWeight: fontWeight!),
            ),
          ),
        ),
      );
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        // `RichText` non eredita il `DefaultTextStyle`: il carattere va detto.
        style: TextStyle(
          fontFamily: AppText.bodyFont,
          color: effectiveColor,
          height: 1.5,
        ),
        children: [
          for (final seg in segments)
            if (seg.isMath)
              mathSpan(
                seg.text,
                fontSize: size,
                color: effectiveColor,
                fontWeight: fontWeight,
              )
            else
              ..._plainSpans(seg.text, effectiveColor, size),
        ],
      ),
    );
  }

  List<InlineSpan> _plainSpans(String text, Color color, double fontSize) {
    final bold = RegExp(r'<b>(.*?)</b>');
    final matches = bold.allMatches(text);
    if (matches.isEmpty) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(fontSize: fontSize),
        ),
      ];
    }
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(
          TextSpan(
            text: text.substring(last, match.start),
            style: TextStyle(fontSize: fontSize),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
        ),
      );
      last = match.end;
    }
    if (last < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(last),
          style: TextStyle(fontSize: fontSize),
        ),
      );
    }
    return spans;
  }
}
