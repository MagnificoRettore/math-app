import 'json_format.dart';

/// Un JSON dei contenuti → il suo Markdown (l'inverso di `compileMarkdown`).
/// Serve a migrare i file già scritti a mano, e a verificare che il compilatore
/// non perda niente: `compile(export(json))` deve dare lo stesso contenuto.
///
/// Se nel JSON c'è qualcosa che il Markdown non sa dire (una chiave
/// sconosciuta, un'intestazione `#` nel testo…) lancia un errore invece di
/// perderlo in silenzio.
String exportMarkdown(Map<String, dynamic> file) {
  final out = StringBuffer('---\n');
  _only(file, const [
    'level',
    'year',
    'section',
    'topic',
    'title',
    'subtitle',
    'icon',
    'lessons',
  ], 'file');
  for (final k in [
    'level',
    'year',
    'section',
    'topic',
    'title',
    'subtitle',
    'icon',
  ]) {
    if (file.containsKey(k)) out.writeln('$k: ${file[k]}');
  }
  out.writeln('---');
  for (final l in file['lessons'] as List<dynamic>) {
    final lesson = l as Map<String, dynamic>;
    _only(lesson, const [
      'id',
      'title',
      'subtitle',
      'minutes',
      'steps',
    ], 'lezione');
    final attrs = [
      'id=${lesson['id']}',
      if ((lesson['subtitle'] as String? ?? '').isNotEmpty)
        'subtitle=${_quote(lesson['subtitle'] as String)}',
      if ((lesson['minutes'] as int? ?? 0) != 0) 'minutes=${lesson['minutes']}',
    ];
    out.writeln('\n# ${lesson['title']} {${attrs.join(' ')}}');
    for (final s in lesson['steps'] as List<dynamic>) {
      _card(out, s as Map<String, dynamic>);
    }
  }
  return out.toString();
}

String _quote(String v) => RegExp(r'\s').hasMatch(v) ? '"$v"' : v;

void _only(Map<String, dynamic> m, List<String> allowed, String what) {
  for (final k in m.keys) {
    if (!allowed.contains(k)) {
      throw StateError('$what: la chiave "$k" non ha un posto nel Markdown');
    }
  }
}

void _card(StringBuffer out, Map<String, dynamic> step) {
  _only(step, const [
    'type',
    'title',
    'content',
    'prompt',
    'options',
    'correctIndex',
    'explanation',
    'exercises',
    'fontSizeMultiplier',
  ], 'card "${step['title']}"');
  final type = switch ((step['type'] as String? ?? 'info').toLowerCase()) {
    'mcq' || 'multiple_choice' => 'mcq',
    'practice_quiz' || 'practice' => 'practice_quiz',
    'info' || 'definition' => 'info',
    final other => throw StateError('tipo di card "$other"'),
  };
  final attrs = [
    if (type != 'info') 'type=$type',
    if (step.containsKey('fontSizeMultiplier'))
      'size=${step['fontSizeMultiplier']}',
  ];
  final title = step['title'] as String? ?? '';
  out.writeln(
    '\n## $title${attrs.isEmpty ? '' : ' {${attrs.join(' ')}}'}'.replaceFirst(
      '##  ',
      '## ',
    ),
  );
  final content = step['content'];
  final items = content is String
      ? content.split('\n')
      : (content as List<dynamic>? ?? const []);
  for (final x in items) {
    if (x is String) {
      out.writeln(_textLine(x));
    } else {
      _box(out, x as Map<String, dynamic>);
    }
  }
  if (type == 'mcq') {
    out.writeln();
    _quiz(out, step);
  }
  for (final e in step['exercises'] as List<dynamic>? ?? const []) {
    out.writeln();
    _quiz(out, e as Map<String, dynamic>);
  }
}

String _textLine(String x) {
  if (x.isEmpty) return r'\';
  final m = RegExp(r'^(#{1,3}) ').firstMatch(x);
  if (m != null) {
    return '${'#' * (m.group(1)!.length + 2)} ${x.substring(m.end)}';
  }
  if (x.startsWith('```') || x == r'\' || RegExp(r'^#{4,} ').hasMatch(x)) {
    throw StateError('riga di testo che il Markdown non sa dire: "$x"');
  }
  if (x != x.trimRight()) {
    throw StateError('riga con spazi in fondo: "$x"');
  }
  return x;
}

void _box(StringBuffer out, Map<String, dynamic> box) {
  _only(box, const [
    'id',
    'box_type',
    'title',
    'payload',
  ], 'riquadro "${box['id']}"');
  final payload = Map<String, dynamic>.from(box['payload'] as Map);
  final title = box['title'] as String? ?? '';
  final attrs = <String>[
    'id=${box['id']}',
    if (title.isNotEmpty) 'title=${_quote(title)}',
  ];
  final hidden = payload.remove('hidden');
  if (hidden != null) attrs.add('hidden=$hidden');
  switch (box['box_type']) {
    case 'graph':
      out
        ..writeln('```graph {${attrs.join(' ')}}')
        ..write(formatJson(payload, compactObjects: true))
        ..writeln('```');
    case 'math_formula':
      _only(payload, const [
        'tex',
        'fontSizeMultiplier',
      ], 'formula "${box['id']}"');
      if (payload.containsKey('fontSizeMultiplier')) {
        attrs.add('size=${payload['fontSizeMultiplier']}');
      }
      out
        ..writeln('```formula {${attrs.join(' ')}}')
        ..writeln(payload['tex'])
        ..writeln('```');
    case 'image':
      _only(payload, const ['source'], 'immagine "${box['id']}"');
      out
        ..writeln('```image {${attrs.join(' ')}}')
        ..writeln(payload['source'])
        ..writeln('```');
    default:
      throw StateError('box_type "${box['box_type']}"');
  }
}

void _quiz(StringBuffer out, Map<String, dynamic> q) {
  out.writeln('```quiz');
  for (final k in ['prompt', 'text']) {
    if (q.containsKey(k)) out.writeln('$k: ${q[k]}');
  }
  final options = q['options'] as List<dynamic>;
  for (final (i, o) in options.indexed) {
    out.writeln('- [${i == q['correctIndex'] ? 'x' : ' '}] $o');
  }
  if (q.containsKey('explanation')) {
    out.writeln('explanation: ${q['explanation']}');
  }
  out.writeln('```');
}
