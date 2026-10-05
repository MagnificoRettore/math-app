// Valida i contenuti delle lezioni (`assets/data/lessons/*.json`).
//
// Due parti:
//  1. controlli sui dati: struttura, id, risposte, asset, formule LaTeX,
//     grafici (nessun elemento scartato in silenzio, funzioni calcolabili);
//  2. controlli di resa: ogni card di ogni lezione si disegna, senza overflow
//     né errori, su più dimensioni di telefono e con il testo del sistema più
//     grande.
//
// Un contenuto sbagliato qui fa fallire il test con il suo posto esatto
// (file, lezione, card, dimensione), invece di mostrarsi a runtime.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/tex.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/models/multifunction_box/box_type.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/expression_evaluator.dart';
import 'package:math_app/widgets/prompt_view.dart';

const _lessonsDir = 'assets/data/lessons';

/// I telefoni su cui ogni card deve stare: dal più stretto supportato (320)
/// al tablet. Larghezze e altezze in punti logici.
const _screens = <(String, Size)>[
  ('320×640', Size(320, 640)),
  ('360×800', Size(360, 800)),
  ('393×852', Size(393, 852)),
  ('412×915', Size(412, 915)),
  ('600×960 tablet', Size(600, 960)),
];

/// Il testo del sistema: normale e ingrandito (impostazione di accessibilità).
const _textScales = [1.0, 1.3];

const _stepTypes = {
  'info',
  'definition',
  'mcq',
  'multiple_choice',
  'practice_quiz',
  'practice',
};

List<String> _lessonFiles() {
  final index = jsonDecode(
    File('$_lessonsDir/index.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return [for (final f in index['argomenti'] as List<dynamic>) f as String];
}

Map<String, dynamic> _readFile(String name) =>
    jsonDecode(File('$_lessonsDir/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Tutte le formule scritte in una stringa di testo (`$...$` e `$$...$$`).
List<String> _formulasIn(String text) => [
  for (final m in RegExp(r'\$\$(.+?)\$\$|\$([^$\n]+)\$').allMatches(text))
    (m.group(1) ?? m.group(2))!,
];

/// Un `$` rimasto senza compagno: il testo si disegnerebbe a metà.
bool _hasUnpairedDollar(String text) {
  final left = text.replaceAll(RegExp(r'\$\$(.+?)\$\$|\$([^$\n]+)\$'), '');
  return left.contains(r'$');
}

/// Se il LaTeX si legge; altrimenti il messaggio dell'errore.
String? _texError(String tex) {
  try {
    TexParser(tex, const TexParserSettings()).parse();
    return null;
  } catch (e) {
    return '$e'.split('\n').first;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('dati', () {
    final names = _lessonFiles();

    test('index.json elenca solo file che esistono, senza doppioni', () {
      expect(names.toSet(), hasLength(names.length));
      for (final name in names) {
        expect(
          File('$_lessonsDir/$name').existsSync(),
          isTrue,
          reason: '$name è in index.json ma il file non c\'è',
        );
      }
      final onDisk = [
        for (final f in Directory(_lessonsDir).listSync())
          if (f is File &&
              f.path.endsWith('.json') &&
              !f.path.endsWith('index.json'))
            f.uri.pathSegments.last,
      ];
      for (final name in onDisk) {
        expect(
          names,
          contains(name),
          reason: '$name non è registrato in index.json: non verrebbe caricato',
        );
      }
    });

    test('gli id delle lezioni sono unici in tutti i file', () {
      final seen = <String, String>{};
      final problems = <String>[];
      for (final name in names) {
        for (final l in _readFile(name)['lessons'] as List<dynamic>) {
          final id = (l as Map<String, dynamic>)['id'] as String? ?? '';
          final other = seen[id];
          if (other != null) problems.add('$id in $name e in $other');
          seen[id] = name;
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('i file sono formattati come da JSON_GUIDELINES.md', () async {
      final ProcessResult result;
      try {
        result = await Process.run('python3', [
          'tool/format_json.py',
          '--check',
        ]);
      } on ProcessException {
        markTestSkipped('python3 non c\'è: formattazione non controllata');
        return;
      }
      expect(
        result.exitCode,
        0,
        reason: '${result.stdout}\nLancia: python3 tool/format_json.py',
      );
    });

    for (final name in names) {
      test('$name: struttura, risposte, asset, formule e grafici', () {
        final problems = <String>[];
        final file = _readFile(name);
        for (final key in ['level', 'year', 'section', 'topic', 'title']) {
          if ((file[key] as String? ?? '').isEmpty) {
            problems.add('manca "$key" nel file');
          }
        }
        final lessons = file['lessons'] as List<dynamic>? ?? const [];
        if (lessons.isEmpty) problems.add('nessuna lezione');
        for (final l in lessons) {
          _validateLesson(l as Map<String, dynamic>, problems);
        }
        expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
      });
    }
  });

  group('resa', () {
    // Senza i font veri i test misurano il testo con un carattere quadrato (ogni
    // lettera larga quanto è alta) e ogni riga sembrerebbe troppo larga: si
    // caricano quelli dell'app, compresi i KaTeX delle formule.
    setUpAll(() async {
      final manifest = jsonDecode(
        await rootBundle.loadString('FontManifest.json'),
      ) as List<dynamic>;
      for (final family in manifest) {
        final loader = FontLoader(family['family'] as String);
        for (final font in family['fonts'] as List<dynamic>) {
          loader.addFont(rootBundle.load(font['asset'] as String));
        }
        await loader.load();
      }
    });

    // Il caricamento sta in `setUp` (zona reale): dentro un `testWidgets` gli
    // asset non si caricano.
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LessonRepository.instance.resetForTest();
      await ProgressStore.instance.resetForTest();
    });

    testWidgets('ogni card di ogni lezione si disegna senza errori su tutte le '
        'dimensioni e con il testo ingrandito', (tester) async {
      final lessons = [
        for (final a in LessonRepository.instance.argomenti)
          for (final l in a.lessons) (a.levelId, l),
      ];
      expect(lessons, isNotEmpty);
      final problems = <String>[];
      try {
        for (final (levelId, lesson) in lessons) {
          for (final (label, size) in _screens) {
            for (final scale in _textScales) {
              await _renderLesson(
                tester,
                levelId,
                lesson,
                label,
                size,
                scale,
                problems,
              );
            }
          }
        }
      } finally {
        tester.view.reset();
      }
      final unique = problems.toSet().toList();
      expect(unique, isEmpty, reason: '\n${unique.join('\n')}');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}

/// Disegna tutte le card di [lesson] su uno schermo e riporta gli errori di
/// disegno (overflow soprattutto) in [problems], col loro posto esatto.
Future<void> _renderLesson(
  WidgetTester tester,
  String levelId,
  Lesson lesson,
  String label,
  Size size,
  double scale,
  List<String> problems,
) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      // La chiave: una lezione nuova riparte da capo, senza ereditare la card
      // in cui era arrivata la precedente.
      home: LessonScreen(
        key: ValueKey('${lesson.id}-$label-$scale'),
        lesson: lesson,
        levelId: levelId,
      ),
    ),
  );
  for (var i = 0; i < lesson.steps.length; i++) {
    final step = lesson.steps[i];
    final where =
        '${lesson.id}, card ${i + 1} "${step.title}", $label, testo ×$scale';
    await tester.pump(const Duration(milliseconds: 600));
    _collect(tester, where, problems);
    // Le verifiche mostrano un esercizio per volta: si scorrono tutti, ognuno
    // deve stare nello schermo.
    if (step.isPracticeQuiz && step.exercises.length > 1) {
      final reload = find.byIcon(Icons.refresh_rounded);
      for (var r = 1; r < step.exercises.length; r++) {
        if (reload.evaluate().isEmpty) break;
        await tester.tap(reload, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 400));
        _collect(tester, '$where, esercizio ${r + 1}', problems);
      }
    }
    if (i < lesson.steps.length - 1) {
      if (find.byType(PageView).evaluate().isEmpty) {
        problems.add('$where → la lezione non mostra le card');
        return;
      }
      await tester.drag(
        find.byType(PageView),
        Offset(-size.width * 0.9, 0),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 600));
    }
  }
}

/// Prende l'errore di disegno in sospeso, se c'è, e lo mette in [problems].
void _collect(WidgetTester tester, String where, List<String> problems) {
  final error = tester.takeException();
  if (error != null) {
    problems.add('$where → ${'$error'.split('\n').take(2).join(' ')}');
  }
}

void _validateLesson(Map<String, dynamic> lesson, List<String> problems) {
  final id = lesson['id'] as String? ?? '';
  if (id.isEmpty) problems.add('lezione senza "id"');
  if ((lesson['title'] as String? ?? '').isEmpty) {
    problems.add('$id: manca "title"');
  }
  final steps = lesson['steps'] as List<dynamic>? ?? const [];
  if (steps.isEmpty) problems.add('$id: nessuna card');
  final boxIds = <String>{};
  for (final (i, s) in steps.indexed) {
    final step = s as Map<String, dynamic>;
    final at = '$id, card ${i + 1} "${step['title'] ?? ''}"';
    final type = step['type'] as String? ?? 'info';
    if (!_stepTypes.contains(type.toLowerCase())) {
      problems.add('$at: tipo sconosciuto "$type"');
    }
    final kind = type.toLowerCase();
    if (kind == 'mcq' || kind == 'multiple_choice') {
      _validateQuestion(step, at, problems);
    }
    if (kind == 'practice_quiz' || kind == 'practice') {
      final exercises = step['exercises'] as List<dynamic>? ?? const [];
      if (exercises.isEmpty) problems.add('$at: nessun esercizio');
      for (final (j, e) in exercises.indexed) {
        _validateQuestion(
          e as Map<String, dynamic>,
          '$at, esercizio ${j + 1}',
          problems,
        );
      }
    }
    _validateContent(step['content'], at, boxIds, problems);
    for (final key in ['explanation', 'prompt']) {
      _validateText(step[key] as String? ?? '', '$at ($key)', problems);
    }
  }
}

void _validateQuestion(
  Map<String, dynamic> q,
  String at,
  List<String> problems,
) {
  final options = q['options'] as List<dynamic>? ?? const [];
  final correct = q['correctIndex'] as int? ?? -1;
  if ((q['prompt'] as String? ?? '').isEmpty &&
      (q['text'] as String? ?? '').isEmpty) {
    problems.add('$at: manca la domanda ("prompt")');
  }
  if (options.length < 2) problems.add('$at: servono almeno 2 opzioni');
  if (correct < 0 || correct >= options.length) {
    problems.add(
      '$at: "correctIndex" $correct fuori dalle ${options.length} opzioni',
    );
  }
  if (options.toSet().length != options.length) {
    problems.add('$at: due opzioni uguali');
  }
  final prompt = q['prompt'] as String? ?? '';
  if (PromptView.isImageSource(prompt) && !File(prompt).existsSync()) {
    problems.add('$at: immagine "$prompt" non trovata');
  }
  for (final key in ['prompt', 'text', 'explanation']) {
    final value = q[key] as String? ?? '';
    if (!PromptView.isImageSource(value)) {
      _validateText(value, '$at ($key)', problems);
    }
  }
  for (final o in options) {
    _validateText('$o', '$at (opzione)', problems);
  }
}

void _validateText(String text, String at, List<String> problems) {
  if (_hasUnpairedDollar(text)) {
    problems.add('$at: un "\$" senza compagno in "$text"');
  }
  for (final tex in _formulasIn(text)) {
    final error = _texError(tex);
    if (error != null) problems.add('$at: LaTeX "$tex" non si legge ($error)');
  }
}

void _validateContent(
  Object? content,
  String at,
  Set<String> boxIds,
  List<String> problems,
) {
  if (content is String) {
    _validateText(content, at, problems);
    return;
  }
  if (content is! List) return;
  for (final segment in content) {
    if (segment is String) {
      _validateText(segment, at, problems);
    } else if (segment is Map<String, dynamic>) {
      _validateBox(segment, at, boxIds, problems);
    }
  }
}

void _validateBox(
  Map<String, dynamic> raw,
  String at,
  Set<String> boxIds,
  List<String> problems,
) {
  final id = raw['id'] as String? ?? '';
  final where = '$at, riquadro "$id"';
  if (id.isEmpty) problems.add('$at: un riquadro senza "id"');
  if (!boxIds.add(id)) problems.add('$where: id già usato nella lezione');
  final type = raw['box_type'] as String? ?? '';
  if (!['image', 'math_formula', 'graph'].contains(type)) {
    problems.add('$where: box_type "$type" sconosciuto');
    return;
  }
  final box = MultifunctionBox.fromJson(raw);
  final payload = raw['payload'] as Map<String, dynamic>? ?? const {};
  switch (box.payload) {
    case ImageBoxPayload(:final source):
      if (source.startsWith('assets/') && !File(source).existsSync()) {
        problems.add('$where: immagine "$source" non trovata');
      }
    case MathFormulaPayload(:final tex):
      if (tex.trim().isEmpty) problems.add('$where: formula vuota');
      final error = _texError(tex);
      if (error != null) problems.add('$where: LaTeX non si legge ($error)');
    case GraphPayload graph:
      _validateGraph(graph, payload, where, problems);
  }
  if (box.boxType == BoxType.image && !payload.containsKey('source')) {
    problems.add('$where: immagine senza "source"');
  }
}

void _validateGraph(
  GraphPayload graph,
  Map<String, dynamic> raw,
  String where,
  List<String> problems,
) {
  // Un elemento che non si capisce viene saltato in silenzio a runtime: qui è
  // un errore, altrimenti il grafico mostra meno di quello che hai scritto.
  final rawItems = (raw['items'] as List<dynamic>? ?? const []).length;
  if (graph.items.length != rawItems) {
    problems.add(
      '$where: ${rawItems - graph.items.length} elementi su $rawItems del '
      'grafico non si capiscono e verrebbero saltati',
    );
  }
  if (graph.isEmpty) problems.add('$where: grafico vuoto');
  for (final key in ['x', 'y']) {
    final range = raw[key];
    if (range != null &&
        !(range is List && range.length == 2 && range[0] < range[1])) {
      problems.add('$where: "$key" deve essere [min, max] con min < max');
    }
  }
  for (final item in raw['items'] as List<dynamic>? ?? const []) {
    if (item is! Map<String, dynamic>) continue;
    final expr = item['expr'] as String?;
    if (item['type'] == 'function' && expr != null) {
      final finite = [
        for (var x = -10.0; x <= 10; x += 0.5)
          ExpressionEvaluator.tryEvaluate(expr, x: x),
      ].any((v) => v != null);
      if (!finite) {
        problems.add('$where: la funzione "$expr" non dà mai un valore');
      }
    }
    final label = item['label'] as String?;
    if (label != null) {
      final error = _texError(label);
      if (error != null) {
        problems.add('$where: etichetta "$label" non si legge ($error)');
      }
    }
  }
}
