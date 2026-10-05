enum AuthMethod { manual, google }

class UserProfile {
  final String name;
  final String email;

  /// Handle univoco fra gli account di questo dispositivo, derivato dall'email
  /// e modificabile dal profilo.
  final String accountId;
  final AuthMethod authMethod;
  final String? photoUrl;

  /// Nome del simbolo dell'avatar scelto fra quelli proposti dall'app; vuoto
  /// significa iniziali.
  final String avatarId;
  final String schoolLevelId;

  /// L'anno (`Course.id`) scelto alla registrazione, dentro `schoolLevelId`;
  /// vuoto per l'università e per chi non l'ha scelto. Decide l'anno con cui
  /// si aprono Lezioni ed Esercizi.
  final String courseId;
  final DateTime createdAt;

  const UserProfile({
    required this.name,
    required this.email,
    this.accountId = '',
    this.authMethod = AuthMethod.manual,
    this.photoUrl,
    this.avatarId = '',
    this.schoolLevelId = '',
    this.courseId = '',
    required this.createdAt,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? accountId,
    AuthMethod? authMethod,
    String? photoUrl,
    String? avatarId,
    String? schoolLevelId,
    String? courseId,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      accountId: accountId ?? this.accountId,
      authMethod: authMethod ?? this.authMethod,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarId: avatarId ?? this.avatarId,
      schoolLevelId: schoolLevelId ?? this.schoolLevelId,
      courseId: courseId ?? this.courseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'accountId': accountId,
      'authMethod': authMethod.name,
      'photoUrl': photoUrl,
      'avatarId': avatarId,
      'schoolLevelId': schoolLevelId,
      'courseId': courseId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      authMethod:
          AuthMethod.values.asNameMap()[json['authMethod'] as String?] ??
          AuthMethod.manual,
      photoUrl: json['photoUrl'] as String?,
      avatarId: json['avatarId'] as String? ?? '',
      schoolLevelId: json['schoolLevelId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
