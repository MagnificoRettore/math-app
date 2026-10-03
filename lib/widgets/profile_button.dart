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

/// Diametro del badge di modifica sovrapposto all'avatar.
const double _kEditBadgeSize = 20;

/// Pulsante del profilo in testata: porta al profilo se l'utente ha fatto il
/// login, all'accesso se è ancora ospite. La registrazione non ha un punto
/// d'ingresso proprio: si arriva dal link «Registrati» del login.
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
                  color: AppColors.of(context).headerOnBlue,
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

/// L'avatar con il badge di modifica nell'angolo in basso a destra.
///
/// Il badge dice che l'avatar si tocca: porta allo stesso posto dell'avatar,
/// quindi non è una scorciatoia in più ma l'affordance di quello che già
/// c'era. Non lo ha l'ospite, che non ha un profilo da modificare.
///
/// Lo `Stack` sta in `Clip.none` perché il badge deborda di due pixel
/// oltre l'avatar: è sovrapposto, non dentro.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            key: const Key('home-profile-avatar'),
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(
              width: kProfileAvatarSize,
              height: kProfileAvatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Anello bianco: sulla pilla blu il bordo del tema sparirebbe.
                border: Border.all(color: c.headerOnBlue, width: 2),
              ),
              child: ProfileAvatar(
                user: user,
                size: kProfileAvatarSize,
                color: c.accent,
                plateColor: c.accentSoft,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              // Il badge è sopra l'avatar quindi lo copre: senza un gesto suo
              // il tap finirebbe a terra e non aprirebbe niente. `GestureDetector`
              // e non `InkWell` perché lo schermo dell'acqua si disegnerebbe
              // sul `Material` della pagina, fuori dal badge.
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Container(
                key: const Key('home-profile-edit-badge'),
                width: _kEditBadgeSize,
                height: _kEditBadgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                  border: Border.all(color: c.headerOnBlue, width: 1.5),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 12,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
