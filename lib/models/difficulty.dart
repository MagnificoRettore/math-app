enum Difficulty {
  easy,
  medium,
  hard;

  static Difficulty fromString(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      default:
        return Difficulty.medium;
    }
  }

  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Facile';
      case Difficulty.medium:
        return 'Medio';
      case Difficulty.hard:
        return 'Difficile';
    }
  }
}
