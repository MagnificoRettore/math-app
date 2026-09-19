enum ExerciseStatus {
  none,
  mastered,
  needsReview;

  static ExerciseStatus fromString(String? value) {
    switch (value) {
      case 'mastered':
        return ExerciseStatus.mastered;
      case 'needsReview':
        return ExerciseStatus.needsReview;
      default:
        return ExerciseStatus.none;
    }
  }
}

class ExerciseProgress {
  final String levelId;
  final String exerciseId;
  final ExerciseStatus status;
  final bool bookmarked;

  const ExerciseProgress({
    this.levelId = '',
    required this.exerciseId,
    required this.status,
    required this.bookmarked,
  });

  String get scopedKey => '$levelId::$exerciseId';

  ExerciseProgress copyWith({
    String? levelId,
    ExerciseStatus? status,
    bool? bookmarked,
  }) {
    return ExerciseProgress(
      levelId: levelId ?? this.levelId,
      exerciseId: exerciseId,
      status: status ?? this.status,
      bookmarked: bookmarked ?? this.bookmarked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'exerciseId': exerciseId,
      'status': status.name,
      'bookmarked': bookmarked,
    };
  }

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      levelId: json['levelId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String,
      status: ExerciseStatus.fromString(json['status'] as String?),
      bookmarked: json['bookmarked'] as bool? ?? false,
    );
  }
}
