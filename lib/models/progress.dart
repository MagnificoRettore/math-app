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
  /// A chi appartiene il progresso: l'ID account, o [guestOwner] se non c'è
  /// una sessione.
  final String ownerId;
  final String levelId;
  final String exerciseId;
  final ExerciseStatus status;

  static const guestOwner = 'guest';

  const ExerciseProgress({
    this.ownerId = guestOwner,
    this.levelId = '',
    required this.exerciseId,
    required this.status,
  });

  String get scopedKey => '$ownerId::$levelId::$exerciseId';

  ExerciseProgress copyWith({String? levelId, ExerciseStatus? status}) {
    return ExerciseProgress(
      ownerId: ownerId,
      levelId: levelId ?? this.levelId,
      exerciseId: exerciseId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'levelId': levelId,
      'exerciseId': exerciseId,
      'status': status.name,
    };
  }

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      // I salvataggi di prima non hanno il proprietario: erano di chi usava
      // l'app senza account.
      ownerId: json['ownerId'] as String? ?? guestOwner,
      levelId: json['levelId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String,
      status: ExerciseStatus.fromString(json['status'] as String?),
    );
  }
}
