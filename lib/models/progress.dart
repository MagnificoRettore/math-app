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
  final String exerciseId;
  final ExerciseStatus status;
  final bool bookmarked;

  const ExerciseProgress({
    required this.exerciseId,
    required this.status,
    required this.bookmarked,
  });

  ExerciseProgress copyWith({ExerciseStatus? status, bool? bookmarked}) {
    return ExerciseProgress(
      exerciseId: exerciseId,
      status: status ?? this.status,
      bookmarked: bookmarked ?? this.bookmarked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'status': status.name,
      'bookmarked': bookmarked,
    };
  }

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      exerciseId: json['exerciseId'] as String,
      status: ExerciseStatus.fromString(json['status'] as String?),
      bookmarked: json['bookmarked'] as bool? ?? false,
    );
  }
}
