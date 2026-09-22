enum BoxType {
  image,
  chart,
  interactiveChart,
  mathFormula;

  static BoxType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return BoxType.image;
      case 'chart':
        return BoxType.chart;
      case 'interactive_chart':
        return BoxType.interactiveChart;
      case 'math_formula':
        return BoxType.mathFormula;
      default:
        return BoxType.image;
    }
  }

  String get key => switch (this) {
    BoxType.image => 'image',
    BoxType.chart => 'chart',
    BoxType.interactiveChart => 'interactive_chart',
    BoxType.mathFormula => 'math_formula',
  };

  String get label => switch (this) {
    BoxType.image => 'Immagine',
    BoxType.chart => 'Grafico',
    BoxType.interactiveChart => 'Grafico interattivo',
    BoxType.mathFormula => 'Formula',
  };
}

enum ChartKind {
  bar,
  line,
  pie;

  static ChartKind fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bar':
      case 'barre':
      case 'istogramma':
        return ChartKind.bar;
      case 'line':
      case 'linee':
        return ChartKind.line;
      case 'pie':
      case 'torta':
        return ChartKind.pie;
      default:
        return ChartKind.bar;
    }
  }

  String get key => switch (this) {
    ChartKind.bar => 'bar',
    ChartKind.line => 'line',
    ChartKind.pie => 'pie',
  };
}

enum FormulaMode {
  display,
  inline;

  static FormulaMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'display':
      case 'block':
        return FormulaMode.display;
      case 'inline':
        return FormulaMode.inline;
      default:
        return FormulaMode.display;
    }
  }
}
