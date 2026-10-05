import 'dart:convert';

/// La forma di riferimento dei JSON dei contenuti (vedi `JSON_GUIDELINES.md`):
/// 4 spazi; un array di soli numeri su una riga (`[-3, 3]`); le coppie di
/// numeri su una riga se ci stanno in 100 colonne; gli altri array un elemento
/// per riga; ordine delle chiavi invariato; a capo finale.
///
/// Con [compactObjects] anche un oggetto che contiene solo valori semplici (o
/// array di numeri) sta su una riga se ci sta: è la forma dei grafici nel
/// Markdown, dove un elemento per riga si legge meglio.
String formatJson(Object? data, {bool compactObjects = false}) =>
    '${_dump(data, 0, compactObjects)}\n';

const _indent = '    ';
const _maxInline = 100;

bool _isNumber(Object? v) => v is num;

bool _isNumericList(Object? v) =>
    v is List && v.isNotEmpty && v.every(_isNumber);

String _inline(List<Object?> v) => '[${v.map(jsonEncode).join(', ')}]';

String _dump(Object? v, int level, bool compact) {
  final pad = _indent * level;
  final inner = _indent * (level + 1);
  if (v is Map) {
    if (v.isEmpty) return '{}';
    if (compact && v.values.every(_isSimple)) {
      final line =
          '{${v.entries.map((e) => '${jsonEncode(e.key)}: ${_dump(e.value, 0, false)}').join(', ')}}';
      if (pad.length + line.length <= _maxInline) return line;
    }
    final items = [
      for (final e in v.entries)
        '$inner${jsonEncode(e.key)}: ${_dump(e.value, level + 1, compact)}',
    ];
    return '{\n${items.join(',\n')}\n$pad}';
  }
  if (v is List) {
    if (v.isEmpty) return '[]';
    if (_isNumericList(v)) return _inline(v);
    if (v.every(_isNumericList)) {
      final line = '[${v.map((x) => _inline(x as List<Object?>)).join(', ')}]';
      if (pad.length + line.length <= _maxInline) return line;
    }
    return '[\n${v.map((x) => '$inner${_dump(x, level + 1, compact)}').join(',\n')}\n$pad]';
  }
  // jsonEncode scrive i caratteri non ASCII così come sono.
  return jsonEncode(v);
}

bool _isSimple(Object? v) =>
    v is! Map && v is! List || _isNumericList(v) || (v is List && v.isEmpty);
