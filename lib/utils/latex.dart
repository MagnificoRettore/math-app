import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class LatexText extends StatelessWidget {
  final String data;
  final double fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;

  const LatexText(
    this.data, {
    super.key,
    this.fontSize = 16,
    this.color,
    this.fontWeight,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.black;
    return Math.tex(
      _clean(data),
      textStyle: TextStyle(
        fontSize: fontSize,
        color: effectiveColor,
        fontWeight: fontWeight,
      ),
      options: MathOptions(
        fontSize: fontSize,
        color: effectiveColor,
      ),
    );
  }

  String _clean(String value) {
    var s = value.trim();
    if (s.startsWith(r'$$') && s.endsWith(r'$$')) {
      s = s.substring(2, s.length - 2);
    } else if (s.startsWith(r'$') && s.endsWith(r'$')) {
      s = s.substring(1, s.length - 1);
    }
    return s;
  }
}