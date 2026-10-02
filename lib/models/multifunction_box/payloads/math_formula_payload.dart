part of '../box_payload.dart';

class MathFormulaPayload extends BoxPayload {
  final String tex;
  final double? fontSizeMultiplier;
  final bool hidden;

  const MathFormulaPayload({
    required this.tex,
    this.fontSizeMultiplier,
    this.hidden = false,
  });

  factory MathFormulaPayload.fromJson(Map<String, dynamic> json) {
    return MathFormulaPayload(
      tex: json['tex'] as String? ?? '',
      fontSizeMultiplier: (json['fontSizeMultiplier'] as num?)?.toDouble(),
      hidden: json['hidden'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'tex': tex,
    if (fontSizeMultiplier != null) 'fontSizeMultiplier': fontSizeMultiplier,
    if (hidden) 'hidden': hidden,
  };
}
