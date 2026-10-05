// Compila i contenuti: `content/*.md` → `assets/data/lessons/*.json`.
//
//   dart run tool/build_content.dart            # compila e scrive
//   dart run tool/build_content.dart --check    # non scrive; esce con 1 se i JSON non sono aggiornati
//   dart run tool/build_content.dart --import   # una tantum: dai JSON in assets ai .md in content/
//
// Il Markdown è la sorgente; i JSON in assets sono generati (e committati, così
// l'app non ha bisogno del compilatore).
import 'dart:convert';
import 'dart:io';

import 'content/builder.dart';
import 'content/md_compiler.dart';
import 'content/md_exporter.dart';

const _contentDir = 'content';
const _assetsDir = 'assets/data/lessons';

void main(List<String> args) {
  if (args.contains('--import')) {
    Directory(_contentDir).createSync();
    final index = jsonDecode(
      File('$_assetsDir/index.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final name in index['argomenti'] as List<dynamic>) {
      final json = jsonDecode(
        File('$_assetsDir/$name').readAsStringSync(),
      ) as Map<String, dynamic>;
      final md = exportMarkdown(json);
      File('$_contentDir/${(name as String).replaceAll('.json', '.md')}')
          .writeAsStringSync(md);
      stdout.writeln('content/${name.replaceAll('.json', '.md')}');
    }
    return;
  }
  final Map<String, String> compiled;
  try {
    compiled = compileDirectory(_contentDir);
  } on ContentError catch (e) {
    stderr.writeln(
      '${e.message.split(': ').first}: riga ${e.line}: ${e.message.substring(e.message.indexOf(': ') + 2)}',
    );
    exit(2);
  }
  final stale = <String>[];
  for (final e in compiled.entries) {
    final file = File('$_assetsDir/${e.key}');
    if (!file.existsSync() || file.readAsStringSync() != e.value) {
      stale.add(e.key);
      if (!args.contains('--check')) file.writeAsStringSync(e.value);
    }
  }
  // Un JSON in assets senza il suo .md non verrebbe più rigenerato.
  final orphans = [
    for (final f in Directory(_assetsDir).listSync().whereType<File>())
      if (f.path.endsWith('.json') &&
          !compiled.containsKey(f.uri.pathSegments.last))
        f.uri.pathSegments.last,
  ];
  for (final o in orphans) {
    stdout.writeln('senza sorgente in content/: $o');
  }
  for (final s in stale) {
    stdout.writeln(
      args.contains('--check') ? 'da compilare: $s' : 'scritto: $s',
    );
  }
  if (stale.isEmpty && orphans.isEmpty) stdout.writeln('tutto aggiornato');
  if (args.contains('--check') && (stale.isNotEmpty || orphans.isNotEmpty)) {
    exit(1);
  }
}
