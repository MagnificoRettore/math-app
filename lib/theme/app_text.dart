/// La scala dei caratteri dell'app.
///
/// Un valore per grandezza, non uno per widget: i letterali sparsi in decine di
/// file non sono una scala, e al primo widget nuovo si ricomincia a scegliere.
/// Ridurre il corpo senza ridurre i titoli lascia il testo nei cornici, che è
/// il difetto che questa scala nasce per evitare.
///
/// I nomi sono quelli di Material per riconoscerli, ma i valori sono più bassi
/// di quelli del tema di default: l'app è densa di card e liste corte, e a 360
/// px il corpo a 15 px tagliava metà delle frasi.
///
/// Il documento delle lezioni ha i suoi slot (`docTitle`, `docHeading`,
/// `docBody`, `docMono`): è un testo lungo e non un'interfaccia, e deve poter
/// restare più grande della UI senza pestare i nomi dei ruoli.
class AppText {
  /// Titoli e bottoni: il carattere tondo del design.
  static const String headingFont = 'Fredoka';

  /// Il testo: il font di base del tema.
  static const String bodyFont = 'Nunito';

  // Interfaccia.
  static const double display = 26;
  static const double hero = 23;
  static const double headline = 21;
  static const double title = 19;
  static const double titleLarge = 18;
  static const double titleMedium = 16;
  static const double titleSmall = 15;
  static const double bodyLarge = 14;
  static const double bodyMedium = 13.5;
  static const double bodySmall = 13;
  static const double label = 12.5;
  static const double labelSmall = 12;
  static const double caption = 11.5;

  /// Il pavimento: sotto gli 11 px su un telefono non c'è più leggibilità, e
  /// i numeri più piccoli dell'app restano a `micro` invece di continuare a
  /// scendere con la scala. L'etichetta della pillola era l'unico testo sotto
  /// questa soglia (10 px) ed è salita a `micro`: era il più stretto e il primo
  /// a soffrire.
  static const double micro = 11;

  // Corpo delle lezioni.
  static const double docTitle = 24;
  static const double docHeading = 19;
  static const double docBody = 15;
  static const double docMono = 12.5;
}
