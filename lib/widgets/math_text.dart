import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../theme/app_colors.dart';

class MathText extends StatelessWidget {
  final String data;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;

  const MathText(
    this.data, {
    super.key,
    this.fontSize = 16,
    this.color,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final effectiveColor = color ?? c.textPrimary;
    final segments = _splitMath(data);
    if (segments.length == 1 && segments.first.isMath) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _mathBlock(segments.first.text, effectiveColor, fontSize),
      );
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: TextStyle(color: effectiveColor, height: 1.5),
        children: [
          for (final seg in segments)
            seg.isMath
                ? _mathSpan(seg.text, effectiveColor, fontSize)
                : TextSpan(text: seg.text, style: TextStyle(fontSize: fontSize)),
        ],
      ),
    );
  }

  Widget _mathBlock(String tex, Color color, double fontSize) {
    final cleaned = _stripDollars(tex);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Math.tex(
        cleaned,
        textStyle: TextStyle(fontSize: fontSize * 1.1, color: color),
        options: MathOptions(fontSize: fontSize * 1.1, color: color),
      ),
    );
  }

  InlineSpan _mathSpan(String tex, Color color, double fontSize) {
    final cleaned = _stripDollars(tex);
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Math.tex(
        cleaned,
        textStyle: TextStyle(fontSize: fontSize, color: color),
        options: MathOptions(fontSize: fontSize, color: color),
      ),
    );
  }

  String _stripDollars(String value) {
    var s = value.trim();
    if (s.startsWith(r'$$') && s.endsWith(r'$$')) {
      s = s.substring(2, s.length - 2);
    } else if (s.startsWith(r'$') && s.endsWith(r'$')) {
      s = s.substring(1, s.length - 1);
    }
    return s;
  }

  static List<_Segment> _splitMath(String data) {
    final segments = <_Segment>[];
    final pattern = RegExp(r'\$\$.*?\$\$');
    var lastIndex = 0;
    for (final match in pattern.allMatches(data)) {
      if (match.start > lastIndex) {
        segments.add(
          _Segment(data.substring(lastIndex, match.start), isMath: false),
        );
      }
      segments.add(_Segment(match.group(0)!, isMath: true));
      lastIndex = match.end;
    }
    if (lastIndex < data.length) {
      segments.add(_Segment(data.substring(lastIndex), isMath: false));
    }
    return segments;
  }
}

class _Segment {
  final String text;
  final bool isMath;
  _Segment(this.text, {required this.isMath});
}