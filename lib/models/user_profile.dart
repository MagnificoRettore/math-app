enum AuthMethod { manual, google }

class UserProfile {
  final String name;
  final String email;
  final String? password;
  final AuthMethod authMethod;
  final String? photoUrl;
  final String schoolLevelId;
  final DateTime createdAt;

  const UserProfile({
    required this.name,
    required this.email,
    this.password,
    this.authMethod = AuthMethod.manual,
    this.photoUrl,
    this.schoolLevelId = '',
    required this.createdAt,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? password,
    AuthMethod? authMethod,
    String? photoUrl,
    String? schoolLevelId,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
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
      'password': password,
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
      password: json['password'] as String?,
      authMethod: AuthMethod.values.asNameMap()[json['authMethod'] as String?] ??
          AuthMethod.manual,
      photoUrl: json['photoUrl'] as String?,
      schoolLevelId: json['schoolLevelId'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}