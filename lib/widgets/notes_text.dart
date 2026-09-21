import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'math_text.dart';

enum NotesBlockType { title, heading, subheading, body, mono, bullet }

enum NotesAlign { left, center, right }

class _Block {
  final NotesBlockType type;
  final NotesAlign align;
  final String text;

  const _Block(this.type, this.align, this.text);
}

class NotesText extends StatelessWidget {
  final String data;
  final double baseFontSize;
  final Color? color;

  const NotesText(this.data, {super.key, this.baseFontSize = 17, this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final effectiveColor = color ?? c.textPrimary;
    final blocks = _parseBlocks(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == blocks.length - 1 ? 0 : 8),
            child: _buildBlock(context, blocks[i], effectiveColor),
          ),
      ],
    );
  }

  List<_Block> _parseBlocks(String data) {
    final result = <_Block>[];
    var pendingAlign = NotesAlign.left;
    for (final rawLine in data.split('\n')) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      var text = trimmed;
      var align = pendingAlign;
      pendingAlign = NotesAlign.left;
      final alignMatch = RegExp(r'^::(left|center|right)\b\s*(.*)$')
          .firstMatch(trimmed);
      if (alignMatch != null) {
        final direction = alignMatch.group(1)!;
        text = alignMatch.group(2)!.trim();
        if (text.isEmpty) {
          pendingAlign = _alignFrom(direction);
          continue;
        }
        align = _alignFrom(direction);
      }

      NotesBlockType type;
      if (text.startsWith('# ')) {
        type = NotesBlockType.title;
        text = text.substring(2);
      } else if (text.startsWith('## ')) {
        type = NotesBlockType.heading;
        text = text.substring(3);
      } else if (text.startsWith('### ')) {
        type = NotesBlockType.subheading;
        text = text.substring(4);
      } else if (_isMonostyleLine(text)) {
        type = NotesBlockType.mono;
        text = _stripMonostyle(text);
      } else if (text.startsWith('- ')) {
        type = NotesBlockType.bullet;
        text = text.substring(2);
      } else {
        type = NotesBlockType.body;
      }

      result.add(_Block(type, align, text));
    }
    return result;
  }

  NotesAlign _alignFrom(String value) => switch (value) {
    'center' => NotesAlign.center,
    'right' => NotesAlign.right,
    _ => NotesAlign.left,
  };

  bool _isMonostyleLine(String line) =>
      line.startsWith('`') && line.endsWith('`');

  String _stripMonostyle(String line) => line.substring(1, line.length - 1);

  Widget _buildBlock(BuildContext context, _Block block, Color color) {
    final styleDefaults = _defaultsFor(block.type);
    final base = TextStyle(
      fontSize: styleDefaults.$1,
      fontWeight: styleDefaults.$2,
      fontFamily: styleDefaults.$3,
      color: color,
      height: 1.35,
    );
    final spans = _inline(block.text, base);

    final align = _textAlignFor(block.align);
    final wrapAlign = _wrapAlignFor(block.align);

    if (block.type == NotesBlockType.bullet) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('•', style: base, textAlign: TextAlign.left),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(style: base, children: spans),
              ),
            ),
          ],
        ),
      );
    }

    if (block.type == NotesBlockType.mono) {
      return Align(
        alignment: wrapAlign,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: RichText(
            text: TextSpan(style: base, children: spans),
            textAlign: align,
          ),
        ),
      );
    }

    return Align(
      alignment: wrapAlign,
      child: RichText(
        text: TextSpan(style: base, children: spans),
        textAlign: align,
      ),
    );
  }

  TextAlign _textAlignFor(NotesAlign value) => switch (value) {
    NotesAlign.center => TextAlign.center,
    NotesAlign.right => TextAlign.right,
    NotesAlign.left => TextAlign.left,
  };

  Alignment _wrapAlignFor(NotesAlign value) => switch (value) {
    NotesAlign.center => Alignment.center,
    NotesAlign.right => Alignment.centerRight,
    NotesAlign.left => Alignment.centerLeft,
  };

  (double, FontWeight?, String?) _defaultsFor(NotesBlockType type) =>
      switch (type) {
        NotesBlockType.title => (28, FontWeight.w800, null),
        NotesBlockType.heading => (22, FontWeight.w700, null),
        NotesBlockType.subheading => (17, FontWeight.w600, null),
        NotesBlockType.body => (baseFontSize, FontWeight.w400, null),
        NotesBlockType.mono => (14, FontWeight.w400, 'monospace'),
        NotesBlockType.bullet => (baseFontSize, FontWeight.w400, null),
      };

  List<InlineSpan> _inline(String raw, TextStyle base) {
    final segments = splitMath(raw);
    final spans = <InlineSpan>[];
    for (final seg in segments) {
      if (seg.isMath) {
        spans.add(
          mathSpan(
            seg.text,
            fontSize: base.fontSize ?? baseFontSize,
            color: base.color ?? Colors.black,
            fontWeight: base.fontWeight,
          ),
        );
      } else {
        spans.addAll(_stylized(seg.text, base));
      }
    }
    return spans;
  }

  List<InlineSpan> _stylized(String text, TextStyle base) {
    if (text.isEmpty) return const [];
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*|__|~~|\*|`)');
    final stack = <String>[];
    var lastIndex = 0;

    void flush(int end) {
      if (end <= lastIndex) return;
      spans.add(
        TextSpan(
          text: text.substring(lastIndex, end),
          style: _applyFlags(stack, base),
        ),
      );
    }

    for (final match in regex.allMatches(text)) {
      flush(match.start);
      final token = match.group(1)!;
      if (stack.isNotEmpty && stack.last == token) {
        stack.removeLast();
      } else {
        stack.add(token);
      }
      lastIndex = match.end;
    }
    flush(text.length);
    return spans;
  }

  TextStyle _applyFlags(List<String> stack, TextStyle base) {
    var style = base;
    if (stack.contains('**')) {
      style = style.copyWith(fontWeight: FontWeight.w700);
    }
    if (stack.contains('*')) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (stack.contains('`')) {
      style = style.copyWith(fontFamily: 'monospace', fontSize: 14);
    }
    final decorations = <TextDecoration>[];
    if (stack.contains('__')) {
      decorations.add(TextDecoration.underline);
    }
    if (stack.contains('~~')) {
      decorations.add(TextDecoration.lineThrough);
    }
    if (decorations.isNotEmpty) {
      style = style.copyWith(decoration: TextDecoration.combine(decorations));
    }
    return style;
  }
}
