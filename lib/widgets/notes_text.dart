import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/multifunction_box/multifunction_box.dart';
import '../theme/app_colors.dart';
import 'math_text.dart';
import 'multifunction_box_widget.dart';

enum NotesBlockType { title, heading, subheading, body, mono, bullet }

enum NotesAlign { left, center, right }

sealed class _Line {
  const _Line();
}

class _TextLine extends _Line {
  final String raw;
  const _TextLine(this.raw);
}

class _BoxLine extends _Line {
  final MultifunctionBox box;
  const _BoxLine(this.box);
}

sealed class _Node {
  const _Node();
}

class _Block extends _Node {
  final NotesBlockType type;
  final NotesAlign align;
  final String text;
  final MultifunctionBox? box;

  const _Block(this.type, this.align, this.text, [this.box]);

  bool get isBox => box != null;
}

enum _CalloutKind { warning, takeaway }

class _Callout extends _Node {
  final _CalloutKind kind;
  final List<_Block> children;

  const _Callout(this.kind, this.children);
}

class NotesText extends StatelessWidget {
  static const int _maxBoxScan = 200;

  final String data;
  final double baseFontSize;
  final double fontScale;
  final Color? color;

  const NotesText(
    this.data, {
    super.key,
    this.baseFontSize = 17,
    this.fontScale = 1.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final effectiveColor = color ?? c.textPrimary;
    final nodes = _parseBlocks(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < nodes.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == nodes.length - 1 ? 0 : 8),
            child: _buildNode(context, nodes[i], effectiveColor),
          ),
      ],
    );
  }

  List<_Node> _parseBlocks(String data) {
    final result = <_Node>[];
    _CalloutKind? pending;
    final calloutChildren = <_Block>[];
    var pendingAlign = NotesAlign.left;

    void closeCallout() {
      if (pending == null) return;
      result.add(_Callout(pending!, List.of(calloutChildren)));
      calloutChildren.clear();
      pending = null;
    }

    for (final line in _tokenizeLines(data)) {
      if (line is _BoxLine) {
        closeCallout();
        result.add(_Block(NotesBlockType.body, NotesAlign.left, '', line.box));
        continue;
      }
      final rawLine = (line as _TextLine).raw;
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) {
        closeCallout();
        continue;
      }

      final calloutMatch = RegExp(
        r'^:::(?<word>[A-Za-z]+)\b\s*(?<rest>.*)$',
      ).firstMatch(trimmed);
      if (calloutMatch != null) {
        final kind = _calloutKindFrom(calloutMatch.group(1)!);
        if (kind != null) {
          if (pending != null && pending != kind) {
            closeCallout();
          }
          pending = kind;
          final rest = calloutMatch.group(2)!.trim();
          if (rest.isNotEmpty) {
            calloutChildren.add(
              _Block(NotesBlockType.body, NotesAlign.left, rest),
            );
          }
          continue;
        }
        closeCallout();
        result.add(_Block(NotesBlockType.body, NotesAlign.left, trimmed));
        continue;
      }

      if (trimmed.startsWith('#')) {
        closeCallout();
      }

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

      final block = _Block(type, align, text);
      if (pending == null) {
        result.add(block);
      } else {
        calloutChildren.add(block);
      }
    }
    closeCallout();
    return result;
  }

  _CalloutKind? _calloutKindFrom(String word) {
    switch (word.toLowerCase()) {
      case 'attenzione':
      case 'warning':
      case 'pericolo':
        return _CalloutKind.warning;
      case 'takeaway':
      case 'suggerimento':
      case 'consiglio':
      case 'tip':
        return _CalloutKind.takeaway;
      default:
        return null;
    }
  }

  Widget _buildNode(BuildContext context, _Node node, Color color) {
    if (node is _Callout) return _buildCallout(context, node, color);
    return _buildBlock(context, node as _Block, color);
  }

  Widget _buildCallout(
    BuildContext context,
    _Callout callout,
    Color baseColor,
  ) {
    final c = AppColors.of(context);
    final (calloutColor, icon, label) = switch (callout.kind) {
      _CalloutKind.warning => (
        c.medium,
        Icons.warning_amber_rounded,
        'Attenzione',
      ),
      _CalloutKind.takeaway => (
        c.accent,
        Icons.lightbulb_outline,
        'Takeaway',
      ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: calloutColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: calloutColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: calloutColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: calloutColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < callout.children.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == callout.children.length - 1 ? 0 : 6,
              ),
              child: _buildBlock(context, callout.children[i], baseColor),
            ),
        ],
      ),
    );
  }

  List<_Line> _tokenizeLines(String data) {
    final lines = data.split('\n');
    final out = <_Line>[];
    var i = 0;
    while (i < lines.length) {
      final trimmed = lines[i].trim();
      if (trimmed == '::box' || trimmed.startsWith('::box ')) {
        var rest = trimmed.startsWith('::box ') ? trimmed.substring(5) : '';
        rest = rest.trim();
        if (rest.endsWith('::endbox')) {
          rest = rest.substring(0, rest.length - '::endbox'.length).trim();
        }
        var endIndex = -1;
        final scanLimit = math.min(lines.length, i + 1 + _maxBoxScan);
        for (var j = i + 1; j < scanLimit; j++) {
          if (lines[j].trim() == '::endbox') {
            endIndex = j;
            break;
          }
        }
        final parts = <String>[if (rest.isNotEmpty) rest];
        if (endIndex != -1) {
          for (var j = i + 1; j < endIndex; j++) {
            parts.add(lines[j]);
          }
        }
        if (parts.isEmpty) {
          out.add(_TextLine(lines[i]));
          i++;
          continue;
        }
        final jsonText = parts.join('\n');
        try {
          final box = MultifunctionBox.fromJson(
            jsonDecode(jsonText) as Map<String, dynamic>,
          );
          out.add(_BoxLine(box));
        } catch (_) {
          if (endIndex == -1) {
            out.add(_TextLine(lines[i]));
          } else {
            for (var j = i; j < endIndex; j++) {
              out.add(_TextLine(lines[j]));
            }
          }
        }
        i = endIndex == -1 ? i + 1 : endIndex + 1;
        continue;
      }
      out.add(_TextLine(lines[i]));
      i++;
    }
    return out;
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
    if (block.isBox) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: MultifunctionBoxWidget(box: block.box!),
      );
    }
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
        NotesBlockType.title => (28 * fontScale, FontWeight.w800, null),
        NotesBlockType.heading => (22 * fontScale, FontWeight.w700, null),
        NotesBlockType.subheading => (17 * fontScale, FontWeight.w600, null),
        NotesBlockType.body => (baseFontSize * fontScale, FontWeight.w400, null),
        NotesBlockType.mono => (14 * fontScale, FontWeight.w400, 'monospace'),
        NotesBlockType.bullet => (
          baseFontSize * fontScale,
          FontWeight.w400,
          null,
        ),
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
      style = style.copyWith(
        fontFamily: 'monospace',
        fontSize: 14 * fontScale,
      );
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
