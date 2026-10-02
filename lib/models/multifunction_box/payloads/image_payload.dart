part of '../box_payload.dart';

class ImageBoxPayload extends BoxPayload {
  final String source;
  final String caption;
  final BoxAlign align;

  const ImageBoxPayload({
    required this.source,
    this.caption = '',
    this.align = BoxAlign.center,
  });

  factory ImageBoxPayload.fromJson(Map<String, dynamic> json) {
    return ImageBoxPayload(
      source: json['source'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      align: BoxAlign.fromString(json['align'] as String? ?? ''),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'source': source,
    if (caption.isNotEmpty) 'caption': caption,
    if (align != BoxAlign.center) 'align': align.key,
  };
}
