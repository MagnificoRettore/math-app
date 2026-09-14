import 'course.dart';

class Level {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String dataFile;
  final List<Course> courses;

  const Level({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dataFile,
    required this.courses,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? 'category',
      dataFile: json['dataFile'] as String? ?? '',
      courses: const [],
    );
  }
}
