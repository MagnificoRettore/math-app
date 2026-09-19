import 'section.dart';
import 'topic.dart';

class Course {
  final String id;
  final String title;
  final String subtitle;
  final List<Section> sections;

  const Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  List<Topic> get topics => sections.expand((s) => s.topics).toList();

  factory Course.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>?;
    final rawTopics = json['topics'] as List<dynamic>?;
    final sections = rawSections != null
        ? rawSections
              .map((e) => Section.fromJson(e as Map<String, dynamic>))
              .toList()
        : rawTopics == null
              ? const <Section>[]
              : [
                  Section(
                    id: '${json['id']}-general',
                    title: 'Argomenti',
                    subtitle: '',
                    topics: rawTopics
                        .map((e) => Topic.fromJson(e as Map<String, dynamic>))
                        .toList(),
                  ),
                ];
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      sections: sections,
    );
  }
}