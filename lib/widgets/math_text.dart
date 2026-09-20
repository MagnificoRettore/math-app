import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../theme/app_colors.dart';

class MathText extends StatelessWidget {
  final String data;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;
  final FontWeight? fontWeight;

  const MathText(
    this.data, {
    super.key,
    this.fontSize = 16,
    this.color,
    this.textAlign = TextAlign.left,
    this.fontWeight,
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
            if (seg.isMath)
              _mathSpan(seg.text, effectiveColor, fontSize)
            else
              ..._plainSpans(seg.text, effectiveColor, fontSize),
        ],
      ),
    );
  }

  List<InlineSpan> _plainSpans(String text, Color color, double fontSize) {
    final bold = RegExp(r'<b>(.*?)</b>');
    final matches = bold.allMatches(text);
    if (matches.isEmpty) {
      return [
        TextSpan(text: text, style: TextStyle(fontSize: fontSize)),
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
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
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

  Widget _mathBlock(String tex, Color color, double fontSize) {
    final cleaned = _stripDollars(tex);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Math.tex(
        cleaned,
        textStyle:
            TextStyle(fontSize: fontSize * 1.1, color: color, fontWeight: fontWeight),
        options: MathOptions(
          fontSize: fontSize * 1.1,
          color: color,
          mathFontOptions: fontWeight == null
              ? null
              : FontOptions(fontWeight: fontWeight!),
        ),
      ),
    );
  }

  InlineSpan _mathSpan(String tex, Color color, double fontSize) {
    final cleaned = _stripDollars(tex);
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Math.tex(
        cleaned,
        textStyle:
            TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight),
        options: MathOptions(
          fontSize: fontSize,
          color: color,
          mathFontOptions: fontWeight == null
              ? null
              : FontOptions(fontWeight: fontWeight!),
        ),
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
    final block = RegExp(r'\$\$.*?\$\$');
    var lastIndex = 0;
    for (final match in block.allMatches(data)) {
      if (match.start > lastIndex) {
        segments.addAll(_splitInline(data.substring(lastIndex, match.start)));
      }
      segments.add(_Segment(match.group(0)!, isMath: true));
      lastIndex = match.end;
    }
    if (lastIndex < data.length) {
      segments.addAll(_splitInline(data.substring(lastIndex)));
    }
    return segments;
  }

  static List<_Segment> _splitInline(String text) {
    if (text.isEmpty) return const [];
    final segments = <_Segment>[];
    final inline = RegExp(r'\$[^$\n]+\$');
    var lastIndex = 0;
    for (final match in inline.allMatches(text)) {
      if (match.start > lastIndex) {
        segments.add(
          _Segment(text.substring(lastIndex, match.start), isMath: false),
        );
      }
      segments.add(_Segment(match.group(0)!, isMath: true));
      lastIndex = match.end;
    }
    if (lastIndex < text.length) {
      segments.add(_Segment(text.substring(lastIndex), isMath: false));
    }
    return segments;
  }
}

class _Segment {
  final String text;
  final bool isMath;
  _Segment(this.text, {required this.isMath});
}
