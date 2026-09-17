enum AuthMethod { manual, google }

class UserProfile {
  final String name;
  final String email;
  final AuthMethod authMethod;
  final String? photoUrl;
  final String schoolLevelId;
  final DateTime createdAt;

  const UserProfile({
    required this.name,
    required this.email,
    this.authMethod = AuthMethod.manual,
    this.photoUrl,
    this.schoolLevelId = '',
    required this.createdAt,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    AuthMethod? authMethod,
    String? photoUrl,
    String? schoolLevelId,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      authMethod: authMethod ?? this.authMethod,
      photoUrl: photoUrl ?? this.photoUrl,
      schoolLevelId: schoolLevelId ?? this.schoolLevelId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'authMethod': authMethod.name,
      'photoUrl': photoUrl,
      'schoolLevelId': schoolLevelId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      authMethod:
          AuthMethod.values.asNameMap()[json['authMethod'] as String?] ??
          AuthMethod.manual,
      photoUrl: json['photoUrl'] as String?,
      schoolLevelId: json['schoolLevelId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
