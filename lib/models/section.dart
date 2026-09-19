import 'topic.dart';

class Section {
  final String id;
  final String title;
  final String subtitle;
  final List<Topic> topics;

  const Section({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.topics,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      topics: (json['topics'] as List<dynamic>? ?? const [])
          .map((e) => Topic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}