part of '../box_payload.dart';

class ImageBoxPayload extends BoxPayload {
  final String source;
  final String caption;

  const ImageBoxPayload({required this.source, this.caption = ''});

  factory ImageBoxPayload.fromJson(Map<String, dynamic> json) {
    return ImageBoxPayload(
      source: json['source'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'source': source,
    if (caption.isNotEmpty) 'caption': caption,
  };
}
