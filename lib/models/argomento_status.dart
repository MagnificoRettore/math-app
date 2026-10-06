/// Lo stato di un argomento, mostrato dal badge nell'angolo della sua card.
enum ArgomentoStatus {
  notStarted,
  started,
  failed,
  passed;

  /// Il nome per lo screen reader e il tooltip.
  String get label => switch (this) {
    notStarted => 'Non iniziato',
    started => 'Iniziato',
    failed => 'Non superato',
    passed => 'Superato',
  };
}
