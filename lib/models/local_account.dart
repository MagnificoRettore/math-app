import 'user_profile.dart';

/// Account salvato sul dispositivo: il profilo più il materiale sensibile.
///
/// La password sta qui e non nel profilo, perché il profilo viene mostrato e
/// questa parte no. Un account registrato con Google non ha password, quindi
/// [passwordHash] e [passwordSalt] restano vuoti e l'unico modo di rientrare è
/// il pulsante Google.
class LocalAccount {
  final UserProfile profile;
  final String passwordHash;
  final String passwordSalt;

  const LocalAccount({
    required this.profile,
    required this.passwordHash,
    required this.passwordSalt,
  });

  /// `true` quando l'account ha una password con cui rientrare.
  bool get hasPassword => passwordHash.isNotEmpty && passwordSalt.isNotEmpty;

  LocalAccount copyWith({
    UserProfile? profile,
    String? passwordHash,
    String? passwordSalt,
  }) {
    return LocalAccount(
      profile: profile ?? this.profile,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'passwordHash': passwordHash,
      'passwordSalt': passwordSalt,
    };
  }

  factory LocalAccount.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    return LocalAccount(
      profile: profile is Map<String, dynamic>
          ? UserProfile.fromJson(profile)
          : UserProfile.fromJson(json),
      passwordHash: json['passwordHash'] as String? ?? '',
      passwordSalt: json['passwordSalt'] as String? ?? '',
    );
  }
}
