import 'box_payload.dart';
import 'box_type.dart';

class MultifunctionBox {
  final String id;
  final BoxType boxType;
  final String title;
  final BoxPayload payload;

  const MultifunctionBox({
    required this.id,
    required this.boxType,
    required this.payload,
    this.title = '',
  });

  factory MultifunctionBox.fromJson(Map<String, dynamic> json) {
    final boxType = BoxType.fromString(json['box_type'] as String? ?? '');
    return MultifunctionBox(
      id: json['id'] as String? ?? '',
      boxType: boxType,
      title: json['title'] as String? ?? '',
      payload: _payloadFromJson(
        boxType,
        json['payload'] as Map<String, dynamic>?,
      ),
    );
  }

  static BoxPayload _payloadFromJson(BoxType type, Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return switch (type) {
      BoxType.image => ImageBoxPayload.fromJson(data),
      BoxType.chart => ChartBoxPayload.fromJson(data),
      BoxType.interactiveChart => InteractiveChartPayload.fromJson(data),
      BoxType.mathFormula => MathFormulaPayload.fromJson(data),
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'box_type': boxType.key,
    if (title.isNotEmpty) 'title': title,
    'payload': payload.toJson(),
  };
}
