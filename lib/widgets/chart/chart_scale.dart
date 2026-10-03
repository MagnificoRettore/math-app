/// Logica dei grafici, senza `package:flutter`.
///
/// Qui stanno i numeri: dominio, tick «belli», conversione in pixel,
/// campionamento delle curve e larghezza delle barre. I painter disegnano, non
/// calcolano, e i test di queste funzioni girano senza widget.
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

class ChartTick {
  /// Valore del tick nei dati.
  final double value;

  /// Etichetta già formattata, senza zeri inutili (`2` e non `2.0`).
  final String label;

  const ChartTick(this.value, this.label);
}

/// Estensione «bella» di un intervallo: stessa durata del dato, bordi su
/// poteri di dieci moltiplicati per 1, 2, 2.5 o 5.
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
    min: (lo).floorToDouble() * step,
    max: ((max + span * pad) / step).ceilToDouble() * step,
  );
}

/// Passo «bello» più vicino ad almeno [target] passi sopra l'intervallo.
double niceStep(double raw, {int target = 4}) {
  if (!raw.isFinite || raw <= 0) return 1;
  final expo = (math.log(raw) / math.ln10).floor();
  final base = math.pow(10, expo).toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0]) {
    if (base * m >= raw) return base * m;
  }
  return base * 10;
}

/// Tick dell'asse su [min]..[max], con passo 1/2/2.5/5.
List<ChartTick> niceTicks(double min, double max, {int count = 4}) {
  final step = niceStep((max - min) / math.max(1, count));
  final first = (min / step).ceilToDouble();
  final out = <ChartTick>[];
  for (var i = 0; ; i++) {
    final v = first + i * step;
    if (v > max + step * _epsilon) break;
    out.add(ChartTick(_round(v), formatTick(v)));
    if (out.length > 64) break;
  }
  return out;
}

double _round(double v) => (v * 1e6).roundToDouble() / 1e6;

/// Etichetta di un tick: intero senza decimali, altrimenti al massimo due
/// cifre e senza zeri finali, così `2.50` non finisce mai sull'asse.
String formatTick(double v) {
  final r = _round(v);
  if ((r - r.roundToDouble()).abs() < _epsilon) return r.toStringAsFixed(0);
  final text = r.toStringAsFixed(2);
  var out = text;
  while (out.contains('.') && (out.endsWith('0') || out.endsWith('.'))) {
    out = out.substring(0, out.length - 1);
  }
  return out;
}

/// Il dominio del grafico e la sua trasformazione in pixel.
///
/// [rect] è l'area di disegno utile: gli assi sono già fuori, e il painter
/// chiede le conversioni con i pixel che ha disegnato.
class ChartScale {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final RectD rect;

  const ChartScale({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.rect,
  });

  /// `true` se il dominio y attraversa lo zero: il painter ne fa una linea più
  /// marcata, perché su un grafico di funzioni è l'asse degli ascisse.
  bool get crossesZero => minY < 0 && maxY > 0;

  double yToPx(double value) {
    final t = (value - minY) / (maxY - minY);
    return rect.bottom - t * rect.height;
  }

  double xToPx(double value) {
    final t = (value - minX) / (maxX - minX);
    return rect.left + t * rect.width;
  }

  /// Il punto finisce dentro l'area di disegno.
  bool isInside(ChartPoint p) =>
      p.x >= minX - _epsilon &&
      p.x <= maxX + _epsilon &&
      p.y >= minY - _epsilon &&
      p.y <= maxY + _epsilon;
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
/// Restituisce gruppi perché è il path a dover sapere dove non passare la penna.
List<List<ChartPoint>> sampledSegments(
  String expression,
  double xMin,
  double xMax, {
  int samples = 160,
  double? clipMin,
  double? clipMax,
}) {
  if (expression.isEmpty || samples < 2 || !xMin.isFinite || !xMax.isFinite) {
    return const [];
  }
  final out = <List<ChartPoint>>[];
  var current = <ChartPoint>[];
  for (var i = 0; i < samples; i++) {
    final x = xMin + (xMax - xMin) * i / (samples - 1);
    final y = ExpressionEvaluator.tryEvaluate(expression, x: x);
    // `null` e i non finiti sono la stessa cosa: un valore assente. `sqrt` di un
    // negativo arriva come NaN, e NaN passerebbe il confronto coi clip.
    final missing =
        y == null ||
        !y.isFinite ||
        (clipMin != null && y < clipMin) ||
        (clipMax != null && y > clipMax);
    if (missing) {
      if (current.isNotEmpty) {
        out.add(current);
        current = <ChartPoint>[];
      }
      continue;
    }
    current.add(ChartPoint(x, y));
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

/// Numero di voci di [xLabels] (o di valori) su cui disegnare le barre.
int barGroupCount(ChartBoxPayload payload) {
  final fromLabels = payload.xLabels.length;
  final fromValues = [for (final s in payload.series) s.values.length]
      .fold<int>(0, math.max);
  return math.max(1, math.max(fromLabels, fromValues));
}
