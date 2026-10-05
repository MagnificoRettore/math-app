import '../../models/multifunction_box/box_payload.dart';
import '../expression_evaluator.dart';

/// Gli slider di un grafico: logica pura, senza `package:flutter`.
///
/// Un grafico con `params` scrive i suoi valori con i nomi dei parametri
/// (`"m*x + q"`, `"at": [0, "q"]`). Per ogni posizione degli slider si mettono
/// i numeri al posto dei nomi e si rilegge il JSON: tutto il resto (layout,
/// tracciati, riempimenti) lavora su un grafico già ordinario.

/// I valori di partenza degli slider.
Map<String, double> defaultParamValues(GraphPayload payload) => {
  for (final p in payload.params) p.name: p.value,
};

/// Il grafico con i parametri sostituiti dai [values]. Senza parametri è lo
/// stesso grafico.
GraphPayload resolveGraph(GraphPayload payload, Map<String, double> values) {
  final source = payload.source;
  if (payload.params.isEmpty || source == null) return payload;
  final json = <String, dynamic>{
    for (final e in source.entries)
      if (e.key != 'items' && e.key != 'params') e.key: e.value,
    'items': [
      for (final item in source['items'] as List<dynamic>? ?? const [])
        item is Map<String, dynamic> ? _resolveItem(item, values) : item,
    ],
  };
  // I parametri restano quelli del grafico originale: lo slider non li cambia.
  final resolved = GraphPayload.fromJson(json);
  return GraphPayload(
    plane: resolved.plane,
    x: resolved.x,
    y: resolved.y,
    aspect: resolved.aspect,
    grid: resolved.grid,
    xLabel: resolved.xLabel,
    yLabel: resolved.yLabel,
    items: resolved.items,
    categories: resolved.categories,
    series: resolved.series,
    hidden: resolved.hidden,
  );
}

/// Un'espressione con i nomi dei parametri al posto dei numeri.
String substituteParams(String expr, Map<String, double> values) {
  var out = expr;
  for (final e in values.entries) {
    out = out.replaceAll(
      RegExp('(?<![A-Za-z0-9_])${RegExp.escape(e.key)}(?![A-Za-z0-9_])'),
      _literal(e.value),
    );
  }
  return out;
}

/// Un numero come lo legge il motore delle espressioni: niente notazione
/// scientifica, e fra parentesi se negativo.
String _literal(double v) {
  var s = v.toStringAsFixed(6);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  if (s == '-0') s = '0';
  return v < 0 ? '($s)' : s;
}

/// Un numero scritto come numero o come espressione dei parametri; altrimenti
/// com'è (l'elemento sarà scartato dal modello, come ogni valore che non si
/// capisce).
Object? _num(Object? v, Map<String, double> values) {
  if (v is! String) return v;
  return ExpressionEvaluator.tryEvaluate(substituteParams(v, values)) ?? v;
}

List<Object?> _nums(Object? v, Map<String, double> values) =>
    v is List ? [for (final x in v) _num(x, values)] : const [];

Object? _pairs(Object? v, Map<String, double> values) =>
    v is List ? [for (final p in v) _nums(p, values)] : v;

Object? _expr(Object? v, Map<String, double> values) =>
    v is String ? substituteParams(v, values) : v;

Map<String, dynamic> _resolveItem(
  Map<String, dynamic> item,
  Map<String, double> values,
) {
  final out = Map<String, dynamic>.from(item);
  void numeric(String key) {
    if (out.containsKey(key)) out[key] = _num(out[key], values);
  }

  void point(String key) {
    if (out.containsKey(key)) out[key] = _nums(out[key], values);
  }

  void pairs(String key) {
    if (out.containsKey(key)) out[key] = _pairs(out[key], values);
  }

  void expression(String key) {
    if (out.containsKey(key)) out[key] = _expr(out[key], values);
  }

  switch (item['type']) {
    case 'function':
      expression('expr');
      point('domain');
    case 'point':
      point('at');
    case 'line':
      numeric('x');
      numeric('y');
      pairs('through');
    case 'curve':
      expression('x');
      expression('y');
      point('t');
    case 'circle':
      point('center');
      numeric('radius');
    case 'segment' || 'vector':
      point('from');
      point('to');
    case 'polygon':
      pairs('points');
    case 'area':
      numeric('from');
      numeric('to');
      expression('under');
      final between = out['between'];
      if (between is List) {
        out['between'] = [for (final b in between) _expr(b, values)];
      }
    case 'region':
      final where = out['where'];
      if (where is List) {
        out['where'] = [for (final w in where) _expr(w, values)];
      }
  }
  return out;
}

/// Un punto trascinabile: quale elemento è, e quali parametri muove (`null` =
/// quella coordinata non dipende dal trascinamento).
class DragHandle {
  final int itemIndex;
  final String? xParam;
  final String? yParam;

  const DragHandle(this.itemIndex, this.xParam, this.yParam);
}

/// I punti `draggable` del grafico. Una coordinata si trascina se è il nome di
/// un parametro (`"at": ["px", "py"]`); le altre (numeri o espressioni) seguono.
/// Un punto senza nessuna coordinata di questo tipo non ha niente da muovere.
List<DragHandle> dragHandles(GraphPayload payload) {
  final source = payload.source;
  if (source == null) return const [];
  final names = {for (final p in payload.params) p.name};
  final out = <DragHandle>[];
  final items = source['items'] as List<dynamic>? ?? const [];
  for (final (i, item) in items.indexed) {
    if (item is! Map<String, dynamic> ||
        item['type'] != 'point' ||
        item['draggable'] != true) {
      continue;
    }
    final at = item['at'];
    if (at is! List || at.length < 2) continue;
    String? param(Object? v) =>
        v is String && names.contains(v.trim()) ? v.trim() : null;
    final x = param(at[0]), y = param(at[1]);
    if (x != null || y != null) out.add(DragHandle(i, x, y));
  }
  return out;
}

/// [value] portato sullo scatto più vicino dello slider, dentro `[min, max]`.
double snapParam(GraphParam p, double value) {
  final steps = ((value - p.min) / p.step).round();
  return (p.min + steps * p.step).clamp(p.min, p.max).toDouble();
}
