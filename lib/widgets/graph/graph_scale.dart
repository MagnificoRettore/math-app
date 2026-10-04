/// Logica dei grafici, senza `package:flutter`.
///
/// Qui stanno i numeri: dominio, tick «belli», conversione in pixel,
/// campionamento delle funzioni e larghezza delle barre. I painter disegnano,
/// non calcolano, e i test di queste funzioni girano senza widget.
///
/// La regola dei buchi è la più importante del file: un valore che non esiste
/// (`sqrt` di un negativo, divisione per zero, `tan` vicino ai poli) **non è
/// zero**, è assente. Collegare i due lati di un buco stampa una retta
/// verticale che nel grafico non c'è, quindi chi spezza il path restituisce i
/// punti in gruppi separati ([sampledSegments]).
library;

import 'dart:math' as math;

import '../../models/multifunction_box/box_payload.dart';
import '../expression_evaluator.dart';

const double _epsilon = 1e-9;

class GraphTick {
  /// Valore del tick nei dati.
  final double value;

  /// Etichetta già formattata, senza zeri inutili (`2` e non `2.0`).
  final String label;

  const GraphTick(this.value, this.label);
}

/// Estensione «bella» di un intervallo: bordi su potenze di dieci moltiplicate
/// per 1, 2, 2.5 o 5.
///
/// Un dominio come `[0, 7]` diventa `[0, 8]`: le etichette dell'asse diventano
/// numeri che si ricordano, e i tick restano equidistanti.
({double min, double max}) niceRange(
  double min,
  double max, {
  double pad = 0.08,
}) {
  if (!min.isFinite || !max.isFinite) return (min: 0, max: 1);
  if ((max - min).abs() < _epsilon) {
    final bump = max.abs() < _epsilon ? 1.0 : max.abs() * 0.5;
    return (min: min - bump, max: max + bump);
  }
  final span = max - min;
  // Il passo si calcola sui dati, non sul padding: misurarlo sul padding
  // allargava il dominio di un'intera fascia (16 di dati diventavano 25).
  final step = niceStep(span / 4);
  var lo = (min - span * pad) / step;
  // Con dati tutti non negativi l'asse resta a zero: mostrare -2 sotto una
  // serie che parte da 0 spende un quinto dell'altezza per niente.
  if (min >= 0 && lo < 0) lo = 0;
  return (
    min: lo.floorToDouble() * step,
    max: ((max + span * pad) / step).ceilToDouble() * step,
  );
}

/// Passo «bello» più vicino ad almeno [raw]: 1, 2, 2.5 o 5 per una potenza di
/// dieci.
double niceStep(double raw) {
  if (!raw.isFinite || raw <= 0) return 1;
  final expo = (math.log(raw) / math.ln10).floor();
  final base = math.pow(10, expo).toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0]) {
    if (base * m >= raw - _epsilon) return base * m;
  }
  return base * 10;
}

/// I multipli di [step] dentro [min]..[max].
List<GraphTick> ticksEvery(double min, double max, double step) {
  if (!step.isFinite || step <= 0) return const [];
  final first = (min / step).ceilToDouble() * step;
  final out = <GraphTick>[];
  for (var v = first; v <= max + step * _epsilon; v += step) {
    out.add(GraphTick(_round(v), formatTick(v)));
    if (out.length > 200) break;
  }
  return out;
}

/// Tick dell'asse su [min]..[max], con passo 1/2/2.5/5.
List<GraphTick> niceTicks(double min, double max, {int count = 4}) =>
    ticksEvery(min, max, niceStep((max - min) / math.max(1, count)));

double _round(double v) => (v * 1e6).roundToDouble() / 1e6;

/// Etichetta di un tick: intero senza decimali, altrimenti al massimo due
/// cifre e senza zeri finali, così `2.50` non finisce mai sull'asse.
String formatTick(double v) {
  final r = _round(v);
  if ((r - r.roundToDouble()).abs() < _epsilon) return r.toStringAsFixed(0);
  var out = r.toStringAsFixed(2);
  while (out.contains('.') && (out.endsWith('0') || out.endsWith('.'))) {
    out = out.substring(0, out.length - 1);
  }
  return out;
}

/// Il dominio del grafico e la sua trasformazione in pixel, sui due assi.
///
/// [rect] è l'area dei dati: tutto ciò che è dentro il dominio finisce lì.
class GraphScale {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final RectD rect;

  const GraphScale({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.rect,
  });

  double get spanX => maxX - minX;
  double get spanY => maxY - minY;

  bool containsX(double x) => x >= minX - _epsilon && x <= maxX + _epsilon;
  bool containsY(double y) => y >= minY - _epsilon && y <= maxY + _epsilon;

  /// Dove passa l'asse x: allo zero se c'è, altrimenti sul bordo più vicino.
  double get axisY => minY > 0 ? minY : (maxY < 0 ? maxY : 0);

  /// Dove passa l'asse y: allo zero se c'è, altrimenti sul bordo più vicino.
  double get axisX => minX > 0 ? minX : (maxX < 0 ? maxX : 0);

  double xToPx(double value) => rect.left + (value - minX) / spanX * rect.width;

  double yToPx(double value) =>
      rect.bottom - (value - minY) / spanY * rect.height;
}

/// Area di disegno in pixel, detta con numeri per non avere `Rect` (che viene da
/// `dart:ui`) in un file di logica pura.
class RectD {
  final double left;
  final double top;
  final double width;
  final double height;

  const RectD(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;
}

/// Campiona [expression] su [samples] punti equispaziati fra [xMin] e [xMax].
///
/// Un valore assente (parsing fallito, non finito, modulo per zero) **spezza il
/// tratto**: i punti sono restituiti a gruppi e un gruppo vuoto è un buco.
///
/// Con [yMin] e [yMax], il dominio visibile, si spezza anche lontano da lì: un
/// punto oltre un'altezza del grafico sopra o sotto è un asintoto e non va
/// collegato al successivo, che sta dall'altra parte (`1/x` vicino a zero).
/// Dentro quella fascia invece i punti restano, così una curva esce dal bordo
/// e non si ferma un pixel prima.
List<List<GraphXY>> sampledSegments(
  String expression,
  double xMin,
  double xMax, {
  int samples = 160,
  double? yMin,
  double? yMax,
}) {
  if (expression.isEmpty || samples < 2 || !xMin.isFinite || !xMax.isFinite) {
    return const [];
  }
  final band = (yMin != null && yMax != null) ? (yMax - yMin) : null;
  final out = <List<GraphXY>>[];
  var current = <GraphXY>[];
  for (var i = 0; i < samples; i++) {
    final x = xMin + (xMax - xMin) * i / (samples - 1);
    final y = ExpressionEvaluator.tryEvaluate(expression, x: x);
    // `null` e i non finiti sono la stessa cosa: un valore assente. `sqrt` di un
    // negativo arriva come NaN, e NaN passerebbe ogni confronto.
    final missing =
        y == null ||
        !y.isFinite ||
        (band != null && (y < yMin! - band || y > yMax! + band));
    if (missing) {
      if (current.isNotEmpty) {
        out.add(current);
        current = <GraphXY>[];
      }
      continue;
    }
    current.add(GraphXY(x, y));
  }
  if (current.isNotEmpty) out.add(current);
  return out;
}

/// Larghezza delle barre di un gruppo: 70% della casella, divisa fra le serie.
({double width, double gap}) barGeometry({
  required double plotWidth,
  required int groups,
  required int series,
}) {
  final cell = plotWidth / math.max(1, groups);
  final group = cell * 0.7;
  final width = series <= 1 ? group : group / series - 2;
  return (width: math.max(1.0, width), gap: 2.0);
}

/// Numero di caselle delle barre: le categorie, o la serie più lunga se le
/// categorie mancano o sono meno. Mai zero.
int barGroupCount(int categories, Iterable<int> seriesLengths) =>
    math.max(1, math.max(categories, seriesLengths.fold<int>(0, math.max)));
