import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/search_index.dart';

/// Tipi che la ricerca dell'header mostra: argomenti e lezioni.
const _scelti = [ResultType.argomento, ResultType.lesson];

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await ContentRepository.instance.resetForTest();
  await LessonRepository.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

void main() {
  // I repository leggono gli asset con `rootBundle`: senza il binding
  // inizializzato il caricamento nel `setUp` non trova nulla.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  test('la ricerca trova l\'argomento dal titolo', () {
    final moduli = SearchIndex.instance.search('moduli', types: _scelti);

    expect(moduli.length, 1);
    expect(moduli.single.type, ResultType.argomento);
    expect(moduli.single.argomento?.title, 'Moduli');
  });

  test(
    'la ricerca trova anche le lezioni, col titolo dell\'argomento sotto',
    () {
      final modulo = SearchIndex.instance.search('modulo', types: _scelti);

      final lezione = modulo.firstWhere((r) => r.type == ResultType.lesson);
      expect(lezione.lesson?.id, 'mod-equations-intro');
      expect(lezione.argomento?.title, 'Moduli');
    },
  );

  test('gli argomenti vengono prima delle lezioni', () {
    final modulo = SearchIndex.instance.search('modul', types: _scelti);

    expect(modulo.length, greaterThan(1));
    expect(modulo.first.type, ResultType.argomento);
    expect(modulo.last.type, ResultType.lesson);
  });

  test(
    'una lezione si trova col suo titolo, non con quello dell\'argomento',
    () {
      // «Definizione» sta sotto Moduli ma nel suo titolo «moduli» non c'è:
      // cercare «moduli» non deve tirarla fuori.
      final moduli = SearchIndex.instance.search('moduli', types: _scelti);
      expect(moduli.any((r) => r.lesson?.id == 'mod-definition'), isFalse);

      final definizione = SearchIndex.instance.search(
        'definizione',
        types: _scelti,
      );
      expect(definizione.length, 1);
      expect(definizione.single.lesson?.id, 'mod-definition');
    },
  );

  test('il sottotitolo è cercato insieme al titolo', () {
    // «distanza» è nel sottotitolo di «Modulo e Equazioni con Modulo» e nel
    // titolo non c'è.
    final risultati = SearchIndex.instance.search('distanza', types: _scelti);

    expect(risultati.single.lesson?.id, 'mod-equations-intro');
  });

  test(
    'il risultato porta il nome del livello, così i livelli non si confondono',
    () {
      final moduli = SearchIndex.instance.search('moduli', types: _scelti);

      expect(moduli.every((r) => r.level?.title.isNotEmpty == true), isTrue);
    },
  );

  test('la ricerca non guarda il livello dello studente', () {
    // Nessun utente è registrato qui: se l'indice filtrasse per il profilo, di
    // fronte a un ospite non restituirebbe niente. «Frazioni» esiste in due
    // livelli, quindi i risultati attraversano la scuola media e il liceo.
    final frazioni = SearchIndex.instance.search('frazioni');

    final levels = frazioni.map((r) => r.level?.id).toSet();
    expect(levels.length, greaterThan(1));
  });

  test('il filtro scarta topic ed esercizi anche quando il titolo torna', () {
    // «Frazioni» è un topic dell'albero esercizi e non è un argomento: con il
    // filtro non deve comparire.
    final frazioni = SearchIndex.instance.search('frazioni', types: _scelti);

    expect(frazioni, isEmpty);
  });

  test('senza il filtro il ramo esercizi risponde ancora', () {
    final quadratiche = SearchIndex.instance.search('quadratiche');

    expect(quadratiche, isNotEmpty);
    expect(quadratiche.any((r) => r.type == ResultType.exercise), isTrue);
  });

  test('query vuota non dà risultati', () {
    expect(SearchIndex.instance.search('', types: _scelti), isEmpty);
    expect(SearchIndex.instance.search('   ', types: _scelti), isEmpty);
  });

  test('ogni tipo sa dichiarare come si chiama in italiano', () {
    // L'etichetta è il dato, non la sua rappresentazione: la riga del risultato
    // la mostra e ogni altro posto che mostra un tipo dirà la stessa parola.
    expect(ResultType.argomento.label, 'Argomento');
    expect(ResultType.lesson.label, 'Lezione');
    // Il ramo esercizi non ha punti d'ingresso nell'app, ma l'enum è completo e
    // le sue etichette non devono inventare parole nuove.
    expect(ResultType.topic.label, 'Topic');
    expect(ResultType.exercise.label, 'Esercizio');
  });
}
