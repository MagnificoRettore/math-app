part of '../box_payload.dart';

class ImageBoxPayload extends BoxPayload {
  final String source;

  const ImageBoxPayload({required this.source});

  factory ImageBoxPayload.fromJson(Map<String, dynamic> json) {
    return ImageBoxPayload(source: json['source'] as String? ?? '');
  }

  @override
  Map<String, dynamic> toJson() => {'source': source};
}
