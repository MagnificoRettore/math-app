import 'dart:io';

import 'json_format.dart';
import 'md_compiler.dart';

/// I file che la compilazione di [contentDir] produce, nome → testo: un JSON
/// per ogni `.md` (in ordine alfabetico) e `index.json` che li elenca.
/// Lancia [ContentError] (con il nome del file) se un Markdown è sbagliato.
Map<String, String> compileDirectory(String contentDir) {
  final sources =
      Directory(contentDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final out = <String, String>{};
  for (final f in sources) {
    final name = f.uri.pathSegments.last.replaceAll(RegExp(r'\.md$'), '');
    try {
      out['$name.json'] = compileToJsonText(f.readAsStringSync());
    } on ContentError catch (e) {
      throw ContentError('${f.path}: ${e.message}', e.line);
    }
  }
  out['index.json'] = formatJson({
    'argomenti': [for (final name in out.keys) name],
  });
  return out;
}
