enum BoxType {
  image,
  mathFormula;

  static BoxType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return BoxType.image;
      case 'math_formula':
        return BoxType.mathFormula;
      default:
        return BoxType.image;
    }
  }

  String get key => switch (this) {
    BoxType.image => 'image',
    BoxType.mathFormula => 'math_formula',
  };

  String get label => switch (this) {
    BoxType.image => 'Immagine',
    BoxType.mathFormula => 'Formula',
  };
}
