import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../models/user_profile.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_colors.dart';
import 'profile_avatar.dart';

/// Diametro dell'avatar del profilo: stessa misura su tutte le pagine, così
/// l'icona non cambia grandezza passando da una schermata all'altra.
const double kProfileAvatarSize = 50;

/// Pulsante del profilo in alto a destra: porta al profilo se l'utente ha
/// fatto il login, all'accesso se è ancora ospite. La registrazione non ha
/// un punto d'ingresso proprio: si arriva dal link «Registrati» del login.
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
                tooltip: 'Accedi',
                onPressed: () => _openLogin(context),
              ),
            ),
          );
        }
        return _ProfileAvatar(user: user);
      },
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
            border: Border.all(color: c.border),
          ),
          child: ProfileAvatar(
            user: user,
            size: kProfileAvatarSize,
            color: c.accent,
            plateColor: c.accentSoft,
          ),
        ),
      ),
    );
  }
}
