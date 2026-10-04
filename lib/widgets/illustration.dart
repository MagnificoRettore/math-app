import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Le illustrazioni del design (canvas «Illustrazioni App Educativa»), in SVG
/// statico sotto `assets/illustrations/`.
enum AppIllustration {
  /// Lampadina da cui escono strumenti di matematica: lo splash.
  idea,

  /// Razzo che decolla da un libro: un traguardo raggiunto.
  razzo,

  /// Laptop da cui escono calcolatrice e grafici: gli esercizi.
  lezione,

  /// Albero che cresce da un libro: la scuola, e le lezioni in arrivo.
  albero;

  String get asset => 'assets/illustrations/$name.svg';
}

/// Un'illustrazione con gli angoli arrotondati, nelle proporzioni delle
/// tavole (600×720). È decorazione: lo screen reader la salta.
class IllustrationView extends StatelessWidget {
  final AppIllustration illustration;
  final double width;

  const IllustrationView(this.illustration, {super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.1),
        child: SvgPicture.asset(
          illustration.asset,
          key: ValueKey('illustration-${illustration.name}'),
          width: width,
          height: width * 720 / 600,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
