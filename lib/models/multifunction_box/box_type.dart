enum BoxType {
  image,
  mathFormula,
  graph;

  static BoxType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return BoxType.image;
      case 'math_formula':
        return BoxType.mathFormula;
      case 'graph':
        return BoxType.graph;
      default:
        return BoxType.image;
    }
  }

  String get key => switch (this) {
    BoxType.image => 'image',
    BoxType.mathFormula => 'math_formula',
    BoxType.graph => 'graph',
  };

  String get label => switch (this) {
    BoxType.image => 'Immagine',
    BoxType.mathFormula => 'Formula',
    BoxType.graph => 'Grafico',
  };
}
