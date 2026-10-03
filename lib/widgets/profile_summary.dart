import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Misura della riga 1 del riepilogo, cioè il nome.
const double kSummaryNameFontSize = AppText.titleLarge;

/// Opacità della riga 2, il titolo della scuola.
///
/// Dentro la banda indaco i colori del tema non arrivano: il secondario del
/// tema sull'indaco non passa 4.5:1, quindi la riga è bianco all'80%, che
/// sull'indaco dà 9.6:1 e resta un gradino sotto il nome.
const double _kSummarySecondaryOpacity = 0.8;

/// Le due righe dentro la pilla dell'header: il nome e la scuola.
///
/// Niente saluto di cortesia: la pilla è una tessera, non una frase. Il nome
/// è l'unica cosa che cambia da utente a utente, la riga sotto dice dove si
/// studia e sparisce quando la scuola non si sa.
///
/// La scuola è quella che si sta guardando (`BrowseStore`) e non quella del
/// profilo: mentre si visitano altre scuole la pilla dice quale, come fa già
/// il bottone «Altre scuole» con la sua icona. Da ospite la visita non esiste
/// (`BrowseStore.levelId` è `null` per contratto), quindi la scuola arriva da
/// chi apre la pagina: Lezioni ed Esercizi sanno il livello che stanno
/// mostrando, la Home no e non mostra nulla.
class ProfileSummary extends StatelessWidget {
  final String? levelId;

  const ProfileSummary({super.key, this.levelId});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([AuthStore.instance, BrowseStore.instance]),
      builder: (context, _) {
        final user = AuthStore.instance.currentUser;
        final name = user?.name.trim() ?? '';
        final id =
            BrowseStore.instance.levelId ??
            user?.schoolLevelId ??
            levelId ??
            '';
        final school =
            ContentRepository.instance.levelById(id)?.title.trim() ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name.isEmpty ? 'Ospite' : name,
              key: const Key('header-name'),
              // Il nome può essere lunghissimo e accanto ci sono le icone
              // dell'header: si tronca con i puntini invece di spingere fuori
              // la riga o far traboccare la pilla.
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: kSummaryNameFontSize,
                fontWeight: FontWeight.w700,
                color: c.onHeaderBand,
              ),
            ),
            if (school.isNotEmpty)
              Text(
                school,
                key: const Key('header-school'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppText.label,
                  fontWeight: FontWeight.w600,
                  color: c.onHeaderBand.withValues(
                    alpha: _kSummarySecondaryOpacity,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
