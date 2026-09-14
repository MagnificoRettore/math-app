import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/course.dart';
import '../models/exercise.dart';
import '../models/level.dart';
import '../models/topic.dart';

class ExerciseLocation {
  final Level level;
  final Course course;
  final Topic topic;
  final Exercise exercise;

  const ExerciseLocation({
    required this.level,
    required this.course,
    required this.topic,
    required this.exercise,
  });
}

class ContentRepository {
  static final ContentRepository instance = ContentRepository._();

  ContentRepository._();

  List<Level> _levels = [];
  bool _loaded = false;
  Object? _loadError;

  List<Level> get levels => _levels;

  bool get loaded => _loaded;

  Object? get loadError => _loadError;

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final levelsJson =
          jsonDecode(await rootBundle.loadString('assets/data/levels.json'))
              as Map<String, dynamic>;

      final rawLevels = (levelsJson['levels'] as List<dynamic>)
          .map((e) => Level.fromJson(e as Map<String, dynamic>))
          .toList();

      final levels = <Level>[];
      for (final level in rawLevels) {
        final dataFile = level.dataFile;
        final coursesJson =
            jsonDecode(await rootBundle.loadString('assets/data/$dataFile'))
                as Map<String, dynamic>;
        final courses = (coursesJson['courses'] as List<dynamic>)
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
        levels.add(
          Level(
            id: level.id,
            title: level.title,
            subtitle: level.subtitle,
            icon: level.icon,
            dataFile: level.dataFile,
            courses: courses,
          ),
        );
      }

      _levels = levels;
      _loaded = true;
    } catch (error) {
      _loadError = error;
    }
  }

  Future<void> reload() async {
    _loaded = false;
    _levels = [];
    await load();
  }

  Level? levelById(String id) {
    for (final l in _levels) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<ExerciseLocation> allExerciseLocations() {
    final result = <ExerciseLocation>[];
    for (final level in _levels) {
      for (final course in level.courses) {
        for (final topic in course.topics) {
          for (final exercise in topic.exercises) {
            result.add(
              ExerciseLocation(
                level: level,
                course: course,
                topic: topic,
                exercise: exercise,
              ),
            );
          }
        }
      }
    }
    return result;
  }
}
