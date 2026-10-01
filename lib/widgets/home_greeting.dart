import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../theme/app_colors.dart';

/// Misura della riga 2 del saluto, cioè il nome.
const double kGreetingNameFontSize = 20;

/// Saluto della Home su due righe: la riga 1 è il «Ciao,» di cortesia, la
/// riga 2 il nome. Niente frasi a caso: due righe fisse tengono la riga
/// dell'header ferma e il nome è l'unica cosa che cambia da utente a utente.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListenableBuilder(
      listenable: AuthStore.instance,
      builder: (context, _) {
        final name = AuthStore.instance.currentUser?.name.trim() ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ciao,',
              key: const Key('home-greeting-hello'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
            Text(
              name.isEmpty ? 'Ospite' : name,
              key: const Key('home-greeting-name'),
              // Il nome può essere lunghissimo e la riga dell'header è alta
              // 80px: si tronca con i puntini invece di spingere fuori il
              // pulsante accanto o far traboccare la riga.
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: kGreetingNameFontSize,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }
}
