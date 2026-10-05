import '../models/argomento.dart';
import '../models/course.dart';
import '../models/exercise.dart';
import '../models/lesson.dart';
import '../models/level.dart';
import '../models/section.dart';
import '../models/topic.dart';
import 'lesson_repository.dart';

/// Ordine di come: gli argomenti e le lezioni sono ciò che la ricerca mostra,
/// i topic e gli esercizi restano indicizzati per il ramo esercizi.
enum ResultType {
  argomento,
  lesson,
  topic,
  exercise;

  /// Come si chiama il tipo per l'utente. Sta sull'enum e non nella riga che lo
  /// mostra: il tipo è un fatto del dato, quindi ogni punto dell'app che lo
  /// mostra dice la stessa parola.
  String get label {
    switch (this) {
      case ResultType.argomento:
        return 'Argomento';
      case ResultType.lesson:
        return 'Lezione';
      case ResultType.topic:
        return 'Topic';
      case ResultType.exercise:
        return 'Esercizio';
    }
  }
}

class SearchResult {
  final ResultType type;
  final Level? level;
  final Course? course;
  final Section? section;
  final Topic? topic;
  final Exercise? exercise;
  final Argomento? argomento;
  final Lesson? lesson;

  const SearchResult({
    required this.type,
    this.level,
    this.course,
    this.section,
    this.topic,
    this.exercise,
    this.argomento,
    this.lesson,
  });
}

class SearchIndex {
  static final SearchIndex instance = SearchIndex._();
  SearchIndex._();

  final List<SearchResult> _results = [];

  void build(List<Level> levels) {
    _results.clear();
    for (final level in levels) {
      for (final course in level.courses) {
        for (final section in course.sections) {
          for (final topic in section.topics) {
            _results.add(
              SearchResult(
                type: ResultType.topic,
                level: level,
                course: course,
                section: section,
                topic: topic,
              ),
            );
            for (final exercise in topic.exercises) {
              _results.add(
                SearchResult(
                  type: ResultType.exercise,
                  level: level,
                  course: course,
                  section: section,
                  topic: topic,
                  exercise: exercise,
                ),
              );
            }
          }
        }
      }
    }
    _buildLessons(levels);
  }

  /// Argomenti e lezioni vengono da `LessonRepository`, che lo splash carica
  /// prima di chiamare [build]. `Argomento` non porta con sé il `Level`, quindi
  /// il nome del livello — necessario perché la ricerca guarda tutti i livelli
  /// — si risolve qui e viaggia nel risultato.
  void _buildLessons(List<Level> levels) {
    final byId = {for (final level in levels) level.id: level};
    for (final argomento in LessonRepository.instance.argomenti) {
      final level = byId[argomento.levelId];
      _results.add(
        SearchResult(
          type: ResultType.argomento,
          level: level,
          argomento: argomento,
        ),
      );
      for (final lesson in argomento.lessons) {
        _results.add(
          SearchResult(
            type: ResultType.lesson,
            level: level,
            argomento: argomento,
            lesson: lesson,
          ),
        );
      }
    }
  }

  /// [types] filtra i risultati: la ricerca dell'header chiede solo argomenti
  /// e lezioni, il ramo esercizi continua a poterli chiedere tutti.
  List<SearchResult> search(String query, {List<ResultType>? types}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final matches = <SearchResult>[];
    for (final result in _results) {
      if (types != null && !types.contains(result.type)) continue;
      if (_matches(result, q)) {
        matches.add(result);
      }
    }

    matches.sort((a, b) => a.type.index.compareTo(b.type.index));
    return matches;
  }

  bool _matches(SearchResult result, String q) {
    switch (result.type) {
      case ResultType.argomento:
        final argomento = result.argomento!;
        final haystack = [
          argomento.title,
          argomento.subtitle,
        ].join(' ').toLowerCase();
        return haystack.contains(q);
      case ResultType.lesson:
        // Solo il titolo della lezione: il titolo dell'argomento è la riga
        // contesto del risultato, non parte della ricerca. Altrimenti cercare
        // «moduli» tirerebbe fuori anche «Definizione», che di moduli non parla.
        final lesson = result.lesson!;
        final haystack = [
          lesson.title,
          lesson.subtitle,
        ].join(' ').toLowerCase();
        return haystack.contains(q);
      case ResultType.topic:
        final topic = result.topic!;
        final haystack = [
          result.section?.title ?? '',
          topic.title,
          topic.subtitle,
          ...topic.exercises.expand((e) => [e.title, ...e.tags]),
        ].join(' ').toLowerCase();
        return haystack.contains(q);
      case ResultType.exercise:
        final ex = result.exercise!;
        final haystack = [
          ex.title,
          ...ex.tags,
          ...ex.formulas,
          ex.problem,
          for (final step in ex.steps) step.text,
          ...ex.hints,
        ].join(' ').toLowerCase();
        return haystack.contains(q);
    }
  }
}
