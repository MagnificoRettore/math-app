import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../models/user_profile.dart';
import '../screens/profile_screen.dart';
import '../screens/registration_screen.dart';
import '../theme/app_colors.dart';

/// Diametro dell'avatar del profilo: stessa misura su tutte le pagine, così
/// l'icona non cambia grandezza passando da una schermata all'altra.
const double kProfileAvatarSize = 50;

/// Pulsante del profilo in alto a destra: porta al profilo se l'utente ha
/// fatto il login, alla creazione del profilo se è ancora ospite.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthStore.instance,
      builder: (context, _) {
        final user = AuthStore.instance.currentUser;
        if (user == null) {
          return SizedBox(
            width: kProfileAvatarSize,
            height: kProfileAvatarSize,
            child: Center(
              child: IconButton(
                key: const Key('profile-button-guest'),
                icon: Icon(
                  Icons.person_outline,
                  color: AppColors.of(context).textPrimary,
                  size: 32,
                ),
                tooltip: 'Crea il tuo profilo',
                onPressed: () => _openRegistration(context),
              ),
            ),
          );
        }
        return _ProfileAvatar(user: user);
      },
    );
  }

  void _openRegistration(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegistrationScreen()));
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserProfile user;

  String _initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    String first(String value) {
      final runes = value.runes;
      return runes.isEmpty ? '' : String.fromCharCode(runes.first);
    }

    if (parts.length == 1) return first(parts.first).toUpperCase();
    return '${first(parts.first)}${first(parts.last)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final photo = user.photoUrl?.trim() ?? '';
    return Center(
      child: InkWell(
        key: const Key('home-profile-avatar'),
        customBorder: const CircleBorder(),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
        child: Container(
          width: kProfileAvatarSize,
          height: kProfileAvatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.accentSoft,
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: photo.isEmpty
              ? _Initials(initials: _initialsOf(user.name))
              : Image.network(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _Initials(initials: _initialsOf(user.name)),
                ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: c.accent,
        ),
      ),
    );
  }
}
