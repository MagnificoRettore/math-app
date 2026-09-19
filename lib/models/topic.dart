import 'exercise.dart';

class Topic {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String? image;
  final List<Exercise> exercises;

  const Topic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.image,
    required this.exercises,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? 'menu_book',
      image: json['image'] as String?,
      exercises: (json['exercises'] as List<dynamic>? ?? const [])
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
