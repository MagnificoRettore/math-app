import 'dart:convert';

import 'json_format.dart';

/// Un errore nel Markdown di una lezione, con la riga (da 1) in cui sta.
class ContentError implements Exception {
  final String message;
  final int line;

  ContentError(this.message, this.line);

  @override
  String toString() => 'riga $line: $message';
}

/// Il Markdown delle lezioni (`content/*.md`) → il JSON che legge l'app.
///
/// Il formato è descritto in `JSON_GUIDELINES.md` («Scrivere una lezione in
/// Markdown»). In breve:
///
/// - front matter fra `---` con `level year section topic title subtitle icon`;
/// - `# Titolo {id=… minutes=…}` una lezione, `## Titolo {type=…}` una card;
/// - il testo della card, una riga per elemento; `\` da solo è una riga vuota;
///   le intestazioni del testo sono `###` (titolo), `####` (intestazione),
///   `#####` (sottointestazione);
/// - blocchi ```` ```graph ````, ```` ```formula ````, ```` ```image ```` per i
///   riquadri e ```` ```quiz ```` per le domande.
Map<String, dynamic> compileMarkdown(String source) =>
    _Compiler(source.replaceAll('\r\n', '\n').split('\n')).compile();

/// Come [compileMarkdown], già nella forma di testo dei JSON dei contenuti.
String compileToJsonText(String source) => formatJson(compileMarkdown(source));

class _Compiler {
  final List<String> lines;
  int i = 0;

  _Compiler(this.lines);

  int get _lineNo => i + 1;

  Map<String, dynamic> compile() {
    final file = _frontMatter();
    final lessons = <Map<String, dynamic>>[];
    Map<String, dynamic>? lesson;
    Map<String, dynamic>? card;
    var cardLine = 0;

    void closeCard() {
      if (card != null) {
        _finishCard(card!, cardLine);
        (lesson!['steps'] as List).add(card!);
        card = null;
      }
    }

    while (i < lines.length) {
      final raw = lines[i];
      final line = raw.trimRight();
      if (line.isEmpty) {
        i++;
        continue;
      }
      if (RegExp(r'^# ').hasMatch(line)) {
        closeCard();
        final (title, attrs) = _heading(line.substring(2));
        lesson = {
          'id': attrs.remove('id') ?? _fail('manca {id=…} nella lezione'),
          'title': title,
          'subtitle': attrs.remove('subtitle') ?? '',
          'minutes': int.parse(attrs.remove('minutes') ?? '0'),
          'steps': <Map<String, dynamic>>[],
        };
        _noLeftover(attrs, 'lezione');
        lessons.add(lesson);
        i++;
        continue;
      }
      if (RegExp(r'^## ').hasMatch(line)) {
        if (lesson == null) _fail('una card prima della prima lezione ("# …")');
        closeCard();
        cardLine = _lineNo;
        final (title, attrs) = _heading(line.substring(3));
        card = {
          '_attrs': attrs,
          'title': title,
          '_content': <Object?>[],
          '_quiz': <Map<String, dynamic>>[],
        };
        i++;
        continue;
      }
      if (card == null) _fail('testo fuori da una card: "$line"');
      if (line.startsWith('```')) {
        _block(card!, line);
        continue;
      }
      (card!['_content'] as List).add(_textLine(line));
      i++;
    }
    closeCard();
    if (lessons.isEmpty) _fail('nessuna lezione ("# Titolo {id=…}")');
    return {...file, 'lessons': lessons};
  }

  Never _fail(String message) => throw ContentError(message, _lineNo);

  void _noLeftover(Map<String, String> attrs, String what) {
    if (attrs.isNotEmpty) {
      _fail('attributo sconosciuto in $what: ${attrs.keys.join(', ')}');
    }
  }

  Map<String, dynamic> _frontMatter() {
    while (i < lines.length && lines[i].trim().isEmpty) {
      i++;
    }
    if (i >= lines.length || lines[i].trim() != '---') {
      _fail('il file deve cominciare con il front matter ("---")');
    }
    i++;
    final values = <String, String>{};
    while (i < lines.length && lines[i].trim() != '---') {
      final l = lines[i].trim();
      if (l.isNotEmpty) {
        final m = RegExp(r'^(\w+):\s*(.*)$').firstMatch(l);
        if (m == null) _fail('front matter: "$l" non è "chiave: valore"');
        var v = m.group(2)!;
        if (v.length >= 2 && v.startsWith('"') && v.endsWith('"')) {
          v = v.substring(1, v.length - 1);
        }
        values[m.group(1)!] = v;
      }
      i++;
    }
    if (i >= lines.length) _fail('front matter senza la "---" di chiusura');
    i++;
    const keys = [
      'level',
      'year',
      'section',
      'topic',
      'title',
      'subtitle',
      'icon',
    ];
    for (final k in ['level', 'year', 'section', 'topic', 'title']) {
      if (!values.containsKey(k)) _fail('front matter: manca "$k"');
    }
    for (final k in values.keys) {
      if (!keys.contains(k)) _fail('front matter: chiave sconosciuta "$k"');
    }
    return {
      for (final k in keys)
        if (values.containsKey(k)) k: values[k]!,
    };
  }

  /// «Titolo {a=1 b="due parole"}» → (titolo, attributi).
  (String, Map<String, String>) _heading(String text) {
    final m = RegExp(r'^(.*?)\s*\{([^}]*)\}\s*$').firstMatch(text);
    if (m == null) return (text.trim(), {});
    return (m.group(1)!.trim(), _attrs(m.group(2)!));
  }

  Map<String, String> _attrs(String text) {
    final out = <String, String>{};
    final re = RegExp(r'(\w+)=(?:"([^"]*)"|(\S+))');
    for (final m in re.allMatches(text)) {
      out[m.group(1)!] = m.group(2) ?? m.group(3)!;
    }
    if (re.allMatches(text).isEmpty
        ? text.trim().isNotEmpty
        : text.replaceAll(re, '').trim().isNotEmpty) {
      _fail('attributi non validi: "$text" (si scrive chiave=valore)');
    }
    return out;
  }

  /// Una riga di testo: `\` è una riga vuota; `###`… sono le intestazioni del
  /// testo (due livelli sotto, perché `#` e `##` sono lezione e card).
  String _textLine(String line) {
    if (line == r'\') return '';
    final m = RegExp(r'^(#{3,5}) ').firstMatch(line);
    if (m != null) {
      final level = m.group(1)!.length - 2;
      return '${'#' * level} ${line.substring(m.end)}';
    }
    if (RegExp(r'^#{6,} ').hasMatch(line)) {
      _fail('intestazione troppo profonda: "$line"');
    }
    return line;
  }

  void _block(Map<String, dynamic> card, String opening) {
    final startLine = _lineNo;
    final info = opening.substring(3).trim();
    final m = RegExp(r'^(\w+)\s*(?:\{([^}]*)\})?$').firstMatch(info);
    if (m == null) _fail('blocco non valido: "$opening"');
    final kind = m.group(1)!;
    final attrs = _attrs(m.group(2) ?? '');
    i++;
    final body = <String>[];
    while (i < lines.length && lines[i].trimRight() != '```') {
      body.add(lines[i]);
      i++;
    }
    if (i >= lines.length) {
      throw ContentError('blocco "$kind" senza la chiusura "```"', startLine);
    }
    i++;
    switch (kind) {
      case 'quiz':
        _noLeftover(attrs, 'quiz');
        (card['_quiz'] as List).add(_quiz(body, startLine));
        card['_quizLine'] = startLine;
      case 'graph':
      case 'formula':
      case 'image':
        (card['_content'] as List).add(_box(kind, attrs, body, startLine));
      default:
        throw ContentError('blocco sconosciuto "$kind"', startLine);
    }
  }

  Map<String, dynamic> _box(
    String kind,
    Map<String, String> attrs,
    List<String> body,
    int line,
  ) {
    ContentError err(String m) => ContentError(m, line);
    final id = attrs.remove('id') ?? (throw err('manca {id=…} nel blocco'));
    final title = attrs.remove('title');
    final hidden = attrs.remove('hidden');
    if (hidden != null && hidden != 'true' && hidden != 'false') {
      throw err('hidden deve essere true o false');
    }
    final payload = <String, dynamic>{};
    final String boxType;
    switch (kind) {
      case 'graph':
        boxType = 'graph';
        try {
          final decoded = jsonDecode(body.join('\n'));
          if (decoded is! Map<String, dynamic>) throw const FormatException();
          payload.addAll(decoded);
        } on FormatException catch (e) {
          throw err('il JSON del grafico non si legge (${e.message})');
        }
      case 'formula':
        boxType = 'math_formula';
        payload['tex'] = body.map((l) => l.trim()).join(' ').trim();
        final size = attrs.remove('size');
        if (size != null) payload['fontSizeMultiplier'] = double.parse(size);
      default:
        boxType = 'image';
        payload['source'] = body.map((l) => l.trim()).join().trim();
    }
    if (hidden != null) payload['hidden'] = hidden == 'true';
    if (attrs.isNotEmpty) {
      throw err('attributo sconosciuto: ${attrs.keys.join(', ')}');
    }
    return {'id': id, 'box_type': boxType, 'title': ?title, 'payload': payload};
  }

  /// ```quiz: `prompt:`, `text:`, `explanation:` e le opzioni `- [x]` / `- [ ]`.
  Map<String, dynamic> _quiz(List<String> body, int line) {
    final out = <String, dynamic>{};
    final options = <String>[];
    var correct = -1;
    for (final raw in body) {
      final l = raw.trim();
      if (l.isEmpty) continue;
      final opt = RegExp(r'^- \[([ xX])\] (.*)$').firstMatch(l);
      if (opt != null) {
        if (opt.group(1) != ' ') {
          if (correct != -1) {
            throw ContentError('più di una risposta giusta ([x])', line);
          }
          correct = options.length;
        }
        options.add(opt.group(2)!);
        continue;
      }
      final kv = RegExp(r'^(prompt|text|explanation):\s*(.*)$').firstMatch(l);
      if (kv == null) {
        throw ContentError('nel quiz non capisco "$l"', line);
      }
      out[kv.group(1)!] = kv.group(2)!;
    }
    if (options.length < 2) {
      throw ContentError('servono almeno 2 opzioni "- [ ] …"', line);
    }
    if (correct == -1) {
      throw ContentError('manca la risposta giusta ("- [x] …")', line);
    }
    return {
      'prompt': ?out['prompt'],
      'text': ?out['text'],
      'options': options,
      'correctIndex': correct,
      'explanation': ?out['explanation'],
    };
  }

  void _finishCard(Map<String, dynamic> card, int line) {
    final attrs = Map<String, String>.from(card.remove('_attrs') as Map);
    final content = card.remove('_content') as List<Object?>;
    final quiz = card.remove('_quiz') as List<Map<String, dynamic>>;
    card.remove('_quizLine');
    final type = attrs.remove('type') ?? 'info';
    final size = attrs.remove('size');
    if (attrs.isNotEmpty) {
      throw ContentError(
        'attributo sconosciuto nella card: ${attrs.keys.join(', ')}',
        line,
      );
    }
    final title = card['title'];
    card.clear();
    card['type'] = type;
    if (title != '') card['title'] = title;
    switch (type) {
      case 'info':
        if (quiz.isNotEmpty) {
          throw ContentError('un blocco quiz in una card di tipo info', line);
        }
        card['content'] = content;
      case 'mcq':
        if (quiz.length != 1) {
          throw ContentError('una card mcq ha esattamente un quiz', line);
        }
        if (content.isNotEmpty) card['content'] = content;
        card.addAll(quiz.single);
      case 'practice_quiz':
        if (quiz.isEmpty) {
          throw ContentError('una card practice_quiz ha dei quiz', line);
        }
        card['content'] = content;
        card['exercises'] = quiz;
      default:
        throw ContentError('tipo di card sconosciuto "$type"', line);
    }
    if (size != null) card['fontSizeMultiplier'] = double.parse(size);
  }
}
