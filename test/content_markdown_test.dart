// Il compilatore del Markdown delle lezioni (`tool/content/`): `content/*.md` →
// `assets/data/lessons/*.json`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/content/builder.dart';
import '../tool/content/json_format.dart';
import '../tool/content/md_compiler.dart';
import '../tool/content/md_exporter.dart';

const _front = '''
---
level: high-school
year: year2
section: s
topic: t
title: Prova
---
''';

Map<String, dynamic> _compile(String body) => compileMarkdown('$_front$body');

/// Il JSON com'è per l'app, senza le differenze che non cambiano niente a
/// runtime (un `content` stringa o lista, un titolo vuoto, un `content` vuoto).
Object? _norm(Object? v) {
  if (v is Map) {
    final m = {for (final e in v.entries) e.key: _norm(e.value)};
    if (m.containsKey('box_type') && m['title'] == '') m.remove('title');
    if (m.containsKey('type') && m['content'] is String) {
      m['content'] = (m['content'] as String).split('\n');
    }
    if (m['content'] is List && (m['content'] as List).isEmpty) {
      m.remove('content');
    }
    return m;
  }
  if (v is List) return [for (final x in v) _norm(x)];
  return v;
}

void main() {
  group('i file del progetto', () {
    test('i JSON in assets sono quelli che escono dai .md', () {
      // Se fallisce: `dart run tool/build_content.dart`.
      final compiled = compileDirectory('content');
      for (final e in compiled.entries) {
        final file = File('assets/data/lessons/${e.key}');
        expect(file.existsSync(), isTrue, reason: '${e.key} manca in assets');
        expect(
          file.readAsStringSync(),
          e.value,
          reason: '${e.key} non è aggiornato: dart run tool/build_content.dart',
        );
      }
      final inAssets = [
        for (final f in Directory('assets/data/lessons').listSync())
          if (f is File && f.path.endsWith('.json')) f.uri.pathSegments.last,
      ];
      expect(
        inAssets.toSet(),
        compiled.keys.toSet(),
        reason: 'un JSON in assets non ha il suo .md in content/ (o viceversa)',
      );
    });

    test('esportare un JSON in Markdown e ricompilarlo non perde niente', () {
      for (final f in Directory('assets/data/lessons').listSync()) {
        if (f is! File ||
            !f.path.endsWith('.json') ||
            f.path.endsWith('index.json')) {
          continue;
        }
        final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        final md = exportMarkdown(json);
        expect(_norm(compileMarkdown(md)), _norm(json), reason: f.path);
      }
    });
  });

  group('formato del Markdown', () {
    test('lezione, card di testo, righe vuote e intestazioni', () {
      final json = _compile(r'''
# Prima {id=l1 minutes=4 subtitle="Una prova"}

## Card uno
Una riga.
\
### Titolo del testo
#### Intestazione
##### Sottointestazione
- un punto
''');
      final lesson = (json['lessons'] as List).single as Map<String, dynamic>;
      expect(lesson['id'], 'l1');
      expect(lesson['minutes'], 4);
      expect(lesson['subtitle'], 'Una prova');
      final step = (lesson['steps'] as List).single as Map<String, dynamic>;
      expect(step['type'], 'info');
      expect(step['title'], 'Card uno');
      expect(step['content'], [
        'Una riga.',
        '',
        '# Titolo del testo',
        '## Intestazione',
        '### Sottointestazione',
        '- un punto',
      ]);
    });

    test('i riquadri: formula, grafico e immagine', () {
      final json = _compile(r'''
# L {id=l}

## C
```formula {id=f1 size=1.2 hidden=false}
m = -\frac{a}{b}
```
```graph {id=g1 title="Una retta"}
{"plane": "cartesian", "x": [-2, 2], "items": [{"type": "function", "expr": "x"}]}
```
```image {id=i1}
assets/images/moduli.jpg
```
''');
      final content =
          ((((json['lessons'] as List).single as Map)['steps'] as List).single
                  as Map)['content']
              as List;
      expect(content[0], {
        'id': 'f1',
        'box_type': 'math_formula',
        'payload': {
          'tex': r'm = -\frac{a}{b}',
          'fontSizeMultiplier': 1.2,
          'hidden': false,
        },
      });
      expect((content[1] as Map)['title'], 'Una retta');
      expect(((content[1] as Map)['payload'] as Map)['x'], [-2, 2]);
      expect(
        ((content[2] as Map)['payload'] as Map)['source'],
        'assets/images/moduli.jpg',
      );
    });

    test('mcq e practice_quiz: la risposta giusta è [x]', () {
      final json = _compile(r'''
# L {id=l}

## Domanda {type=mcq}
```quiz
prompt: Quanto fa 1 + 1?
- [ ] 1
- [x] 2
explanation: Perché sì.
```

## Prova tu {type=practice_quiz}
```quiz
prompt: assets/images/moduli.jpg
text: Quale?
- [x] a
- [ ] b
```
```quiz
prompt: Secondo
- [ ] a
- [ ] b
- [x] c
```
''');
      final steps = ((json['lessons'] as List).single as Map)['steps'] as List;
      final mcq = steps[0] as Map;
      expect(mcq['type'], 'mcq');
      expect(mcq['options'], ['1', '2']);
      expect(mcq['correctIndex'], 1);
      expect(mcq['explanation'], 'Perché sì.');
      final practice = steps[1] as Map;
      expect(practice['type'], 'practice_quiz');
      final exercises = practice['exercises'] as List;
      expect(exercises, hasLength(2));
      expect((exercises[0] as Map)['correctIndex'], 0);
      expect((exercises[1] as Map)['correctIndex'], 2);
    });
  });

  group('errori, con la riga', () {
    void fails(String body, String expected, {int? line}) {
      try {
        _compile(body);
      } on ContentError catch (e) {
        expect(e.message, contains(expected));
        if (line != null) expect(e.line, line);
        return;
      }
      fail('doveva dare errore: $expected');
    }

    test('mancano front matter, lezione o id', () {
      expect(() => compileMarkdown('# L {id=l}'), throwsA(isA<ContentError>()));
      fails('', 'nessuna lezione');
      fails('# Lezione senza id\n', 'manca {id=');
    });

    test('card senza lezione o testo fuori da una card', () {
      fails('## Card\n', 'prima della prima lezione');
      fails('# L {id=l}\nTesto libero\n', 'fuori da una card');
    });

    test('quiz sbagliati', () {
      fails(
        '# L {id=l}\n## Q {type=mcq}\n```quiz\nprompt: x\n- [x] a\n- [x] b\n```\n',
        'più di una risposta giusta',
      );
      fails(
        '# L {id=l}\n## Q {type=mcq}\n```quiz\nprompt: x\n- [ ] a\n- [ ] b\n```\n',
        'manca la risposta giusta',
      );
      fails(
        '# L {id=l}\n## Q {type=mcq}\n```quiz\nprompt: x\n- [x] a\n```\n',
        'almeno 2 opzioni',
      );
      fails(
        '# L {id=l}\n## Q\n```quiz\nprompt: x\n- [x] a\n- [ ] b\n```\n',
        'tipo info',
      );
    });

    test('blocchi e attributi sbagliati', () {
      fails(
        '# L {id=l}\n## C\n```graph {id=g}\n{non json}\n```\n',
        'non si legge',
      );
      fails('# L {id=l}\n## C\n```formula\nx\n```\n', 'manca {id=');
      fails('# L {id=l}\n## C\n```formula {id=f}\nx\n', 'senza la chiusura');
      fails('# L {id=l}\n## C\n```strano {id=f}\nx\n```\n', 'sconosciuto');
      fails('# L {id=l capra=1}\n## C\n', 'attributo sconosciuto');
      fails('# L {id=l}\n## C {tipo=info}\n', 'attributo sconosciuto');
      fails('# L {id=l}\n## C {type=boh}\n', 'tipo di card sconosciuto');
      fails('# L {id=l}\n## C\n###### troppo\n', 'troppo profonda');
    });

    test('il numero di riga è quello del problema', () {
      // Il front matter sono 7 righe; poi una vuota, «# L», «## C» e la riga 11
      // apre il blocco che non si chiude: l'errore indica dove il blocco comincia.
      fails('\n# L {id=l}\n## C\n```formula {id=f}\nx\n', 'chiusura', line: 11);
    });
  });

  group('la forma dei JSON', () {
    test('gli array di numeri stanno su una riga', () {
      final text = formatJson({
        'x': [-3, 3],
        'points': [
          [0, 0],
          [2, 0],
        ],
        'items': [
          {'a': 1},
        ],
      });
      expect(text, contains('"x": [-3, 3],'));
      expect(text, contains('"points": [[0, 0], [2, 0]],'));
      expect(text, contains('"items": [\n        {\n'));
    });

    test('compactObjects mette un elemento semplice su una riga', () {
      final text = formatJson({
        'items': [
          {
            'type': 'point',
            'at': [1, 0],
          },
        ],
      }, compactObjects: true);
      expect(text, contains('{"type": "point", "at": [1, 0]}'));
    });
  });
}
