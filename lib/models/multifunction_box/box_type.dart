enum BoxType {
  image,
  mathFormula,
  chart;

  static BoxType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return BoxType.image;
      case 'math_formula':
        return BoxType.mathFormula;
      case 'chart':
        return BoxType.chart;
      default:
        return BoxType.image;
    }
  }

  String get key => switch (this) {
    BoxType.image => 'image',
    BoxType.mathFormula => 'math_formula',
    BoxType.chart => 'chart',
  };

  String get label => switch (this) {
    BoxType.image => 'Immagine',
    BoxType.mathFormula => 'Formula',
    BoxType.chart => 'Grafico',
  };
}
