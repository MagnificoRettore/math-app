library;

part 'payloads/image_payload.dart';
part 'payloads/math_formula_payload.dart';

sealed class BoxPayload {
  const BoxPayload();

  Map<String, dynamic> toJson();
}
